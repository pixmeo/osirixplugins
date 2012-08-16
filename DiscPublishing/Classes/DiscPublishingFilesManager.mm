//
//  DiscPublishingFilesManager.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingFilesManager.h"
#import "NSString+DiscPublishing.h"
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/ThreadsManager.h>
#import "NSUserDefaultsController+DiscPublishing.h"
#import "NSArray+DiscPublishing.h"
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomDatabase.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingOptions.h"
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/N2Stuff.h>


@interface DiscPublishingFilesManager (Private)

-(NSArray*)namesForStudies:(NSArray*)studies;
-(NSArray*)studiesForImages:(NSArray*)images;
-(void)spawnBurns;
-(void)spawnPatientBurn:(NSString*)patientUID;

@end

@interface DiscPublishingDummyThread : NSThread
@end
@implementation DiscPublishingDummyThread

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        while (!self.isCancelled)
            [NSThread sleepForTimeInterval:0.01];
    } @catch (...) {
        // do nothing
    } @finally {
        [pool release];
    }
}

@end

@interface DiscPublishingPatientStack : NSObject {
    NSMutableArray* _images;
    DiscPublishingDummyThread* _dummyThread;
    NSDate* _lastAdditionDate;
    NSTimer* _refreshTimer;
}

@property(retain) NSDate* lastAdditionDate;

@end

@implementation DiscPublishingPatientStack

@synthesize lastAdditionDate = _lastAdditionDate;

-(id)initWithPatientName:(NSString*)patientName {
    if ((self = [super init])) {
        _dummyThread = [[DiscPublishingDummyThread alloc] init];
        _dummyThread.name = [NSString stringWithFormat:NSLocalizedString(@"Receiving images for %@", nil), patientName];
        _dummyThread.status = NSLocalizedString(@"Initializing...", nil);
        _dummyThread.supportsCancel = YES;
        [ThreadsManager.defaultManager addThreadAndStart:_dummyThread];
        
        _images = [[NSMutableArray alloc] init];
        
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_timerRefresh:) userInfo:nil repeats:YES];
    }
    
    return self;
}

-(void)invalidate {
    [_refreshTimer invalidate]; _refreshTimer = nil;
    [_dummyThread cancel];
}

-(void)dealloc {
    [_dummyThread release];
    [_images release];
    self.lastAdditionDate = nil;
    [super dealloc];
}

-(NSArray*)images {
    return _images;
}

-(void)addImage:(DicomImage*)image {
    [_images addObject:image];
    self.lastAdditionDate = [NSDate date];
}

-(void)_timerRefresh:(NSTimer*)timer {
    if (_lastAdditionDate) {
        CGFloat s = floorf(-[_lastAdditionDate timeIntervalSinceNow]);
        _dummyThread.status = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ since last transfer", nil), N2LocalizedSingularPluralCount(_images.count, @"image", @"images"), N2LocalizedSingularPluralCount(s, @"second", @"seconds")];
    }
}

-(BOOL)isCancelled {
    return _dummyThread.isCancelled;
}

@end

@implementation DiscPublishingFilesManager

-(id)init {
	if ((self = [super init])) {
        _patientStacks = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddition:) name:OsirixAddToDBCompleteNotification object:NULL];
        _publishTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_timerPublish:) userInfo:nil repeats:YES];
	}
    
	return self;
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddToDBCompleteNotification object:NULL];
	[_patientStacks release];
	[super dealloc];
}

-(id)invalidate {
    [_publishTimer invalidate];
    _publishTimer = nil;
    return self;
}

-(void)_timerPublish:(NSTimer*)timer {
	NSTimeInterval burnDelay = [[NSUserDefaultsController sharedUserDefaultsController] discPublishingPatientModeDelay];
    
    @synchronized (_patientStacks) {
        for (NSString* key in _patientStacks.allKeys) { // allKeys in not mutable, so we can safely iterate
            DiscPublishingPatientStack* dpps = [_patientStacks objectForKey:key];
            
            if (dpps.isCancelled) {
                [_patientStacks removeObjectForKey:key];
                continue;
            }
            
            if (-[dpps.lastAdditionDate timeIntervalSinceNow] > burnDelay) {
                [dpps retain];
                
                [dpps invalidate];
                [_patientStacks removeObjectForKey:key];
                
                DiscPublishingPatientDisc* dppd = [[[DiscPublishingPatientDisc alloc] initWithImages:dpps.images options:[[NSUserDefaultsController sharedUserDefaultsController] discPublishingPatientModeOptions]] autorelease];
                [[ThreadsManager defaultManager] addThreadAndStart:dppd];
                
                [dpps release];
            }
        }
    }
}

-(DiscPublishingPatientStack*)stackForImage:(DicomImage*)image {
    @synchronized (_patientStacks) {
        DiscPublishingPatientStack* dpps = [_patientStacks objectForKey:image.series.study.patientUID];
        if (dpps)
            return dpps;
        
        dpps = [[[DiscPublishingPatientStack alloc] initWithPatientName:image.series.study.name] autorelease];
        [_patientStacks setObject:dpps forKey:image.series.study.patientUID];
        
        return dpps;
    }
    
    return nil;
}

-(void)observeDatabaseAddition:(NSNotification*)notification {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(observeDatabaseAddition:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    if (![[NSUserDefaultsController sharedUserDefaultsController] discPublishingIsActive])
		return;
    
	NSArray* addedImages = [[notification userInfo] objectForKey:OsirixAddToDBNotificationImagesArray];
	
	for (DicomImage* image in addedImages)
        @try {
            if ([image managedObjectContext] == [[DicomDatabase defaultDatabase] managedObjectContext]) {
                DiscPublishingPatientStack* dpps = [self stackForImage:image];
                if (![dpps.images containsObject:image])
                    if (image.modality && ![image.modality isEqual:@"SR"]) // TODO: why?
                        [dpps addImage:image];
            }
        } @catch (NSException* e) {
            NSLog(@"[DiscPublishingFilesManager observeDatabaseAddition:] error: %@", e.reason);
        }
}

/*-(NSArray*)namesForStudies:(NSArray*)studies {
	NSMutableArray* names = [[NSMutableArray alloc] initWithCapacity:studies.count];
	
	for (DicomStudy* study in studies) {
		NSString* name = [study valueForKeyPath:@"name"];
		if (![names containsObject:name])
			[names addObject:name];
	}
	
	return [names autorelease];
}

-(NSArray*)studiesForImages:(NSArray*)images {
	NSMutableArray* studies = [[NSMutableArray alloc] initWithCapacity:8];
	
	for (DicomImage* image in images) {
		DicomStudy* study = [image valueForKeyPath:@"series.study"];
		if (![studies containsObject:study])
			[studies addObject:study];
	}
	
	return [studies autorelease];
}*/

@end
























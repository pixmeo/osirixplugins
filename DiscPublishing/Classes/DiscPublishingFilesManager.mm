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
#import <OsiriXAPI/NSString+N2.h>
#import "DiscPublishingTool.h"
#import <OsiriX/DCMAbstractSyntaxUID.h>
#include <cmath>


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

-(id)initWithPatientName:(NSString*)patientName serviceId:(NSString*)sid {
    if ((self = [super init])) {
        _dummyThread = [[DiscPublishingDummyThread alloc] init];
        if (!sid)
            _dummyThread.name = patientName;
        else _dummyThread.name = [NSString stringWithFormat:@"%@ [%@]", patientName, [NSUserDefaultsController.sharedUserDefaultsController DPServiceNameForId:sid]];
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

+ (NSString*)timeString:(NSTimeInterval)time {
    NSMutableArray* rs = [NSMutableArray array];
    
    do {
        NSString* unit; unsigned value;
        if (time < 60) {
            unit = NSLocalizedString(@"s", @"short for second/seconds");
            value = std::floor(time);
            time -= value;
        } else if (time < 3600) {
            unit = NSLocalizedString(@"m", @"short for minute/minutes");
            value = std::floor(time/60);
            time -= value*60;
        } else {
            unit = NSLocalizedString(@"h", @"short for hour/hours");
            value = std::floor(time/3600);
            time -= value*3600;
        }
        
        NSString* s = [NSString stringWithFormat:@"%d%@", value, unit];
        [rs addObject:s];
    } while (/*rs.count < maxUnits && */time >= 1);
    
    NSMutableString* s = [NSMutableString string];
    for (NSUInteger i = 0; i < rs.count; ++i)
        [s appendString:[rs objectAtIndex:i]];
    
    return s;
}

-(void)addImage:(DicomImage*)image {
    [_images addObject:image];
    self.lastAdditionDate = [NSDate date];
}

-(void)_timerRefresh:(NSTimer*)timer {
    if (_lastAdditionDate) {
        CGFloat s = floorf(-[_lastAdditionDate timeIntervalSinceNow]);
        _dummyThread.status = [NSString stringWithFormat:NSLocalizedString(@"%@, %@ since last transfer", nil), N2LocalizedSingularPluralCount(_images.count, NSLocalizedString(@"image", nil), NSLocalizedString(@"images", nil)), [[self class] timeString:s]/*N2LocalizedSingularPluralCount(s, @"second", @"seconds")*/];
    }
}

-(BOOL)isCancelled {
    return _dummyThread.isCancelled;
}

@end

@implementation DiscPublishingFilesManager

-(id)init {
	if ((self = [super init])) {
        _serviceStacks = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeDatabaseAddition:) name:OsirixAddToDBCompleteNotification object:NULL];
        _publishTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(_timerPublish:) userInfo:nil repeats:YES];
        
        [NSDistributedNotificationCenter.defaultCenter addObserver:self selector:@selector(observeJobCompletedNotification:) name:DPTJobCompletedNotification object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	}
    
	return self;
}

-(void)dealloc {
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddToDBCompleteNotification object:NULL];
	[_serviceStacks release];
	[super dealloc];
}

-(id)invalidate {
    [_publishTimer invalidate];
    _publishTimer = nil;
    return self;
}

-(void)_timerPublish:(NSTimer*)timer {
    @synchronized (_serviceStacks) {
        for (NSString* sid in _serviceStacks.allKeys) { // allKeys in not mutable, so we can safely iterate
            NSMutableDictionary* serviceStacks = [_serviceStacks objectForKey:sid];
            
            if ([sid isKindOfClass:[NSNull class]])
                sid = nil;
            NSTimeInterval serviceDelay = [NSUserDefaultsController.sharedUserDefaultsController DPDelayForServiceId:sid];
            
            for (NSString* key in serviceStacks.allKeys) { // allKeys in not mutable, so we can safely iterate
                DiscPublishingPatientStack* dpps = [serviceStacks objectForKey:key];
                
                if (dpps.isCancelled) {
                    [serviceStacks removeObjectForKey:key];
                    continue;
                }
                
                if (-[dpps.lastAdditionDate timeIntervalSinceNow] > serviceDelay) {
                    [dpps retain];
                    
                    [dpps invalidate];
                    [serviceStacks removeObjectForKey:key];
                    
                    DiscPublishingPatientDisc* dppd = [[[DiscPublishingPatientDisc alloc] initWithImages:dpps.images options:[NSUserDefaultsController.sharedUserDefaultsController DPOptionsForServiceId:sid]] autorelease];
                    [[ThreadsManager defaultManager] addThreadAndStart:dppd];
                    
                    [dpps release];
                }
            }
        }
    }
}

-(DiscPublishingPatientStack*)stackForImage:(DicomImage*)image serviceId:(NSString*)sid {
    @synchronized (_serviceStacks) {
        id sidk = sid;
        if (!sidk)
            sidk = [NSNull null];
        NSMutableDictionary* serviceStacks = [_serviceStacks objectForKey:sidk];
        if (!serviceStacks)
            [_serviceStacks setObject:(serviceStacks = [NSMutableDictionary dictionary]) forKey:sidk];
        
        DiscPublishingPatientStack* dpps = [serviceStacks objectForKey:image.series.study.patientUID];
        if (dpps)
            return dpps;
        
        dpps = [[[DiscPublishingPatientStack alloc] initWithPatientName:image.series.study.name serviceId:sid] autorelease];
        [serviceStacks setObject:dpps forKey:image.series.study.patientUID];
        
        return dpps;
    }
    
    return nil;
}

-(void)observeDatabaseAddition:(NSNotification*)notification {
	if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(observeDatabaseAddition:) withObject:notification waitUntilDone:NO];
        return;
    }
    
	//NSArray* addedImages = [[notification userInfo] objectForKey:OsirixAddToDBNotificationImagesArray];
	NSDictionary* addedImagesByAET = [[notification userInfo] objectForKey:OsirixAddToDBNotificationImagesPerAETDictionary];
    
    for (NSString* aet in addedImagesByAET) {
        NSArray* addedImages = [addedImagesByAET objectForKey:aet];
        
        NSString* sid = nil;
        for (NSDictionary* sd in [NSUserDefaults.standardUserDefaults objectForKey:DPServicesListDefaultsKey]) {
            NSString* isid = [sd objectForKey:@"id"];
            NSString* matchedAETsString = [NSUserDefaults.standardUserDefaults objectForKey:[NSUserDefaults transformKeyPath:DPServiceMatchedAETsDefaultsKey forDPServiceId:isid]];
            
            NSArray* matchedAETs = [matchedAETsString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", ;"]];
            for (NSString* m in matchedAETs)
                if ([[m stringByTrimmingStartAndEnd] isEqualToString:aet]) {
                    sid = isid;
                    break;
                }
        }
        
        BOOL active = [NSUserDefaultsController.sharedUserDefaultsController boolForKey:[NSUserDefaults transformKeyPath:DPServiceActiveFlagDefaultsKey forDPServiceId:sid]];
        if (!active)
            return;
        
        for (DicomImage* image in addedImages)
            @try {
                if ([image managedObjectContext] == [[DicomDatabase defaultDatabase] managedObjectContext]) {
                    DiscPublishingPatientStack* dpps = [self stackForImage:image serviceId:sid];
                    if (![dpps.images containsObject:image])
                        if (image.modality && ![image.modality isEqual:@"SR"]) // TODO: why?
                            [dpps addImage:image];
                }
            } @catch (NSException* e) {
                NSLog(@"[DiscPublishingFilesManager observeDatabaseAddition:] error: %@", e.reason);
            }
    }
}

-(void)observeJobCompletedNotification:(NSNotification*)n {
    if ([[n.userInfo objectForKey:DPJobInfoDeleteWhenCompletedKey] boolValue]) {
        NSArray* objectIDs = [n.userInfo objectForKey:DPJobInfoObjectIDsKey];
        
        DicomDatabase* db = [DicomDatabase defaultDatabase];
        
        NSMutableArray* images = [[[db objectsWithIDs:objectIDs] mutableCopy] autorelease];
        
        // filter away objects used by queued jobs
        @synchronized (_serviceStacks) {
            for (NSString* sid in _serviceStacks.allKeys) { // allKeys in not mutable, so we can safely iterate
                NSMutableDictionary* serviceStacks = [_serviceStacks objectForKey:sid]; // by patient
                for (DiscPublishingPatientStack* dpps in [serviceStacks allValues]) {
                    for (DicomImage* image in dpps.images)
                        if ([images containsObject:image])
                            [images removeObject:image];
                }
            }
        }
        
        NSMutableArray* series = [NSMutableArray array];
        NSMutableArray* studies = [NSMutableArray array];
        for (DicomImage* image in images) {
            DicomSeries* serie = [image series];
            if (![series containsObject:serie])
                [series addObject:serie];
        }
        for (DicomSeries* serie in series) {
            DicomStudy* study = [serie study];
            if (![studies containsObject:study])
                [studies addObject:study];
        }
        
        [[BrowserController currentBrowser] proceedDeleteObjects:images];
        
        NSMutableArray* dels = [NSMutableArray array];
        for (DicomStudy* study in studies)
            if (!study.isDeleted) {
                BOOL allNonImage = YES;
                for (DicomSeries* serie in study.series) {
                    NSString* uid = [serie seriesSOPClassUID];
                    if ([DCMAbstractSyntaxUID isImageStorage: uid] || [DCMAbstractSyntaxUID isRadiotherapy:uid] || [DCMAbstractSyntaxUID isWaveform:uid])
                        allNonImage = NO;
                }
                if (allNonImage)
                    [dels addObject:study];
            }
        
        [[BrowserController currentBrowser] proceedDeleteObjects:dels];
        
        /*  for (DicomImage* image in images)
         [db.managedObjectContext deleteObject:image];
         for (DicomSeries* serie in series)
         if (!serie.images.count)
         [db.managedObjectContext deleteObject:serie];
         for (DicomStudy* study in studies)
         if (!study.series.count)
         [db.managedObjectContext deleteObject:study];*/
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
























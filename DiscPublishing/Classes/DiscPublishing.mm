//
//  DiscPublishing.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishing.h"
#import "DiscPublishingFilesManager.h"
#import <OsiriXAPI/N2Shell.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import "NSUserDefaultsController+DiscPublishing.h"
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#import <QTKit/QTKit.h>
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingTasksManager.h"
#import "DiscPublishingOptions.h"
#import <OsiriXAPI/NSAppleEventDescriptor+N2.h>
#import <PTRobot/PTRobot.h>
#import <OsiriXAPI/NSPanel+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/AppController.h>

//#include "NSThread+N2.h"

@interface DiscPublishing ()

@property(retain,readwrite,nonatomic) NSDistantObject<DiscPublishingTool>* tool;

@end

@implementation DiscPublishing

@synthesize tool = _tool;

static DiscPublishing* discPublishingInstance = NULL;
+(DiscPublishing*)instance {
	return discPublishingInstance;
}

-(NSDistantObject<DiscPublishingTool>*)toolOnlyIfRunning:(BOOL)onlyIfRunning {
    @synchronized (self) { 
        BOOL ok = NO;
        @try {
            ok = [_tool ping];
        } @catch (...) {
        }
        
        if (!ok) { // maybe already running?
            [_tool release];
            _tool = (NSDistantObject<DiscPublishingTool>*)[[NSConnection rootProxyForConnectionWithRegisteredName:DiscPublishingToolProxyName host:nil] retain];
            ok = [_tool ping];
        }
        
        if (!onlyIfRunning)
            if (!ok) { // not running, we must launch it
                [N2Shell execute:@"/usr/bin/open" arguments:[NSArray arrayWithObjects: @"-a", [[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"DiscPublishingTool.app"], NULL]];
                NSDate* start = NSDate.date;
                while (!ok && [NSDate.date timeIntervalSinceDate:start] < 20) {
                    [_tool release];
                    _tool = (NSDistantObject<DiscPublishingTool>*)[[NSConnection rootProxyForConnectionWithRegisteredName:DiscPublishingToolProxyName host:nil] retain];
                    ok = [_tool ping];
                }
            }
    }
    
    return _tool;
}

-(NSDistantObject<DiscPublishingTool>*)tool {
    return [self toolOnlyIfRunning:NO];
}

const static NSString* const RobotReadyTimerCallbackUserInfoWindowKey = @"Window";
const static NSString* const RobotReadyTimerCallbackUserInfoStartDateKey = @"StartDate";

-(void)initPlugin {
	if (![AppController hasMacOSXSnowLeopard])
		[NSException raise:NSGenericException format:@"The DiscPublishing Plugin requires Mac OS 10.6. Please upgrade your system."];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeOsirixWillTerminate:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
    
	discPublishingInstance = self;
    
    _robotReadyThreadLock = [[NSLock alloc] init];
    
    // TODO: we should recover leftover jobs, not just delete them... but then maybe they're the reason why we crashed in the first place
    @try {
        NSString* discsDirPath = [[self class] discsDirPath];
        for (NSString* p in [NSFileManager.defaultManager contentsOfDirectoryAtPath:discsDirPath error:NULL]) {
            NSLog(@"DiscPublishing plugin is deleting %@", [discsDirPath stringByAppendingPathComponent:p]);
            [NSFileManager.defaultManager removeItemAtPath:[discsDirPath stringByAppendingPathComponent:p] error:NULL];
        }
	} @catch (...) {
    }
	
	[QTMovie movie]; // this initializes the QT kit on the main thread
	[NSUserDefaultsController discPublishingInitialize];
	
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"DiscPublishingPreferences" inBundle:bundle withTitle:NSLocalizedString(@"Disc Publishing", NULL) image:[[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Icon" ofType:@"png"]] autorelease]]; // TODO: icon
	
//	[[ActivityWindowController defaultController] window];
	
	_toolAliveKeeperTimer = [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(toolAliveKeeperTimerCallback:) userInfo:NULL repeats:YES];
	[_toolAliveKeeperTimer fire];
	
	[DiscPublishingTasksManager defaultManager];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
    NSString* xml = nil;
	@try {
		xml = [self.tool getStatusXML];
	} @catch (NSException* e) {
	}
    
	NSPanel* w = nil;
    if (!xml) {
        w = [[NSPanel alertWithTitle:NSLocalizedString(@"Disc Publishing Error", NULL) message:NSLocalizedString(@"OsiriX was unable to communicate with the Disc Publishing robot. Please check that the robot is on and connected to the computer. This dialog will automatically disappear if the plugin finds a usable robot.", NULL) defaultButton:NSLocalizedString(@"Ignore", NULL) alternateButton:NULL icon:[[NSImage alloc] initWithContentsOfFile:[[[NSBundle bundleForClass:[self class]] pathForResource:@"Icon" ofType:@"png"] autorelease]]] retain];
		[w setLevel:NSModalPanelWindowLevel];
		[[w defaultButtonCell] setAction:@selector(close)];
		[[w defaultButtonCell] setTarget:w];
    }
    
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	if (w) [userInfo setObject:w forKey:RobotReadyTimerCallbackUserInfoWindowKey];
	[userInfo setObject:[NSDate date] forKey:RobotReadyTimerCallbackUserInfoStartDateKey];
	_robotReadyTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(robotReadyTimerCallback:) userInfo:userInfo repeats:YES];
	
/*	NSThread* bidon = [[NSThread alloc] initWithTarget:self selector:@selector(bidonThread:) object:NULL];
//	bidon.supportsCancel = YES;
	[[ThreadsManager defaultManager] addThreadAndStart:bidon];
*/
}

-(void)toolAliveKeeperTimerCallback:(NSTimer*)timer {
    @try {
        [[self toolOnlyIfRunning:YES] setQuitWhenDone:YES]; // if is currently running, ask it to quit
        [NSThread sleepForTimeInterval:0.05];
    } @catch (NSException* e) {
        NSLog(@"Tool quit error: %@", e.reason);
    }
    
	@try {
        [[self tool] setQuitWhenDone:NO];
	} @catch (NSException* e) {
		NSLog(@"Tool relaunch error: %@", e.reason);
	}
}

- (void) willUnload {
    [_robotReadyTimer invalidate];
	[self.tool setQuitWhenDone:YES];
}

-(void)observeOsirixWillTerminate:(NSNotification*)notification {
	[_robotReadyTimer invalidate];
	[self.tool setQuitWhenDone:YES];
}

/*-(void)bidonThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	thread.name = @"Bidon...";
	
	while (!thread.isCancelled) {
		[NSThread sleepForTimeInterval:0.001];
		thread.status = [NSString stringWithFormat:@"Time: %.2f", [NSDate timeIntervalSinceReferenceDate]];
	}
	
	[pool release];
}*/

-(void)dealloc {
	NSLog(@"DiscPublishing dealloc");
    [_robotReadyThreadLock release];
	[_robotReadyTimer invalidate]; _robotReadyTimer = NULL;
	[[_filesManager invalidate] release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
	[super dealloc];
}

-(void)filesIn:(id)obj into:(NSMutableArray*)files {
	if ([obj isKindOfClass:[NSArray class]])
		for (id sobj in obj)
			[self filesIn:sobj into:files];
	else
	if ([obj isKindOfClass:[DicomAlbum class]])
		for (id study in ((DicomAlbum*)obj).studies)
			[self filesIn:study into:files];
	else
	if ([obj isKindOfClass:[DicomStudy class]])
		for (id series in ((DicomStudy*)obj).series)
			[self filesIn:series into:files];
	else
	if ([obj isKindOfClass:[DicomSeries class]])
		[files addObjectsFromArray:[((DicomSeries*)obj).images allObjects]];
}

-(NSArray*)filesIn:(NSArray*)arr {
	NSMutableArray* files = [NSMutableArray array];
	[self filesIn:arr into:files];
	return files;
}

-(long)filterImage:(NSString*)menuName {
	BrowserController* bc = [BrowserController currentBrowser];
	NSArray* sel = [bc databaseSelection];
	
	DiscPublishingPatientDisc* dppd = [[[DiscPublishingPatientDisc alloc] initWithFiles:[self filesIn:sel] options:[[NSUserDefaultsController sharedUserDefaultsController] discPublishingPatientModeOptions]] autorelease];
    dppd.window = bc.window;
	[[ThreadsManager defaultManager] addThreadAndStart:dppd];
	
	return 0;
}

+(NSString*)baseDirPath {
	NSString* path = [[[NSFileManager defaultManager] userApplicationSupportFolderForApp] stringByAppendingPathComponent:[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

+(NSString*)discsDirPath {
    return [[self baseDirPath] stringByAppendingPathComponent:@"Discs"];
}

+(NSString*)discCoverTemplatesDirPath {
	NSString* path = [[self baseDirPath] stringByAppendingPathComponent:@"Disc Cover Templates"];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

-(void)updateBinSelection {
	if (!_robotIsReady)
		return;
	
	NSString* xml = [self.tool getStatusXML];
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
	NSArray* bins = [doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL];
	
//#warning: this MUST be enabled when releasing
	if (bins.count == 1) {
		[self.tool setBinSelectionEnabled:NO leftBinType:0 rightBinType:0 defaultBin:LOCATION_REJECT];
	} else
	if (bins.count == 2) {
		NSUserDefaultsController* defaultsC = [NSUserDefaultsController sharedUserDefaultsController];
		[self.tool setBinSelectionEnabled:YES leftBinType:[defaultsC discPublishingMediaTypeTagForBin:1] rightBinType:[defaultsC discPublishingMediaTypeTagForBin:0] defaultBin:LOCATION_REJECT];
	} else {
		NSLog(@"Warning: we didn't expect having to handle more than 2 bins...");
	}
	
	[doc release];
}

-(void)robotReadyTimerCallback:(NSTimer*)timer {
    NSWindow* window = [[timer userInfo] objectForKey:RobotReadyTimerCallbackUserInfoWindowKey];
    
	if (window && [[NSDate date] timeIntervalSinceDate:[[timer userInfo] objectForKey:RobotReadyTimerCallbackUserInfoStartDateKey]] > 3) {
		[window center];
		[window makeKeyAndOrderFront:self];
		[[timer userInfo] removeObjectForKey:RobotReadyTimerCallbackUserInfoStartDateKey];
	}
    
    [self performSelectorInBackground:@selector(robotReadyThread:) withObject:window];
}

-(void)robotReadyThread:(NSWindow*)window {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        if ([_robotReadyThreadLock tryLock])
            @try {
                NSString* xml = [self.tool getStatusXML];
                if (xml) {
                    [self performSelectorOnMainThread:@selector(robotReadyMainThread:) withObject:[NSArray arrayWithObjects: xml, window, nil] waitUntilDone:NO];
                }
            } @catch (NSException* e) {
                // N2LogExceptionWithStackTrace(e);
            } @finally {
                [_robotReadyThreadLock unlock];
            }
    } @catch (NSException* e) {
        // N2LogExceptionWithStackTrace(e);
    } @finally {
        [pool release];
    }
}

-(void)robotReadyMainThread:(NSArray*)io {
    @try {
        NSString* xml = [io objectAtIndex:0];
        NSWindow* window = io.count > 1 ? [io objectAtIndex:1] : nil;
        
        [window close];
        [_robotReadyTimer invalidate]; _robotReadyTimer = NULL;
        // this will only happen ONCE
        _robotIsReady = YES;
        [self updateBinSelection];
        NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:0] options:NULL context:NULL];
        //#warning: this MUST be enabled when releasing
        if ([[doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL] count] > 1)
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:1] options:NULL context:NULL];
    } @catch (NSException* e) {
        // N2LogExceptionWithStackTrace(e);
    }
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"plugin observeValueForKeyPath:%@", keyPath);
	
	if ([keyPath hasSuffix:DiscPublishingMediaTypeTagSuffix]) {
		[self updateBinSelection];
	}
}


@end

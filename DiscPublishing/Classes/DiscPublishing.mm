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
#import <OsiriXAPI/DicomDatabase.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingTasksManager.h"
#import "DiscPublishingOptions.h"
#import <OsiriXAPI/NSAppleEventDescriptor+N2.h>
#import <PTRobot/PTRobot.h>
#import <OsiriXAPI/NSPanel+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/AppController.h>
#import <OsiriXAPI/N2XMLRPC.h>
#import <OsiriXAPI/Notifications.h>
#import <objc/runtime.h>

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
        
        if (!ok) // maybe already running?
            @try {
                [_tool release];
                _tool = (NSDistantObject<DiscPublishingTool>*)[[NSConnection rootProxyForConnectionWithRegisteredName:DiscPublishingToolProxyName host:nil] retain];
                ok = [_tool ping];
            } @catch (...) {
            }
        
        if (!ok)
            if (!onlyIfRunning)// not running, we must launch it
                @try {
                    [N2Shell execute:@"/usr/bin/open" arguments:[NSArray arrayWithObjects: @"-a", [[NSBundle bundleForClass:[self class]] pathForAuxiliaryExecutable:@"DiscPublishingTool.app"], NULL]];
                    NSDate* start = NSDate.date;
                    while (!ok && [NSDate.date timeIntervalSinceDate:start] < 20) {
                        [_tool release];
                        _tool = (NSDistantObject<DiscPublishingTool>*)[[NSConnection rootProxyForConnectionWithRegisteredName:DiscPublishingToolProxyName host:nil] retain];
                        ok = [_tool ping];
                    }
                } @catch (...) {
                }
        
        if (ok)
            return _tool;
    }
    
    return nil;
}

-(NSDistantObject<DiscPublishingTool>*)tool {
    return [self toolOnlyIfRunning:NO];
}

const static NSString* const RobotReadyTimerCallbackUserInfoWindowKey = @"Window";
const static NSString* const RobotReadyTimerCallbackUserInfoStartDateKey = @"StartDate";

-(void)initPlugin {
	if (![AppController hasMacOSXSnowLeopard])
		[NSException raise:NSGenericException format:@"The DiscPublishing Plugin requires Mac OS 10.6. Please upgrade your system."];
    
    // swizzle the -[AppController displayListenerError:] method to growl instead of showing modal dialogs
    Class AppControllerClass = NSClassFromString(@"AppController");
    Method method = class_getInstanceMethod(AppControllerClass, @selector(displayListenerError:));
    IMP imp = method_getImplementation(method);
    class_addMethod(AppControllerClass, @selector(_AppControllerDisplayListenerError:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_AppControllerDisplayListenerError:)));
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeOsirixWillTerminate:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeXMLRPCMessageNotification:) name:OsirixXMLRPCMessageNotification object:nil];
    
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
        w = [[NSPanel alertWithTitle:NSLocalizedString(@"Disc Publishing Error", NULL) message:NSLocalizedString(@"OsiriX was unable to communicate with the Disc Publishing robot. Please check that the robot is on and connected to the computer. This dialog will automatically disappear if the plugin finds a usable robot.", NULL) defaultButton:NSLocalizedString(@"Ignore", NULL) alternateButton:NULL icon:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Icon" ofType:@"png"]] autorelease]] retain];
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

-(void)_AppControllerDisplayListenerError:(NSString*)message {
    NSDistantObject<DiscPublishingTool>* tool = [discPublishingInstance tool];
    if (tool)
        [tool growlWithTitle:NSLocalizedString(@"DICOM Listener Error", nil) message:message];
    else [self _AppControllerDisplayListenerError:message];
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

-(void)imagesIn:(id)obj into:(NSMutableArray*)files {
	if ([obj isKindOfClass:[NSArray class]])
		for (id sobj in obj)
			[self imagesIn:sobj into:files];
	else
	if ([obj isKindOfClass:[DicomAlbum class]])
		for (id study in ((DicomAlbum*)obj).studies)
			[self imagesIn:study into:files];
	else
	if ([obj isKindOfClass:[DicomStudy class]])
		for (id series in ((DicomStudy*)obj).series)
			[self imagesIn:series into:files];
	else
	if ([obj isKindOfClass:[DicomSeries class]])
		[files addObjectsFromArray:[((DicomSeries*)obj).images allObjects]];
}

-(NSArray*)imagesIn:(NSArray*)arr {
	NSMutableArray* files = [NSMutableArray array];
	[self imagesIn:arr into:files];
	return files;
}

-(long)filterImage:(NSString*)menuName {
	BrowserController* bc = [BrowserController currentBrowser];
	NSArray* sel = [bc databaseSelection];
	
	DiscPublishingPatientDisc* dppd = [[[DiscPublishingPatientDisc alloc] initWithImages:[self imagesIn:sel] options:[[NSUserDefaultsController sharedUserDefaultsController] DPOptionsForServiceId:nil]] autorelease];
    dppd.window = bc.window;
	[[ThreadsManager defaultManager] addThreadAndStart:dppd];
	
	return 0;
}

-(void)observeXMLRPCMessageNotification:(NSNotification*)n {
    NSMutableDictionary* no = [n object];
    
    NSString* methodName = [no objectForKey:@"MethodName"];
    if (!methodName) methodName = [no objectForKey:@"methodName"];
    
    if ([methodName isEqualToString:@"DPPublish"]) {
        // if there is a NSXMLDocument key in no, we must parse it and extract the request args...
        @try {
            NSXMLDocument* doc = [no objectForKey:@"NSXMLDocument"];
            if (doc) {
                NSDictionary* params = (id)[N2XMLRPC ParseElement:[[doc objectsForXQuery:@"/methodCall/params/param/value/*" error:NULL] objectAtIndex:0]];
                [no addEntriesFromDictionary:params];
            }
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        }
        
        [no setObject:[NSNumber numberWithBool:YES] forKey:@"Processed"];
        
        NSInteger err = 0;
        NSMutableDictionary* result = [NSMutableDictionary dictionary];
        
        NSString* request = [no objectForKey:@"request"];
        NSString* entity = [no objectForKey:@"table"];
        if (!request or !entity) err = -1;
        
        if (!err)
            @try {
                NSManagedObjectContext* context = [[DicomDatabase defaultDatabase] managedObjectContext];
                
                NSFetchRequest* fr = [[[NSFetchRequest alloc] init] autorelease];
                fr.entity = [NSEntityDescription entityForName:entity inManagedObjectContext:context];
                fr.predicate = [NSPredicate predicateWithFormat:request];
                
                NSError* error = nil;
                NSArray* matches = [context executeFetchRequest:fr error:&error];
                if (error) {
                    err = -2;
                    [result setObject:[error localizedDescription] forKey:@"localizedDescription"];
                } else {
                    NSArray* images = [self imagesIn:matches];
                    
                    if (images.count) {
                        DiscPublishingPatientDisc* dppd = [[[DiscPublishingPatientDisc alloc] initWithImages:images options:[[NSUserDefaultsController sharedUserDefaultsController] DPOptionsForServiceId:nil]] autorelease];
                        [[ThreadsManager defaultManager] addThreadAndStart:dppd];
                        
                        [result setObject:[NSNumber numberWithInt:images.count] forKey:@"count"];
                    } else {
                        err = -3;
                    }
                }
            } @catch (NSException* e) {
                err = -666;
                [result setObject:[e reason] forKey:@"reason"];
            }
        
        [result setObject:[NSNumber numberWithInt:err] forKey:@"error"];
        
        [no setObject:result forKey:@"Response"];
        NSString* xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodResponse><params><param><value>%@</value></param></params></methodResponse>", [N2XMLRPC FormatElement:result]];
        NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:0 error:NULL];
        [no setObject:doc forKey:@"NSXMLDocumentResponse"];
    }
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
        [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaults DPMediaTypeTagKVOKeyForBin:0] options:NULL context:NULL];
        //#warning: this MUST be enabled when releasing
        if ([[doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL] count] > 1)
            [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaults DPMediaTypeTagKVOKeyForBin:1] options:NULL context:NULL];
    } @catch (NSException* e) {
        // N2LogExceptionWithStackTrace(e);
    }
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"plugin observeValueForKeyPath:%@", keyPath);
	
	if ([keyPath hasSuffix:DPMediaTypeTagKVOKeySuffix]) {
		[self updateBinSelection];
	}
}


@end

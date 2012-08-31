//
//  DiscPublishingTool.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingToolAppDelegate.h"
#import "DiscPublisher.h"
#import "DiscPublisher+Constants.h"
#import "DiscPublisherStatus.h"
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/NSXMLNode+N2.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <Growl/GrowlDefines.h>
#import "DiscPublishingJob.h"
#import "DiscPublisherJob.h"

int main(int argc, const char* argv[]) {
	return NSApplicationMain(argc, argv);
}

@interface DiscPublishingToolAppDelegate ()

@property(retain) NSConnection* connection;
@property(retain) NSString* lastErr;

@end

@implementation DiscPublishingToolAppDelegate

@synthesize connection = _connection;
@synthesize lastErr = _lastErr;

-(void)applicationWillFinishLaunching:(NSNotification*)n {
	[GrowlApplicationBridge setGrowlDelegate:self];
    
    _prevValues = [[NSMutableDictionary alloc] init];
    
    _connection = [[NSConnection alloc] init];
    if ([self.connection registerName:DiscPublishingToolProxyName])
        [self.connection setRootObject:self];
    else self.connection = nil;
    
    _threads = [[NSMutableArray alloc] init];
	
    // TODO: we should recover leftover jobs, not just delete them... but then maybe they're the reason why we crashed in the first place
    @try {
        NSString* jobsDirPath = [DiscPublisher jobsDirPath];
        for (NSString* p in [NSFileManager.defaultManager contentsOfDirectoryAtPath:jobsDirPath error:NULL]) {
            NSLog(@"DiscPublishing plugin is deleting %@", [jobsDirPath stringByAppendingPathComponent:p]);
            [NSFileManager.defaultManager removeItemAtPath:[jobsDirPath stringByAppendingPathComponent:p] error:NULL];
        }
	} @catch (...) {
    }
    
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisherThread) object:nil] autorelease];
    [thread start];
    
//	_statusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(statusTimerCallback:) userInfo:NULL repeats:YES];
	
    _statusThread = [[NSThread alloc] initWithTarget:self selector:@selector(statusThread) object:nil];
    [_statusThread start];
    
	NSLog(@"Welcome to DiscPublishingTool.");
    
    [NSDistributedNotificationCenter.defaultCenter postNotificationName:DPTWillFinishLaunchingNotification object:nil userInfo:nil options:NSNotificationDeliverImmediately];
}

-(void)applicationWillTerminate:(NSNotification*)n {
    [NSDistributedNotificationCenter.defaultCenter postNotificationName:DPTWillTerminateNotification object:nil userInfo:nil options:NSNotificationDeliverImmediately];

	NSLog(@"DiscPublishingTool says Goodbye.");
}

-(void)dealloc {
    [_discPublisher release];
    [_connection release];
	
    [_statusThread cancel];
    while (_statusThread.isExecuting)
        [NSThread sleepForTimeInterval:0.01];
    [_statusThread release];
    
    [_prevValues release];
    
	self.lastErr = nil;
	[_threads release];
	[super dealloc];
}

-(void)quitNow {
	NSLog(@"DiscPublishingTool is Quitting.");
    [NSApp stop:self];
    [NSApp postEvent:[NSEvent otherEventWithType:NSApplicationDefined location:NSMakePoint(0,0) modifierFlags:0 timestamp:0.0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:true];
}

#pragma mark Tasks

-(NSThread*)threadWithId:(NSString*)threadId {
	for (NSThread* thread in _threads)
		if ([thread.uniqueId isEqual:threadId])
			return thread;
	return NULL;
}

-(void)distributeNotificationsForThread:(NSThread*)thread {
	static NSUInteger uniqueThreadIdBase = 0;
	++uniqueThreadIdBase;
	NSString* threadId = [NSString stringWithFormat:@"%d", uniqueThreadIdBase];
	thread.uniqueId = threadId;
	
	[_threads addObject:thread];
	
	[thread addObserver:self forKeyPath:NSThreadSupportsCancelKey options:NULL context:NULL];
	[thread addObserver:self forKeyPath:NSThreadIsCancelledKey options:NULL context:NULL];
	[thread addObserver:self forKeyPath:NSThreadStatusKey options:NULL context:NULL];
	[thread addObserver:self forKeyPath:NSThreadProgressKey options:NULL context:NULL];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadWillExit:) name:NSThreadWillExitNotification object:thread];
}

-(void)stopDistributingNotificationsForThread:(NSThread*)thread {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSThreadWillExitNotification object:thread];

	[thread removeObserver:self forKeyPath:NSThreadSupportsCancelKey];
	[thread removeObserver:self forKeyPath:NSThreadIsCancelledKey];
	[thread removeObserver:self forKeyPath:NSThreadStatusKey];
	[thread removeObserver:self forKeyPath:NSThreadProgressKey];

	[_threads removeObject:thread];
}

-(void)threadWillExit:(NSNotification*)notification {
	NSThread* thread = notification.object;
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:NSThreadWillExitNotification forKey:DPTThreadChangedInfoKey];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:DPTThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];

	[self stopDistributingNotificationsForThread:thread];
//	NSLog(@"%d threads left, quit? %d", threads.count, !threads.count && quitWhenDone);
	if (_quitWhenDone && !_threads.count)
        [self quitNow];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
	if ([object isKindOfClass:[NSThread class]]) {
		NSThread* thread = object;
		
		if (!thread.uniqueId)
			return;
		
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
									  [thread valueForKeyPath:keyPath], keyPath,
									  keyPath, DPTThreadChangedInfoKey,
								  NULL];
		[NSDistributedNotificationCenter.defaultCenter postNotificationName:DPTThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];
	}
}

#pragma mark Stuff

-(void)errorWithTitle:(NSString*)title description:(NSString*)description uniqueContext:(id)context {
	if (![_lastErr isEqual:description]) {
		self.lastErr = description;
		//[errs addObject:context];
		NSLog(@"%@: %@", title, description);
		[GrowlApplicationBridge notifyWithTitle:title description:description notificationName:@"RobotError" iconData:NULL priority:0 isSticky:YES clickContext:context];
	}
}

-(void)initDiscPublisherThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	thread.name = @"Initializing Disk Publisher...";
	
	while (![thread isCancelled] && !_discPublisher)
		@try {
			_discPublisher = [[DiscPublisher alloc] init];
			
			for (NSNumber* robotId in _discPublisher.status.robotIds)
                [_discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_CHECKDISCS];
            
			for (NSNumber* robotId in _discPublisher.status.robotIds)
				[_discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_IGNOREINKLOW];
            
			while (![thread isCancelled]) @try {
				if ([_discPublisher.status allRobotsAreIdle])
					break;
			} @catch (NSException* e) {
				NSLog(@"[DiscPublishingTool initDiscPublisher:] exception: %@", e);
			} @finally {
				[NSThread sleepForTimeInterval:0.5];
			}
		} @catch (NSException* e) {
			NSLog(@"Robot initialization error %@", e);
			[NSThread sleepForTimeInterval:5];
		}
	
	[pool release];
}

-(void)statusThread {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
    
    while (![thread isCancelled])
        @try {
            UInt32 errorS = 0;

            if (_discPublisher) {
                [_discPublisher.status refresh];
                // NSLog(@"Status: %@", discPublisher.status.doc.XMLString);
            }
            
            if (_discPublisher)
                for (NSXMLNode* robot in [_discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT" constants:NULL error:NULL]) {
                    UInt32 state = [[[robot childNamed:@"SYSTEM_STATE"] stringValue] intValue];
                    UInt32 error = [[[robot childNamed:@"SYSTEM_ERROR"] stringValue] intValue];
                    
                    NSNumber* lastStateNS = [_prevValues objectForKey:@"STATE"];
                    int lastState = lastStateNS? [lastStateNS intValue] : 0;
                    NSNumber* lastErrorNS = [_prevValues objectForKey:@"ERROR"];
                    int lastError = lastErrorNS? [lastErrorNS intValue] : 0;
                    
                    if (state != lastState || error != lastError) {
                        if (error) {
                            [self errorWithTitle:NSLocalizedString(@"Robot System Error", NULL) description:[[robot childNamed:@"SYSTEM_STATUS"] stringValue] uniqueContext:@"STATUS"];
                            errorS += error;
                        }

                        if (lastState == SYSSTATE_ERROR && lastError == SYSERR_COVER_OPEN) {
                            for (NSNumber* robotId in _discPublisher.status.robotIds)
                                [_discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_CHECKDISCS];
                        }
                        
                        if (lastState == SYSSTATE_ERROR && state != SYSSTATE_ERROR)
                            [self errorWithTitle:NSLocalizedString(@"Robot System Error Cleared", NULL) description:NSLocalizedString(@"Previous robot errors were cleared", nil) uniqueContext:@"STATUS"];
                    }
                    
                    [_prevValues setObject:[NSNumber numberWithInt:state] forKey:@"STATE"];
                    [_prevValues setObject:[NSNumber numberWithInt:error] forKey:@"ERROR"];
                }
            
            if (!errorS) {
                NSArray* windows = [NSApp windows];
                if (windows.count && windows.count != _lastNumberOfWindows) {
                    NSLog(@"Warning: we shouldn't display any windows, and somehow we're currently displaying %d", windows.count);
                    
                    // TODO: this is where we may want to use the PowerRelay

                    NSString* message = nil;
                    for (NSWindow* window in windows)
                        for (NSView* view in [window.contentView subviews])
                            if ([view isKindOfClass:[NSTextField class]]) {
                                NSString* value = [(NSTextField*)view stringValue];
                                if (value.length)
                                    message = value;
                            }
                    
                    if (message.length) {
                        message = [NSString stringWithFormat:@"%@%@", [[message substringWithRange:NSMakeRange(0,1)] lowercaseString], [message substringWithRange:NSMakeRange(1,message.length-1)]];
                        ++errorS;
                        [self errorWithTitle:NSLocalizedString(@"Robot Framework GUI", NULL) description:[NSString stringWithFormat:NSLocalizedString(@"The Primera framework requires your attention: %@", nil), message] uniqueContext:nil];
                    }
                }
                
                _lastNumberOfWindows = windows.count;
            }
            
            // warn when bins are running low
            if (_discPublisher) {
                NSArray* bins = [_discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL];
                for (NSXMLNode* bin in bins) {
                    UInt32 location = [[[bin childNamed:@"LOCATION"] stringValue] intValue];
                    
                    NSString* locationString = NSLocalizedString(@"input bin", nil);
                    if (bins.count > 1)
                        switch (location) {
                            case 0: locationString = NSLocalizedString(@"left input bin", nil); break;
                            case 1: locationString = NSLocalizedString(@"right input bin", nil); break;
                        }
                    
                    NSString* disc = NSLocalizedString(@"disc", nil);
                    NSString* discs = NSLocalizedString(@"discs", nil);
                    
                    if (_discPublisher.binSelection.fEnabled) {
                        UInt32 type = 5;
                        switch (location) {
                            case 0: type = _discPublisher.binSelection.nLeftBinType; break;
                            case 1: type = _discPublisher.binSelection.nRightBinType; break;
                        }
                        
                        if (type != DISCTYPE_UNKNOWN) {
                            disc = [DiscPublisherJob DiscType:type];
                            discs = [disc stringByAppendingString:NSLocalizedString(@"s", @"plural suffix for 'CD' or 'DVD' (-> 'CDs' or 'DVDs')")];
                        }
                    }
                    
                    UInt32 dib = [[[bin childNamed:@"DISCS_IN_BIN"] stringValue] intValue];
                    
                    NSString* context = [NSString stringWithFormat:@"BIN-%d", (int)location];

                    NSNumber* lastDibNS = [_prevValues objectForKey:context];
                    int lastDib = lastDibNS? [lastDibNS intValue] : -1;

                    if (dib != lastDib) {
                        [_prevValues setObject:[NSNumber numberWithInt:dib] forKey:context];
                        if (dib <= 5) {
                            NSString* title = NSLocalizedString(@"Robot Bin Warning", NULL);
                            
                            NSString* desc = nil;
                            if (dib == 0)
                                desc = [NSString stringWithFormat:NSLocalizedString(@"The %@ is empty, please load it with some %@", nil), locationString, discs];
                            else if (dib == 1)
                                desc = [NSString stringWithFormat:NSLocalizedString(@"Only %d %@ is left in the %@", nil), (int)dib, disc, locationString];
                            else
                                desc = [NSString stringWithFormat:NSLocalizedString(@"Only %d %@ are left in the %@", nil), (int)dib, discs, locationString];
                            
                            [self errorWithTitle:title description:desc uniqueContext:context];
                        } else {
                            if (lastDib != -1 && lastDib <= 5)
                                [self errorWithTitle:NSLocalizedString(@"Robot Bin Warning Cleared", NULL) description:[NSString stringWithFormat:NSLocalizedString(@"The %@ now has %d %@, thank you!", nil), locationString, dib, discs] uniqueContext:context];
                        }
                    }
                }
            }
            
            // warn when ink is running low
            if (_discPublisher) {
                NSArray* cartridges = [_discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/CARTRIDGES/CARTRIDGE" constants:NULL error:NULL];
                for (NSXMLNode* cartridge in cartridges) {
                    NSString* type = [[cartridge childNamed:@"TYPE"] stringValue];
                    int fill = [[[cartridge childNamed:@"FILL"] stringValue] intValue];
                    int status = [[[cartridge childNamed:@"STATUS"] stringValue] intValue];
                    
                    NSString* context = [NSString stringWithFormat:@"INK-%@", type];
                    
                    NSNumber* lastFillNS = [_prevValues objectForKey:context];
                    int lastFill = lastFillNS? [lastFillNS intValue] : -1;
                    
                    if (fill != lastFill) {
                        [_prevValues setObject:[NSNumber numberWithInt:fill] forKey:context];
                        if (fill == 20 ||
                            fill == 10 ||
                            fill <= 5) {
                            [self errorWithTitle:NSLocalizedString(@"Robot Ink Warning", nil) description:[NSString stringWithFormat:NSLocalizedString(@"Ink level in the %@ cartridge is %d%%", nil), type, fill] uniqueContext:context];
                        } else {
                            if (lastFill != -1 && fill > lastFill+10)
                                [self errorWithTitle:NSLocalizedString(@"Robot Ink Warning Cleared", nil) description:[NSString stringWithFormat:NSLocalizedString(@"Ink level in the %@ cartridge is %d%%, thank you!", nil), type, fill] uniqueContext:context];
                        }
                    }
                }
            }
            
            
            if (!errorS)
                self.lastErr = NULL;
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            [NSThread sleepForTimeInterval:1];
        }
    
    [pool release];
}

#pragma mark Growl

-(NSDictionary*)registrationDictionaryForGrowl {
	NSDictionary* hrNotifs = [NSDictionary dictionaryWithObjectsAndKeys:
							 NSLocalizedString(@"Robot Error", NULL), @"RobotError",
							 NULL];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			@"ch.osirix.discpublishing.tool", GROWL_APP_ID,
			[hrNotifs allKeys], GROWL_NOTIFICATIONS_DEFAULT,
			[hrNotifs allKeys], GROWL_NOTIFICATIONS_ALL,
			hrNotifs, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
			NULL];
}

-(NSString*)applicationNameForGrowl {
	return NSLocalizedString(@"Disc Publishing", NULL);
}

-(NSData*)applicationIconDataForGrowl {
	return [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"../Icon.png"]];
}

/*-(void)growlNotificationGoingOut:(id)context {
	if ([errs containsObject:context])
		[errs removeObject:context];
}

-(void)growlNotificationWasClicked:(id)context {
	[self growlNotificationGoingOut:context];
}

-(void)growlNotificationTimedOut:(id)context {
	[self growlNotificationGoingOut:context];
}*/

-(void)discJobThread:(DiscPublishingJob*)job {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	thread.name = [NSString stringWithFormat:@"Publishing disc %@...", [job.info objectForKey:DPJobInfoDiscNameKey]];
	
	@try {
		thread.status = @"Starting job...";
		[job start];
		
		while (YES) {
			if (job.status.dwJobState == JOB_FAILED) {
				// TODO: recover job, retry, whatever!!
				thread.status = [NSString stringWithFormat:@"Job failed with error: %d", (int)job.status.dwLastError];
			} else
				thread.status = job.statusString;
			
			if (job.status.dwJobState == JOB_COMPLETED) {
                [NSDistributedNotificationCenter.defaultCenter postNotificationName:DPTJobCompletedNotification object:thread.uniqueId userInfo:job.info];
                break;
            }
			[NSThread sleepForTimeInterval:1];
		}
		
	} @catch (NSException* e) {
		NSLog(@"Job exception: %@", e);
	}
	
	[pool release];
}

#pragma mark DiscPublishingTool

-(BOOL)ping {
    return YES;
}

-(void)growlWithTitle:(NSString*)title message:(NSString*)message {
    [self errorWithTitle:title description:message uniqueContext:nil];
}

-(void)setBinSelectionEnabled:(BOOL)enabled leftBinType:(NSUInteger)leftBinType rightBinType:(NSUInteger)rightBinType defaultBin:(NSUInteger)defaultBin {
    JM_BinSelection bs;
	bs.fEnabled = enabled;
	bs.nLeftBinType = leftBinType;
	bs.nRightBinType = rightBinType;
	bs.nDefaultBin = defaultBin;
    [_discPublisher applyBinSelection:&bs];
}

-(NSString*)publishDiscWithRoot:(NSString*)root info:(NSDictionary*)info {
    DiscPublishingJob* job = [_discPublisher createJobOfClass:[DiscPublishingJob class]];
	job.root = root;
	job.info = info;
	
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(discJobThread:) object:job] autorelease];
	[thread start];
	[self distributeNotificationsForThread:thread];

    return thread.uniqueId;
}

-(NSArray*)listTasks {
	NSMutableArray* taskIds = [NSMutableArray array];
	
	for (NSThread* thread in _threads)
		if (thread.uniqueId)
			[taskIds addObject:thread.uniqueId];
    
	return taskIds;
}

-(NSDictionary*)getTaskInfoForId:(NSString*)taskId {
	NSThread* thread = [self threadWithId:taskId];
	
	NSMutableDictionary* ret = [NSMutableDictionary dictionary];
	if (thread) {
		if (thread.name) [ret setObject:thread.name forKey:@"name"];
		id supportsCancel = [thread.threadDictionary objectForKey:NSThreadSupportsCancelKey];
		if (supportsCancel) [ret setObject:supportsCancel forKey:NSThreadSupportsCancelKey];
		id isCancelled = [thread.threadDictionary objectForKey:NSThreadIsCancelledKey];
		if (isCancelled) [ret setObject:isCancelled forKey:NSThreadIsCancelledKey];
		id status = [thread.threadDictionary objectForKey:NSThreadStatusKey];
		if (status) [ret setObject:status forKey:NSThreadStatusKey];
		id progress = [thread.threadDictionary objectForKey:NSThreadProgressKey];
		if (progress) [ret setObject:progress forKey:NSThreadProgressKey];
	}
	
	return ret;
}

-(NSString*)getStatusXML {
	DiscPublisherStatus* status = [_discPublisher status];
	[status refresh];
	return [[status doc] XMLString];
}

-(void)setQuitWhenDone:(BOOL)flag {
	_quitWhenDone = flag;
	DLog(@"quit set to %d, %d threads", flag, _threads.count);
	if (_quitWhenDone && !_threads.count)
        [self quitNow]; //[self performSelector:@selector(quitNow) withObject:nil afterDelay:0.01];
}

@end

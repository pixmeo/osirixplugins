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
    
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisherThread:) object:NULL] autorelease];
    [thread start];
    
	_statusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(statusTimerCallback:) userInfo:NULL repeats:YES];
	
	NSLog(@"Welcome to DiscPublishingTool.");
    
    [NSDistributedNotificationCenter.defaultCenter postNotificationName:DiscPublishingToolWillFinishLaunchingNotification object:nil userInfo:nil options:NSNotificationDeliverImmediately];
}

-(void)applicationWillTerminate:(NSNotification*)n {
    [NSDistributedNotificationCenter.defaultCenter postNotificationName:DiscPublishingToolWillTerminateNotification object:nil userInfo:nil options:NSNotificationDeliverImmediately];

	NSLog(@"DiscPublishingTool says Goodbye.");
}

-(void)dealloc {
    [_discPublisher release];
    [_connection release];
	[_statusTimer invalidate];
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
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:NSThreadWillExitNotification forKey:DiscPublishingToolThreadChangedInfoKey];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:DiscPublishingToolThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];

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
									  keyPath, DiscPublishingToolThreadChangedInfoKey,
								  NULL];
		[NSDistributedNotificationCenter.defaultCenter postNotificationName:DiscPublishingToolThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];
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

-(void)initDiscPublisherThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	thread.name = @"Initializing Disk Publisher...";
	
	while (![thread isCancelled] && !_discPublisher)
		@try {
			_discPublisher = [[DiscPublisher alloc] init];
			
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

-(void)statusTimerCallback:(NSTimer*)timer {
	if (_discPublisher) {
		[_discPublisher.status refresh];
		UInt32 errorS = 0;
//		NSLog(@"Status: %@", discPublisher.status.doc.XMLString);
		for (NSXMLNode* robot in [_discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT" constants:NULL error:NULL]) {
			UInt32 error = [[[robot childNamed:@"SYSTEM_ERROR"] stringValue] intValue];
			if (error) {
				[self errorWithTitle:NSLocalizedString(@"Robot System Error", NULL) description:[[robot childNamed:@"SYSTEM_STATUS"] stringValue] uniqueContext:[NSString stringWithFormat:@"Robot%@SystemError", [[robot childNamed:@"ROBOT_ID"] stringValue]]];
				errorS += error;
			}
		}
		if (!errorS) {
			self.lastErr = NULL;
		}
	}
}

-(void)applyBinSelection {
    if (_hasBinSelection) {
        DLog(@"Applying bin selection: %d,%d,%d,%d", _binSelection.fEnabled, _binSelection.nLeftBinType, _binSelection.nRightBinType, _binSelection.nDefaultBin);
        UInt32 err = JM_SetBinSelection(&_binSelection);
        if (err != JM_OK)
            [NSException raise:NSGenericException format:@"JM_SetBinSelection returned %d", err];
    } else
        DLog(@"Should apply bin selection, but it is undefined!");
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
	thread.name = [NSString stringWithFormat:@"Publishing disc %@...", [job.info objectForKey:DiscPublishingJobInfoDiscNameKey]];
	
	@try {
		thread.status = @"Starting job...";
		[job start];
		
		while (YES) {
			if (job.status.dwJobState == JOB_FAILED) {
				// TODO: recover job, retry, whatever!!
				thread.status = [NSString stringWithFormat:@"Job failed with error: %d", job.status.dwLastError];
			} else
				thread.status = job.statusString;
			
			if (job.status.dwJobState == JOB_COMPLETED) break;
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

-(void)setBinSelectionEnabled:(BOOL)enabled leftBinType:(NSUInteger)leftBinType rightBinType:(NSUInteger)rightBinType defaultBin:(NSUInteger)defaultBin {
    _hasBinSelection = YES;
	_binSelection.fEnabled = enabled;
	_binSelection.nLeftBinType = leftBinType;
	_binSelection.nRightBinType = rightBinType;
	_binSelection.nDefaultBin = defaultBin;
    [self applyBinSelection];
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

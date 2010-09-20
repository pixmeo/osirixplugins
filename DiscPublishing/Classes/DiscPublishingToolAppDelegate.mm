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
#import "DiscPublishingTool+DistributedNotifications.h"
#import <OsiriX Headers/NSThread+N2.h>
#import <OsiriX Headers/NSXMLNode+N2.h>
#import <OsiriX Headers/N2Debug.h>
#import <Growl/GrowlDefines.h>


int main(int argc, const char* argv[]) {
	return NSApplicationMain(argc, argv);
}


@implementation DiscPublishingToolAppDelegate

@synthesize lastErr;

#pragma mark Thread property distributed notifications

-(void)distributeNotificationsForThread:(NSThread*)thread {
	static NSUInteger uniqueThreadIdBase = 0;
	++uniqueThreadIdBase;
	NSString* threadId = [NSString stringWithFormat:@"%d", uniqueThreadIdBase];
	thread.uniqueId = threadId;
	
	[threads addObject:thread];
	
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

	[threads removeObject:thread];
}

-(void)threadWillExit:(NSNotification*)notification {
	NSThread* thread = notification.object;
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:NSThreadWillExitNotification forKey:DiscPublishingToolThreadChangedInfoKey];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:DiscPublishingToolThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];

	[self stopDistributingNotificationsForThread:thread];
//	NSLog(@"%d threads left, quit? %d", threads.count, !threads.count && quitWhenDone);
	if (quitWhenDone && !threads.count)
		[NSApp stop:self];
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
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:DiscPublishingToolThreadInfoChangeNotification object:thread.uniqueId userInfo:userInfo options:NSNotificationDeliverImmediately];
	}
}

#pragma mark Application initialization & finalization

@synthesize discPublisher;
@synthesize quitWhenDone;

-(NSArray*)threads {
	return threads;
}

-(NSThread*)threadWithId:(NSString*)threadId {
	for (NSThread* thread in threads)
		if ([thread.uniqueId isEqual:threadId])
			return thread;
	return NULL;
}

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	threads = [[NSMutableArray alloc] init];
//	errs = [[NSMutableArray alloc] init];
	
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisherThread:) object:NULL] autorelease];
	[thread start];
	
	statusTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(statusTimerCallback:) userInfo:NULL repeats:YES];
	
//	[self distributeNotificationsForThread:thread];
	
	NSLog(@"Welcome to DiscPublishingTool.");
	
	// recover jobs, need folder XXX and files XXX.plist & XXX.jpg
//	for (<#initial#>; <#condition#>; <#increment#>) {
//		<#statements#>
//	}
	
}

-(void)errorWithTitle:(NSString*)title description:(NSString*)description uniqueContext:(id)context {
	if (![lastErr isEqual:description]) {
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
	
	while (![thread isCancelled] && !discPublisher)
		@try {
			discPublisher = [[DiscPublisher alloc] init];
			
			for (NSNumber* robotId in discPublisher.status.robotIds)
				[self.discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_IGNOREINKLOW];
			
			while (![thread isCancelled]) @try {
				if ([self.discPublisher.status allRobotsAreIdle])
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

-(void)dealloc {
	[statusTimer invalidate];
	self.lastErr = NULL;
	[threads release];
//	[errs release];
	[super dealloc];
}

-(void)setQuitWhenDone:(BOOL)qwd {
	quitWhenDone = qwd;
	DLog(@"quit set to %d, %d threads", qwd, threads.count);
	if (quitWhenDone && !threads.count) {
		[NSApp stop:self];
		[NSApp postEvent:[NSEvent otherEventWithType:NSApplicationDefined location:NSMakePoint(0,0) modifierFlags:0 timestamp:0.0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:true];
	}
}

-(void)statusTimerCallback:(NSTimer*)timer {
	NSLog(@"statusTimerCallback:");
	if (discPublisher) {
		[discPublisher.status refresh];
		UInt32 errorS = 0;
//		NSLog(@"Status: %@", discPublisher.status.doc.XMLString);
		for (NSXMLNode* robot in [discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT" constants:NULL error:NULL]) {
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

@end

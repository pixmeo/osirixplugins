//
//  DiscPublishingTool.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingToolAppDelegate.h"
#import "DiscPublisher.h"
#import "DiscPublisherStatus.h"
#import "DiscPublishingTool+DistributedNotifications.h"
#import <OsiriX Headers/NSThread+N2.h>


int main(int argc, const char* argv[]) {
	return NSApplicationMain(argc, argv);
}


@implementation DiscPublishingToolAppDelegate

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
	
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisherThread:) object:NULL] autorelease];
	[thread start];
	
	[self distributeNotificationsForThread:thread];
	
	NSLog(@"Welcome to DiscPublishingTool.");
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
			thread.status = [NSString stringWithFormat:@"Initialization error %@, is any robot connected to the computer?", e];
			[NSThread sleepForTimeInterval:5];
		}
	
	[pool release];
}

-(void)dealloc {
	[threads release];
	[super dealloc];
}

-(void)setQuitWhenDone:(BOOL)qwd {
	quitWhenDone = qwd;
//	NSLog(@"quit set to %d, %d threads", qwd, threads.count);
	if (quitWhenDone && !threads.count) {
		[NSApp stop:self];
		[NSApp postEvent:[NSEvent otherEventWithType:NSApplicationDefined location:NSMakePoint(0,0) modifierFlags:0 timestamp:0.0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:true];
	}
}

@end

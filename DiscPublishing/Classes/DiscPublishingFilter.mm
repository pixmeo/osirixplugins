//
//  DiscPublishingFilter.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishingFilter.h"
#import "DiscPublishingPrefsViewController.h"
#import "ThreadsWindowController.h"
#import "DiscPublishingFilesManager.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadsManager.h"
#import "DiscPublisher.h"
#import "DiscPublisherStatus.h"
#import <QTKit/QTKit.h>


@implementation DiscPublishingFilter

@synthesize discPublisher = _discPublisher;

-(void)initPlugin {
	[QTMovie movie]; // this initializes the QT kit on the main thread
	
	NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 300) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setContentView:[self prefsView]];
	[window orderFront:self];
	
	[[ThreadsWindowController defaultController] window];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
	[[[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisher:) object:NULL] autorelease] start];

}

-(void)dealloc {
	[[_filesManager invalidate] release];
	[super dealloc];
}

-(NSView*)prefsView {
	return [[[DiscPublishingPrefsViewController alloc] init] view];
}

-(long)filterImage:(NSString*)menuName {
	return 0;
}

-(void)initDiscPublisher:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:thread name:@"Initializing Disk Publisher..."];
	[[ThreadsManager defaultManager] setSupportsCancel:YES forThread:thread];
	
	while (![thread isCancelled] && !_discPublisher)
		@try {
			_discPublisher = [[DiscPublisher alloc] init];
			
			for (NSNumber* robotId in self.discPublisher.status.robotIds)
				[self.discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_IGNOREINKLOW];
			
			while (![thread isCancelled]) @try {
				if ([self.discPublisher.status allRobotsAreIdle])
					break;
			} @catch (NSException* e) {
				NSLog(@"[DiscPublishingFilter initDiscPublisher:] exception: %@", e);
			} @finally {
				[NSThread sleepForTimeInterval:0.5];
			}
		} @catch (NSException* e) {
			[threadInfo setStatus:[NSString stringWithFormat:@"Initialization error %@, is any robot connected to the computer?", e]];
			[NSThread sleepForTimeInterval:5];
		}
	
	[pool release];
}

@end

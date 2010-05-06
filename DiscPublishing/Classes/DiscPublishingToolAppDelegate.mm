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
#import "NSThread+DiscPublishingTool.h"


int main(int argc, const char* argv[]) {
	return NSApplicationMain(argc, argv);
}


@implementation DiscPublishingToolAppDelegate

@synthesize discPublisher;

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification {
	threads = [[NSArrayController alloc] init];
	
	NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisherThread:) object:NULL] autorelease];
	[thread start];
	
	[threads addObject:thread];
	
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

@end

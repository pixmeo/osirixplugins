//
//  PrimieraAppDelegate.m
//  Primiera
//
//  Created by Alessandro Volz on 2/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "PrimieraAppDelegate.h"
#import "DiscPublisher.h"
#import "DiscPublisher+Constants.h"
#import "DiscPublisherJob.h"
#import "DiscPublisherStatus.h"
//#import "DiscPublisherRobot.h"
#import "ThreadsWindowController.h"
#import "ThreadsManager.h"
#import "ThreadsManagerThreadInfo.h"
//#import "DiscPublisherPrintOnlyJob.h"
//#import "NSString+Primiera.h"


@implementation PrimieraAppDelegate

@synthesize window = _window;
@synthesize discPublisher = _discPublisher;

-(void)applicationDidFinishLaunching:(NSNotification*)notification {
	[[ThreadsWindowController defaultController] window];
	NSThread* initThread = [[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisher:) object:NULL];
	[[initThread autorelease] start];
}

-(void)applicationWillTerminate:(NSNotification*)notification {
	[_discPublisher release];
	// should release ThreadsManager by invalidate] release] ?
}

-(void)criticalException:(NSException*)e {
	NSAlert* alert = [NSAlert alertWithMessageText:[e name] defaultButton:@"Quit" alternateButton:NULL otherButton:NULL informativeTextWithFormat:[e description]];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(criticalExceptionAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)criticalExceptionAlertDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[NSApp endSheet:sheet returnCode:returnCode];
	[NSApp terminate:self];
}

-(void)warningException:(NSException*)e {
	NSAlert* alert = [NSAlert alertWithMessageText:[e name] defaultButton:@"Ok" alternateButton:NULL otherButton:NULL informativeTextWithFormat:[e description]];
	[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(warningExceptionAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(void)warningExceptionAlertDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[NSApp endSheet:sheet returnCode:returnCode];
}

-(void)initDiscPublisher:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:thread name:@"Initializing Disk Publisher..." modalForWindow:self.window];
	[[ThreadsManager defaultManager] setSupportsCancel:YES forThread:thread];
	
	while (![thread isCancelled] && !_discPublisher)
		@try {
			_discPublisher = [[DiscPublisher alloc] init];
			
			for (NSNumber* robotId in self.discPublisher.status.robotIds)
				[self.discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_IGNOREINKLOW];
			
			while (![thread isCancelled]) @try {
				[self.discPublisher.status refresh];
				if ([self.discPublisher.status allRobotsAreIdle]) break;
			} @catch (NSException* e) {
				NSLog(@"Exception: %@", e);
			} @finally {
				[NSThread sleepForTimeInterval:0.5];
			}
		} @catch (NSException* e) {
			NSLog(@"error %@, dp is %x", e, _discPublisher);
			[threadInfo setStatus:[NSString stringWithFormat:@"Initialization error %@, is any robot connected to the computer?", e]];
			[NSThread sleepForTimeInterval:1];
		}
	
	[pool release];
}

-(IBAction)printOnlyTestJobAction:(id)source {
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(printOnlyTestJob:) object:NULL];
	[[thread autorelease] start];
}

-(void)printOnlyTestJob:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:thread name:@"Printing a test disc..."];
	
	@try {
		[threadInfo setStatus:@"Creating job..."];
		DiscPublisherJob* job = [self.discPublisher createPrintOnlyJob];
		job.printFile = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Merged.dcover"];
		job.printMergeFile = [[NSBundle mainBundle] pathForResource:@"Test" ofType:@"txt"];
		job.discType = DISCTYPE_CD;
		[job start];
		
		//		[threadInfo setSupportsCancel:YES];
		while (![thread isCancelled]) {
			[threadInfo setStatus:job.statusString];
			if (job.status.dwJobState == JOB_COMPLETED) break;
			[NSThread sleepForTimeInterval:1];
		}
		
		//		[threadInfo setSupportsCancel:NO];
		//		if ([thread isCancelled])
		//			[job abort];
		//		
		//		while (job.refreshStatus.dwJobState != JOB_COMPLETED)
		//			[NSThread sleepForTimeInterval:1];
	} @catch (NSException* e) {
		NSLog(@"Job exception: %@", e);
	}
	
	[pool release];
}

-(IBAction)testJobAction:(id)source {
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(testJob:) object:NULL];
	[[thread autorelease] start];
}

-(void)testJob:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:thread name:@"Publishing a test disc..."];
	
	@try {
		[threadInfo setStatus:@"Creating job..."];
		DiscPublisherJob* job = [self.discPublisher createJob];
		job.discType = DISCTYPE_CD;
		job.type = JP_JOB_DATA;
		job.volumeName = @"Test";
		job.printFile = [[NSBundle mainBundle] pathForResource:@"Ale" ofType:@"jpg"];
//		[job.files addObject:[[NSBundle mainBundle] resourcePath]];
		[job.files addObject:[[NSBundle mainBundle] executablePath]];
		NSLog(@"job.files: %@", job.files);
		[job start];
		
		while (YES) {
			[threadInfo setStatus:job.statusString];
			if (job.status.dwJobState == JOB_COMPLETED) break;
			NSLog(@"Status:\n\n%@\n\n", [DiscPublisher descriptionForJobStatus:job.status]);
			[NSThread sleepForTimeInterval:1];
		}
		
	} @catch (NSException* e) {
		NSLog(@"Job exception: %@", e);
	}
	
	[pool release];
}

-(IBAction)statusAction:(id)source {
	[self.discPublisher.status refresh];
}

@end

//
//  NSApplication+Scripting.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSApplication+Scripting.h"
#import "DiscPublishingJob.h"
#import "DiscPublishingJob+Info.h"
#import "NSThread+DiscPublishingTool.h"
#import "DiscPublishingToolAppDelegate.h"
#import "DiscPublishingOptions.h"
#import "DiscPublisher.h"
#import "NSAppleEventDescriptor+N2.h"


@implementation NSApplication (Scripting)

-(NSThread*)spawnDiscWrite:(NSString*)discRootDirPath info:(NSDictionary*)info {
	DiscPublishingJob* job = [[self.delegate discPublisher] createJobOfClass:[DiscPublishingJob class]];
	job.root = discRootDirPath;
	job.info = info;
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(discJobThread:) object:job];
	[thread start];
	
	return [thread autorelease];
}

-(void)publishDisc:(NSScriptCommand*)command {
	NSLog(@"publishDisc:%@", command.description);
	NSString* name = command.directParameter;
	NSDictionary* args = command.evaluatedArguments;
	NSString* root = [args objectForKey:@"root"];
	NSMutableDictionary* info = [args objectForKey:@"info"];
	
	info = [[info mutableCopy] autorelease];
	[info setObject:name forKey:DiscPublishingJobInfoDiscNameKey];
	
	NSThread* thread = [self spawnDiscWrite:root info:info];
	
	// TODO: return thread id so the requesting app knows what thread was created
}

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

@end



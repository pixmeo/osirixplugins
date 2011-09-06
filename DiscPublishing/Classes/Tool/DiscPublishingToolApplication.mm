//
//  DiscPublishingToolApplication.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingToolApplication.h"
#import "DiscPublishingJob.h"
#import "DiscPublishingJob+Info.h"
#import <OsiriXAPI/NSThread+N2.h>
#import "DiscPublishingToolAppDelegate.h"
//#import "DiscPublishingOptions.h"
#import "DiscPublisher.h"
#import "DiscPublisherStatus.h"
#import <OsiriXAPI/NSAppleEventDescriptor+N2.h>


@implementation DiscPublishingToolApplication

-(DiscPublishingToolAppDelegate*)delegate {
    return (DiscPublishingToolAppDelegate*)[super delegate];
}

#pragma mark PublishDisk

-(NSThread*)spawnDiscWrite:(NSString*)discRootDirPath info:(NSDictionary*)info {
	DiscPublishingJob* job = [[self.delegate discPublisher] createJobOfClass:[DiscPublishingJob class]];
	job.root = discRootDirPath;
	job.info = info;
	
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(discJobThread:) object:job];
	[thread start];
	
	return [thread autorelease];
}

-(id)PublishDisc:(NSScriptCommand*)command {
    [self.delegate applyBinSelection];
    
	NSString* name = command.directParameter;
	NSDictionary* args = command.evaluatedArguments;
	NSString* root = [args objectForKey:@"root"];
	NSMutableDictionary* info = [args objectForKey:@"info"];
	
	info = [[info mutableCopy] autorelease];
	[info setObject:name forKey:DiscPublishingJobInfoDiscNameKey];
	
	NSThread* thread = [self spawnDiscWrite:root info:info];
	[self.delegate distributeNotificationsForThread:thread];
	
	return thread.uniqueId;
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

#pragma mark GetTaskInfo

-(id)GetTaskInfo:(NSScriptCommand*)command {
	NSString* taskId = command.directParameter;
	NSThread* thread = [self.delegate threadWithId:taskId];
	
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

#pragma mark ListTasks

-(id)ListTasks:(NSScriptCommand*)command {
	NSMutableArray* taskIds = [NSMutableArray array];
	
	for (NSThread* thread in [self.delegate threads])
		if (thread.uniqueId)
			[taskIds addObject:thread.uniqueId];

	return taskIds;
}

#pragma mark SetQuitWhenDone

-(void)SetQuitWhenDone:(NSScriptCommand*)command {
	NSNumber* quit = command.directParameter;
	[self.delegate setQuitWhenDone:quit.boolValue];
}

#pragma mark GetStatusXML

-(id)GetStatusXML:(NSScriptCommand*)command {
	DiscPublisherStatus* status = [[self.delegate discPublisher] status];
	[status refresh];
	NSString* xml = [[status doc] XMLString];
	if (!xml)
		[NSException raise:NSGenericException format:@"No status available, probably no robot connected"];
	return xml;
}

#pragma mark SetBinSelection

-(id)SetBinSelection:(NSScriptCommand*)command {
	NSDictionary* args = command.evaluatedArguments;

	JM_BinSelection jmbs;
	jmbs.fEnabled = [command.directParameter boolValue];
	jmbs.nLeftBinType = [[args objectForKey:@"leftBinMediaType"] unsignedIntValue];
	jmbs.nRightBinType = [[args objectForKey:@"rightBinMediaType"] unsignedIntValue];
	jmbs.nDefaultBin = [[args objectForKey:@"defaultBin"] unsignedIntValue];
	
    [self.delegate setBinSelection:jmbs];
}

@end



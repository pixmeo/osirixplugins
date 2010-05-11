//
//  DiscPublishingTasksManager.m
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/11/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingTasksManager.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"
#import "NSAppleEventDescriptor+N2.h"
#import <OpenScripting/OpenScripting.h>
#import "DiscPublishingJob+Info.h"
#import "DiscPublishingTool+DistributedNotifications.h"


@interface ToolThread : NSThread

-(BOOL)isToolCancelled;
-(void)setIsToolCancelled:(BOOL)isToolCancelled;

@end


@implementation DiscPublishingTasksManager

+(DiscPublishingTasksManager*)defaultManager {
	DiscPublishingTasksManager* defaultManager = NULL;
	if (!defaultManager)
		defaultManager = [[DiscPublishingTasksManager alloc] initWithThreadsManager:[ThreadsManager defaultManager]];
	return defaultManager;
}

-(id)initWithThreadsManager:(ThreadsManager*)threadsManager {
	self = [super init];
	_threadsManager = [threadsManager retain];
	return self;
}

-(void)dealloc {
	[super dealloc];
}

-(void)spawnDiscWrite:(NSString*)discRootDirPath info:(NSDictionary*)info {
	NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"DiscPublishingTool.scpt"];
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:[errors description]];
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"PublishDisc" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[[info objectForKey:DiscPublishingJobInfoDiscNameKey] appleEventDescriptor] atIndex:1];
	[params insertDescriptor:[discRootDirPath appleEventDescriptor] atIndex:2];
	[params insertDescriptor:[info appleEventDescriptor] atIndex:3];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSAppleEventDescriptor* result = [appleScript executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:errors.description];
	
	NSString* threadId = [result object];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(observeThreadInfoChange:) name:DiscPublishingToolThreadInfoChangeNotification object:threadId suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
	
	// a dummy thread that displays info about the Tool thread that handles this burn
	NSThread* thread = [[ToolThread alloc] init];
	thread.name = [NSString stringWithFormat:@"Tool Thread %@", threadId];
	thread.uniqueId = threadId;
	[_threadsManager addThread:thread];
	[thread start];
	
	[appleScript release];
}

-(ToolThread*)threadWithId:(NSString*)threadId {
	for (NSThread* thread in _threadsManager.threads)
		if ([thread.uniqueId isEqual:threadId])
			return (ToolThread*)thread;
	return NULL;
}

-(void)observeThreadInfoChange:(NSNotification*)notification {
	NSString* key = [notification.userInfo objectForKey:DiscPublishingToolThreadChangedInfoKey];

	ToolThread* thread = [self threadWithId:notification.object];
	if (!thread) {
		NSLog(@"thread info change for key %@ of unknown thread id %@", key, notification.object);
		return;
	}
	
	if ([key isEqual:NSThreadSupportsCancelKey])
		thread.supportsCancel = [[notification.userInfo objectForKey:key] boolValue];
	else
	if ([key isEqual:NSThreadIsCancelledKey])
		thread.isToolCancelled = [[notification.userInfo objectForKey:key] boolValue];
	else
	if ([key isEqual:NSThreadStatusKey])
		thread.status = [notification.userInfo objectForKey:key];
	else
	if ([key isEqual:NSThreadProgressKey])
		thread.progress = [[notification.userInfo objectForKey:key] floatValue];
	else
	if ([key isEqual:NSThreadWillExitNotification])
		thread.isToolCancelled = YES;
	
	else NSLog(@"unexpected thread info change with key %@", key);
}

@end

// Cancel in plugin interface
//   => AppleScript:CancelJob(id)
//   => Tool:Thread.isCancelled = YES
//   => DistributedNotification:NSThreadIsCancelledKey
//   => ToolThread(id).isToolCancelled = YES

@implementation ToolThread

NSString* const NSThreadIsToolCancelledKey = @"isToolCancelled";

-(BOOL)isToolCancelled {
	NSNumber* isToolCancelled = [self.threadDictionary objectForKey:NSThreadIsToolCancelledKey];
	return isToolCancelled? [isToolCancelled boolValue] : NO;
}

-(void)setIsToolCancelled:(BOOL)isToolCancelled {
	if (isToolCancelled == self.isToolCancelled) return;
	[self willChangeValueForKey:NSThreadIsToolCancelledKey];
	[self.threadDictionary setObject:[NSNumber numberWithBool:isToolCancelled] forKey:NSThreadIsToolCancelledKey];
	[self didChangeValueForKey:NSThreadIsToolCancelledKey];
}

-(NSDictionary*)info {
	NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"DiscPublishingTool.scpt"];
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:[errors description]];
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"GetTaskInfo" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[self.uniqueId appleEventDescriptor] atIndex:1];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSAppleEventDescriptor* result = [appleScript executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:errors.description];
	
	return [result object];
}

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	// TODO: get tool thread properties: name, supportsCancel, isCancelled(isToolCancelled), status, progress
	NSDictionary* info = [self info];
	
	NSLog(@"info: %@", info.description);
	
	while (!self.isToolCancelled)
		[NSThread sleepForTimeInterval:0.1];
	
	[pool release];
}

@end

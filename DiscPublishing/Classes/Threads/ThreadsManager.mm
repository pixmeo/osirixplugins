//
//  ThreadsManager.mm
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import "ThreadsManager.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadModalForWindowController.h"


const NSString* const ThreadsManagerThreadCompletedNotification = @"ThreadsManagerThreadCompletedNotification";
const NSString* const ThreadsManagerThreadCancelledNotification = @"ThreadsManagerThreadCancelledNotification";

@implementation ThreadsManager

@synthesize threads = _threads;
@synthesize threadsController = _threadsController;

+(ThreadsManager*)defaultManager {
	static ThreadsManager* threadsManager = [[self alloc] init];
	return threadsManager;
}

-(id)init {
	self = [super init];
	
	_threads = [[NSMutableArray alloc] init];
	
	_threadsController = [[NSArrayController alloc] init];
	[_threadsController setSelectsInsertedObjects:NO];
	[_threadsController setAvoidsEmptySelection:NO];
	[_threadsController setObjectClass:[ThreadsManagerThreadInfo class]];
    [_threadsController bind:@"contentArray" toObject:self withKeyPath:@"threads" options:NULL];
	
	_threadsWatcherThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadsWatcherThread:) object:NULL];
	[_threadsWatcherThread start];
	
	return self;
}

-(void)invalidate {
	[_threadsWatcherThread cancel];
	while ([_threadsWatcherThread isExecuting])
		[NSThread sleepForTimeInterval:0.02];
}

-(void)dealloc {
	[_threads release];
	[super dealloc];
}

-(void)threadsWatcherThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	[thread setName:@"ThreadsManager threads watcher"];

	while (![thread isCancelled]) {
		[NSThread sleepForTimeInterval:0.02];
		for (NSInteger i = [self threadsCount]-1; i >= 0; --i) {
			ThreadsManagerThreadInfo* threadInfo = [self objectInThreadsAtIndex:i];
			if ([threadInfo.thread isFinished])
				[self removeThread:threadInfo];
		}
	}

	[pool release];
}

#pragma mark Interface

-(NSUInteger)threadsCount {
	return [_threads count];
}

-(ThreadsManagerThreadInfo*)addThread:(NSThread*)thread name:(NSString*)name modalForWindow:(NSWindow*)window {
	ThreadsManagerThreadInfo* threadInfo = [self infoForThread:thread];
	if (!threadInfo) {
		threadInfo = [[ThreadsManagerThreadInfo alloc] initWithThread:thread manager:self];
		[self addThread:threadInfo];
	}
	
	threadInfo.thread.name = name;
	
	if (window)
		[[ThreadModalForWindowController alloc] initWithThread:threadInfo window:window];
	
	return [threadInfo autorelease];
}

-(ThreadsManagerThreadInfo*)addThread:(NSThread*)thread name:(NSString*)name {
	return [self addThread:thread name:name modalForWindow:NULL];
}

-(ThreadsManagerThreadInfo*)infoForThread:(NSThread*)thread {
	for (ThreadsManagerThreadInfo* threadInfo in _threads)
		if (threadInfo.thread == thread)
			return threadInfo;
	return NULL;
}

-(void)addThread:(ThreadsManagerThreadInfo*)threadInfo {
	if ([[NSThread currentThread] isMainThread]) {
		if (![_threads containsObject:threadInfo])
			[[self mutableArrayValueForKey:@"threads"] addObject:threadInfo];	
	} else [self performSelectorOnMainThread:@selector(addThread:) withObject:threadInfo waitUntilDone:NO];
}

-(void)cancelThread:(ThreadsManagerThreadInfo*)threadInfo {
	if ([[NSThread currentThread] isMainThread]) {
		[threadInfo.thread cancel];
//		threadInfo.cancelled = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:ThreadsManagerThreadCancelledNotification object:threadInfo];
	} else [self performSelectorOnMainThread:@selector(cancelThread:) withObject:threadInfo waitUntilDone:NO];
}

-(void)removeThread:(id)thread {
	if ([[NSThread currentThread] isMainThread]) {
		if ([thread isKindOfClass:[NSThread class]])
			thread = [self infoForThread:thread];
		[[self mutableArrayValueForKey:@"threads"] removeObject:thread];
		[[NSNotificationCenter defaultCenter] postNotificationName:ThreadsManagerThreadCompletedNotification object:thread];
	} else [self performSelectorOnMainThread:@selector(removeThread:) withObject:thread waitUntilDone:NO];
}

-(ThreadsManagerThreadInfo*)threadInfoAtIndex:(NSUInteger)index {
	return [self objectInThreadsAtIndex:index];
}

-(void)setStatus:(NSString*)status forThread:(NSThread*)thread {
	[[self infoForThread:thread] setStatus:status];
}

-(void)setProgress:(CGFloat)progress ofTotal:(CGFloat)total forThread:(NSThread*)thread {
	[[self infoForThread:thread] setProgress:progress ofTotal:total];
}

-(void)setSupportsCancel:(BOOL)flag forThread:(NSThread*)thread {
	[[self infoForThread:thread] setSupportsCancel:flag];
}


#pragma mark Core Data

-(NSUInteger)countOfThreads {
    return [_threads count];
}

-(id)objectInThreadsAtIndex:(NSUInteger)index {
    return [_threads objectAtIndex:index];
}

-(void)insertObject:(id)obj inThreadsAtIndex:(NSUInteger)index {
    [_threads insertObject:obj atIndex:index];
}

-(void)removeObjectFromThreadsAtIndex:(NSUInteger)index {
    [_threads removeObjectAtIndex:index];
}

-(void)replaceObjectInThreadsAtIndex:(NSUInteger)index withObject:(id)obj {
    [_threads replaceObjectAtIndex:index withObject:obj];
}

@end

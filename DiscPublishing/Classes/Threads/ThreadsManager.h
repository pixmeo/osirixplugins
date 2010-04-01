//
//  ThreadsManager.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ThreadsManagerThreadInfo;

extern const NSString* const ThreadsManagerThreadCompletedNotification;
extern const NSString* const ThreadsManagerThreadCancelledNotification;

@interface ThreadsManager : NSObject {
	@private 
    NSMutableArray* _threads;
	NSArrayController* _threadsController;
	NSThread* _threadsWatcherThread;
}

@property(readonly) NSMutableArray* threads;
@property(readonly) NSArrayController* threadsController;

+(ThreadsManager*)defaultManager;

-(NSUInteger)threadsCount;
-(ThreadsManagerThreadInfo*)addThread:(NSThread*)thread name:(NSString*)name;
-(ThreadsManagerThreadInfo*)addThread:(NSThread*)thread name:(NSString*)name modalForWindow:(NSWindow*)window;
-(void)addThread:(ThreadsManagerThreadInfo*)thread;
-(void)cancelThread:(ThreadsManagerThreadInfo*)thread;
-(void)removeThread:(id)thread;
-(ThreadsManagerThreadInfo*)threadInfoAtIndex:(NSUInteger)index;

-(void)setStatus:(NSString*)status forThread:(NSThread*)thread;
-(void)setProgress:(CGFloat)progress ofTotal:(CGFloat)total forThread:(NSThread*)thread;
-(void)setSupportsCancel:(BOOL)flag forThread:(NSThread*)thread;

-(ThreadsManagerThreadInfo*)infoForThread:(NSThread*)thread;

-(NSUInteger)countOfThreads;
-(id)objectInThreadsAtIndex:(NSUInteger)index;
-(void)insertObject:(id)obj inThreadsAtIndex:(NSUInteger)index;
-(void)removeObjectFromThreadsAtIndex:(NSUInteger)index;
-(void)replaceObjectInThreadsAtIndex:(NSUInteger)index withObject:(id)obj;

@end

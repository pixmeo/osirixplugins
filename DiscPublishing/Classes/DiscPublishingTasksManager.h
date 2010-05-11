//
//  DiscPublishingTasksManager.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/11/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ThreadsManager;

@interface DiscPublishingTasksManager : NSObject {
	ThreadsManager* _threadsManager;
}

+(DiscPublishingTasksManager*)defaultManager;

-(id)initWithThreadsManager:(ThreadsManager*)threadsManager;

-(void)spawnDiscWrite:(NSString*)discRootDirPath info:(NSDictionary*)info;

@end

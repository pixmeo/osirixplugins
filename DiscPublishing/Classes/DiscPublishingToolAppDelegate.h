//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DiscPublisher;

@interface DiscPublishingToolAppDelegate : NSObject {
@private
	DiscPublisher* discPublisher;
	NSMutableArray* threads;
}

@property(readonly) DiscPublisher* discPublisher;
@property(readonly) NSArray* threads;

-(NSThread*)threadWithId:(NSString*)threadId;
-(void)distributeNotificationsForThread:(NSThread*)thread;

@end

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
	BOOL quitWhenDone;
}

@property(readonly) DiscPublisher* discPublisher;
@property(readonly) NSArray* threads;
@property BOOL quitWhenDone;

-(NSThread*)threadWithId:(NSString*)threadId;
-(void)distributeNotificationsForThread:(NSThread*)thread;

@end

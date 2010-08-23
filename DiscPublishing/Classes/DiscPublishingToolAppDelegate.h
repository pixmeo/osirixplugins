//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@class DiscPublisher;

@interface DiscPublishingToolAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
@private
	DiscPublisher* discPublisher;
	NSMutableArray* threads;
	BOOL quitWhenDone;
	//NSMutableArray* errs;
	NSTimer* statusTimer;
	NSString* lastErr;
}

@property(readonly) DiscPublisher* discPublisher;
@property(readonly) NSArray* threads;
@property BOOL quitWhenDone;
@property(retain) NSString* lastErr;

-(NSThread*)threadWithId:(NSString*)threadId;
-(void)distributeNotificationsForThread:(NSThread*)thread;

@end

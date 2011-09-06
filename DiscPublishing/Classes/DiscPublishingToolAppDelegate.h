//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import <JobManager/PTJobManager.h>

@class DiscPublisher;

@interface DiscPublishingToolAppDelegate : NSObject <GrowlApplicationBridgeDelegate> {
@private
	DiscPublisher* discPublisher;
	NSMutableArray* threads;
	BOOL quitWhenDone;
	//NSMutableArray* errs;
	NSTimer* statusTimer;
	NSString* lastErr;
    JM_BinSelection binSelection;
    BOOL hasBinSelection;
}

@property(readonly) DiscPublisher* discPublisher;
@property(readonly) NSArray* threads;
@property(nonatomic) BOOL quitWhenDone;
@property(retain) NSString* lastErr;
@property(nonatomic,assign) JM_BinSelection binSelection;

-(NSThread*)threadWithId:(NSString*)threadId;
-(void)distributeNotificationsForThread:(NSThread*)thread;

-(void)applyBinSelection;

@end

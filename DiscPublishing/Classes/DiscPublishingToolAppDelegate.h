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
#import "DiscPublishingTool.h"

@class DiscPublisher;

@interface DiscPublishingToolAppDelegate : NSObject <GrowlApplicationBridgeDelegate,DiscPublishingTool> {
@private
	DiscPublisher* _discPublisher;
	NSMutableArray* _threads;
	BOOL _quitWhenDone;
	NSThread* _statusThread;
	NSString* _lastErr;
    NSInteger _lastNumberOfWindows;
    NSMutableDictionary* _prevValues;
    NSConnection* _connection;
}

@end

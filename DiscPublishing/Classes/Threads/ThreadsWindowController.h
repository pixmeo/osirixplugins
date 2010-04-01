//
//  ThreadsWindowController.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ThreadsManager;

@interface ThreadsWindowController : NSWindowController {
	ThreadsManager* _manager;
    NSTableView* _tableView;
    NSTextField* _statusLabel;
	NSMutableArray* _cells;
}

@property(readonly) ThreadsManager* manager;
@property(retain) IBOutlet NSTableView* tableView;
@property(retain) IBOutlet NSTextField* statusLabel;

+(ThreadsWindowController*)defaultController;

-(id)initWithManager:(ThreadsManager*)manager;

@end

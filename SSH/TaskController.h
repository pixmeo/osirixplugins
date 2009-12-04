//
//  TaskController.h
//  sshPlugin
//
//  Created by Lance Pysher on 7/19/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TaskController : NSArrayController {
	NSMutableDictionary *_tasks;

}

- (IBAction)tunnelAction: (id)sender;
- (NSTask *)taskForKey:(id)key;
- (void)openTunnelForKey:(id)key;
- (void)closeTunnelForKey:(id)key;
- (void)openTerminal:(NSArray *)selection;



@end

//
//  SSHWindowController.h
//  sshPlugin
//
//  Created by Lance Pysher on 7/19/06.
//  Copyright 2006 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSHWindowController : NSWindowController {
	NSArray *_content;
	BOOL _running;
	NSArrayController *_taskController;
	IBOutlet NSWindow *_helpWindow;
}

- (NSArray *)content;
- (void)setContent:(NSArray *)content;

- (void)setTaskController:(NSArrayController *)taskController;
- (NSArrayController *)taskController;
- (void)windowWillClose:(NSNotification *)note;
- (IBAction)help:(id)sender;
@end

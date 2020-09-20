//
//  UserNeededPanelController.h
//  HUG Framework
//
//  Created by Alessandro Volz on 19.04.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UsernameWindowController : NSWindowController {
	IBOutlet NSButton* _closeButton;
	IBOutlet NSButton* _checkHybridButton;
	IBOutlet NSTextField* _messageLabel;
	NSTimer* _timer;
	NSLock* _timerLock;
	NSString* _username;
	NSInteger _returnCode;
}

@property(readonly) NSButton* closeButton;
@property(readonly,retain) NSString* username;

-(IBAction)cancelAction:(id)sender;
-(IBAction)checkHybridAction:(id)sender;

-(NSInteger)runModal;
-(NSInteger)runModalOnWindow:(NSWindow*)onwindow;

-(void)setMessage:(NSString*)message;

@end

//
//  AuthenticationWindowController.h
//  HUG Framework
//
//  Created by Alessandro Volz on 26.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AuthenticationWindowController : NSWindowController {
	IBOutlet NSTextField* _infoLabel;
	IBOutlet NSButton* _okButton;
	IBOutlet NSButton* _checkHybridButton;
	IBOutlet NSTextField* _loginField;
	IBOutlet NSTextField* _passwordField;
	IBOutlet NSTextField* _messageLabel;
	NSTimer* _timer;
	NSLock* _timerLock;
	BOOL _requestHybrid;
	NSString* _certificate;
	NSString* _password;
	NSModalSession _modalSession;
}

@property(readonly,retain) NSString* certificate;
@property(readonly,retain) NSString* password;

-(NSInteger)runModal __deprecated;
-(NSInteger)runModalOnWindow:(NSWindow*)onwindow __deprecated;

-(void)beginSheetOnWindow:(NSWindow*)parentWindow callbackTarget:(id)target selector:(SEL)sel context:(void*)context;

-(IBAction)cancelAction:(id)sender;
-(IBAction)okAction:(id)sender;
-(IBAction)checkHybridAction:(id)sender;

-(IBAction)updateOkButton:(id)sender;

-(void)invalidate;

@end

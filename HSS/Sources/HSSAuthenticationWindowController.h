//
//  AuthenticationWindowController.h
//  HUG Framework
//
//  Created by Alessandro Volz on 26.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HSSAPISession;

@interface HSSAuthenticationWindowController : NSWindowController {
	NSTextField* _infoLabel;
	NSTextView* _messageLabel;
	NSButton* _okButton;
	NSTextField* _loginField;
	NSTextField* _passwordField;
	NSTimer* _timer;
	NSLock* _timerLock;
    HSSAPISession* _session;
    CGFloat _previousMessageHeight;
    NSString* _lastEnterpriseUsername;
}

@property(assign) IBOutlet NSTextField* infoLabel;
@property(assign) IBOutlet NSTextView* messageLabel;
@property(assign) IBOutlet NSButton* okButton;
@property(assign) IBOutlet NSTextField* loginField;
@property(assign) IBOutlet NSTextField* passwordField;

@property(retain,readonly) HSSAPISession* session;
@property(retain,readonly) NSString* lastEnterpriseUsername;

- (void)beginSheetOnWindow:(NSWindow*)parentWindow callbackTarget:(id)target selector:(SEL)sel context:(void*)context;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;

- (IBAction)updateOkButton:(id)sender;

- (void)invalidate;

@end

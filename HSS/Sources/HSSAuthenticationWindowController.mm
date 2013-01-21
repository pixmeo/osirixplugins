//
//  AuthenticationWindowController.mm
//  HUG Framework
//
//  Created by Alessandro Volz on 26.05.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "HSSAuthenticationWindowController.h"
#import "HSS.h"
//#import "HUGSOAPWebServiceClient.h"
//#import "Utils.h"
//#import "HUG.h"
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/NSTextView+N2.h>
#import "HSSAPI.h"

@interface HSSAuthenticationWindowController ()

@property(retain,readwrite) HSSAPISession* session;
@property(retain,readwrite) NSString* lastEnterpriseUsername;

- (void)_timerCallback:(NSTimer*)timer;

@end

@implementation HSSAuthenticationWindowController

@synthesize infoLabel = _infoLabel;
@synthesize messageLabel = _messageLabel;
@synthesize okButton = _okButton;
@synthesize loginField = _loginField;
@synthesize passwordField = _passwordField;

@synthesize session = _session;
@synthesize lastEnterpriseUsername = _lastEnterpriseUsername;


- (id)init {
	if ((self = [super initWithWindowNibName:@"HSSAuthenticationWindow"])) {
		_timerLock = [[NSLock alloc] init];
        _previousMessageHeight = -7;
		//[HUG checkMasterUserAgain];
		[self _timerCallback:nil];
		_timer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_timerCallback:) userInfo:nil repeats:YES];
		[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
	}
	return self;
}

- (void)awakeFromNib {
//	_infoLabel.stringValue = MessageInsererCarte;
	_loginField.stringValue = @"";
	_passwordField.stringValue = @"";
    [_messageLabel setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	[_okButton setEnabled:NO];
	[self.window center];
}

- (void)dealloc {
//	NSLog(@"-[AuthenticationWindowController dealloc]");
	
	NSLock* lock = _timerLock;
	[lock lock];
	_timerLock = nil;
	[lock unlock];
	[lock release];
	
	self.session = nil;
	self.lastEnterpriseUsername = nil;
    
	[super dealloc];
}

- (void)_timerCallback:(NSTimer*)timer {
	if ([_timerLock tryLock]) {
		[self performSelectorInBackground:@selector(_getUsernameThread) withObject:nil];
		[_timerLock unlock];
	}
}

- (void)_getUsernameThread {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[_timerLock lock];
	@try {
        Class enterprise = [HSS enterpriseClass];
        NSString* enterpriseUsername = nil;
        if ([enterprise respondsToSelector:@selector(Username)])
            enterpriseUsername = [enterprise performSelector:@selector(Username)];
        
		[self performSelectorOnMainThread:@selector(_getUsernameResult:) withObject:enterpriseUsername waitUntilDone:NO];
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
	} @finally {
		[_timerLock unlock];
		[pool release];
	}
}

- (void)_getUsernameResult:(NSString*)enterpriseUsername {
    BOOL sameAsLast = _lastEnterpriseUsername == enterpriseUsername || [_lastEnterpriseUsername isEqualToString:enterpriseUsername];
    self.lastEnterpriseUsername = enterpriseUsername;
	if (enterpriseUsername.length) {
        if (!sameAsLast) {
            _loginField.stringValue = enterpriseUsername;
    //      if (_loginField.isEnabled)
    //          [_loginField setEnabled:NO];
            [_passwordField selectText:self];
            
            Class enterprise = [HSS enterpriseClass];
            NSString* storedPassword = nil;
            if ([enterprise respondsToSelector:@selector(StoredPasswordForUsername:)])
                storedPassword = [enterprise performSelector:@selector(StoredPasswordForUsername:) withObject:enterpriseUsername];
            if (storedPassword)
                _passwordField.stringValue = storedPassword;
        }
    } else {
//      if (!_loginField.isEnabled)
//          [_loginField setEnabled:YES];
        if (!sameAsLast)
            [_loginField selectText:self];
    }
    
	[self updateOkButton:self];
}

- (void)updateOkButton:(id)sender {
	[_okButton setEnabled: _loginField.stringValue.length && _passwordField.stringValue.length];
}

- (void)invalidate {
//	NSLog(@"-[AuthenticationWindowController invalidate]");
	
	[_timer invalidate];
	_timer = nil;
	
	//[self.window orderOut:self];
	[self.window close];
	[self.window autorelease];
	[self autorelease];
}

- (void)beginSheetOnWindow:(NSWindow*)parentWindow callbackTarget:(id)target selector:(SEL)sel context:(void*)context {
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[HSSAuthenticationWindowController instanceMethodSignatureForSelector:@selector(_dummySheetCallbackWithSession:contextInfo:)]];
	invocation.selector = sel;
	invocation.target = target;
	[invocation setArgument:&context atIndex:3];
	
	[self.window retain]; [self retain]; // release in [invalidate]
	
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(_sheetDidEnd:returnCode:contextInfo:) contextInfo:[[NSArray alloc] initWithObjects: invocation, NULL]];
	[self.window makeKeyAndOrderFront:self];
}

- (void)_sheetDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	NSArray* context = [(NSArray*)contextInfo autorelease];
	NSInvocation* invocation = [context objectAtIndex:0];
	
	HSSAPISession* session = nil;
	if (returnCode == NSRunStoppedResponse)
		session = [[self.session retain] autorelease];	
	
	[self invalidate];
	
	[invocation setArgument:&session atIndex:2];
	[invocation invoke];
}

- (void)_dummySheetCallbackWithSession:(HSSAPISession*)session contextInfo:(void*)contextInfo {
	// nothing
}

- (IBAction)cancelAction:(id)sender {
	// stop sheet
	[NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}

- (void)setMessage:(NSString*)message {
    _messageLabel.string = message;
    
    NSSize oldSize = _messageLabel.frame.size;
    [_messageLabel adaptToContent:oldSize.width];
    NSSize size = _messageLabel.frame.size;
    size.width = oldSize.width;
    [_messageLabel setFrameSize:size];
    
    CGFloat delta = size.height-_previousMessageHeight;
    _previousMessageHeight = size.height;
    NSRect frame = self.window.frame;
    frame.origin.y -= delta;
    frame.size.height += delta;
    
    [self.window setFrame:frame display:YES animate:YES];

    _messageLabel.hidden = NO;
}

- (IBAction)okAction:(id)sender {
	@try {
        NSError* error = nil;
		self.session = [HSSAPI.defaultAPI newSessionWithLogin:_loginField.stringValue password:_passwordField.stringValue timeout:10 error:&error];
        if (error)
            [self setMessage:error.localizedDescription];
        else {
            Class enterprise = [HSS enterpriseClass];
            SEL sel = @selector(StorePassword:forUsername:);
            if (enterprise && [enterprise respondsToSelector:sel]) {
                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[enterprise methodSignatureForSelector:sel]];
                invocation.selector = sel;
                invocation.target = enterprise;
                NSString* login = _loginField.stringValue;
                NSString* password = _passwordField.stringValue;
                [invocation setArgument:&password atIndex:2];
                [invocation setArgument:&login atIndex:3];
                [invocation invoke];
            }
            
            [NSApp endSheet:self.window];
        }
	} @catch (NSException* e) {
		N2LogExceptionWithStackTrace(e);
        [self setMessage:e.reason];
	}
}

/*- (IBAction)checkHybridAction:(id)sender {
	[HUG checkMasterUserAgain];
	[_messageLabel setStringValue:@"Vérification du lecteur du PC: cette fonctionnalité ne fonctionne que si sur le PC les Applications Cliniques sont actives. En cas de problème, réouvrez les."];
}*/

/*- (BOOL)_dummyVerifyPassword:(NSString*)password forUsername:(NSString*)username {
	return NO;
}*/

@end

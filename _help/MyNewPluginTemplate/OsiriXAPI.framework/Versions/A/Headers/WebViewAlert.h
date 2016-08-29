/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface WebViewAlert : NSWindowController <WebPolicyDelegate, WebFrameLoadDelegate>
{
    BOOL displayCancel, showDontShowAgain, dontShowAgain;
    NSURL *url;
    NSString *signature;
    int modalResponse;
    IBOutlet WebView *webView;
}

+ (NSInteger) alertWithURL: (NSURL*) u;
+ (NSInteger) alertWithDictionary: (NSDictionary*) d;
- (id) initWithDictionary: (NSDictionary*) d;

@property (readonly) int modalResponse;
@property BOOL displayCancel, showDontShowAgain, dontShowAgain;
@property (retain) NSURL *url;
@property (retain) NSString *signature;

@end
//
//  ThanksControoler.h
//  Invert
//
//  Created by rossetantoine on Tue Jun 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#import <WebKit/WebView.h>

@interface ThanksController : NSWindowController {

		char*					myPointer;
		
		IBOutlet	WebView		*web;
		IBOutlet	NSTextField *urlText;
}

- (IBAction) fetch:(id) sender;

@end

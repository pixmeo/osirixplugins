//
//  MIRCWebController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/29/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface MIRCWebController : NSWindowController {
	IBOutlet WebView *webView;
	NSURL *_url;

}

- (id)initWithURL:(NSURL *)url;
- (void)setURL:(NSURL *)url;

@end

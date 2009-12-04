//
//  MIRCWebController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/29/05.
//  Copyright 2005 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCWebController.h"


@implementation MIRCWebController

- (id)initWithURL:(NSURL *)url{
	
	self = [super initWithWindowNibName:@"MIRCWebView"];
	_url = [url retain];
	return self;
}

- (void)dealloc{
	[_url release];
	[super dealloc];
}

- (void)windowDidLoad{
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:_url]];
}

- (void)setURL:(NSURL *)url{
	[_url release];	
	_url = [url retain];
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:_url]];
}

@end

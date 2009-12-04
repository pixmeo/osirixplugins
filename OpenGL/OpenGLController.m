//
//  OpenGLController.m
//  OpenGLController
//
//  Created by rossetantoine on Tue Jun 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "OpenGLController.h"

@implementation OpenGLController

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
}

- (id) init
{
	self = [super initWithWindowNibName:@"OpenGLWindow"];
	
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"Window will close.... and release his memory...");
	
	[self release];
}

- (void) dealloc
{
    NSLog(@"My window is deallocating a pointer");
	
	[super dealloc];
}
@end

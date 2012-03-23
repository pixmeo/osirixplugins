//
//  ThanksControoler.m
//  Invert
//
//  Created by rossetantoine on Tue Jun 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "ThanksController.h"

@implementation ThanksController

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
}

- (id) init
{
	self = [super initWithWindowNibName:@"ThanksNib"];
	
	myPointer = malloc( 100);
	
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"Window will close.... and release his memory...");
	
	[self autorelease];
}

- (void) dealloc
{
    NSLog(@"My window is deallocating a pointer");
	
	free( myPointer);
	
	[super dealloc];
}

- (IBAction) fetch:(id) sender
{
	[[web mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[urlText stringValue]]]];
}

@end

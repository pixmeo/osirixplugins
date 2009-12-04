//
//  CMIVSlider.m
//  CMIV_CTA_TOOLS
//
//  Created by chuwang on 2007-07-27.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CMIVSlider.h"


@implementation CMIVSlider

- (void)mouseDown:(NSEvent *)theEvent
{
	mouseLeftKeyDown=YES;
	[super mouseDown:theEvent];
	mouseLeftKeyDown=NO;
	[self sendAction:[self action] to:[self target]];
}

-(BOOL) isMouseLeftKeyDown
{
	return mouseLeftKeyDown;
}

@end

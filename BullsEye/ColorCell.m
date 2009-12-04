//
//  ColorCell.m
//  color cell test
//
//  Created by John Harte on Sat Sep 14 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "ColorCell.h"

@implementation ColorCell

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView
{
	NSRect square = NSInsetRect (cellFrame, 0.5, 0.5);	// move in half a point to put the lines on even point boundries
	
	// use the smallest size to square off the box & center the box
	if (square.size.height < square.size.width) {
		square.size.width = square.size.height;
		square.origin.x = square.origin.x + (cellFrame.size.width - square.size.width) / 2.0;
	} else {
		square.size.height = square.size.width;
		square.origin.y = square.origin.y + (cellFrame.size.height - square.size.height) / 2.0;
	}

	// draw a black border around the color
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect: square];

	// inset the color 2 points from the border and draw it
	NSColor *color = [NSUnarchiver unarchiveObjectWithData: [self objectValue]];
	[color  drawSwatchInRect: NSInsetRect (square, 2.0, 2.0)];	// as per Scott Anguish
}

@end

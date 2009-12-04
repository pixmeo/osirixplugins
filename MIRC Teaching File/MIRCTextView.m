//
//  MIRCTextView.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/27/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCTextView.h"


@implementation MIRCTextView

- (void)keyDown:(NSEvent *)theEvent{
	if ([[theEvent characters] length] > 0 && [[theEvent characters] characterAtIndex:0] == NSEnterCharacter)
		[[self window] selectNextKeyView:nil];
	else
		[super keyDown:theEvent];
}

@end

//
//  AdaptiveBox.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/3/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "AdaptiveBox.h"
#import <OsiriX Headers/N2Operators.h>


@implementation AdaptiveBox

-(void)awakeFromNib {
	idealContentSize = NSZeroSize;
}

-(void)adaptWindowSizeToIdealSize {
	NSView* view = [self contentView];
	NSSize contentSize = view.frame.size;
	NSSize windowSizeDelta = idealContentSize - contentSize;
	NSRect windowFrame = self.window.frame;
	windowFrame.size += windowSizeDelta;
	windowFrame.origin.y -= windowSizeDelta.height;
	[self.window setFrame:windowFrame display:YES];
	idealContentSize = NSZeroSize;
}

-(void)setContentView:(NSView*)view {
	idealContentSize = view.frame.size;
	[super setContentView:view];
	if (self.window)
		[self adaptWindowSizeToIdealSize];
}

-(void)viewDidMoveToWindow {
	if (!NSEqualSizes(idealContentSize, NSZeroSize))
		[self adaptWindowSizeToIdealSize];
	[super viewDidMoveToWindow];
}

@end

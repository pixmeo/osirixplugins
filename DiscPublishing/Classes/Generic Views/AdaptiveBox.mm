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

-(void)adaptContainersToIdealSize {
	NSView* view = [self contentView];
	NSSize contentSize = view.frame.size;
	NSSize sizeDelta = idealContentSize - contentSize;
	idealContentSize = NSZeroSize;
	
/*	NSMutableArray* animations = NULL;
	if ([self.window.windowController respondsToSelector:@selector(animations)])
		animations = [self.window.windowController valueForKey:@"animations"];*/
	
	for (NSView* parentView = [self superview]; parentView; parentView = [parentView superview]) {
		if ([parentView isKindOfClass:[NSScrollView class]])
			break;
		NSRect pf = parentView.frame;
		pf.size += sizeDelta;
		pf.origin.y -= sizeDelta.height;
/*		if (animations)
			[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								       parentView, NSViewAnimationTargetKey,
								       [NSValue valueWithRect:pf], NSViewAnimationEndFrameKey,
								   NULL]];
		else*/ [parentView setFrame:pf];
	}
}

-(void)setContentView:(NSView*)view {
	NSMutableArray* animations = NULL;
	if ([self.window.windowController respondsToSelector:@selector(animations)])
		animations = [self.window.windowController valueForKey:@"animations"];
	idealContentSize = view.frame.size;
	/*[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   self.contentView, NSViewAnimationTargetKey,
						   NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
						   NULL]];*/
	[super setContentView:view];
	[animations addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   view, NSViewAnimationTargetKey,
						   NSViewAnimationFadeInEffect, NSViewAnimationEffectKey,
						   NULL]];
	if (self.window)
		[self adaptContainersToIdealSize];
}

-(void)viewDidMoveToWindow {
	if (!NSEqualSizes(idealContentSize, NSZeroSize))
		[self adaptContainersToIdealSize];
	[super viewDidMoveToWindow];
}

@end

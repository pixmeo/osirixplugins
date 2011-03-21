//
//  N2ZoomView.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 2/15/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "EjectionFractionZoomView.h"
#import <OsiriXAPI/NSView+N2.h>
#import <OsiriXAPI/N2Operators.h>


@implementation EjectionFractionZoomView

+(id)zoomWithView:(NSView*)view {
	return [[[self alloc] initWithView:view] autorelease];
}

-(id)initWithView:(NSView*)view {
	self = [super initWithSize:[view frame].size];
	
	[self addSubview:_view = view];
	
	return self;
}

-(void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	NSSize content = [_view frame].size, frame = frameRect.size;
	
	NSRect bounds;
	if (content.width/frame.width > content.height/frame.height) // fit width
		bounds.size = frame*content.width/frame.width;
	else bounds.size = frame*content.height/frame.height;
	bounds.origin = NSZeroPoint-(bounds.size-content)/2;
		
	[self setBounds:bounds];
}

-(NSSize)optimalSize {
	return [_view frame].size;
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	NSSize fs = [self optimalSize];
	return NSMakeSize(width, width/fs.width*fs.height);
}

@end

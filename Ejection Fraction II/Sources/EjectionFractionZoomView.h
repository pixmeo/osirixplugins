//
//  N2ZoomView.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 2/15/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//


@interface EjectionFractionZoomView : NSView {
	NSView* _view;
}

+(id)zoomWithView:(NSView*)view;
-(id)initWithView:(NSView*)view;

@end

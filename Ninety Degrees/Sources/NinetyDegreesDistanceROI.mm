//
//  NinetyDegreesDistanceROI.mm
//  Ninety Degrees
//
//  Created by Alessandro Volz on 03.11.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "NinetyDegreesDistanceROI.h"
#import <Nitrogen/N2Operators.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/Notifications.h>


@implementation NinetyDegreesDistanceROI

-(id)initWithRoi1:(ROI*)roi1 roi2:(ROI*)roi2 {
	self = [self initWithRoi1:roi1 roi2:roi2 type:tMesure];
	
	[self setThickness:.25];
	[self setSelectable:NO];
	[self setName:@"Distance"];
	
	[self update];

	return self;
}

//-(void)dealloc {
//	[super dealloc];
//}

-(void)update {
	NSLine l1 = NSMakeLine([_roi1 pointAtIndex:0], [_roi1 pointAtIndex:1]);
	NSLine l2 = NSMakeLine([_roi2 pointAtIndex:0], [_roi2 pointAtIndex:1]);
	
	NSVector pd = !l1.direction; // direction perpendicular to l1 and l2 (since these are parallel)
	
	// find where to draw the perpendicular line
	
	CGFloat l1a = NSLineInterceptionValue(l1, NSMakeLine([_roi2 pointAtIndex:0], pd));
	BOOL bl1a = l1a >= 0 && l1a <= 1;
	CGFloat l1b = NSLineInterceptionValue(l1, NSMakeLine([_roi2 pointAtIndex:1], pd));
	BOOL bl1b = l1b >= 0 && l1b <= 1;
	CGFloat l2a = NSLineInterceptionValue(l2, NSMakeLine([_roi1 pointAtIndex:0], pd));
	BOOL bl2a = l2a >= 0 && l2a <= 1;
	CGFloat l2b = NSLineInterceptionValue(l2, NSMakeLine([_roi1 pointAtIndex:1], pd));
	BOOL bl2b = l2b >= 0 && l2b <= 1;
	
	// CGFloat l2a1 = NSLineInterceptionValue(l1, NSMakeLine([_roi1 pointAtIndex:0], pd)); // is 0
	// CGFloat l2b1 = NSLineInterceptionValue(l1, NSMakeLine([_roi1 pointAtIndex:1], pd)); // is 1
	
	CGFloat l1f = 0;
	NSUInteger c = 0;
	if (bl1a) { ++c; l1f += l1a; }
	if (bl1b) { ++c; l1f += l1b; }
	if (bl2a) { ++c; /* l1f += 0; */ }
	if (bl2b) { ++c; l1f += 1; }
	
	if (c) {
		NSLine pl = NSMakeLine(NSLineAtValue(l1, l1f/c), pd);
		NSPoint p1 = pl*l1, p2 = pl*l2;
		if ([[self points] count] > 0) [self setPoint:p1 atIndex:0]; else [self addPoint:p1];
		if ([[self points] count] > 1) [self setPoint:p2 atIndex:1]; else [self addPoint:p2];
		[self setOpacity:.5];
	} else 
		[self setOpacity:0];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:self];
}

@end

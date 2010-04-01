//
//  NinetyDegreesROI.mm
//  Ninety Degrees
//
//  Created by Alessandro Volz on 02.11.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "NinetyDegreesROI.h"
#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/N2Operators.h>


@implementation NinetyDegreesROI
@synthesize roi1 = _roi1, roi2 = _roi2;

-(id)initWithRoi1:(ROI*)roi1 roi2:(ROI*)roi2 type:(long)roitype {
	self = [super initWithType:roitype :[roi1 pixelSpacingX] :[roi1 pixelSpacingY] :[roi1 imageOrigin]];
	
	_roi1 = roi1;
	_roi2 = roi2;
	
/*	[self setDisplayTextualData:NO];
	[self setThickness:1];
	[self setIsSpline:NO];
	[self setSelectable:NO];
	[self setLocked:YES];
	
	NSLine l1 = NSMakeLine([[[roi1 points] objectAtIndex:0] point], [[[roi1 points] objectAtIndex:1] point]);
	NSLine l2 = NSMakeLine([[[roi2 points] objectAtIndex:0] point], [[[roi2 points] objectAtIndex:1] point]);
	NSPoint p12 = l1*l2;
	
	[[self points] addObject:[MyPoint point:p12+l1.direction/NSLength(l1.direction)]];
	[[self points] addObject:[MyPoint point:p12+l1.direction/NSLength(l1.direction)+l2.direction/NSLength(l2.direction)]];
	[[self points] addObject:[MyPoint point:p12+l2.direction/NSLength(l2.direction)]];*/
	
	return self;
}

-(BOOL)isOnROI:(ROI*)roi {
	return roi == _roi1 || roi == _roi2;
}

@end

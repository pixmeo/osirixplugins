/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "RoiEnhancementAreaDataSet.h"
#import <GRLineDataSet.h>
#import <GRAxes.h>
#import "RoiEnhancementChart.h"

@implementation RoiEnhancementAreaDataSet
@synthesize min = _min, max = _max, displayed = _displayed;

-(id)initWithOwnerChart:(RoiEnhancementChart*)chart min:(GRLineDataSet*)min max:(GRLineDataSet*)max {
	self = [super init];
	_chart = chart;
	_min = [min retain];
	_max = [max retain];
	return self;
}

-(void)dealloc {
	[_min release]; _min = NULL;
	[_max release]; _max = NULL;
	[super dealloc];
}

-(void)setDisplayed:(BOOL)displayed {
	_displayed = displayed;
	[_chart setNeedsDisplay: YES];
}

-(float)from:(float)x r0:(float)r0 r1:(float)r1 toR0:(float)R0 toR1:(float)R1 {
	return (x-r0)/(r1-r0)*(R1-R0)+R0;
}

-(void)drawRect:(NSRect)dirtyRect
{
	// only draw if displayed
	if (!_displayed)
		return;
	
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	@try
	{
		NSRect r = [[_chart axes] plotRect];
		[[NSBezierPath bezierPathWithRect:r] setClip];
		float p0x = [[_chart axes] xValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)];
		float p0y = [[_chart axes] yValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)];
		float p1x = [[_chart axes] xValueAtPoint: NSMakePoint(r.origin.x+r.size.width, r.origin.y+r.size.height)];
		float p1y = [[_chart axes] yValueAtPoint: NSMakePoint(r.origin.x+r.size.width, r.origin.y+r.size.height)];
		
		[[[_min propertyForKey: GRDataSetPlotColor] colorWithAlphaComponent: 0.25] setFill];
		
		NSBezierPath* path = [NSBezierPath bezierPath];
		
		BOOL logscale = [(NSString*)[[_chart axes] propertyForKey:GRAxesYAxisScale] isEqualToString: GRAxesLog10Scale];
		
		for (int x = [_chart xMin]; x <= [_chart xMax]; ++x)
        {
			NSPoint p; p.x = [self from:x r0:p0x r1:p1x toR0:r.origin.x toR1:r.origin.x+r.size.width];
			double y = [[_min dataSource] chart:_chart yValueForDataSet:_min element:x];
			if (!logscale) p.y = [self from:y r0:p0y r1:p1y toR0:r.origin.y toR1:r.origin.y+r.size.height];
			else p.y = [[_chart axes] locationForXValue:x yValue:y].y;
			
            if( p.y == p.y && p.x == p.x) // test for nan
            {
                if ([path isEmpty])
                    [path moveToPoint:p];
                else
                    [path lineToPoint:p];
            }
		}
		
		for (int x = [_chart xMax]; x >= [_chart xMin]; --x)
        {
			NSPoint p;
            p.x = [self from:x r0:p0x r1:p1x toR0:r.origin.x toR1:r.origin.x+r.size.width];
			
            double y = [[_max dataSource] chart:_chart yValueForDataSet:_max element:x];
            
			if (!logscale) p.y = [self from:y r0:p0y r1:p1y toR0:r.origin.y toR1:r.origin.y+r.size.height];
			else p.y = [[_chart axes] locationForXValue:x yValue:y].y;
            
            if( p.y == p.y && p.x == p.x) // test for nan
                [path lineToPoint:p];
		}
	
		[path closePath];
		[path fill];
	}
	
	@catch (NSException *e)
	{
		NSLog( @"drawRect AreaDataSet exception : %@", e);
	}
	
	[context restoreGraphicsState];
	
}

@end

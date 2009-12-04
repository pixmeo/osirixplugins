//
//  Graph.m
//  Mapping
//
//  Created by Antoine Rosset on Tue Aug 03 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import "Graph.h"

#include "math.h"

@implementation GraphT2Fit

- (void) dealloc
{
	if(minValues) free( minValues);
	if(maxValues) free( maxValues);
	if(meanValues) free( meanValues);
	
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code here.
		minValues = 0L;
		maxValues = 0L;
		meanValues = 0L;
    }
    return self;
}

-(void) setArrays: (long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log
{
	if(minValues) free( minValues);
	if(maxValues) free( maxValues);
	if(meanValues) free( meanValues);

	arraySize = nb;
	meanValues = meanPtr;
	maxValues = maxPtr;
	minValues = minPtr;
	teValues = teV;
	logMode = log;
	
	[self setNeedsDisplay: YES];
}

-(void) setLinearRegression:(float)b :(float) m
{
	slope = m;
	intercept = b;
}

- (void)drawRect:(NSRect)rect
{
    // Drawing code here.
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	NSDictionary *boldFont;
	NSString *trace;
	NSRect  boundsRect = [self bounds];
	long	i;
	float   maxValue, minValue;
	float	teStart, teEnd;
	
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont boldSystemFontOfSize:30.0],NSFontAttributeName,
															[NSColor redColor],NSForegroundColorAttributeName,
															paragraphStyle,NSParagraphStyleAttributeName,
															nil];

	[[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0] set];
	NSRectFill( rect);

	if( minValues == 0L)
	{
		trace = [NSString stringWithString:@"Select a ROI !"];
		[trace drawInRect: boundsRect withAttributes: boldFont];
		
		return;
	}
	
	// Find the max and min values of the arrays
	minValue = maxValue = minValues[ 0];
	teStart = teEnd = teValues[ 0];
	for( i = 0; i < arraySize; i++)
	{
		if( minValue > minValues[ i]) minValue = minValues[ i];
		if( maxValue < minValues[ i]) maxValue = minValues[ i];
		if( minValue > maxValues[ i]) minValue = maxValues[ i];
		if( maxValue < maxValues[ i]) maxValue = maxValues[ i];
		if( minValue > meanValues[ i]) minValue = meanValues[ i];
		if( maxValue < meanValues[ i]) maxValue = meanValues[ i];
		
		if( teStart > teValues[ i]) teStart = teValues[ i];
		if( teEnd < teValues[ i])	teEnd = teValues[ i];
	}
	
	if( logMode)
	{
		minValue = log( minValue);
		maxValue = log( maxValue);
	}
	
	// Draw the 3 curves	
	NSBezierPath *curveMin = [NSBezierPath bezierPath];
	NSBezierPath *curveMax = [NSBezierPath bezierPath];
	NSBezierPath *curveMean = [NSBezierPath bezierPath];
	
	for( i = 0; i < arraySize; i++)
	{
		float   xx, yy;
		
		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
		
		if( logMode) yy = log( minValues[ i]) - minValue;
		else yy = minValues[ i] - minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		
		if( i == 0) [curveMin moveToPoint: NSMakePoint( xx, yy)];
		else [curveMin lineToPoint: NSMakePoint( xx, yy)];
	}
	
	for( i = 0; i < arraySize; i++)
	{
		float   xx, yy;
		
		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
		
		if( logMode) yy = log( maxValues[ i]) - minValue;
		else yy = maxValues[ i] - minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		
		if( i == 0) [curveMax moveToPoint: NSMakePoint( xx, yy)];
		else [curveMax lineToPoint: NSMakePoint( xx, yy)];
	}
	
	for( i = 0; i < arraySize; i++)
	{
		float   xx, yy;
		
		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
		
		if( logMode) yy = log( meanValues[ i]) - minValue;
		else yy = meanValues[ i] - minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		
		if( i == 0) [curveMean moveToPoint: NSMakePoint( xx, yy)];
		else [curveMean lineToPoint: NSMakePoint( xx, yy)];
	}
	
	[curveMax setLineWidth: 1];
	[curveMin setLineWidth: 1];
	[curveMean setLineWidth: 2];
	
	[[NSColor blackColor] set];
	
	[curveMax stroke];
	[curveMin stroke];
	[curveMean stroke];
	
	NSBezierPath *curveRegression = [NSBezierPath bezierPath];

	// Draw the linear regression line
	if( logMode)
	{
		float   xx, yy;
		
		yy = teStart*slope + intercept;
		yy -= minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		xx = 0;
		[curveRegression moveToPoint: NSMakePoint( xx, yy)];
		
		yy = teEnd*slope + intercept;
		yy -= minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		xx = boundsRect.size.width;
		[curveRegression lineToPoint: NSMakePoint( xx, yy)];
	}
	else
	{
		for( i = 0; i < arraySize; i++)
		{
			float   xx, yy;
			
			yy = exp( teValues[ i]*slope + intercept) - minValue;
			yy = (yy * boundsRect.size.height) / (maxValue-minValue);
			
			xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
			
			if( i == 0) [curveRegression moveToPoint: NSMakePoint( xx, yy)];
			else [curveRegression lineToPoint: NSMakePoint( xx, yy)];
		}
	}
	
	
	[[NSColor redColor] set];
	[curveRegression setLineWidth: 2];
	[curveRegression stroke];

	// Draw small dots for each points
	[[NSColor blackColor] set];
	for( i = 0; i < arraySize; i++)
	{
		float   xx, yy;
		NSRect	aRect;
		
		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
		
		if( logMode) yy = log( meanValues[ i]) - minValue;
		else yy = meanValues[ i] - minValue;
		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		
		aRect = NSMakeRect(xx-3, yy-3, 6, 6);
		[[NSBezierPath bezierPathWithOvalInRect: aRect] fill];
	}

	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:[self bounds]];
	
	// TEXT
	if( minValue < 0)
	{
		trace = [NSString stringWithString:@"\nWARNING\nSome values are negative!\nAdapt the background signal"];
		[trace drawInRect: boundsRect withAttributes: boldFont];
	}
	
	boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont labelFontOfSize:12.0],NSFontAttributeName,
																			[NSColor blackColor],NSForegroundColorAttributeName,
																			paragraphStyle,NSParagraphStyleAttributeName,
																			nil];

	
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	
	trace = [NSString stringWithFormat:@"Max signal: %2.2f", maxValue];
	[trace drawInRect: boundsRect withAttributes: boldFont];
	
	NSRect	cRect = boundsRect; 
	cRect.origin.y = boundsRect.origin.y - boundsRect.size.height + 20;
	trace = [NSString stringWithFormat:@"Min signal: %2.2f", minValue];
	[trace drawInRect: cRect withAttributes: boldFont];
}

@end

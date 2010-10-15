//
//  Graph.m
//  Mapping
//
//  Created by Antoine Rosset on Tue Aug 03 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import "Graph.h"

#include "math.h"

@implementation GraphCMIRT2Fit

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


//-- -(void) setArrays: (long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log
-(void) setArrays: (long) off :(long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log
{
	
	if(minValues) free( minValues);
	if(maxValues) free( maxValues);
	if(meanValues) free( meanValues);

	offset = off;
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

//+++++++++++++++++++++++++++++
-(void) setThreshold:(float)th
{
	threshold = th;
}
//+++++++++++++++++++++++++++++

- (void)drawRect:(NSRect)rect
{
	
    // Drawing code here.
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	NSDictionary *boldFont;
	NSString *trace;
	NSRect  boundsRect = [self bounds];
	long	i;
	float   maxValue, minValue;
	//++
	float deltaY;
	//++
	float	teStart, teEnd;
	//++
	float deltaX;
	//++
	
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
//--	teStart = teEnd = teValues[ 0];
	teStart = teEnd = teValues[ offset+0];
	for( i = 0; i < arraySize; i++)
	{
		
		if( minValue > minValues[ i]) minValue = minValues[ i];
		if( maxValue < minValues[ i]) maxValue = minValues[ i];
		if( minValue > maxValues[ i]) minValue = maxValues[ i];
		if( maxValue < maxValues[ i]) maxValue = maxValues[ i];
		if( minValue > meanValues[ i]) minValue = meanValues[ i];
		if( maxValue < meanValues[ i]) maxValue = meanValues[ i];
		
//--		if( teStart > teValues[ i]) teStart = teValues[ i];
			if( teStart > teValues[ offset+i]) teStart = teValues[offset+ i];
//--		if( teEnd < teValues[ i])	teEnd = teValues[ i];
		if( teEnd < teValues[ offset+i])	teEnd = teValues[offset+ i];

		
	}
	
	if( logMode)
	{
		minValue = log( minValue);
		maxValue = log( maxValue);
	}

//+++++++++++++++++++++++++++++++++++	
	deltaY = maxValue - minValue;
	deltaX = teEnd - teStart;

	// Draw x,y axis
	float yOffset, xOffset;
	{
		NSBezierPath *xAxis = [NSBezierPath bezierPath];
		NSBezierPath *yAxis = [NSBezierPath bezierPath];
		
//		NSLog(@"minVale: %4.4f", minValue);
//		NSLog(@"maxValue: %4.4f", maxValue);
		
		if (logMode) yOffset = (deltaY) / 10;
		else yOffset = (deltaY) / 10;
//		NSLog(@"yOffset value after log: %4.4f", yOffset);
		yOffset = (yOffset * boundsRect.size.height) / (deltaY);
//		NSLog(@"Graph height value: %4.4f", boundsRect.size.height);
//		NSLog(@"yOffset value: %4.4f", yOffset);
		
		xOffset = (deltaX) / 10;
		xOffset = (xOffset * boundsRect.size.width) / (deltaX);
//		NSLog(@"Graph width value: %4.4f", boundsRect.size.width);
//		NSLog(@"xOffset value: %4.4f", xOffset);
		
		[xAxis moveToPoint: NSMakePoint(xOffset,yOffset)];
		[xAxis lineToPoint: NSMakePoint(boundsRect.size.width,yOffset)];
		
		[yAxis moveToPoint: NSMakePoint(xOffset,yOffset)];
		[yAxis lineToPoint: NSMakePoint(xOffset,boundsRect.size.height)];
		
		// draw ticks yAxis
		float ypos = yOffset;
		float inc = (boundsRect.size.height-yOffset) / 10;
		
		[paragraphStyle setAlignment:NSLeftTextAlignment];
		boldFont = [NSDictionary dictionaryWithObjectsAndKeys:	[NSFont labelFontOfSize:8.0],NSFontAttributeName,
					[NSColor blackColor],NSForegroundColorAttributeName,
					paragraphStyle,NSParagraphStyleAttributeName,
					nil];
		
		for (i=0; i<10; i++) {
			ypos += inc;
			[yAxis moveToPoint: NSMakePoint(xOffset,ypos)];
			[yAxis lineToPoint: NSMakePoint(xOffset+2,ypos)];
			
			if (i+1<10) {
				NSRect cRect = boundsRect; 
				cRect.origin.y = boundsRect.origin.y - boundsRect.size.height + ypos + 6.5;
				cRect.origin.x += 5;						// dv = (pixvalue * deltaY / (height-yOffset)) + minValue
				if (logMode) trace = [NSString stringWithFormat:@"%2.2f", ((ypos-yOffset) * deltaY / (boundsRect.size.height-yOffset)) + minValue];
				else trace = [NSString stringWithFormat:@"%2.f", ((ypos-yOffset) * deltaY / (boundsRect.size.height-yOffset)) + minValue];
				[trace drawInRect: cRect withAttributes: boldFont];
			}
		}
		
		// draw ticks xAxis
		float xpos = xOffset;
		inc = (boundsRect.size.width-xOffset) / 10;
		for (i=0; i<10; i++) {
			xpos += inc;
			[xAxis moveToPoint: NSMakePoint(xpos,yOffset)];
			[xAxis lineToPoint: NSMakePoint(xpos,yOffset+2)];
			
			if (i+1<10) {
				NSRect cRect = boundsRect; 
				cRect.origin.y = boundsRect.origin.y - boundsRect.size.height + 40;
				cRect.origin.x = boundsRect.origin.x + xpos; //boundsRect.origin.x - boundsRect.size.width + xpos;
				cRect.origin.x -= 14;						// dv = (pixvalue * deltaY / (height-yOffset)) + minValue
				trace = [NSString stringWithFormat:@"%2.2f", (((xpos-xOffset) * deltaX / (boundsRect.size.width-xOffset)) + teStart) * 1000.0];
				NSLog(@"teStart: %2.2f",teStart*1000);
				[trace drawInRect: cRect withAttributes: boldFont];
			}
		}
		[paragraphStyle setAlignment:NSCenterTextAlignment];
		
		[xAxis setLineWidth: 1];
		[yAxis setLineWidth: 1];
		[[NSColor blackColor] set];
		[xAxis stroke];
		[yAxis stroke];
	}
	
	// Draw threshold line if threshold > 0
	NSLog(@"ThresholdValue set in graph: %2.f",threshold);
	if (threshold-minValue>0)
	{
		NSBezierPath *thresholdLine = [NSBezierPath bezierPath];
		
		float yy;
		
		if (logMode) yy = log(threshold) - minValue;
		else yy = threshold-minValue;
//		NSLog(@"ThresholdValue in graph: %2.f",yy);
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue); // ((datavalue-minValue) * (height-yOffset)) / (deltaY) = pixvalue
		yy += yOffset;														// dv = (pixvalue * deltaY / (height-yOffset)) + minValue
//		NSLog(@"minValue: %2.f",minValue);
//		NSLog(@"ThresholdValue in graph: %2.f",yy);
		
		[thresholdLine moveToPoint: NSMakePoint(xOffset,yy)];
		[thresholdLine lineToPoint: NSMakePoint(boundsRect.size.width,yy)];
		[thresholdLine setLineWidth: 1];
		
		[[NSColor greenColor] set];
		
		[thresholdLine stroke];
	}
	
	
//+++++++++++++++++++++++++++++++++++
	
	// Draw the 3 curves	
	NSBezierPath *curveMin = [NSBezierPath bezierPath];
	NSBezierPath *curveMax = [NSBezierPath bezierPath];
	NSBezierPath *curveMean = [NSBezierPath bezierPath];

	for( i = 0; i < arraySize; i++)
	{
		float   xx, yy;
		
//--		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
//+++++
		xx = ((teValues[offset+i] - teStart) * (boundsRect.size.width - xOffset)) / (teEnd - teStart) + xOffset;
//+++++
		
		if( logMode) yy = log( minValues[ i]) - minValue;
		else yy = minValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++		
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;	
		
//++
		if( i == 0) [curveMin moveToPoint: NSMakePoint( xx, yy)];
		else [curveMin lineToPoint: NSMakePoint( xx, yy)];
		
		//++++++ union of 3 cycles
		if( logMode) yy = log( maxValues[ i]) - minValue;
		else yy = maxValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;	
//++		
		if( i == 0) [curveMax moveToPoint: NSMakePoint( xx, yy)];
		else [curveMax lineToPoint: NSMakePoint( xx, yy)];
		

		if( logMode) yy = log( meanValues[ i]) - minValue;
		else yy = meanValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;		
//++		
		if( i == 0) [curveMean moveToPoint: NSMakePoint( xx, yy)];
		else [curveMean lineToPoint: NSMakePoint( xx, yy)];
		
		//++++++
		
		
	}
	
//--	for( i = 0; i < arraySize; i++)
//--	{
//--		float   xx, yy;
//--		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
//--		if( logMode) yy = log( maxValues[ i]) - minValue;
//--		else yy = maxValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//--		if( i == 0) [curveMax moveToPoint: NSMakePoint( xx, yy)];
//--		else [curveMax lineToPoint: NSMakePoint( xx, yy)];
//--	}
	
//--	for( i = 0; i < arraySize; i++)
//--	{
//--		float   xx, yy;
//--		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
//--		if( logMode) yy = log( meanValues[ i]) - minValue;
//--		else yy = meanValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//--		if( i == 0) [curveMean moveToPoint: NSMakePoint( xx, yy)];
//--		else [curveMean lineToPoint: NSMakePoint( xx, yy)];
//--	}
	
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
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;	
//++		
//--		xx = 0;
//++
		xx = xOffset;
//++		
		[curveRegression moveToPoint: NSMakePoint( xx, yy)];
		
		yy = teEnd*slope + intercept;
		yy -= minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++
				yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;
//++		
		xx = boundsRect.size.width;
		[curveRegression lineToPoint: NSMakePoint( xx, yy)];
	}
	else
	{
		for( i = 0; i < arraySize; i++)
		{
			float   xx, yy;
			
//--			yy = exp( teValues[ i]*slope + intercept) - minValue;
			yy = exp( teValues[offset+i]*slope + intercept) - minValue;
//--			yy = (yy * boundsRect.size.height) / (maxValue-minValue);
//++
			yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;
//++			
//--			xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
//++
			xx = ((teValues[offset+i] - teStart) * (boundsRect.size.width-xOffset)) / (teEnd - teStart) + xOffset;
//++			
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
		
//--		xx = ((teValues[ i] - teStart) * boundsRect.size.width) / (teEnd - teStart);
//++
		xx = ((teValues[offset+i] - teStart) * (boundsRect.size.width-xOffset)) / (teEnd - teStart) + xOffset;
//++		
		if( logMode) yy = log( meanValues[ i]) - minValue;
		else yy = meanValues[ i] - minValue;
//--		yy = (yy * boundsRect.size.height) / (maxValue-minValue);
		yy = (yy * (boundsRect.size.height-yOffset)) / (maxValue-minValue) + yOffset;
		
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

//
//  CMIVVesselPlotView.m
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CMIVVesselPlotView.h"


@implementation CMIVVesselPlotView
@synthesize curPtX;
#pragma mark-
#pragma mark 1. init and delloc functions

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		backgroundColor = [NSColor blackColor];
		pointsColor = [NSColor blackColor];
		textLabelColor = [NSColor whiteColor];
		curveColor = [NSColor whiteColor];
		axesColor = [NSColor whiteColor];
		selectBoxColor = [NSColor blueColor];
		referenceLineColor = [NSColor yellowColor];
		[curveColor retain];
		pointDiameter = 8;
		lineWidth = 1.5;


		xUnit=1.0;
		yUnit=1.0;
		xLeftLimit=0;
		xRightLimit=500;
		yTopLimit=100;
		yBottomLimit=0;
		handleSize=20;
		leftSpace=22;
		bottomSpace=22;
		
		xScaleFactor=(frame.size.width-leftSpace)/xRightLimit;
		yScaleFactor=(frame.size.height-bottomSpace)/yTopLimit;
		
		viewFrame=frame;

		currentCurve=nil;
    }
    return self;
}
- (void)dealloc
{
	if(globalTransform)
		[globalTransform release];
	if(currentCurve)
		[currentCurve release];
	currentCurve=nil;
	if(curveColor)
		[curveColor release];
	[super dealloc];
}
- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

#pragma mark-
#pragma mark 2. drawing functions
- (void)drawRect:(NSRect)rect {
    [self drawAxesInRect:rect];
	[self drawCurveInRect:rect]; 
	[self drawSelectedBoxInRect:rect];
	[self drawStenosisBoxInRect:rect];
	
	
	
}
- (void)drawAxesInRect:(NSRect)rect {
	//background
	[backgroundColor set];
	NSRectFill(rect);
	
	//y axis
	[axesColor set];
	
	NSAffineTransform *transform = [self transform:rect];
	NSBezierPath *line = [NSBezierPath bezierPath];
	[line setLineWidth:lineWidth];
	NSPoint p1, p2;
	
	p1 = NSMakePoint(xLeftLimit, yBottomLimit-handleSize*2);
	p2 = NSMakePoint(xLeftLimit, yTopLimit);
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	

	//handle of y axis
	NSRect hanlerect;
	hanlerect.origin.x=p1.x-handleSize/2;
	hanlerect.origin.y=p1.y+handleSize/2;
	hanlerect.size.width=handleSize;
	hanlerect.size.height=handleSize;	

	
	//x axis
	p1 = NSMakePoint(xLeftLimit-handleSize*2, yBottomLimit);
	p2 = NSMakePoint(xRightLimit, yBottomLimit);	
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	
	//handle of x axis
	hanlerect.origin.x=p1.x+handleSize/2;
	hanlerect.origin.y=p1.y-handleSize/2;
	hanlerect.size.width=handleSize;
	hanlerect.size.height=handleSize;
	//path = [NSBezierPath bezierPathWithOvalInRect:hanlerect];
	//[path setLineWidth:lineWidth];
	//[path stroke];
	if(mousePtX>0)
	{
		p1 = NSMakePoint(mousePtX, 0);
		p2 = NSMakePoint(mousePtX, yTopLimit);	
		p1 = [transform transformPoint:p1];
		p2 = [transform transformPoint:p2];
		[line moveToPoint:p1];
		[line lineToPoint:p2];
	}
	[line stroke];
	

}
- (void)drawCurveInRect:(NSRect)rect {
	if(!currentCurve||[currentCurve count]==0)
		return;
	NSAffineTransform *transform = [self transform:rect];
	NSBezierPath *line = [NSBezierPath bezierPath];
	NSPoint pt;
	
	pt = NSMakePoint(0,[[currentCurve objectAtIndex:0] floatValue]);
	[line moveToPoint:pt];
	unsigned j;
	for (j=1; j<[currentCurve count]; j++)
	{
		pt = NSMakePoint(j*xUnit,[[currentCurve objectAtIndex:j] floatValue]);
		[line lineToPoint:pt];
	}
	line = [transform transformBezierPath:line];
	[curveColor set];
	[line setLineWidth:lineWidth];
	[line stroke];
	 
}
- (void)drawSelectedBoxInRect:(NSRect)rect 
{
	//draw box borders
	if(!currentCurve||[currentCurve count]==0||(endPtX==0&&startPtX==0))
		return;
	NSRect selectRect;
	selectRect.origin.x=startPtX;
	selectRect.origin.y=0;
	selectRect.size.width=endPtX-startPtX;
	selectRect.size.height=yTopLimit;
	NSBezierPath *line = [NSBezierPath bezierPathWithRect:selectRect];
	NSAffineTransform *transform = [self transform:rect];
	line = [transform transformBezierPath:line];
	[selectBoxColor set];
	[line setLineWidth:lineWidth];
	[line stroke];
	
	line = [NSBezierPath bezierPath];
	[line setLineWidth:lineWidth];
	NSPoint p1, p2;
	p1 = NSMakePoint(curPtX, 0);
	p2 = NSMakePoint(curPtX, yTopLimit);
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	[line stroke];
	
	line = [NSBezierPath bezierPath];
	
	//draw reference Lines
	[referenceLineColor set];
	p1 = NSMakePoint(startPtX, 0);
	unsigned int xindex;
	float y;
	xindex=startPtX/xUnit;
	if(xindex+1>=[currentCurve count])
		y=[[currentCurve lastObject] floatValue];
	else
	{
		y=[[currentCurve objectAtIndex:xindex] floatValue]+([[currentCurve objectAtIndex:xindex+1] floatValue]-[[currentCurve objectAtIndex:xindex] floatValue])*(startPtX-(float)xindex*xUnit)/xUnit;
	}
	
	p2 = NSMakePoint(startPtX, y);
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	
	referenceY=y;
	
		
	p1 = NSMakePoint(endPtX, 0);
	xindex=endPtX/xUnit;
	if(xindex+1>=[currentCurve count])
		y=[[currentCurve lastObject] floatValue];
	else
	{
		y=[[currentCurve objectAtIndex:xindex] floatValue]+([[currentCurve objectAtIndex:xindex+1] floatValue]-[[currentCurve objectAtIndex:xindex] floatValue])*(endPtX-(float)xindex*xUnit)/xUnit;
	}
	p2 = NSMakePoint(endPtX, y);	
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	[line moveToPoint:p1];
	[line lineToPoint:p2];
	
	if(endPtX!=curPtX)
		referenceY=(referenceY+y)/2;
	
	p1 = NSMakePoint(curPtX, 0);
	xindex=curPtX/xUnit;
	if(xindex+1>=[currentCurve count])
		y=[[currentCurve lastObject] floatValue];
	else
	{
		y=[[currentCurve objectAtIndex:xindex] floatValue]+([[currentCurve objectAtIndex:xindex+1] floatValue]-[[currentCurve objectAtIndex:xindex] floatValue])*(curPtX-(float)xindex*xUnit)/xUnit;
	}
	p2 = NSMakePoint(curPtX, y);	
	p1 = [transform transformPoint:p1];
	p2 = [transform transformPoint:p2];
	[line moveToPoint:p2];
	[line lineToPoint:p1];
	NSPoint pt;
	pt.y=p1.y-handleSize;
	pt.x=p1.x-handleSize/2;
	[line lineToPoint:pt];
	pt.y=p1.y-handleSize;
	pt.x=p1.x+handleSize/2;
	[line lineToPoint:pt];
	[line lineToPoint:p1];
	curXHandleRect.origin.x=p1.x-handleSize/2;
	curXHandleRect.origin.y=pt.y;
	curXHandleRect.size.width=handleSize;
	curXHandleRect.size.height=handleSize;
	curPtY=y;
	[line stroke];	
	
}
- (void)drawStenosisBoxInRect:(NSRect)rect {
	if(!currentCurve||[currentCurve count]==0||(endPtX==0&&startPtX==0))
		return;


	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.2f/%.2f=%d%%", curPtY, referenceY, (int)(100.0*curPtY/referenceY)] attributes:attrsDictionary] autorelease];
	

	NSPoint pt1 = curXHandleRect.origin;
	NSPoint labelPosition = NSMakePoint(pt1.x + 2*handleSize, pt1.y);
	
	

	NSRect labelBounds = [label boundingRectWithSize:rect.size options:NSStringDrawingUsesDeviceMetrics];

	labelBounds.size.height += 1.0;
	labelBounds.size.width += 4.0;
	
	
	if(labelPosition.x+labelBounds.size.width >= rect.size.width)
	{
		labelPosition.x = pt1.x - handleSize - labelBounds.size.width;
	}
	
	//NSBezierPath *labelRect = [NSBezierPath bezierPathWithRect:NSMakeRect(labelPosition.x-2.0,labelPosition.y,labelBounds.size.width,labelBounds.size.height)];
	//[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
	//[labelRect fill];
	[label drawAtPoint:labelPosition];
}

#pragma mark-
#pragma mark 3. central parameters

- (NSAffineTransform *)transform:(NSRect) rect
{
	if(!globalTransform || rect.size.width!=viewFrame.size.width ||rect.size.height!=viewFrame.size.height)
	{
		if(globalTransform)
			[globalTransform release];

		if(xRightLimit>0&&yTopLimit>0)
		{
			xScaleFactor=(rect.size.width-leftSpace)/xRightLimit;
			yScaleFactor=(rect.size.height-bottomSpace)/yTopLimit;
			if(xScaleFactor<1/xUnit)
				xScaleFactor=1/xUnit;
		}		
		
		globalTransform = [NSAffineTransform transform];
		[globalTransform scaleXBy:xScaleFactor yBy:yScaleFactor];
		
		NSAffineTransform* transform2 = [NSAffineTransform transform];
		[transform2 translateXBy:leftSpace yBy:bottomSpace];
		[globalTransform appendTransform:transform2];
		[globalTransform retain];
		viewFrame=rect;
		if(invertedTransfer)
			[invertedTransfer release];
		invertedTransfer = [[NSAffineTransform alloc] initWithTransform:globalTransform];
		[invertedTransfer invert];
	}
	return globalTransform;
}
-(void) updateAllControllsWithCurve:(NSString*)name
{
}
#pragma mark-
#pragma mark 4. mouse operations

- (void)mouseDown:(NSEvent *)theEvent
{
	
	if(currentCurve&&[currentCurve count]>0)
	{
			
		[[self window] makeFirstResponder: self];
		

		NSPoint mousePositionInWindow = [theEvent locationInWindow];
		NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];
		
		if(mousePositionInView.x>0  && mousePositionInView.y>0 && mousePositionInView.x<viewFrame.size.width && mousePositionInView.y<viewFrame.size.height)
		{
		

			NSPoint ptInPlot;
			ptInPlot = [invertedTransfer transformPoint:mousePositionInView];
			mouseStartDraggingFlag=0;
			if(ptInPlot.x>0 && ptInPlot.y>0 && ptInPlot.x<xRightLimit && ptInPlot.y<yTopLimit)
			{
				mouseStartDraggingFlag=1;
				startPtX=endPtX= curPtX=ptInPlot.x;
				[viewControllor syncWithPlot];
			}
			else if(NSPointInRect(mousePositionInView, curXHandleRect))
			{
				mouseStartDraggingFlag=2;
				startDragPoint=ptInPlot;
				startDragPoint.y=curPtX;
			}
		}	
		[self setNeedsDisplay:YES];
	}
	[super mouseDown:theEvent];


	
}
- (void)mouseDragged:(NSEvent *)theEvent
{
	if(currentCurve&&[currentCurve count]>0)
	{
		NSPoint mousePositionInWindow = [theEvent locationInWindow];
		NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];
		if(mouseStartDraggingFlag)
		{
			NSPoint ptInPlot;
			ptInPlot = [invertedTransfer transformPoint:mousePositionInView];
			if(ptInPlot.x>0 && ptInPlot.x<xRightLimit && ptInPlot.y<yTopLimit)
			{
				if( mouseStartDraggingFlag==1)
					endPtX=curPtX=ptInPlot.x;
				else if( mouseStartDraggingFlag==2)
				{
					curPtX=startDragPoint.y+ptInPlot.x-startDragPoint.x;
				}
				[viewControllor syncWithPlot];
			}
		}
		[self setNeedsDisplay:YES];
	}
	
	[super mouseDragged:theEvent];
		
}
- (void)mouseMoved:(NSEvent *)theEvent
{
	if(currentCurve&&[currentCurve count]>0)
	{
		
		NSPoint mousePositionInWindow = [theEvent locationInWindow];
		NSPoint mousePositionInView = [self convertPoint:mousePositionInWindow fromView:nil];
		NSPoint ptInPlot;
		ptInPlot = [invertedTransfer transformPoint:mousePositionInView];

		if(ptInPlot.x>0 && ptInPlot.y>0 && ptInPlot.x<xRightLimit && ptInPlot.y<yTopLimit)
		{
			curseLabelFlag=1;
			unsigned int xindex=ptInPlot.x/xUnit;
			float y;
			if(xindex+1>=[currentCurve count])
				y=[[currentCurve lastObject] floatValue];
			else
			{
				y=[[currentCurve objectAtIndex:xindex] floatValue]+([[currentCurve objectAtIndex:xindex+1] floatValue]-[[currentCurve objectAtIndex:xindex] floatValue])*(ptInPlot.x-(float)xindex*xUnit)/xUnit;
			}
			[self setCursorLabelWithText:[NSString stringWithFormat:@"x: %.1fmm, y:%.2f", ptInPlot.x, y]];
			mousePtX=ptInPlot.x;
			[self setNeedsDisplay:YES];
		}
		else
		{
			if(curseLabelFlag==1)
			{
				curseLabelFlag=0;
				[self setCursorLabelWithText:@""];
				mousePtX=0;
				[self setNeedsDisplay:YES];
			}
		}
	}
	[super mouseMoved:theEvent];
}

- (void)setCursorLabelWithText:(NSString*)text
{
	if([text isEqualToString:@""])
	{
		[[NSCursor arrowCursor] set];
		return;
	}
	
	NSPoint hotSpot = [[NSCursor arrowCursor] hotSpot];
	
	NSMutableDictionary *attrsDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
	[attrsDictionary setObject:textLabelColor forKey:NSForegroundColorAttributeName];
	NSAttributedString *label = [[[NSAttributedString alloc] initWithString:text attributes:attrsDictionary] autorelease];
	//	NSRect labelBounds = [label boundingRectWithSize:[self bounds].size options:NSStringDrawingUsesDeviceMetrics];
	NSRect labelBounds = [label boundingRectWithSize:viewFrame.size options:NSStringDrawingUsesDeviceMetrics];
	
	NSSize imageSize = [[[NSCursor arrowCursor] image] size];
	float arrowWidth = imageSize.width;
	imageSize.width += labelBounds.size.width;
	NSImage *cursorImage = [[NSImage alloc] initWithSize: imageSize];
	NSPoint labelPosition = NSMakePoint(arrowWidth-6, .0);
	
	// draw
	[cursorImage lockFocus];
	[[[NSCursor arrowCursor] image] drawAtPoint: NSMakePoint( 0, 0) fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
	[[[NSColor blackColor] colorWithAlphaComponent:0.5] set];
	//NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, labelBounds.size.height+4));
	NSRectFill(NSMakeRect(labelPosition.x-2, labelPosition.y+1, labelBounds.size.width+4, 13)); // nicer if the height stays the same when moving the mouse
	[label drawAtPoint:labelPosition];
	[cursorImage unlockFocus];
	
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:hotSpot];
	[cursor set];
	
	[cursorImage release];
	[cursor release];
}

#pragma mark-
#pragma mark 4. outlet for controllor
- (void)setViewControllor:(id)controllor
{
	viewControllor=controllor;
}
- (void)setACurve:(NSString*)name:(NSArray*)curve:(NSColor*)color:(float)xu:(float)yu
{
	if(currentCurve)
		[currentCurve release];
	currentCurve=curve;
	[currentCurve retain];
	[curveColor release];
	curveColor = color;
	[curveColor retain];
	xUnit=xu;
	yUnit=yu;
	xRightLimit=[currentCurve count]*xUnit*1.05;
	unsigned i;
	yTopLimit=[[currentCurve objectAtIndex:0] floatValue];
	for(i=0;i<[currentCurve count];i++)
	{
		if(yTopLimit<[[currentCurve objectAtIndex:i] floatValue])
			yTopLimit=[[currentCurve objectAtIndex:i] floatValue];
	}
	yTopLimit=yTopLimit*1.2;
	
	[globalTransform release];
	globalTransform=nil;
	[self setNeedsDisplay:YES];
	
	
}
- (void)removeCurCurve
{
	if(currentCurve)
		[currentCurve release];
	currentCurve=nil;
	curveColor = [NSColor whiteColor];
	xUnit=1.0;
	yUnit=1.0;
	xScaleFactor=1.0;
	yScaleFactor=1.0;
	[self setNeedsDisplay:YES];
}


@end

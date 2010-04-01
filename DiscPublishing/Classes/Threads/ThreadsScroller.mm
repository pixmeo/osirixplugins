//
//  ThreadsScroller.mm
//  ManualBindings
//
//  Created by Alessandro Volz on 2/17/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "ThreadsScroller.h"


@implementation ThreadsScroller // TODO: Moche, moche, moche!

-(BOOL)isOnHUDWindow {
	return [[self window] styleMask]&NSHUDWindowMask != 0;
}

-(BOOL)isOpaque {
	if ([self isOnHUDWindow])
		return NO;
	else return [super isOpaque];
}

-(void)setNeedsDisplayInRect:(NSRect)invalidRect {
	if ([self isOnHUDWindow])
		[super setNeedsDisplayInRect:[self bounds]]; 
	else [super setNeedsDisplayInRect:invalidRect]; ;
}

static NSPoint operator+(const NSPoint& p, const NSSize& s)
{ return NSMakePoint(p.x+s.width, p.y+s.height); }

-(void)drawRect:(NSRect)dirtyRect {
	if ([self isOnHUDWindow]) {
		NSRect bounds = [self bounds];
		
		[NSGraphicsContext saveGraphicsState];
		
		[[NSColor colorWithDeviceWhite:1 alpha:0.25] set];
		[NSBezierPath strokeLineFromPoint:bounds.origin toPoint:bounds.origin+NSMakeSize(0,bounds.size.height)];
		[[NSColor colorWithDeviceWhite:1 alpha:0.20] set];
		[NSBezierPath strokeLineFromPoint:bounds.origin+NSMakeSize(1,0) toPoint:bounds.origin+NSMakeSize(1,bounds.size.height)];
		[[NSColor colorWithDeviceWhite:1 alpha:0.03] set];
		[NSBezierPath fillRect:bounds];
		
		[self drawArrow:NSScrollerIncrementArrow highlight:NO];
		[self drawArrow:NSScrollerDecrementArrow highlight:NO];
		[self drawKnob];

		[NSGraphicsContext restoreGraphicsState];
	} else [super drawRect:dirtyRect];
}

-(void)drawKnob {
	if ([self isOnHUDWindow]) {
		NSRect rect = NSInsetRect([self rectForPart:NSScrollerKnob], 1,0.5);
		rect.origin.x += 1; rect.size.width -= 1;
		[[NSColor colorWithDeviceWhite:1 alpha:0.75] set];
		[[NSBezierPath bezierPathWithRoundedRect:rect xRadius:rect.size.width/2 yRadius:rect.size.width/2] fill];
	} else [super drawKnob];
}

-(void)drawArrow:(NSScrollerArrow)arrow highlight:(BOOL)highlight {
	if ([self isOnHUDWindow]) {
		NSScrollerPart part = (arrow == NSScrollerIncrementArrow)? NSScrollerIncrementLine : NSScrollerDecrementLine;
		NSRect rect = NSInsetRect([self rectForPart:part], 1, 0);
		rect.origin.x += 1; rect.size.width -= 1;
		
		CGFloat y = (arrow == NSScrollerIncrementArrow)? 2 : -2;
		
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(0, y)];
		[path lineToPoint:NSMakePoint(y, -y)];
		[path lineToPoint:NSMakePoint(-y, -y)];
		[path closePath];
		
		NSAffineTransform* transform = [NSAffineTransform transform];
		[transform translateXBy:rect.origin.x+rect.size.width/2 yBy:rect.origin.y+rect.size.height/2];
		[path transformUsingAffineTransform:transform];
		
		[[NSColor colorWithDeviceWhite:1 alpha:0.75] set];
		[path fill];
		//[NSBezierPath fillRect:rect];
	} else [super drawArrow:arrow highlight:highlight];
}

-(NSRect)rectForPart:(NSScrollerPart)part {
	if ([self isOnHUDWindow]) {
		NSRect bounds = [self bounds];
		
		CGFloat pos = [self floatValue];
		CGFloat knobProportion = [self knobProportion];
		CGFloat arrowsSpace = (bounds.size.width-1)*2;
		CGFloat knobSpace = bounds.size.height-arrowsSpace;
		CGFloat knobSize = knobSpace*knobProportion;
		CGFloat emptySpace = knobSpace-knobSize;
		
		switch (part) {
			case NSScrollerDecrementLine: return NSMakeRect(bounds.origin.x, bounds.origin.y+knobSpace, bounds.size.width, arrowsSpace/2);
			case NSScrollerIncrementLine: return NSMakeRect(bounds.origin.x, bounds.origin.y+knobSpace+arrowsSpace/2, bounds.size.width, arrowsSpace/2);
			case NSScrollerDecrementPage: return NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, emptySpace*pos);
			case NSScrollerIncrementPage: return NSMakeRect(bounds.origin.x, bounds.origin.y+emptySpace*pos+knobSize, bounds.size.width, emptySpace*(1.0-pos));
			case NSScrollerKnob: return NSMakeRect(bounds.origin.x, bounds.origin.y+emptySpace*pos, bounds.size.width, knobSize);
			case NSScrollerKnobSlot: return NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, knobSpace);
		}

		return [super rectForPart:part];
	} else return [super rectForPart:part];
}

@end

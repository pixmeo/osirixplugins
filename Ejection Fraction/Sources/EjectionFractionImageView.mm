//
//  EjectionFractionImageView.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 17.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionImageView.h"
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/MyPoint.h>
#import <OsiriXAPI/N2Operators.h>
#import <OsiriXAPI/N2MinMax.h>
#import <OsiriXAPI/NSView+N2.h>


@implementation EjectionFractionImageView
@synthesize rois = _rois, pix = _pix;

+(EjectionFractionImageView*)viewWithObjects:(NSArray*)objects {
	return [[(EjectionFractionImageView*)[self alloc] initWithObjects:objects] autorelease];
}

-(id)initWithObjects:(NSArray*)objects {
	NSMutableArray* rois = [NSMutableArray arrayWithCapacity:[objects count]];
	for (id o in objects)
		if ([o isKindOfClass:[DCMPix class]]) {
			[o baseAddr]; // make sure [o baseAddr] is valid, or [o image] will crash in older versions of OsiriX
			[self setPix:[o image]];
		} else [rois addObject:o];
	[self setRois:rois];
	
	for (ROI* roi in rois)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiChanged:) name:OsirixROIChangeNotification object:roi];
	
	return [self initWithSize: _pix? [_pix size] : NSMakeSize(128)];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self setRois:NULL];
	[self setPix:NULL];
	[super dealloc];
}

-(BOOL)isOpaque {
	return NO;
}

-(void)roiChanged:(NSNotification*)n {
	[self setNeedsDisplay:YES];
}

-(NSRect)optimalRoiRect {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:0];
	for (ROI* roi in _rois)
		[points addObjectsFromArray:[roi splinePoints]];
	
	N2MinMax x = N2MakeMinMax([[points objectAtIndex:0] x]);
	N2MinMax y = N2MakeMinMax([[points objectAtIndex:0] y]);
	for (MyPoint* p in points) {
		N2ExtendMinMax(x, p.x);
		N2ExtendMinMax(y, p.y);
	}
	
	NSRect space = NSMakeRect(x.min, y.min, x.max-x.min, y.max-y.min);
	
	NSRect contentRect;
	contentRect.size = NSMakeSize(std::max(space.size.width, space.size.height));
	contentRect.origin = space.origin - (contentRect.size-space.size)/2;
	
	contentRect = NSInsetRect(contentRect, -contentRect.size.width/100, -contentRect.size.height/100);
	
	return contentRect;
}

/*-(void)paintImageWithPic:(NSImage*)pic rois:(NSArray*)rois {
	NSSize size = [self size];
	[self lockFocus];
	
	NSRectFillUsingOperation(NSMakeRect(NSZeroPoint, size), NSCompositeClear);

	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform scaleXBy:1 yBy:-1];
	[transform translateXBy:0 yBy:-size.height];
	
	NSRect contentRect = NSZeroRect;
	if (pic) {
		contentRect.size = [pic size];
		[pic drawInRect:NSMakeRect(NSZeroPoint, size) fromRect:NSMakeRect(NSZeroPoint, contentRect.size) operation:NSCompositeCopy fraction:1];
	} else {
		contentRect = [self optimalRoiRect];
	}
	
	[transform translateXBy:-contentRect.origin.x*size.width/contentRect.size.width yBy:-contentRect.origin.y*size.height/contentRect.size.height];
	[transform scaleXBy:size.width/contentRect.size.width yBy:size.height/contentRect.size.height];
	
	for (ROI* roi in rois) {
		NSBezierPath* path = [NSBezierPath bezierPath];
		NSMutableArray* points = [roi splinePoints];
		
		[path moveToPoint:[[points objectAtIndex:0] point]];
		for (MyPoint* p in points)
			[path lineToPoint:[p point]];
		[path closePath];
		[path transformUsingAffineTransform:transform];
		
		RGBColor rgb = [roi rgbcolor];
		NSColor* color = [NSColor colorWithDeviceRed:float(rgb.red)/0xffff green:float(rgb.green)/0xffff blue:float(rgb.blue)/0xffff alpha:1];
		[color setStroke];
		[path setLineWidth:(contentRect.size.width+contentRect.size.height)/320];
		[path stroke];
	}
	
	[self unlockFocus];
	return;
}*/

-(NSSize)optimalSize {
	return n2::ceil(_pix? [_pix size] : [self optimalRoiRect].size);
}

-(NSSize)optimalSizeForWidth:(CGFloat)width {
	NSSize imageSize = _pix? [_pix size] : [self optimalRoiRect].size;
	if (width == CGFLOAT_MAX) width = imageSize.width;
	return n2::ceil(NSMakeSize(width, width/imageSize.width*imageSize.height));
}

-(void)setFrame:(NSRect)frameRect {
	[super setFrame:frameRect];
	[self setNeedsDisplay:YES];
}

-(void)drawRect:(NSRect)dirtyRect {
	NSRect bounds = [self bounds];
	[NSGraphicsContext saveGraphicsState];
	
	NSRect contentRect;
	if (_pix)
		contentRect = NSMakeRect(NSZeroPoint, [_pix size]);
	else contentRect = [self optimalRoiRect];
	
	NSRect contentBoundsRect = NSZeroRect;
	CGFloat scaleFactor;
	if (bounds.size.width/bounds.size.height > contentRect.size.width/contentRect.size.height) {
		scaleFactor = bounds.size.height/contentRect.size.height;
		contentBoundsRect.size = NSMakeSize(contentRect.size.width*scaleFactor, bounds.size.height);
		contentBoundsRect.origin = NSMakePoint((bounds.size.width-contentBoundsRect.size.width)/2, 0);
	} else {
		scaleFactor = bounds.size.width/contentRect.size.width;
		contentBoundsRect.size = NSMakeSize(bounds.size.width, contentRect.size.height*scaleFactor);
		contentBoundsRect.origin = NSMakePoint(0, (bounds.size.height-contentBoundsRect.size.height)/2);
	}
	
	if (_pix)
		[_pix drawInRect:contentBoundsRect fromRect:contentRect operation:NSCompositeCopy fraction:1];

	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform scaleXBy:1 yBy:-1];
	[transform translateXBy:0 yBy:-bounds.size.height];

	for (ROI* roi in _rois) {
		NSBezierPath* path = [NSBezierPath bezierPath];
		NSMutableArray* points = [roi splinePoints];
		
		[path moveToPoint:([[points objectAtIndex:0] point]-contentRect.origin)*scaleFactor+contentBoundsRect.origin];
		for (MyPoint* p in points)
			[path lineToPoint:([p point]-contentRect.origin)*scaleFactor+contentBoundsRect.origin];

		if(roi.type != tOPolygon)
			[path closePath];
		
		[path transformUsingAffineTransform:transform];
		
		RGBColor rgb = [roi rgbcolor];
		NSColor* color = [NSColor colorWithDeviceRed:float(rgb.red)/0xffff green:float(rgb.green)/0xffff blue:float(rgb.blue)/0xffff alpha:1];
		[color setStroke];
		[path setLineWidth:3];
		[path stroke];
	}
	
	[NSGraphicsContext restoreGraphicsState];
}

@end

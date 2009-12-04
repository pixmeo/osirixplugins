//
//  SelectablePDFView.m
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 6/8/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "SelectablePDFView.h"
#import <Nitrogen/Nitrogen.h>
#import "ArthroplastyTemplatingWindowController+Templates.h"
#include <algorithm>
#include <cmath>

NSString* SelectablePDFViewDocumentDidChangeNotification = @"SelectablePDFViewDocumentDidChangeNotification";

@interface NSImage (Test)
@end
@implementation NSImage (Test)

-(NSRect)bBoxSkippingColor:(NSColor*)color inRect:(NSRect)box {
	BOOL flipped = [self isFlipped];
	[self setFlipped:YES];
	
	if (box.size.width < 0) { box.origin.x += box.size.width; box.size.width = -box.size.width; } 
	if (box.size.height < 0) { box.origin.y += box.size.height; box.size.height = -box.size.height; } 
	
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
	//	NSSize imageSize = [self size];
	
	NSAssert([bitmap numberOfPlanes] == 1, @"Image must be planar");
	NSAssert([bitmap samplesPerPixel] == 4, @"Image bust be RGBA");
	NSAssert([bitmap bitmapFormat] == 0, @"Image format must be zero");
	NSAssert([bitmap bitsPerPixel] == 32, @"Image samples must be 8 bits wide");
	
	
	int x, y;
	// change origin.x
	for (x = box.origin.x; x < box.origin.x+box.size.width; ++x)
		for (y = box.origin.y; y <= box.origin.y+box.size.height; ++y)
			if (![[bitmap colorAtX:x y:y] isEqualToColor:color alphaThreshold:0.1])
				goto end_origin_x;
end_origin_x:
	NSColor* c = [bitmap colorAtX:x y:y];
	[c isEqualToColor:color alphaThreshold:0.1];
	if (x < box.origin.x+box.size.width) {
		box.size.width -= x-box.origin.x;
		box.origin.x = x;
	}
	
/*	// change origin.y
	for (y = box.origin.y; y < box.origin.y+box.size.height; ++y)
		for (x = box.origin.x; x <= box.origin.x+box.size.width; ++x)
			if (![[bitmap colorAtX:x y:y] isEqualToColor:color alphaThreshold:0.1])
				goto end_origin_y;
end_origin_y:
	if (y < box.origin.y+box.size.height) {
		box.size.height -= y-box.origin.y;
		box.origin.y = y;
	}
	
	// change size.width
	for (x = box.origin.x+box.size.width-1; x >= box.origin.x; --x)
		for (y = box.origin.y; y <= box.origin.y+box.size.height; ++y)
			if (![[bitmap colorAtX:x y:y] isEqualToColor:color alphaThreshold:0.1])
				goto end_size_x;
end_size_x:
	if (x >= box.origin.x)
		box.size.width = x-box.origin.x+1;
		
		// change size.height
		for (y = box.origin.y+box.size.height-1; y >= box.origin.y; --y)
			for (x = box.origin.x; x <= box.origin.x+box.size.width; ++x)
				if (![[bitmap colorAtX:x y:y] isEqualToColor:color alphaThreshold:0.1])
					goto end_size_y;
end_size_y:
	if (y >= box.origin.y)
		box.size.height = y-box.origin.y+1;*/
		
	[bitmap release];
	[self setFlipped:flipped];
	return box;
}

@end

@implementation SelectablePDFView

-(void)awakeFromNib {
	[self setMenu:NULL];
}

-(NSPoint)convertPointTo01:(NSPoint)point forPage:(PDFPage*)page {
	NSRect box = [page boundsForBox:kPDFDisplayBoxMediaBox];
	return NSMakePoint([_controller flipTemplatesHorizontally]? 1-point.x/box.size.width : point.x/box.size.width, point.y/box.size.height);
}

-(NSPoint)convertPointFrom01:(NSPoint)point forPage:(PDFPage*)page {
	NSRect box = [page boundsForBox:kPDFDisplayBoxMediaBox];
	return NSMakePoint(box.origin.x+point.x*box.size.width,
					   box.origin.y+point.y*box.size.height);
}

-(NSRect)convertRectFrom01:(NSRect)rect forPage:(PDFPage*)page {
	NSRect box = [page boundsForBox:kPDFDisplayBoxMediaBox];
	return NSMakeRect(box.origin.x+rect.origin.x*box.size.width,
					  box.origin.y+rect.origin.y*box.size.height,
					  rect.size.width*box.size.width,
					  rect.size.height*box.size.height);
}

-(BOOL)performKeyEquivalent:(NSEvent *)theEvent {
	return NO;
}

-(void)mouseDown:(NSEvent*)event {
	_selectionInitiated = NO;
	_mouseDownLocation = [event locationInWindow];
	if ([event modifierFlags]&NSCommandKeyMask) {
		_selected = NO;
		if ([event clickCount] == 1) {
			_selectionInitiated = YES;
			_selectedRect.origin = [self convertPointTo01: [self convertPoint:[self convertPoint:[event locationInWindow] fromView:NULL] toPage:[self currentPage]] forPage:[self currentPage]];
			_selectedRect.size = NSMakeSize(0, 0);
		}
	}
	
	[self setNeedsDisplay:YES];
}

-(void)mouseDragged:(NSEvent*)event {
	if (_selectionInitiated) {
		_selected = YES;
		NSPoint position = [self convertPointTo01: [self convertPoint:[self convertPoint:[event locationInWindow] fromView:NULL] toPage:[self currentPage]] forPage:[self currentPage]];
		_selectedRect.size = NSMakeSize(position.x-_selectedRect.origin.x, position.y-_selectedRect.origin.y);
		[self setNeedsDisplay:YES];
	} else
		if (NSDistance(_mouseDownLocation, [event locationInWindow]) > 5)
			[_controller dragTemplate:[_controller currentTemplate] startedByEvent:event onView:self];
}

-(void)enhanceSelection {
	N2Image* image = [[N2Image alloc] initWithContentsOfFile:[[[self document] documentURL] path]];
	
	NSSize size = [image size];
	NSRect sel = _selectedRect;
	sel = NSMakeRect(std::floor(sel.origin.x*size.width), std::floor(sel.origin.y*size.height), std::ceil(sel.size.width*size.width), std::ceil(sel.size.height*size.height));
	
	sel = [image bBoxSkippingColor:[[NSColor whiteColor] colorUsingColorSpaceName:NSCalibratedRGBColorSpace] inRect:sel];
	
	sel = NSMakeRect(sel.origin/size, sel.size/size);

 	const static CGFloat margin = 0.01; // facteur 0..1
	sel.origin -= margin;
	sel.size += margin*2;
	
	_selectedRect = sel;
}

-(void)mouseUp:(NSEvent*)event {
	if (_selectionInitiated)
		if (_selected) {
			[self enhanceSelection];
			[_controller setSelectionForCurrentTemplate:_selectedRect];
			[self setNeedsDisplay:YES];
		} else [_controller setSelectionForCurrentTemplate:NSMakeRect(0,0,1,1)];
}

-(void)setDocument:(PDFDocument*)document {
	[super setDocument:document];
	_selected = [_controller selectionForCurrentTemplate:&_selectedRect];
	[[NSNotificationCenter defaultCenter] postNotificationName:SelectablePDFViewDocumentDidChangeNotification object:self];
}

-(void)drawPage:(PDFPage*)page {
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	NSRect box = [page boundsForBox:kPDFDisplayBoxMediaBox];

	if ([_controller flipTemplatesHorizontally]) {
		NSAffineTransform* transform = [NSAffineTransform transform];
		[transform translateXBy:box.size.width yBy:0];
		[transform scaleXBy:-1 yBy:1];
		[transform concat];
	}	
	
	[super drawPage:page];
	
	if (_selected && _selectedRect != NSMakeRect(0,0,1,1)) {
		NSRect selection = [self convertRectFrom01:_selectedRect forPage:[self currentPage]];
		NSBezierPath* path = [NSBezierPath bezierPath];
		[path appendBezierPathWithRect:box];
		[path setWindingRule:NSEvenOddWindingRule];
		[path appendBezierPathWithRect:selection];
		[[[NSColor grayColor] colorWithAlphaComponent:.75] setFill];
		[path fill];
	}
	
	[context restoreGraphicsState];
}

@end

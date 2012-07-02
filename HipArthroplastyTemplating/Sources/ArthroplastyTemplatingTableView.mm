//
//  ArthroplastyTemplatingTableView.m
//  Arthroplasty Templating II
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingTableView.h"
#import "ArthroplastyTemplatingWindowController+Templates.h"
#import <OsiriXAPI/NSImage+N2.h>
#import <OsiriXAPI/N2Operators.h>

@implementation ArthroplastyTemplatingTableView

-(NSImage*)dragImageForRowsWithIndexes:(NSIndexSet*)dragRows tableColumns:(NSArray*)cols event:(NSEvent*)event offset:(NSPointPointer)offset {
	if ([dragRows count] >1) return NULL;
	[self selectRowIndexes:dragRows byExtendingSelection:NO];
	[self setNeedsDisplay:YES];
    
    ArthroplastyTemplate* t = [_controller currentTemplate];
	N2Image* image = [_controller dragImageForTemplate:t];
    
    
    NSPoint o = NSZeroPoint;
    if ([t origin:&o forDirection:_controller.templateDirection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if (![_controller mustFlipHorizontally:t])
			o.x = image.size.width-o.x;
        if (!image.isFlipped)
            o.y = image.size.height-o.y;
	}
    
    *offset = o-image.size/2-NSMakePoint(1,-3);
    
//    NSPoint click = [self convertPoint:[event locationInWindow] fromView:NULL];
//	
//	NSSize size = [image size];
//	NSPoint o = NSMakePoint(size)/2;
//	
//    
//	[view dragImage:image at:click-o-NSMakePoint(1,-3) offset:NSMakeSize(0,0) event:event pasteboard:pboard source:view slideBack:YES];

    
    
    
    
    
    
    return image;
}

-(BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
	return YES;
}

@end

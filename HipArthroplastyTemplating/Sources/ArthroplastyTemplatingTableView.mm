//
//  ArthroplastyTemplatingTableView.m
//  Arthroplasty Templating II
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingTableView.h"
#import "ArthroplastyTemplatingWindowController+Templates.h"
#import <OsiriX Headers/NSImage+N2.h>

@implementation ArthroplastyTemplatingTableView

-(NSImage*)dragImageForRowsWithIndexes:(NSIndexSet*)dragRows tableColumns:(NSArray*)cols event:(NSEvent*)event offset:(NSPointPointer)offset {
	if ([dragRows count] >1) return NULL;
	[self selectRowIndexes:dragRows byExtendingSelection:NO];
	[self setNeedsDisplay:YES];
	return [_controller dragImageForTemplate:[_controller currentTemplate]];
}

-(BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
	return YES;
}

@end

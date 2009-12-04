//
//  MIRCFileTableView.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/12/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCFileTableView.h"


@implementation MIRCFileTableView

- (void)awakeFromNib{
	[self  registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}
/*
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSLog(@"Dragging entered");
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSLog(@"perform drag");
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        // Depending on the dragging source and modifier keys,
        // the file data may be copied or linked
        if (sourceDragMask & NSDragOperationLink) {
            [self addFiles:files];
        }
    }
    return YES;
}
*/



- (void)addFiles:(NSArray *)files{
	[[self delegate] addFiles:files];
}

@end

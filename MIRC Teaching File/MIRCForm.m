//
//  MIRCForm.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/25/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCForm.h"


@implementation MIRCForm

- (void)awakeFromNib{
	[self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	NSLog(@"drag entered");
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSStringPboardType] ) {
        return sourceDragMask;
    }

    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSStringPboardType] ) {
		//[self setStringValue:[pboard stringForType: NSStringPboardType]];
	}
    return YES;
}

@end

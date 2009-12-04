//
//  AccessoryFileArrayController.m
//  TeachingFile
//
//  Created by Lance Pysher on 2/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "AccessoryFileArrayController.h"


@implementation AccessoryFileArrayController

- (void)awakeFromNib{
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects: NSFilenamesPboardType, nil]];
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    // Add code here to validate the drop
    NSLog(@"validate Drop");
    return NSDragOperationEvery;    
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation{
return YES;
}

@end

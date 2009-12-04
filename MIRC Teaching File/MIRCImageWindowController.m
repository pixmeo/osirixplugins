//
//  MIRCImageWindowController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/24/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCImageWindowController.h"


@implementation MIRCImageWindowController

- (id)initWithImage:(NSXMLElement *)image imageArray:(NSArray *)images{
	if (self = [super initWithWindowNibName:@"MIRCImages"]) {
		_image = [image retain];
		_images = [images retain];
	}
	return self;
	
}

- (void)dealloc {
	[_image release];
	[_images release];
	[super dealloc];
}

- (NSXMLElement *)image{
	return _image;
}

- (NSArray *)images{
	return _images;
}

- (IBAction)closeWindow:(id)sender{
	[nodeController commitEditing];
	[NSApp endSheet:[self window]];
	[[self window]  orderOut:self];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard{
	int row = [rowIndexes firstIndex];
	if (row != NSNotFound){
		NSString *title = [[[imageArrayController selectedObjects] objectAtIndex:0] title];
		[pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
            owner:nil];
		[pboard setString:title forType:NSStringPboardType];
		return YES;
	}
	return NO;
	
	
}

@end

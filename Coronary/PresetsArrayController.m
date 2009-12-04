//
//  PresetsArrayController.m
//  Coronary
//
//  Created by Antoine Rosset on 19.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "PresetsArrayController.h"
#import "CoronaryView.h"

@implementation PresetsArrayController

- (void)add:(id)sender
{
	NSColor *color = [NSColor whiteColor];
	
	if( [[self arrangedObjects] count] == 1) color = [NSColor yellowColor];
	if( [[self arrangedObjects] count] == 2) color = [NSColor orangeColor];
	if( [[self arrangedObjects] count] == 3) color = [NSColor redColor];
	if( [[self arrangedObjects] count] == 4) color = [NSColor purpleColor];
	if( [[self arrangedObjects] count] == 5) color = [NSColor cyanColor];
	if( [[self arrangedObjects] count] == 6) color = [NSColor magentaColor];
	if( [[self arrangedObjects] count] == 7) color = [NSColor brownColor];
	if( [[self arrangedObjects] count] == 8) color = [NSColor lightGrayColor];
	if( [[self arrangedObjects] count] == 9) color = [NSColor darkGrayColor];
	
	[self addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: @"normal", @"state", [NSArchiver archivedDataWithRootObject: color], @"color", nil]];
	
	[[CoronaryView view] refresh];
}

- (void)remove:(id)sender
{
	[super remove: sender];
	[[CoronaryView view] refresh];
}

- (void)objectDidEndEditing:(id)editor
{
	[[CoronaryView view] refresh];
	[super objectDidEndEditing: editor];
}
@end

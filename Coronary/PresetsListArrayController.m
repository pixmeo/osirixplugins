//
//  PresetsArrayController.m
//  Coronary
//
//  Created by Antoine Rosset on 19.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "PresetsListArrayController.h"
#import "CoronaryView.h"


@implementation PresetsListArrayController

- (void)add:(id)sender
{
	[self addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: @"perfusion", @"name", nil]];
	
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

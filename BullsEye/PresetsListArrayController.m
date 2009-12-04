//
//  PresetsArrayController.m
//  BullsEye
//
//  Created by Antoine Rosset on 19.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "PresetsListArrayController.h"
#import "BullsEyeView.h"


@implementation PresetsListArrayController

- (void)add:(id)sender
{
	[self addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys: @"perfusion", @"name", nil]];
	
	[[BullsEyeView view] refresh];
}

- (void)remove:(id)sender
{
	[super remove: sender];
	[[BullsEyeView view] refresh];
}

- (void)objectDidEndEditing:(id)editor
{
	[[BullsEyeView view] refresh];
	[super objectDidEndEditing: editor];
}

@end

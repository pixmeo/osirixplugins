//
//  BullsEye.m
//  BullsEye
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import "BullsEye.h"
#import "BullsEyeController.h"

@implementation BullsEye

- (long) filterImage:(NSString*) menuName
{
	BullsEyeController *c = [[BullsEyeController alloc] initWithWindowNibName: @"BullsEyeController"];
	
	[[c window] makeKeyAndOrderFront: self];
	
	return 0;   // No Errors
}

@end

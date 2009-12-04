//
//  Coronary.m
//  Coronary
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import "Coronary.h"
#import "CoronaryController.h"

@implementation Coronary

- (long) filterImage:(NSString*) menuName
{
	CoronaryController *c = [[CoronaryController alloc] initWithWindowNibName: @"CoronaryController"];
	
	[[c window] makeKeyAndOrderFront: self];
	
	return 0;   // No Errors
}

@end

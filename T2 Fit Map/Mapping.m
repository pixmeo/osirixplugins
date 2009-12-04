//
//  DuplicateFilter.m
//  Duplicate
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import "Mapping.h"
#import "Controller.h"

@implementation MappingT2FitFilter

- (ViewerController*)   viewerController
{
	return viewerController;
}

- (long) filterImage:(NSString*) menuName
{
	// Display a nice window to thanks the user for using our powerful filter!
	ControllerT2Fit* coWin = [[ControllerT2Fit alloc] init:self];
	[coWin showWindow:self];
	
	return 0;
}
@end

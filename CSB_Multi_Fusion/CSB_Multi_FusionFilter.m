//
//  CSB_Multi_FusionFilter.m
//  CSB_Multi_Fusion
//
//  Copyright (c) 2009 CSB_MGH. All rights reserved.
//

#import "CSB_Multi_FusionFilter.h"
#import "Controller.h"

@implementation CSB_Multi_FusionFilter

- (void) initPlugin
{
}

- (ViewerController*)   viewerController
{
	return viewerController;
}


- (long) filterImage:(NSString*) menuName
{
	
	// Display a nice window to thanks the user for using our powerful filter!
	ControllerCMIRFusion3* coWin = [[ControllerCMIRFusion3 alloc] init:self];
	[coWin showWindow:self];
	
	return 0;
}

@end

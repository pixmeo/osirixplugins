//
//  CMIR_T2_Fit_MapFilter.m
//  CMIR_T2_Fit_Map
//
//  Copyright (c) 2009 CMIR. All rights reserved.
//

#import "CMIR_T2_Fit_MapFilter.h"
#import "Controller.h"

@implementation CMIR_T2_Fit_MapFilter

- (ViewerController*)   viewerController
{
	return viewerController;
}

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	ControllerCMIRT2Fit* coWin = [[ControllerCMIRT2Fit alloc] init:self];
	[coWin showWindow:self];

	if( coWin) return 0; // No Errors
	else return -1;

}

@end

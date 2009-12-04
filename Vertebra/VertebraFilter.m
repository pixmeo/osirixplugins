//
//  VertebraFilter.m
//  Vertebra
//
//  Copyright (c) 2008 Antoine. All rights reserved.
//

#import "VertebraFilter.h"

@implementation VertebraFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	ViewerController	*new2DViewer;
	
	// In this plugin, we will simply duplicate the current 2D window!
	
	new2DViewer = [self duplicateCurrent2DViewerWindow];
	
	if( new2DViewer) return 0; // No Errors
	else return -1;
}

@end

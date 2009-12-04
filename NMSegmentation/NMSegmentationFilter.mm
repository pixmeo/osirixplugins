//
//  NMSegmentationFilter.m
//  NMSegmentation
//
//  Copyright (c) 2008 - 2009 Brian Jensen. All rights reserved.
//

#import "NMSegmentationFilter.h"
#import "NMRegionGrowingController.h"

#import "ITKRegionGrowing3D.h"

@implementation NMSegmentationFilter

- (void) initPlugin
{
	//Plugin init code goes here
}

- (long) filterImage:(NSString*) menuName
{
	NSLog(@"NMSegmentation triggered");

	//search for an open controller for the viewer pair
	NMRegionGrowingController* controller = [NMSegmentationFilter getControllerForMainViewer:viewerController registeredViewer:[viewerController blendedWindow]];
	if(controller == nil)
		controller = [[NMRegionGrowingController alloc] initWithMainViewer:viewerController registeredViewer:[viewerController blendingController]];
	else	
		[controller showWindow:self]; //an active instance was found, just redisplay the window
	
	return 0;		//returning a non zero value indicates a plugin error

}

+ (id) getControllerForMainViewer:(ViewerController*) mViewer registeredViewer:(ViewerController*) rViewer
{
	NSArray *winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"NMRegionGrowingWindow"])
		{
			if( [[loopItem windowController] mainViewer] == mViewer &&
			   [[loopItem windowController] registeredViewer] == rViewer)
			{
				DebugLog(@"Found an existing segmentation window controller, just using that");
				return [loopItem windowController];
			}
		}
	}
	
	return nil;
}


@end

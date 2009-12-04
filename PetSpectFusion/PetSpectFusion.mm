//
//  PetSpectFusion.m
//  PetSpectFusion
//
//  Copyright (c) 2008 - 2009 Brian Jensen. All rights reserved.
//

#import <Foundation/NSDebug.h>

#import "PetSpectFusion.h"
#import "PSFSettingsWindowController.h"

@implementation PetSpectFusion

- (void) initPlugin
{
	//TODO init plugin here
}

- (void) dealloc
{
	DebugLog(@"PetSpectFusion dealloc called!");
	[super dealloc];
}

- (long) filterImage:(NSString*) menuName
{	
	if([viewerController blendedWindow] == nil)
	{
		NSLog(@"PetSpectFusion aborting, blending viewer is not defined");
		return 0;
	}
	
	NSLog(@"PetSpectFusion filter triggered");
	
	PSFSettingsWindowController* controller = [PetSpectFusion getControllerForFixedViewer:viewerController movingViewer:[viewerController blendedWindow]];
	
	if(controller == nil)
	{
		//change titles
		[[[viewerController blendedWindow] window] setTitle: [[[[viewerController blendedWindow] window] title] stringByAppendingString:@" :: Moving Image"]];
		[[viewerController window] setTitle: [[[viewerController window] title] stringByAppendingString:@" :: Fixed Image"]];
		NSString* movingCLUTMenu = [[[viewerController blendedWindow] curCLUTMenu] retain];
		ITKNS::MultiThreader::SetGlobalDefaultNumberOfThreads(MPProcessors());
	
		controller = [[PSFSettingsWindowController alloc] initWithFixedImageViewer:viewerController movingImageViewer:[viewerController blendedWindow]];
	
		//activate blending
		[viewerController blendWithViewer:[viewerController blendedWindow] blendingType:1];
		[[viewerController blendingController] ApplyCLUTString:movingCLUTMenu];
		[[viewerController window] performZoom: self];
	
		//Make sure to catch the viewer closing events for both of the viewers
		[[NSNotificationCenter defaultCenter]  addObserver:controller 
										       selector:@selector(viewerWillClose:) name:@"CloseViewerNotification" 
										       object:viewerController];
	
		[[NSNotificationCenter defaultCenter]  addObserver:controller
											   selector:@selector(viewerWillClose:) name:@"CloseViewerNotification" 
										       object:[viewerController blendedWindow]];
	
	}
	else
	{
		[controller showWindow:self];
	}
		
	return 0;

}

+(id) getControllerForFixedViewer:(ViewerController*) fViewer movingViewer:(ViewerController*) mViewer
{
	NSArray *winList = [NSApp windows];
	
	for( id loopItem in winList)
	{
		if( [[[loopItem windowController] windowNibName] isEqualToString:@"PSFSettingsWindow"])
		{
			if( [[loopItem windowController] fixedImageViewer] == fViewer &&
				[[loopItem windowController] movingImageViewer] == mViewer)
			{
				return [loopItem windowController];
			}
		}
	}
	
	return nil;
}




@end

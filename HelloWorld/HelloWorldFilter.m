//
//  HelloWorldFilter.m
//  HelloWorld
//
//  Copyright (c) 2008 Joris Heuberger. All rights reserved.
//

#import "HelloWorldFilter.h"
#import <OsiriX Headers/PreferencesWindowController.h>

@implementation HelloWorldFilter

- (void) initPlugin
{
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"HelloWorldPreferences" inBundle:[NSBundle bundleForClass:[self class]] withTitle:@"Hello World" image:[NSImage imageNamed:@"NSUser"]];
}

- (long) filterImage:(NSString*) menuName
{
	NSString* message = [[NSUserDefaults standardUserDefaults] stringForKey:@"HelloWorld_Message"];
	if (!message) message = @"Define this message in the Hello World plugin's preferences";
	
	NSAlert *myAlert = [NSAlert alertWithMessageText:@"Hello World!"
									   defaultButton:@"Hello"
									 alternateButton:nil
										 otherButton:nil
						   informativeTextWithFormat:@"%@", message];
	
	[myAlert runModal];

	[self loopTroughImages];
	
	return 0; // No Errors
}

// This method demonstrate how to loop through all the images of the current viewer
- (void) loopTroughImages;
{
	// the 'viewerController' variable is defined in PluginFilter.h
	// it is the selected viewer (if more than one is open)
	ViewerController *currentViewer = viewerController;
	
	// loop through time (for dynamic studies)
	for (long frame=0; frame<[currentViewer maxMovieIndex]; frame++)
	{
		NSLog(@"Frame : %d/%d", frame+1, [currentViewer maxMovieIndex]);

		// the pixList contains all DCMPix for the current frame
		NSArray *pixList = [currentViewer pixList:frame];
		for (int i=0; i<[pixList count]; i++)
		{
			DCMPix *pix = [pixList objectAtIndex:i];
			// do something with the DCMPix...
			NSLog(@"Image : %d/%d || Location : %f", i+1, [pixList count], pix.sliceLocation);
		}
	}
}

@end

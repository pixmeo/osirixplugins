/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>

#import "DCMPix.h"				// An object containing an image, including pixels values
#import "ViewerController.h"	// An object representing a 2D Viewer window
#import "DCMView.h"				// An object representing the 2D pane, contained in a 2D Viewer window
#import "MyPoint.h"				// An object representing a point
#import "ROI.h"					// An object representing a ROI

@interface PluginFilter : NSObject
{
	ViewerController*   viewerController;   // Current (frontmost and active) 2D viewer containing an image serie
}

+ (PluginFilter *)filter;

// FUNCTIONS TO SUBCLASS

// This function is called to apply your plugin
- (long) filterImage: (NSString*) menuName;

// This function is called at the OsiriX startup, if you need to do some memory allocation, etc.
- (void) initPlugin;


// UTILITY FUNCTIONS - Defined in the PluginFilter.m file

// Return the complete lists of opened studies in OsiriX
// NSArray contains an array of ViewerController objects
- (NSArray*) viewerControllersList;

// Create a new 2D window, containing a copy of the current series
- (ViewerController*) duplicateCurrent2DViewerWindow;

// PRIVATE FUNCTIONS - DON'T SUBCLASS OR MODIFY

- (long) prepareFilter:(ViewerController*) vC;
@end

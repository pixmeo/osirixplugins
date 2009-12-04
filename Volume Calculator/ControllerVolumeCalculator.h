//
//  Controller.h
//  Volume Calculator
//
//  Created by Antoine Rosset on Mon Aug 02 2008
//  Copyright (c) 2008 OsiriX. All rights reserved.
//

#import <AppKit/AppKit.h>

@class VolumeCalculator;

@interface ControllerVolumeCalculator : NSWindowController
{
	IBOutlet		NSTextField			*diameter1, *diameter2;
	IBOutlet		NSTextField			*volume1, *volume2;
	IBOutlet		NSTextField			*change, *changeTime;
	
	IBOutlet		NSWindow			*fillWindow;
	
	VolumeCalculator *filter;
	ROI *curROI1, *curROI2;
}

- (id) init: (VolumeCalculator*) f ;
- (IBAction) compute:(id) sender;
@end

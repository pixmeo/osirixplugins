//
//  Controller.m
//  Volume Calculator
//
//  Created by Antoine Rosset on Mon Aug 02 2008
//  Copyright (c) 2008 OsiriX. All rights reserved.
//

#include "math.h"

#import "PluginFilter.h"
#import "VolumeCalculator.h"
#import "ViewerController.h"

#import "ControllerVolumeCalculator.h"

NSInteger compareStudy(ViewerController *v1, ViewerController *v2, void *context)
{
	NSDate *d1 = [[v1 currentStudy] valueForKey:@"date"];
	
	NSDate *d2 = [[v2 currentStudy] valueForKey:@"date"];
	
	return [d1 compare: d2];
}

@implementation ControllerVolumeCalculator

-(IBAction) compute:(id) sender
{
	// ( π •d³)/6
	
	if( [diameter1 floatValue] > 0)
	{
		[volume1 setFloatValue: [diameter1 floatValue] * [diameter1 floatValue] * [diameter1 floatValue] * pi / 6.];
	}
	
	if( [diameter2 floatValue] > 0)
	{
		[volume2 setFloatValue: [diameter2 floatValue] * [diameter2 floatValue] * [diameter2 floatValue] * pi / 6.];
	}
	
	if( [diameter1 floatValue] > 0 && [diameter2 floatValue] > 0)
	{
		float val = (100. * [volume2 floatValue] / [volume1 floatValue]) - 100;
		
		if( val > 0)
			[change setStringValue: [NSString stringWithFormat: @"+%2.2f%%", val]];
		else
			[change setStringValue: [NSString stringWithFormat: @"%2.2f%%", val]];
			
		[changeTime setStringValue: [NSString stringWithFormat: @"x%2.2f", [volume2 floatValue] / [volume1 floatValue]]];
	}
}

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(closeViewer:)
               name: @"CloseViewerNotification"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiChange"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"removeROI"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiSelected"
             object: nil];

			 
}

- (id) init:( VolumeCalculator*) f 
{
	self = [super initWithWindowNibName:@"ControllerVolume"];
		
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	filter = f;
	
	NSMutableArray		*roiSeriesList, *roiImageList;

	// TRY TO FIND THE SELECTED ROI OF ALL VIEWERS
	// All rois contained in the current series
	
	NSArray *orderedViewers = [[ViewerController getDisplayed2DViewers] sortedArrayUsingFunction: compareStudy context: 0];
	
	NSLog( @"%@", orderedViewers);
	
	for( ViewerController *v in orderedViewers)
	{
		roiSeriesList = [v roiList];
		
		// All rois contained in the current image
		roiImageList = [roiSeriesList objectAtIndex: [[v imageView] curImage]];
		
		// Find the first selected ROI of current image
		for( ROI *r in roiImageList)
		{
			if( [r type] == tMesure)
			{
				if( [r ROImode] == ROI_selected || [r ROImode] == ROI_selectedModify)
				{
					// We find it! What's his name?
					
					if( curROI1 == 0L)
						curROI1 = [r retain];
						
					else if( curROI2 == 0L)
						curROI2 = [r retain];
						
					break;
				}
			}
		}
	}
	
	// Did we find them? Re-do it without selected parameter
	
	for( ViewerController *v in orderedViewers)
	{
		roiSeriesList = [v roiList];
		
		// All rois contained in the current image
		roiImageList = [roiSeriesList objectAtIndex: [[v imageView] curImage]];
		
		// Find the first selected ROI of current image
		for( ROI *r in roiImageList)
		{
			if( [r type] == tMesure)
			{
				// We find it! What's his name?
				
				if( curROI1 == 0L)
					curROI1 = [r retain];
					
				else if( curROI2 == 0L)
					curROI2 = [r retain];
					
				break;
			}
		}
	}
	
	if( curROI1)
	{
		float lPix, lMm = [curROI1 MesureLength: &lPix];
		
		if( lMm == 0)
			lMm = lPix;
		
		[diameter1 setFloatValue: lMm];
	}
		
	if( curROI2)
	{
		float lPix, lMm = [curROI2 MesureLength: &lPix];
		
		if( lMm == 0)
			lMm = lPix;
		
		[diameter2 setFloatValue: lMm];
	}
	
	[self compute: self];
	
	return self;
}

- (void) roiChange: (NSNotification*) note
{
	if( [[note name] isEqualToString:@"removeROI"])
	{
		if( [note object] == curROI1)
		{
			[curROI1 release];
			curROI1 = 0L;
		}
		
		if( [note object] == curROI2)
		{
			[curROI2 release];
			curROI2 = 0L;
		}
	}
	else
	{
		if( [note object] == curROI1)
		{
			float lPix, lMm = [curROI1 MesureLength: &lPix];
			
			if( lMm == 0)
				lMm = lPix;
		
			[diameter1 setFloatValue: lMm];
		}
			
		if( [note object] == curROI2)
		{
			float lPix, lMm = [curROI2 MesureLength: &lPix];
			
			if( lMm == 0)
				lMm = lPix;
		
			[diameter2 setFloatValue: lMm];
		}
	}
	
	[self compute: self];
}

- (void) closeViewer :(NSNotification*) note
{
	if( [note object] == [filter viewerController])
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		[self release];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[self release];
}

- (void) dealloc
{
	[curROI1 release];
	curROI1 = 0L;
	
	[curROI2 release];
	curROI2 = 0L;

	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

@end

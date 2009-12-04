//
//  CreateROIFilter.m
//  CreateROI
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CreateROIFilter.h"

@implementation CreateROIFilter

- (long) filterImage:(NSString*) menuName
{
	NSMutableArray  *roiSeriesList;
	NSMutableArray  *roiImageList;
	DCMPix			*curPix;
	ROI				*newROI;
	
	// In this plugin, we will produce a new ROI on the current image displayed in the 2D viewer
	
	curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
	
	// All rois contained in the current series
	roiSeriesList = [viewerController roiList];
	
	// All rois contained in the current image
	roiImageList = [roiSeriesList objectAtIndex: [[viewerController imageView] curImage]];
	
	// See DCMView.h for available ROIs, we create here a closed polygon
	newROI = [viewerController newROI: tCPolygon];
	
	// Points of this ROI (it's currently empty)
	NSMutableArray  *points = [newROI points];
	
	[points addObject: [viewerController newPoint: 20 : 20]];   // Values are in pixels! not in mm!
	[points addObject: [viewerController newPoint: 20 : 50]];
	[points addObject: [viewerController newPoint: 50 : 50]];
	[points addObject: [viewerController newPoint: 50 : 0]];
	
	// Select it!
	[newROI setROIMode: ROI_selected];
	
	[roiImageList addObject: newROI];
	
	// Just fo fun! Compute mean, max, min, etc... of the new ROI and display them!
	float rmean, rtotal, rdev, rmin, rmax;
	[curPix computeROI: newROI :&rmean :&rtotal :&rdev :&rmin :&rmax];
	
	// and now... take all pixels of the ROI
	long noOfValues;
	float *theVal = [curPix getROIValue:&noOfValues :newROI  :0L];
	// What would you like to do with pixels contained in this ROI?
	free(theVal);
	
	// and finally erase points inside this ROI!
	[curPix fillROI:newROI :1 :-99999 :99999 :NO];
	
	NSRunInformationalAlertPanel(@"The new ROI", [NSString stringWithFormat:@"Mean:%f, Total:%f", rmean, rtotal], @"OK", 0L, 0L);
	
	// We modified the view: OsiriX please update the display!
	[viewerController needsDisplayUpdate];
	
	return 0;
}

@end

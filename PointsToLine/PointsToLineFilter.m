//
//  PointsToLineFilter.m
//  PointsToLine
//
//  Copyright (c) 2009 OsiriX. All rights reserved.
//

#import "PointsToLineFilter.h"

@implementation PointsToLineFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	// Find the first 2 points
	ROI *pt1 = nil, *pt2 = nil;
	DCMPix *pt1pix = nil, *pt2pix = nil;
	
	// All rois contained in the current series
	NSArray *roiSeriesList = [viewerController roiList];
	
	for( NSArray *roisImageList in roiSeriesList)
	{
		for( ROI *roi in roisImageList)
		{
			if( [roi type] == t2DPoint && [roi.comments isEqualToString: @"generated"] == NO)
			{
				if( pt1 == nil)
				{
					pt1 = roi;
					pt1pix = [[viewerController pixList] objectAtIndex: [roiSeriesList indexOfObject: roisImageList]];
				}
				else if( pt2 == nil)
				{
					pt2 = roi;
					pt2pix = [[viewerController pixList] objectAtIndex: [roiSeriesList indexOfObject: roisImageList]];
				}
			}
		}
	}
	
	[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"ROITEXTIFSELECTED"];
	
	if( pt1 && pt2)
	{
		float pt1_3D[ 3], pt2_3D[ 3];
		
		// Convert 2D position in 3D DICOM world
		[pt1pix convertPixX: pt1.rect.origin.x pixY: pt1.rect.origin.y toDICOMCoords: pt1_3D];
		
		[pt2pix convertPixX: pt2.rect.origin.x pixY: pt2.rect.origin.y toDICOMCoords: pt2_3D];
		
		// Get the direction vector
		float vec[ 3];
		
		vec[ 0] = pt1_3D[ 0] - pt2_3D[ 0];
		vec[ 1] = pt1_3D[ 1] - pt2_3D[ 1];
		vec[ 2] = pt1_3D[ 2] - pt2_3D[ 2];
		
		// Normalize
		double length = sqrt( vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2]);
	
		vec[ 0] = vec[ 0] / length;
		vec[ 1] = vec[ 1] / length;
		vec[ 2] = vec[ 2] / length;
		
		float curPos[ 3] = { pt2_3D[ 0], pt2_3D[ 1], pt2_3D[ 2]};
		
		DCMPix *firstObject = [[viewerController pixList] objectAtIndex: 0];
		
		// Create a new pt for each mm
		do
		{
			curPos[ 0] += vec[ 0];
			curPos[ 1] += vec[ 1];
			curPos[ 2] += vec[ 2];
			
			float sc[ 3];
			
			[firstObject convertDICOMCoords: curPos toSliceCoords: sc pixelCenter: YES];
			
			sc[ 0] /= [firstObject pixelSpacingX];
			sc[ 1] /= [firstObject pixelSpacingY];
			sc[ 2] /= [firstObject sliceInterval];
			
			ROI *newROI = [[[ROI alloc] initWithType: t2DPoint :[firstObject pixelSpacingX] :[firstObject pixelSpacingY] :NSMakePoint( [firstObject originX], [firstObject originY])] autorelease];
			
			NSRect irect;
			
			irect.origin.x = sc[ 0];
			irect.origin.y = sc[ 1];
			irect.size.width = irect.size.height = 0;
			
			[newROI setROIRect:irect];
			[[viewerController imageView] roiSet: newROI];
			
			// copy the name
			[newROI setName: @"generated"];
			
			// add the 2D Point ROI to the ROI list
			[[[viewerController roiList] objectAtIndex: sc[ 2]] addObject: newROI];
			[[viewerController imageView] setNeedsDisplay:YES];
		}
		while( fabs( curPos[ 0] - pt1_3D[ 0]) > 2 || fabs( curPos[ 1] - pt1_3D[ 1]) > 2 || fabs( curPos[ 2] - pt1_3D[ 2]) > 2);
	}
	
	return 0; // No Errors
}

@end

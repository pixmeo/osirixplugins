/*=========================================================================
  Program:   OsiriX

  Copyright (c) Kanteron Systems, Spain
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.kanteron.com

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "ROIRotationFilter.h"

@implementation ROIRotationFilter

- (void) initPlugin
{
	angleValue=0;
}

- (long) filterImage:(NSString*) menuName
{
	[NSBundle loadNibNamed:@"ROIRotation" owner:self];	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	return 0;
}
- (IBAction)endDialog:(id)sender
{
	[window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		float angleRoi;
		angleRoi=[angleField floatValue];
		//NSLog(@"Rotation angle obtained: %f",angleRoi);
		[self rotateRoi:angleRoi];

	// We modified the pixels: OsiriX please update the display!
	//[viewerController needsDisplayUpdate];
	}
}

- (IBAction)setAngleToRoi:(id)sender
{
		float angleRoi;
		angleRoi=[angleCir floatValue];
		angleRoiNew=angleRoi;		
		//NSLog(@"Rotation angle obtained: %f",angleRoi);
		if (angleRoiNew<angleRoiOld) {
			angleRoi=-1;
			angleValue--;
			[angleField2 setFloatValue:angleValue];
		}
		else
		{
			angleRoi=1;
			angleValue++;
			[angleField2 setFloatValue:angleValue];			
		}
		angleRoiOld=angleRoiNew;
		[self rotateRoi:angleRoi];

}
-(void)rotateRoi:(float)rotationAngle
{
		NSMutableArray  *pixList;
		NSMutableArray  *roiSeriesList;
		NSMutableArray  *roiImageList;
		DCMPix			*curPix;
		NSString		*roiName = 0L;
		long			i;		
		// In this plugin, we will take the selected roi of the current 2D viewer
		// and search all rois with same name in other images of the series		
		pixList = [viewerController pixList];		
		curPix = [pixList objectAtIndex: [[viewerController imageView] curImage]];		
		// All rois contained in the current series
		roiSeriesList = [viewerController roiList];		
		// All rois contained in the current image
		roiImageList = [roiSeriesList objectAtIndex: [[viewerController imageView] curImage]];		
		// Find the first selected ROI of current image
		//use previous lines for others purposes
		//in our case we search for selected rois at current image only
		for( i = 0; i < [roiImageList count]; i++)
		{
			if( [[roiImageList objectAtIndex: i] ROImode] == ROI_selected)
			{
				// We find it! What's his name?				
				roiName = [[roiImageList objectAtIndex: i] name];				
				//Let's try so rotate the roi
				NSPoint testPoint;
				//testPoint = NSMakePoint (0, 0);
				ROI *myRoi;
				myRoi=[roiImageList objectAtIndex: i];
				testPoint=[myRoi centroid];				
				[myRoi rotate:rotationAngle :testPoint]; 				
				//NSLog(@"Applied rotation angle: %f degrees. Roi %d centroid at %f,%f",rotationAngle,i,testPoint.x,testPoint.y);
				
			}
		}
		if (i==0)
		{
			NSRunInformationalAlertPanel(@"ROI Rotation", @"You need to create and select a ROI!", @"OK", 0L, 0L);
			return ;
		}
		else
		{
			if( roiName == 0L)
			{
				NSRunInformationalAlertPanel(@"ROI Rotation", @"You need to select a ROI!", @"OK", 0L, 0L);
				return ;
			}
		}
}

@end

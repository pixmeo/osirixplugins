//
//  NormalizeROIFilter.m
//  Normalize
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "NormalizeROIFilter.h"

@implementation NormalizeROIFilter

- (IBAction) setFactor:(id) sender
{
	[normValue setFloatValue: [meanValue floatValue] * [factorValue floatValue]];
}

- (IBAction) setNormalize:(id) sender
{
	[factorValue setFloatValue: [normValue floatValue] / [meanValue floatValue]];
}

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		long		i, y, x;
		NSArray		*pixList = [viewerController pixList];
		float		*fImage, factor = [factorValue floatValue];
		DCMPix		*curPix;
		
		// Display a waiting window
		id waitWindow = [viewerController startWaitWindow:@"I'm working for you!"];
		
		// Loop through all images contained in the current series
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [pixList objectAtIndex: i];
			
			if( i == [[viewerController imageView] curImage])
			{
				NSLog(@"Cool, this is the image (%d) currently displayed!", i);
			}
			
			// fImage is a pointer on the pixels, ALWAYS represented in float (float*) or in ARGB (unsigned char*) 
			
			if( [curPix isRGB])
			{
				
			}
			else
			{
				fImage = [curPix fImage];
				
				for( y = 0; y < [curPix pheight]; y++)
				{
					for( x = 0; x < [curPix pwidth]; x++)
					{
						fImage[ [curPix pwidth] * y + x] *= factor;
					}
				}
			}
		}
		
		// Close the waiting window
		[viewerController endWaitWindow: waitWindow];
		
		[[viewerController imageView] setWLWW:0 :0];
		
		// We modified the view: OsiriX please update the display!
		[viewerController needsDisplayUpdate];
    }
}

- (long) filterImage:(NSString*) menuName
{
	NSMutableArray  *roiSeriesList;
	NSMutableArray  *roiImageList;
	DCMPix			*curPix;
	ROI				*curROI = 0L;
	long			i;
	
	[NSBundle loadNibNamed:@"DialogNormalize" owner:self];
	
	curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];

	// All rois contained in the current series
	roiSeriesList = [viewerController roiList];
	
	// All rois contained in the current image
	roiImageList = [roiSeriesList objectAtIndex: [[viewerController imageView] curImage]];

	// Find the first selected ROI of current image
	for( i = 0; i < [roiImageList count]; i++)
	{
		if( [[roiImageList objectAtIndex: i] ROImode] == ROI_selected)
		{
			// We find it! What's his name?
			
			curROI = [roiImageList objectAtIndex: i];
			
			i = [roiImageList count];   //Break the loop
		}
	}
	
	if( curROI)
	{
		float rmean, rtotal, rdev, rmin, rmax;
		[curPix computeROI: curROI :&rmean :&rtotal :&rdev :&rmin :&rmax];
		
		[meanValue setFloatValue: rmean];
		
		[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	}
	else
	{
		NSRunAlertPanel(@"Error", @"Select a ROI first!", nil, nil, nil);
	}

	return 0;
}

@end

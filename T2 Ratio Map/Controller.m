//
//  Controller.m
//  Mapping
//
//  Created by Antoine Rosset on Mon Aug 02 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#include "math.h"

#import "PluginFilter.h"
#import "Mapping.h"

#import "Controller.h"


@implementation Controller

-(IBAction) compute:(id) sender
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray				*pixListA;
	NSArray				*pixListB;
	NSArray				*pixListC;
	DCMPix				*curPix;
	long				i, x, y;
	unsigned char		*rgbImage;
	float				*dstImage, *pixels1, *pixels2, kValue;
	float				v1, v2;
	NSMutableArray		*roiSeriesList;
	NSMutableArray		*roiImageList;
	NSString			*roiName = 0L;
	float				*rmean, *rmin, *rmax, dr2s, factor, threshold, thresholdSet, minValue;
	ViewerController	*new2DViewer;
	ROI					*curROI;
	
	pixListA = [[filter viewerController] pixList];
	pixListB = [blendedWindow pixList];

	if( [pixListA count] != [pixListB count])
	{
		NSRunAlertPanel(@"Error", @"Series must to have the same number of images.", nil, nil, nil);
		return;
	}
	
	if( [[mode selectedCell] tag] == 1)
	{
		//FIND THE SELECTED ROI
		
		// All rois contained in the current series
		roiSeriesList = [[filter viewerController] roiList];
		
		// All rois contained in the current image
		roiImageList = [roiSeriesList objectAtIndex: [[[filter viewerController] imageView] curImage]];
		
		// Find the first selected ROI of current image
		for( i = 0; i < [roiImageList count]; i++)
		{
			if( [[roiImageList objectAtIndex: i] ROImode] == ROI_selected)
			{
				// We find it! What's his name?
				
				roiName = [[roiImageList objectAtIndex: i] name];
				
				i = [roiImageList count];   //Break the loop
			}
		}
		
		if( roiName == 0L)
		{
			NSLog(@"No ROI found");
			NSRunAlertPanel(@"Error", @"No ROI selected.", nil, nil, nil);
			return;
		}
	}
	else roiName = 0L;

	new2DViewer = [filter duplicateCurrent2DViewerWindow];
	pixListC = [new2DViewer pixList];

	[new2DViewer roiDeleteAll: self];
/*
	rmean = (float*) malloc( sizeof(float) * [pixList count]);
	rmin = (float*) malloc( sizeof(float) * [pixList count]);
	rmax = (float*) malloc( sizeof(float) * [pixList count]);
	
	// Find the first selected ROI of current image
	for( i = 0; i < [roiSeriesList count]; i++)
	{
		roiImageList = [roiSeriesList objectAtIndex: i];
		
		rmin[ x] = 0;
		rmax[ x] = 0;
		rmean[ x] = 0;
		
		if( [[[roiImageList objectAtIndex: i] name] isEqualToString: roiName])
		{
			// Compute the min, max, mean values
			curPix = [pixList objectAtIndex: x];
			
			[curPix computeROI: [roiImageList objectAtIndex: i] :&rmean[ x] :0L :0L : &rmin[ x] :&rmax[ x]];
		}
	}
	
	[resultView setArrays: [pixList count] :rmean :rmin :rmax];*/
		
	kValue = [K floatValue];
	factor = [factorText floatValue];
	threshold = [thresholdText floatValue];
//	thresholdSet = [thresholdSetText floatValue];
	thresholdSet = 0;
	minValue = 99999;
	
	NSLog(@"Threshold:%0.0f", threshold);
	
	// Loop through all images contained in the current series
	for( i = 0; i < [pixListA count]; i++)
	{
		pixels1 = [[pixListA objectAtIndex: i] fImage];
		pixels2 = [[pixListB objectAtIndex: i] fImage];
		dstImage = [[pixListC objectAtIndex: i] fImage];
		
		curPix = [pixListA objectAtIndex: i];
				
		// fImage is a pointer on the pixels, ALWAYS represented in float (float*) or in ARGB (unsigned char*) 
		if( [curPix isRGB])
		{
//			rgbImage = (unsigned char*) [curPix fImage];
//			
//			for( y = 0; y < [curPix pheight]; y++)
//			{
//				for( x = 0; x < [curPix pwidth]; x++)
//				{
//					rgbImage[ [curPix pwidth] * y * 4 + x*4 + 1] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 1];
//					rgbImage[ [curPix pwidth] * y * 4 + x*4 + 2] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 2];
//					rgbImage[ [curPix pwidth] * y * 4 + x*4 + 3] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 3];
//				}
//			}
		}
		else
		{
			for( x = 0; x < [curPix pwidth]; x++)
			{
				for( y = 0; y < [curPix pheight]; y++)
				{
					v1 = pixels1[ x + y*[curPix pwidth]];
					v2 = pixels2[ x + y*[curPix pwidth]];
					
					// dr2s = -(1.0/te)*(ALOG(postim > 1.0) - ALOG(preim > 1.0))
					//  dr2s = dr2s*(preim GE threshold)
					
					if( v1 > threshold && v1 > 1.0 && v2 > 1.0) dr2s = -(1.0/kValue)*(log(v2) - log(v1));
					else dr2s = thresholdSet;
					
					dr2s *= factor;
					
					if( minValue > dr2s) minValue = dr2s;
					dstImage[ x + y*[curPix pwidth]] = dr2s;
				}
			}
		}
	}

	if( roiName)
	{
		for( i = 0; i < [pixListA count]; i++)
		{
			curROI = 0L;
			roiImageList = [roiSeriesList objectAtIndex: i];
			curPix = [pixListC objectAtIndex: i];
			
			for( x = 0 ; x < [roiImageList count]; x++)
			{
				if( [[[roiImageList objectAtIndex: x] name] isEqualToString: roiName])
				{
					curROI = [roiImageList objectAtIndex: x];
				}
			}
			
			if( curROI)
			{
				// DELETE ALL PIXELS THAT ARE OUTSIDE THE ROI
				
				[curPix fillROI: curROI :minValue :-999999 :99999 :YES];
			}
			else
			{
				dstImage = [curPix fImage];
				// DELETE ALL PIXELS
				for( x = 0; x < [curPix pwidth]; x++)
				{
					for( y = 0; y < [curPix pheight]; y++)
					{
						dstImage[ x + y*[curPix pwidth]] = minValue;
					}
				}
			}
		}
	}
	
	
	// We modified the pixels: OsiriX please update the display!
	[new2DViewer needsDisplayUpdate];
	[[new2DViewer imageView] setWLWW:0 :0];
	
	[self close];
}

- (void)awakeFromNib
{
	NSLog( @"Nib loaded!");
}

- (id) init:(MappingFilter*) f 
{
	self = [super initWithWindowNibName:@"Controller"];
		
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	filter = f;
	blendedWindow = [[filter viewerController] blendedWindow];
	
	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"Window will close.... and release his memory...");
	
	[self release];
}

- (void) dealloc
{
    NSLog(@"My window is deallocating a pointer");
	
	[super dealloc];
}

- (IBAction) fetch:(id) sender
{

}

@end

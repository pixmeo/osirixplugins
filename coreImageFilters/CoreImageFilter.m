//
//  CoreImageFilter.m
//  Invert
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "CoreImageFilter.h"
#import <QuartzCore/QuartzCore.h>

@implementation CoreImageFilter

- (long) filterImage:(NSString*) menuName
{
	long			i, x, y;
	float			*fImage;
	unsigned char   *rgbImage;
	
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray		*pixList = [viewerController pixList];		
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
			rgbImage = (unsigned char*) [curPix fImage];
			
			x = [curPix pheight] * [curPix pwidth] / 4;
			
			while ( x-- > 0)
			{
				rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				
				rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				
				rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				
				rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
				*rgbImage = 255-*rgbImage;		rgbImage++;
			}
		}
		else
		{
			
			fImage = [curPix fImage];
			
			x = [curPix pheight] * [curPix pwidth]/4;
			
			while ( x-- > 0)
			{
				*fImage = -*fImage;
				fImage++;
				*fImage = -*fImage;
				fImage++;
				*fImage = -*fImage;
				fImage++;
				*fImage = -*fImage;
				fImage++;
			}
		}
	}
	
	// Close the waiting window
	[viewerController endWaitWindow: waitWindow];
	
	// Update the current displayed WL & WW : we just inverted the image -> invert the WL !
	long wl, ww;
	
	[[viewerController imageView] getWLWW: &wl :&ww];
	if( [curPix isRGB]) wl = 255-wl;
	else wl = -wl;
	[[viewerController imageView] setWLWW: wl :ww];
	
	// We modified the pixels: OsiriX please update the display!
	[viewerController needsDisplayUpdate];
	
	return 0;   // No Errors
}

@end

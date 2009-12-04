//
//  InvertFilter.m
//  Invert
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "InvertFilter.h"

#import "ThanksController.h"

@implementation InvertFilter

- (void) initPlugin
{
	NSLog(@"initPlugin - InvertFilter");
}

- (long) filterImage:(NSString*) menuName
{
	long			i, x, y;
	float			*fImage;
	unsigned char   *rgbImage;
	
	if( [menuName isEqualToString:@"Do Nothing"])
	{
		NSRunAlertPanel(@"???", @"Why are you trying to execute a 'Do Nothing' plugin??", nil, nil, nil);
		return 0;
	}
	
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray		*pixList = [viewerController pixList];		
	DCMPix		*curPix;
	
	// Ask a question to the user!
	if( NSRunInformationalAlertPanel(@"Hello World!", @"Are you ready to apply this computer intensive filter?", @"OK", @"Cancel", nil)  == NSAlertDefaultReturn)
	{
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
				
				for( y = 0; y < [curPix pheight]; y++)
				{
					for( x = 0; x < [curPix pwidth]; x++)
					{
						rgbImage[ [curPix pwidth] * y * 4 + x*4 + 1] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 1];
						rgbImage[ [curPix pwidth] * y * 4 + x*4 + 2] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 2];
						rgbImage[ [curPix pwidth] * y * 4 + x*4 + 3] = 255-rgbImage[ [curPix pwidth] * y * 4 + x*4 + 3];
					}
				}
			}
			else
			{
				fImage = [curPix fImage];
				
				for( y = 0; y < [curPix pheight]; y++)
				{
					for( x = 0; x < [curPix pwidth]; x++)
					{
						fImage[ [curPix pwidth] * y + x] = -fImage[ [curPix pwidth] * y + x];
					}
				}
			}
		}
		
		// Close the waiting window
		[viewerController endWaitWindow: waitWindow];
		
		// Update the current displayed WL & WW : we just inverted the image -> invert the WL !
		float wl, ww;
		
		[[viewerController imageView] getWLWW: &wl :&ww];
		if( [curPix isRGB]) wl = 255-wl;
		else wl = -wl;
		[[viewerController imageView] setWLWW: wl :ww];
		
		// We modified the pixels: OsiriX please update the display!
		[viewerController needsDisplayUpdate];
		
		// Display a nice window to thanks the user for using our powerful filter!
		ThanksController* thanksWin = [[ThanksController alloc] init];
		[thanksWin showWindow:self];
	}
	
	return 0;   // No Errors
}

@end

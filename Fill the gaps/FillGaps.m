//
//  InvertFilter.m
//  Invert
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "FillGaps.h"

@implementation FillGaps

- (long) filterImage:(NSString*) menuName
{
	long				i, x, z, newTotal;
	float				interval;
	unsigned char		*emptyData;
	ViewerController	*new2DViewer;
	
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray		*pixList = [viewerController pixList];	
	DCMPix		*firstPix = [pixList objectAtIndex: 0];
	
	[viewerController computeInterval];
	
	interval = fabs( [firstPix sliceInterval]);
	
	if( interval <= 0) return 0;
	
	newTotal = [pixList count];
	// Is there really a gap in this series?
	for( i = 0 ; i < [pixList count]-1; i++)
	{
		float gap;
		
		gap = fabs( fabs([[pixList objectAtIndex: i+1] sliceLocation]) - fabs( [[pixList objectAtIndex: i] sliceLocation]));
		
		if( gap - interval >= interval)
		{
			long val;
			
			NSLog( @"There is a hole here... missing slices: %2.2f", gap / interval);
			
			val = gap / interval;
			val --;
			newTotal += val;
		}
	}
	
	if( newTotal == [pixList count]) return 0;
	
	// Display a waiting window
	id waitWindow = [viewerController startWaitWindow:@"I'm working for you! FOR FREE !"];
	
	// CREATE A NEW SERIES WITH ALL IMGES !
	
	long imageSize = sizeof(float) * [firstPix pwidth] * [firstPix pheight];
	long size = newTotal * imageSize;
	
	emptyData = malloc( size);
	if( emptyData)
	{
		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
		NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
		
		NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
		
		for( i = 0 ; i < [pixList count]; i++)
		{
			float gap;
			
			if( i != [pixList count] -1)
				gap = fabs( fabs([[pixList objectAtIndex: i+1] sliceLocation]) - fabs( [[pixList objectAtIndex: i] sliceLocation]));
			else gap = 0;
			
			if( gap - interval >= interval)
			{
				long slices = gap / interval;
				
				for( x = 0; x < slices; x++)
				{
					DCMPix	*cc = [[[pixList objectAtIndex: i] copy] autorelease];
					[newPixList addObject: cc];
					[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
					[[newPixList lastObject] setTot: newTotal];
					[[newPixList lastObject] setFrameNo: [newPixList count]-1];
					[[newPixList lastObject] setSliceLocation: [[newPixList lastObject] sliceLocation] + x * [firstPix sliceInterval]];
					[newDcmList addObject: [[viewerController fileList] objectAtIndex: i] ];
					
					if( x != 0)
					{
						for( z = 0; z < imageSize/4; z++)
						{
							[[newPixList lastObject] fImage] [ z] = -1000.f;
						}
					}
					else
					{
						memcpy( [[newPixList lastObject] fImage], [[pixList objectAtIndex: i] fImage], imageSize);
					}
				}
			}
			else
			{
				DCMPix	*cc = [[[pixList objectAtIndex: i] copy] autorelease];
				[newPixList addObject: cc];
				[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
				memcpy( [[newPixList lastObject] fImage], [[pixList objectAtIndex: i] fImage], imageSize);
				[[newPixList lastObject] setTot: newTotal];
				[[newPixList lastObject] setFrameNo: [newPixList count]-1];
				[newDcmList addObject: [[viewerController fileList] objectAtIndex: i] ];
			}
		}
		
		if( [newPixList count] != newTotal)
		{
			NSLog(@"?? %d - %d", [newPixList count], newTotal);
		}
		// CREATE A SERIES
		new2DViewer = [viewerController newWindow				:newPixList
																:newDcmList
																:newData];
	}
	
	// Close the waiting window
	[viewerController endWaitWindow: waitWindow];
		
	// We modified the pixels: OsiriX please update the display!
	[viewerController needsDisplayUpdate];
	
	return 0;   // No Errors
}

@end

//
//  CardiacTaggingMRI.m
//  Resample Data
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Rosset Antoine. All rights reserved.
//

#import "CardiacTaggingMRIFilter.h"
#include <Accelerate/Accelerate.h>

@implementation CardiacTaggingMRIFilter

- (long) filterImage:(NSString*) menuName
{
		DCMPix			*curPix;
	
		curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];

		long				i, y, x, z, imageSize, size;
		NSArray				*pixList = [viewerController pixList];
		float				*srcImage, *srcImage2, *dstImage, *emptyData;
		ViewerController	*new2DViewer;
		long				maxVal[ 1024];
		
		imageSize = [curPix pwidth] * [curPix pheight];
		size = sizeof(float) * [pixList count]/2 * imageSize;
		
		// CREATE A NEW SERIES TO CONTAIN THIS NEW RE-SAMPLED SERIES
		emptyData = malloc( size);
		if( emptyData)
		{
			NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
			NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
			NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
			
			for( z = 0 ; z < [pixList count] /2; z ++)
			{
				curPix = [pixList objectAtIndex: z];
				
				[newPixList addObject: [curPix copy]];
				[newDcmList addObject: [[viewerController fileList] objectAtIndex: z]];
				
				curPix = [pixList objectAtIndex: z];
				srcImage2 = [[pixList objectAtIndex: z + [pixList count] /2]  fImage];
				srcImage = [[pixList objectAtIndex: z]  fImage];
				
				dstImage = emptyData + imageSize * z;
				
				float curMax = 0;
				i = [curPix pwidth] * [curPix pheight];
				while( i-- > 0)
				{
					*dstImage = *srcImage2++ * *srcImage++ / [curPix fullww];
					
					if( curMax < *dstImage) curMax = *dstImage;
					
					dstImage++;
				}
				
				maxVal[ z] = curMax;
				
				[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * z)];
				[[newPixList lastObject] setTot: [pixList count] /2];
				[[newPixList lastObject] setFrameNo: z];
				[[newPixList lastObject] setID: z];
			}
			
			float maxSeries = 0;
			
			// Normalize
			for( z = 0 ; z < [pixList count] /2; z ++)
			{
				if( maxSeries < maxVal[ z]) maxSeries = maxVal[ z];
			}
			
			for( z = 0 ; z < [pixList count] /2; z ++)
			{
				float factor = maxSeries / maxVal[ z];
				
				dstImage = emptyData + imageSize * z;
				i = [curPix pwidth] * [curPix pheight];
				while( i-- > 0)
				{
					*dstImage++ *= factor;
				}
			}
			
			// CREATE A SERIES
			new2DViewer = [viewerController newWindow	:newPixList
														:newDcmList
														:newData];
		}
		
		// We modified the view: OsiriX please update the display!
		[viewerController needsDisplayUpdate];

	return 0;
}

@end

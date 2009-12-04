//
//  ResampleDataFilter.m
//  Resample Data
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Rosset Antoine. All rights reserved.
//

#import "ResampleDataFilter.h"
#include <Accelerate/Accelerate.h>

@implementation ResampleDataFilter

- (id)init
{
	NSLog( @"ResampleDataFilter Init");
	
	return [super init];
}

- (void) dealloc
{
	NSLog( @"ResampleDataFilter Dealloc");
	
	[super dealloc];
}


- (IBAction) setXYZSlider:(id) sender;
{
	switch( [sender tag])
	{
		case 0:
		{
			int xValue = [sender intValue] * originWidth / 100.;
			[XText setIntValue:  xValue];
			[self setXYZValue: XText];
		}
		break;
		
		case 1:
		{
			int yValue = [sender intValue] * originHeight / 100.;
			[YText setIntValue:  yValue];
			[self setXYZValue: YText];
		}
		break;
		
		case 2:
		{
			int zValue = [sender intValue] * originZ / 100.;
			[ZText setIntValue:  zValue];
			[self setXYZValue: ZText];
		}
		break;
	}
}

- (IBAction) setXYZValue:(id) sender
{
	DCMPix	*curPix = [[viewerController pixList] objectAtIndex: 0];
	
	if( [ForceRatioCheck state] == NSOnState)
	{
		switch( [sender tag])
		{
			case 0:
				[YText setIntValue:  originRatio * ([sender intValue]  * originHeight) / (originWidth)];
			break;
			
			case 1:
				[XText setIntValue: ([sender intValue]  * originWidth) / (originHeight * originRatio)];
			break;
			
			case 2:
			break;
		}
		
		[RatioText setFloatValue:1.0];
	}
	else
	{
		[RatioText setFloatValue: originRatio * ([XText floatValue] / (float) originWidth) / ([YText floatValue] / (float) originHeight) ];
	}
	
	float mem = ([XText intValue] * [YText intValue] * [ZText intValue] * 4.) / (1024. * 1024.);
	float oldmem = (originHeight * originWidth * originZ *  4.) / (1024. * 1024.);
	
	[MemoryText setStringValue: [NSString stringWithFormat:@"%.2f Mb / %d%%", mem, (long) (100 * mem / oldmem)]];
	[thicknessText setStringValue: [NSString stringWithFormat: @"Original: %.2f mm / Resampled: %.2f mm", [curPix sliceThickness], [curPix sliceThickness] * (float) originZ / (float) [ZText intValue]]];
	
	[xSlider setFloatValue: 100. * [XText floatValue] / (float) originWidth];
	[ySlider setFloatValue: 100. * [YText floatValue] / (float) originHeight];
	[zSlider setFloatValue: 100. * [ZText floatValue] / (float) originZ];
}

- (IBAction) setForceRatio:(id) sender
{
	if( [sender state] == NSOnState)
	{
		[self setXYZValue: XText];
	}
}

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
	{
		id waitWindow = [viewerController startWaitWindow:@"Resampling data..."];
		
		// resampling
		float xFactor = (float) originWidth / [XText floatValue];
		float yFactor = (float) originHeight / [YText floatValue];
		float zFactor = (float) originZ / [ZText floatValue];
		BOOL isResampled = [viewerController resampleDataWithXFactor:xFactor yFactor:yFactor zFactor:zFactor];

		[viewerController endWaitWindow: waitWindow];
		if(!isResampled)
		{
			NSRunAlertPanel(NSLocalizedString(@"Not enough memory", nil), NSLocalizedString(@"Your computer doesn't have enough RAM to complete the resampling - Upgrade to OsiriX 64-bit to solve this problem.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		}
	}
    //{
//		long				i, y, z, imageSize, newX, newY, newZ, size;
//		NSArray				*pixList = [viewerController pixList];
//		float				*srcImage, *dstImage, *emptyData;
//		DCMPix				*curPix;
//		ViewerController	*new2DViewer;
//		
//		// Display a waiting window
//		id waitWindow = [viewerController startWaitWindow:@"I'm working for you!"];
//		
//		newX = [XText intValue];
//		newY = [YText intValue];
//		newZ = [ZText intValue];
//		
//		imageSize = newX * newY;
//		size = sizeof(float) * originZ * imageSize;
//		
//		// CREATE A NEW SERIES TO CONTAIN THIS NEW RE-SAMPLED SERIES
//		emptyData = malloc( size);
//		if( emptyData)
//		{
//			float vectors[ 9], vectorsB[ 9], interval = 0, origin[ 3], newOrigin[ 3];
//			BOOL equalVector = YES;
//			int o;
//			
//			[[pixList objectAtIndex:0] orientation: vectors];
//			[[pixList objectAtIndex:1] orientation: vectorsB];
//			
//			origin[ 0] = [[pixList objectAtIndex:0] originX]; 
//			origin[ 1] = [[pixList objectAtIndex:1] originY]; 
//			origin[ 2] = [[pixList objectAtIndex:2] originZ]; 
//		
//			for( i = 0; i < 9; i++)
//			{
//				if( vectors[ i] != vectorsB[ i]) equalVector = NO;
//			}
//		
//			if( equalVector)
//			{
//				if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
//				{
//					interval = [[pixList objectAtIndex:0] originX] - [[pixList objectAtIndex:1] originX];
//				
//					if( vectors[6] > 0) interval = -( interval);
//					else interval = ( interval);
//					o = 0;
//				}
//				
//				if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
//				{
//					interval = [[pixList objectAtIndex:0] originY] - [[pixList objectAtIndex:1] originY];
//					
//					if( vectors[7] > 0) interval = -( interval);
//					else interval = ( interval);
//					o = 1;
//				}
//				
//				if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
//				{
//					interval = [[pixList objectAtIndex:0] originZ] - [[pixList objectAtIndex:1] originZ];
//					
//					if( vectors[8] > 0) interval = -( interval);
//					else interval = ( interval);
//					o = 2;
//				}
//			}
//			
//			interval *= (float) originZ / (float) newZ;
//			
//			NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
//			NSMutableArray	*finalnewPixList = [NSMutableArray arrayWithCapacity: 0];
//			NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
//			NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
//			
//			float pos1 = [[pixList objectAtIndex: 0] sliceLocation];
//			float pos2 = [[pixList objectAtIndex: 1] sliceLocation];
//			float intervalSlice = pos2 - pos1;
//			
//			intervalSlice *= (float) originZ / (float) newZ;
//			
//			for( z = 0 ; z < newZ; z ++)
//			{
//				curPix = [pixList objectAtIndex: (z * originZ) / newZ];
//				
//				DCMPix	*copyPix = [curPix copy];
//				
//				[newPixList addObject: copyPix];
//				[copyPix release];
//				
//				[[newPixList lastObject] setPwidth: newX];
//				[[newPixList lastObject] setPheight: newY];
//				
//				[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * z)];
//				[[newPixList lastObject] setTot: newZ];
//				[[newPixList lastObject] setFrameNo: z];
//				[[newPixList lastObject] setID: z];
//				
//				[[newPixList lastObject] setPixelSpacingX: ([curPix pixelSpacingX] * (float) originWidth) / (float) newX];
//				[[newPixList lastObject] setPixelSpacingY: ([curPix pixelSpacingY] * (float) originHeight) / (float) newY];
//				[[newPixList lastObject] setSliceThickness: [copyPix sliceThickness] * (float) originZ / (float) newZ];
//				[[newPixList lastObject] setPixelRatio:  originRatio * ((float) newX / (float) originWidth) / ((float) newY / (float) originHeight)];
//				
//				newOrigin[ 0] = origin[ 0];	newOrigin[ 1] = origin[ 1];	newOrigin[ 2] = origin[ 2];
//				switch( o)
//				{
//					case 0:
//						newOrigin[ 0] = origin[ 0] + (float) z * interval; 
//					break;
//					
//					case 1:
//						newOrigin[ 1] = origin[ 1] + (float) z * interval;
//					break;
//					
//					case 2:
//						newOrigin[ 2] = origin[ 2] + (float) z * interval;
//					break;
//				}
//				[[newPixList lastObject] setOrigin: newOrigin];
//				[[newPixList lastObject] setSliceLocation: pos1 + intervalSlice * (float) z];
//				[[newPixList lastObject] setSliceInterval: intervalSlice * (float) z];
//			}
//		
//			for( z = 0; z < originZ; z++)
//			{
//				vImage_Buffer	srcVimage, dstVimage;
//				
//				curPix = [pixList objectAtIndex: z];
//				
//				srcImage = [curPix  fImage];
//				dstImage = emptyData + imageSize * z;
//				
//				srcVimage.data = srcImage;
//				srcVimage.height =  originHeight;
//				srcVimage.width = originWidth;
//				srcVimage.rowBytes = originWidth*4;
//				
//				dstVimage.data = dstImage;
//				dstVimage.height =  newY;
//				dstVimage.width = newX;
//				dstVimage.rowBytes = newX*4;
//				
//				if( [curPix isRGB])
//					vImageScale_ARGB8888( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
//				else
//					vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
//			}
//			
//			// Z RESAMPLING
//			
//			if( originZ != newZ)
//			{
//				curPix = [newPixList objectAtIndex: 0];
//				
//				for( y = 0; y < newY; y++)
//				{
//					vImage_Buffer	srcVimage, dstVimage;
//					
//					srcImage = [curPix  fImage] + y * newX;
//					dstImage = emptyData + y * newX;
//					
//					srcVimage.data = srcImage;
//					srcVimage.height =  originZ;
//					srcVimage.width = newX;
//					srcVimage.rowBytes = newY*newX*4;
//					
//					dstVimage.data = dstImage;
//					dstVimage.height =  newZ;
//					dstVimage.width = newX;
//					dstVimage.rowBytes = newY*newX*4;
//					
//					if( [curPix isRGB])
//						vImageScale_ARGB8888( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
//					else
//						vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, kvImageHighQualityResampling);
//				}
//			}
//			
//			for( z = 0 ; z < newZ; z ++)
//			{
//				[newDcmList addObject: [[viewerController fileList] objectAtIndex: (z * originZ) / newZ]];
//				[finalnewPixList addObject: [newPixList objectAtIndex: z]];
//			}
//			
//			// CREATE A SERIES
//			new2DViewer = [viewerController newWindow	:finalnewPixList
//														:newDcmList
//														:newData];
//		}
//		// Close the waiting window
//		[viewerController endWaitWindow: waitWindow];
//		
//		// We modified the view: OsiriX please update the display!
//		[viewerController needsDisplayUpdate];
//    }
}

- (long) filterImage:(NSString*) menuName
{
	DCMPix			*curPix;
	
	[NSBundle loadNibNamed:@"DialogResampleData" owner:self];
	
	curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
	
	originRatio = [curPix pixelRatio];
	originWidth = [curPix pwidth];
	originHeight = [curPix pheight];
	originZ = [[viewerController pixList] count];
	
	if( originRatio == 1.0) [ForceRatioCheck setState: NSOnState];
	else [ForceRatioCheck setState: NSOffState];
	
	[RatioText setFloatValue: originRatio];
	[XText setIntValue: originWidth];
	[YText setIntValue: originHeight];
	[ZText setIntValue: originZ];
	
	[oXText setIntValue: originWidth];
	[oYText setIntValue: originHeight];
	[oZText setIntValue: originZ];
	
	if( [curPix sliceInterval] == 0)
	{
		[oZText setEnabled: NSOffState];
		[ZText setEnabled: NSOffState];
		[zSlider setEnabled: NSOffState];
	}
	
	[self setXYZValue: XText];
	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	return 0;
}

@end

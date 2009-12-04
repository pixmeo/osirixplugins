//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "DCMPix.h"
#import "OrthogonalReslice.h"
#include <Accelerate/Accelerate.h>

@implementation OrthogonalReslicePlugin

-(void) executeReslice:(long) directionm :(BOOL) square :(BOOL) newViewer
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
		NSArray				*pixList = [viewerController pixList];	
		DCMPix				*firstPix = [pixList objectAtIndex: 0];
		DCMPix				*lastPix = [pixList lastObject];
		long				i, newTotal;
		unsigned char		*emptyData;
		ViewerController	*new2DViewer;
		long				imageSize, size, x, y, newX, newY;
		float				orientation[ 9], newXSpace, newYSpace, origin[ 3], sign, ratio;
		
		NSLog(@"Start-Reslice");
		
		// Get Values
		if( directionm == 0)		// X - RESLICE
		{
			newTotal = [firstPix pheight];
			
			newX = [firstPix pwidth];
			
//			if( fabs( [firstPix sliceInterval]) < [firstPix pixelSpacingX])
//				square = NO;
			
			if( square)
			{
				newXSpace = [firstPix pixelSpacingX];
				newYSpace = [firstPix pixelSpacingX];
				
				ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingX];
				
				newY = ([pixList count] * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingX];
			}
			else
			{
				newXSpace = [firstPix pixelSpacingX];
				newYSpace = fabs( [firstPix sliceInterval]);
				newY = [pixList count];
			}
		}
		else
		{
			newTotal = [firstPix pwidth];				// Y - RESLICE
			
			newX = [firstPix pheight];
			
//			if( fabs( [firstPix sliceInterval]) < [firstPix pixelSpacingY])
//				square = NO;
			
			if( square)
			{
				newXSpace = [firstPix pixelSpacingY];
				newYSpace = [firstPix pixelSpacingY];
				
				ratio = fabs( [firstPix sliceInterval]) / [firstPix pixelSpacingY];
				
				newY = ([pixList count]  * fabs( [firstPix sliceInterval])) / [firstPix pixelSpacingY];
			}
			else
			{
				newY = [pixList count];
				
				newXSpace = [firstPix pixelSpacingY];
				newYSpace = fabs( [firstPix sliceInterval]);
			}
		}
		
		// Display a waiting window
		id waitWindow = [viewerController startWaitProgressWindow:@"I'm working for you!" :newTotal];
		
		if( [firstPix sliceInterval] > 0) sign = 1.0;
		else sign = -1.0;
		
		imageSize = sizeof(float) * newX * newY;
		size = newTotal * imageSize        + sizeof(float) * newX * [pixList count]; // to avoid the problem if sliceinterval is smaller than pixel spacing
		
		// CREATE A NEW SERIES WITH ALL IMAGES !
		emptyData = malloc( size);
		if( emptyData)
		{
			NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
			NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
			
			NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
			
			for( i = 0 ; i < newTotal; i ++)
			{
				[viewerController waitIncrementBy: waitWindow :1];
				
				[newPixList addObject: [[[pixList objectAtIndex: 0] copy] autorelease]];
				
				DCMPix	*curPix = [newPixList lastObject];
				
				[curPix setPwidth: newX];
				[curPix setPheight: newY];

				// SUV
				[curPix setDisplaySUVValue: [firstPix displaySUVValue]];
				[curPix setSUVConverted: [firstPix SUVConverted]];
				[curPix setRadiopharmaceuticalStartTime: [firstPix radiopharmaceuticalStartTime]];
				[curPix setPatientsWeight: [firstPix patientsWeight]];
				[curPix setRadionuclideTotalDose: [firstPix radionuclideTotalDose]];
				[curPix setRadionuclideTotalDoseCorrected: [firstPix radionuclideTotalDoseCorrected]];
				[curPix setAcquisitionTime: [firstPix acquisitionTime]];
				[curPix setDecayCorrection: [firstPix decayCorrection]];
				[curPix setDecayFactor: [firstPix decayFactor]];
				[curPix setUnits: [firstPix units]];
				
				[curPix setfImage: (float*) (emptyData + imageSize * ([newPixList count] - 1))];
				[curPix setTot: newTotal];
				[curPix setFrameNo: [newPixList count]-1];
				[curPix setID: [newPixList count]-1];
				
				[newDcmList addObject: [[viewerController fileList] objectAtIndex: 0] ];
				
				if( directionm == 0)		// X - RESLICE
				{
					if( sign > 0)
					{
						for( y = 0; y < [pixList count]; y++)
						{
							memcpy(			[curPix fImage] + ([pixList count]-y-1) * newX,
											[[pixList objectAtIndex: y] fImage] + i * [[pixList objectAtIndex: y] pwidth],
											newX * sizeof( float));
						}
					}
					else
					{
						for( y = 0; y < [pixList count]; y++)
						{
							memcpy(			[curPix fImage] + y * newX,
											[[pixList objectAtIndex: y] fImage] + i * [[pixList objectAtIndex: y] pwidth],
											newX * sizeof( float));
						}
					}
					
					if( square)
					{
						vImage_Buffer	srcVimage, dstVimage;
						
						srcVimage.data = [curPix fImage];
						srcVimage.height =  [pixList count];
						srcVimage.width = newX;
						srcVimage.rowBytes = newX*4;
						
						dstVimage.data = [curPix fImage];
						dstVimage.height =  newY;
						dstVimage.width = newX;
						dstVimage.rowBytes = newX*4;
						
						vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
												
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
					}
					
					if( sign > 0)
							[lastPix orientation: orientation];
					else
							[firstPix orientation: orientation];
					
					float cc[ 3];
					
					cc[ 0] = orientation[ 3];
					cc[ 1] = orientation[ 4];
					cc[ 2] = orientation[ 5];
					
					if( sign > 0)
					{
						// Y Vector = Normal Vector
						orientation[ 3] = orientation[ 6] * -sign;
						orientation[ 4] = orientation[ 7] * -sign;
						orientation[ 5] = orientation[ 8] * -sign;
					}
					else
					{
						// Y Vector = Normal Vector
						orientation[ 3] = orientation[ 6] * sign;
						orientation[ 4] = orientation[ 7] * sign;
						orientation[ 5] = orientation[ 8] * sign;
					}
					
					[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
					
					[curPix setPixelSpacingX: newXSpace];
					[curPix setPixelSpacingY: newYSpace];
					
					[curPix setPixelRatio:  newYSpace / newXSpace];
					
					[curPix orientation: orientation];
					
					if( sign > 0)
					{
						origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * sign;
						origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * sign;
						origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * sign;
					}
					else
					{
						origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingY]) * orientation[ 6] * -sign;
						origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingY]) * orientation[ 7] * -sign;
						origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingY]) * orientation[ 8] * -sign;
					}
					
					if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 0]];
					}
					if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 1]];
					}
					if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 2]];
					}
					
					[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingY]];
					[[newPixList lastObject] setSliceInterval: [firstPix pixelSpacingY]];
					[curPix setOrigin: origin];
				}
				else											// Y - RESLICE
				{
					DCMPix	*curPix = [newPixList lastObject];
					float	*srcPtr;
					float	*dstPtr;
					long	rowBytes = [firstPix pwidth];
					
					for(x = 0; x < [pixList count]; x++)
					{
						if( sign > 0)
							srcPtr = [[pixList objectAtIndex: [pixList count]-x-1] fImage] + i;
						else
							srcPtr = [[pixList objectAtIndex: x] fImage] + i;
						dstPtr = [curPix fImage] + x * newX;
						
						y = newX;
						while (y-->0)
						{
							*dstPtr = *srcPtr;
							dstPtr++;
							srcPtr += rowBytes;
						}
					}
										
					if( square)
					{
						vImage_Buffer	srcVimage, dstVimage;
						
						srcVimage.data = [curPix fImage];
						srcVimage.height =  [pixList count];
						srcVimage.width = newX;
						srcVimage.rowBytes = newX*4;
						
						dstVimage.data = [curPix fImage];
						dstVimage.height =  newY;
						dstVimage.width = newX;
						dstVimage.rowBytes = newX*4;
						
						vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
						
//						for( x = 0; x < newX; x++)
//						{
//							srcPtr = [curPix fImage] + x ;
//							
//							for( y = newY-1; y >= 0; y--)
//							{
//								s = y / ratio;
//								left = s - floor(s);
//								right = 1-left;
//								
//								*(srcPtr + y * rowBytes) = right * *(srcPtr + (long) (s) * rowBytes) + left * *(srcPtr + (long) ((s)+1) * rowBytes);
//							}
//						}
					}
					
					if( sign > 0)
							[lastPix orientation: orientation];
					else
							[firstPix orientation: orientation];
					
					// Y Vector = Normal Vector
					orientation[ 0] = orientation[ 3];
					orientation[ 1] = orientation[ 4];
					orientation[ 2] = orientation[ 5];
					
					if( sign > 0)
					{
						orientation[ 3] = orientation[ 6] * -sign;
						orientation[ 4] = orientation[ 7] * -sign;
						orientation[ 5] = orientation[ 8] * -sign;
					}
					else
					{
						orientation[ 3] = orientation[ 6] * sign;
						orientation[ 4] = orientation[ 7] * sign;
						orientation[ 5] = orientation[ 8] * sign;
					}
					
					[curPix setOrientation: orientation];	// Normal vector is recomputed in this procedure
					
					[curPix setPixelSpacingX: newXSpace];
					[curPix setPixelSpacingY: newYSpace];
					
					[curPix setPixelRatio:  newYSpace / newXSpace];
					
					[curPix orientation: orientation];
					if( sign > 0)
					{
						origin[ 0] = [lastPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * -sign;
						origin[ 1] = [lastPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * -sign;
						origin[ 2] = [lastPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * -sign;
					}
					else
					{
						origin[ 0] = [firstPix originX] + (i * [firstPix pixelSpacingX]) * orientation[ 6] * sign;
						origin[ 1] = [firstPix originY] + (i * [firstPix pixelSpacingX]) * orientation[ 7] * sign;
						origin[ 2] = [firstPix originZ] + (i * [firstPix pixelSpacingX]) * orientation[ 8] * sign;
					}
					
					if( fabs( orientation[6]) > fabs(orientation[7]) && fabs( orientation[6]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 0]];
					}
					if( fabs( orientation[7]) > fabs(orientation[6]) && fabs( orientation[7]) > fabs(orientation[8]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 1]];
					}
					if( fabs( orientation[8]) > fabs(orientation[6]) && fabs( orientation[8]) > fabs(orientation[7]))
					{
						[[newPixList lastObject] setSliceLocation: origin[ 2]];
					}
					
					[[newPixList lastObject] setSliceThickness: [firstPix pixelSpacingX]];
					[[newPixList lastObject] setSliceInterval: 0];
					
					[curPix setOrigin: origin];
				}
			}
			
			int newOrientationTool, currentOrientationTool = [viewerController orthogonalOrientation];
			
			if( newViewer == NO)
			{
				[viewerController replaceSeriesWith :newPixList :newDcmList :newData];
				
				new2DViewer = viewerController;
			}
			else
			{
				// CREATE A SERIES
				new2DViewer = [viewerController newWindow	:newPixList
															:newDcmList
															:newData];
															
				[new2DViewer setImageIndex: [newPixList count]/2];
				
				[[new2DViewer window] makeKeyAndOrderFront: self];
			}
			
			switch( currentOrientationTool)
			{
				case 0:	// axial
					if( directionm == 0) newOrientationTool = 1;
					else newOrientationTool = 2;
				break;
				
				case 1:	// cor
					if( directionm == 0) newOrientationTool = 0;
					else newOrientationTool = 2;
				break;
				
				case 2:	// sag
					if( directionm == 0) newOrientationTool = 0;
					else newOrientationTool = 1;
				break;
			}
			
			switch( currentOrientationTool)
			{
				case 0:
				{
					switch( newOrientationTool)
					{
						case 0:
						break;
						case 1:
						break;
						case 2:
						break;
					}
				}
				break;

				case 1:
				{
					switch( newOrientationTool)
					{
						case 0:
							[new2DViewer vertFlipDataSet: self];
						break;
						case 1:
						break;
						case 2:
							[new2DViewer rotateDataSet: kRotate90DegreesClockwise];
						break;
					}
				}
				break;

				case 2:
				{
					switch( newOrientationTool)
					{
						case 0:
							[new2DViewer rotateDataSet: kRotate90DegreesClockwise];
							[new2DViewer horzFlipDataSet: self];
						break;
						case 1:
							[new2DViewer rotateDataSet: kRotate90DegreesClockwise];
							[new2DViewer horzFlipDataSet: self];
						break;
						case 2:
						break;
					}
				}
				break;
			}
			
			[new2DViewer computeInterval];
		}
		
		// Close the waiting window
		[viewerController endWaitWindow: waitWindow];
		
		NSLog(@"End-Reslice");
}

-(IBAction) endDialog:(id) sender
{
    [window orderOut:sender];
    
    [NSApp endSheet:window returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		if( [[direction selectedCell] tag] == 2)
		{
			[self executeReslice: 0 :[squarePixels state] :[newWindow state]];
			[self executeReslice: 1 :[squarePixels state] :YES];
		}
		else [self executeReslice: [[direction selectedCell] tag] :[squarePixels state] :[newWindow state]];
		
		// We modified the pixels: OsiriX please update the display!
		[viewerController needsDisplayUpdate];
    }
	
	[[NSUserDefaults standardUserDefaults] setBool:[newWindow state] forKey:@"newWindow - OrthogonalReslice"];
	[[NSUserDefaults standardUserDefaults] setBool:[squarePixels state] forKey:@"squarePixels - OrthogonalReslice"];
}

- (long) filterImage:(NSString*) menuName
{
	NSArray				*pixList = [viewerController pixList];	
	DCMPix				*firstPix = [pixList objectAtIndex: 0];
	long				im;
	float				thick;
	
	[NSBundle loadNibNamed:@"OrthogonalReslice" owner:self];
	
	[viewerController computeInterval];
	
	im = [firstPix pheight];		thick = [firstPix pixelSpacingY];
	[xResolution setStringValue: [NSString stringWithFormat: @"%d images, %2.2f thickness", im, thick]];
	
	im = [firstPix pwidth];			thick = [firstPix pixelSpacingX];
	[yResolution setStringValue: [NSString stringWithFormat: @"%d images, %2.2f thickness", im, thick]];
	
	[newWindow setState: [[NSUserDefaults standardUserDefaults] boolForKey:@"newWindow - OrthogonalReslice"]];
	[squarePixels setState: [[NSUserDefaults standardUserDefaults] boolForKey:@"squarePixels - OrthogonalReslice"]];
	
	NSLog(@"X: %2.2f, Y: %2.2f, Interval: %2.2f", [firstPix pixelSpacingX], [firstPix pixelSpacingY], fabs( [firstPix sliceInterval]));
	
	if( fabs( [firstPix sliceInterval]) != [firstPix pixelSpacingX] || fabs( [firstPix sliceInterval]) != [firstPix pixelSpacingY])
	{
		if( fabs( [firstPix sliceInterval]) > [firstPix pixelSpacingX] && fabs( [firstPix sliceInterval]) > [firstPix pixelSpacingY])
		{
			[squarePixels setEnabled: YES];
		}
	}
	
	[NSApp beginSheet: window modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	return 0;   // No Errors
}

@end

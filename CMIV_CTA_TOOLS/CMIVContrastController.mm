/*=========================================================================
Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

CMIV CTA image processing Plugin for OsiriX is free software;
you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option)
any later version.

CMIV CTA image processing Plugin for OsiriX is distributed in
the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import "CMIVSegmentCore.h"
#import "CMIVContrastController.h"
#import "CMIV3DPoint.h"

#define id Id
#include "itkMultiThreader.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkGradientAnisotropicDiffusionImageFilter.h"
#include "itkRecursiveGaussianImageFilter.h"
#include "itkHessianRecursiveGaussianImageFilter.h"
#include "itkHessian3DToVesselnessMeasureImageFilter.h"
#include "itkCannyEdgeDetectionImageFilter.h"
#include "itkHoughTransform2DCirclesImageFilter.h"
#undef id


@implementation CMIVContrastController

- (IBAction)addToRight:(id)sender
{

	int row = [inROIList selectedRow];
	ROI* tempROI = [inROIArray objectAtIndex: row];
	unsigned int i;
	int	thereIsSameName=0;
	for( i =0; i<[outROIArray count];i++)
	{

		if ([[tempROI name] isEqualToString:[[outROIArray objectAtIndex: i] name]]==YES)
			thereIsSameName=1;
	}
	if( !thereIsSameName )
		[outROIArray addObject: tempROI ];
		 
	[outROIList reloadData];
}

- (IBAction)onCancel:(id)sender
{
	int tag=0;
	if(sender&&[sender respondsToSelector:@selector(tag)])
		tag=[sender tag];
	[window setReleasedWhenClosed:YES];
	[window close];
    [NSApp endSheet:window returnCode:tag];
	//sleep(1);
	if(tag!=2)
	{
		[inROIArray removeAllObjects];
		[outROIArray removeAllObjects];
		[outputColorList removeAllObjects];
	}
	[inROIArray release];
	[outROIArray release];
	[outputColorList release];
	if(tag!=2)
		[parent cleanSharedData];
	
}
- (IBAction)onOk:(id)sender
{
	
	
	int err;
	float               *inputData=0L, *outputData=0L;
	unsigned char       *colorData=0L, *directionData=0L;
	unsigned int rowIndex;
	int outputcomponent=0;
	for(rowIndex=0;rowIndex<[outROIArray count];rowIndex++)
		if([[outROIArray objectAtIndex:rowIndex] ROImode]== ROI_selected)
			outputcomponent++;
	if(!outputcomponent)
	{
		NSRunAlertPanel(NSLocalizedString(@"no output", nil), NSLocalizedString(@"no export component is selected, nothing to export", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;	

	}

	// Display a waiting window
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
	[self runSegmentation:&inputData :&outputData:&colorData:&directionData];
	//export result and release memory
	if(inputData&&outputData&&colorData&&directionData)
	{
		if([exportCenterlineChechBox state]!= NSOnState)
			free(directionData);
		if([exportConnectednessChechBox state]== NSOnState)
		{
			err=[self exportToTempFolder:inputData :outputData:colorData];
			outputData=nil;
			
		}
		if([exportIntoOneChechBox state]== NSOnState)
		{
			err=[self exportToImages:inputData :outputData:colorData];
			outputData=nil;
		}
		if([exportIntoSeparateChechBox state]== NSOnState)
		{
			err=[self exportToSeries:inputData :outputData:colorData];
			outputData=nil;
		}
		if([exportIntoMaskChechBox state]== NSOnState)
		{
			err=[self exportToROIs:inputData :outputData:colorData];
			outputData=nil;

		}
	
		
		if([exportCenterlineChechBox state]== NSOnState)
		{
			
			err=[self exportToCenterLines:inputData :outputData:directionData:colorData];
			outputData=nil;
			free(directionData);
		}
		else
			free( colorData );//clean the  color matrix
	}
	
	[originalViewController endWaitWindow: waitWindow];
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onCancel:)  userInfo:0L repeats:NO];
	
	
	
}

- (IBAction)onPreview:(id)sender
{
	float               *inputData=0L, *outputData=0L;
	unsigned char       *colorData=0L, *directionData=0L;
	unsigned short int* seedVolume;
	int size= sizeof(unsigned short int)*imageWidth*imageHeight*imageAmount;	
	seedVolume=(unsigned short int*)malloc(size);
	if(!seedVolume)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	memset(seedVolume, 0, size);
	// Display a waiting window
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
	NSLog( @"start step 3");
	[self runSegmentation:&inputData:&outputData:&colorData:&directionData];
	
	[originalViewController endWaitWindow: waitWindow];	
	

	
	if(inputData&&outputData&&colorData&&directionData)
	{
		[parent cleanDataOfWizard];
		size= sizeof(float)*imageWidth*imageHeight*imageAmount;
		NSData	*newData = [[NSData alloc] initWithBytesNoCopy:inputData length: size freeWhenDone:NO];
		NSMutableDictionary* dic=[parent dataOfWizard];
		[dic setObject:newData forKey:@"InputData"];
		[newData release];
		newData = [[NSData alloc] initWithBytesNoCopy:outputData length: size freeWhenDone:YES];
		[dic setObject:newData  forKey:@"OutputData"];
		[newData release];
		size= sizeof(unsigned char)*imageWidth*imageHeight*imageAmount;
		newData = [[NSData alloc] initWithBytesNoCopy:directionData length: size freeWhenDone:YES];
		[dic setObject:newData  forKey:@"DirectionData"];
		[newData release];
		newData = [[NSData alloc] initWithBytesNoCopy:colorData length: size freeWhenDone:YES];
		[dic setObject:newData  forKey:@"ColorData"];
		[newData release];
		size= sizeof(unsigned short int)*imageWidth*imageHeight*imageAmount;	
		newData = [[NSData alloc] initWithBytesNoCopy:seedVolume length: size freeWhenDone:YES];
		[dic setObject:newData  forKey:@"SeedData"];
		[newData release];
		NSMutableArray  *seedROIList=[[NSMutableArray alloc] initWithCapacity: 0] ;	
		[dic setObject:outROIArray  forKey:@"SeedList"];
		[dic setObject:outputColorList  forKey:@"ShownColorList"];
		[dic setObject:seedROIList  forKey:@"ROIList"];
		if([neighborhoodModeMatrix selectedRow])
			[dic setObject:[NSNumber numberWithInt:6] forKey:@"CFCTNeighborhood"];
		//[parent setDataofWizard:dic];
		[self onCancel: sender];
		[parent gotoStepNo:3];

	}
	else
		free(seedVolume);
	
		
	
	
}
- (void) runSegmentation:(float **)ppInData :(float **)ppOutData :(unsigned char **)ppColorData:(unsigned char **)ppDirectionData
{
	long				y, x, z;
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	float               *inputData=0L, *outputData=0L;
	unsigned char       *colorData=0L, *directionData=0L;
	int err=0;
	ifUseSmoothFilter=0;
	
	if([outROIArray count]>62)
	{
		NSRunAlertPanel(NSLocalizedString(@"too many kinds of seeds", nil), NSLocalizedString(@"no more than 62 kinds of seeds can be selected in one round segment.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	imageSize=imageWidth * imageHeight;
	
	//if([exportConnectednessChechBox state]== NSOnState)
	//	ifUseSmoothFilter=1;
	// get memory first
	if(ifUseSmoothFilter)
	{
		inputData = [originalViewController volumePtr:0];
		if( !inputData)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			
			return ;	
		}
		
		//err=[self smoothInputData:inputData];
		//err=[self enhanceInputData:inputData];
		//err=[self CannyEdgeDetection:inputData];
		if(err)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough to smooth input data", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			free(inputData);
			inputData=0L;
			outputData=0L;
			colorData=0L;
			return ;	
		}	
		return;
		
	}
	else
		inputData=[originalViewController volumePtr:0];
	
	outputData = (float*) malloc( size);
	if( !outputData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		if(ifUseSmoothFilter)
			free(inputData);
		inputData=0L;
		outputData=0L;
		colorData=0L;
		return ;	
	}
	
	
	size = sizeof(char) * imageWidth * imageHeight * imageAmount;
	colorData = (unsigned char*) malloc( size);
	if( !colorData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		if(ifUseSmoothFilter)
			free(inputData);
		free(outputData);
		inputData=0L;
		outputData=0L;
		colorData=0L;
		return ;	
	}	
	directionData= (unsigned char*) malloc( size);
	if( !directionData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		if(ifUseSmoothFilter)
			free(inputData);
		free(outputData);
		free(colorData);
		inputData=0L;
		outputData=0L;
		colorData=0L;
		directionData=0L;
		return ;	
	}		
	

	
	curPix = [pixList objectAtIndex: 0];
	
	upperThreshold = [curPix maxValueOfSeries];
	lowerThreshold = minValueInCurSeries = [curPix minValueOfSeries];
	
	
	for( z = 0; z < imageAmount; z++)
		for(y = 0;y < imageHeight; y++)
			for(x = 0; x < imageWidth; x++)
			{
				*(outputData+ imageWidth * imageHeight*z + imageWidth*y + x) = minValueInCurSeries;
				if( *(inputData+ imageWidth * imageHeight*z + imageWidth*y + x) > upperThreshold ||  *(inputData+ imageWidth * imageHeight*z + imageWidth*y + x) <= lowerThreshold )
					*(directionData+ imageWidth * imageHeight*z + imageWidth*y + x) = 0xbf; // binary 1011 1111 the 63rd kind of seeds -- empty space
				else 
					*(directionData+ imageWidth * imageHeight*z + imageWidth*y + x) = 0x00;
			}
				
				
	//planting seed in color matrix
				
	int seednumber = [self seedPlantingfloat:inputData:outputData:directionData];
	if(seednumber < 1)
	{
		
		NSRunAlertPanel(NSLocalizedString(@"no seed", nil), NSLocalizedString(@"no seeds are found, draw ROI first.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		if(ifUseSmoothFilter)
			free(inputData);
		free( outputData );	
		free( colorData );
		free(directionData);
		inputData=0L;
		outputData=0L;
		colorData=0L;
		directionData=0L;
		
		return;
		
	}			
	//creat ouput color list
	unsigned int rowIndex;
	outputColorList= [[NSMutableArray alloc] initWithCapacity: 0];
	for(rowIndex=0;rowIndex<[outROIArray count];rowIndex++)
		if([[outROIArray objectAtIndex:rowIndex] ROImode]== ROI_selected)
			[outputColorList addObject: [NSNumber numberWithInt:rowIndex+1]];
	//get spacing
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	float spacing[3];
	
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	spacing[2]=sliceThickness;
	
	//start seed growing	
	CMIVSegmentCore *segmentCoreFunc = [[CMIVSegmentCore alloc] init];
	[segmentCoreFunc setImageWidth:imageWidth Height: imageHeight Amount: imageAmount Spacing:spacing];
	if([neighborhoodModeMatrix selectedRow])
		[segmentCoreFunc startShortestPathSearchAsFloatWith6Neighborhood:inputData Out:outputData Direction: directionData];
	else
		[segmentCoreFunc startShortestPathSearchAsFloat:inputData Out:outputData :colorData Direction: directionData];
	//initilize the out and color buffer
	memset(colorData,0,size);
	[segmentCoreFunc caculateColorMapFromPointerMap:colorData:directionData]; 
	[segmentCoreFunc release];

	*ppInData = inputData;
	*ppOutData = outputData;
	*ppColorData = colorData;
	*ppDirectionData = directionData;
	
}

- (IBAction)removeFromRight:(id)sender
{
	int row = [outROIList selectedRow];
	[outROIArray removeObjectAtIndex:row];
	[outROIList reloadData];
}
- (int) showContrastPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner
{
	int err=0;
	originalViewController=vc;
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	parent = owner;
	if( [curPix isRGB])
	{
		NSRunAlertPanel(NSLocalizedString(@"no RGB Support", nil), NSLocalizedString(@"This plugin doesn't surpport RGB images, please convert this series into BW images first", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 0;
	}	
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [pixList count];
	
	
	inROIArray = [[NSMutableArray alloc] initWithCapacity: 0];
	outROIArray = [[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableArray *curRoiList = [originalViewController roiList];
	ROI * tempROI;
	
	unsigned int i,j,k;
	int thereIsSameName ;
	for(i=0;i<[curRoiList count];i++)
		for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
		{
			tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
			thereIsSameName=0;
			for(k=0;k<[inROIArray count];k++)
			{ 
				if ([[tempROI name] isEqualToString:[[inROIArray objectAtIndex: k] name]]==YES)
                  thereIsSameName=1;
			}
			if(!thereIsSameName)
			{
				[inROIArray addObject:tempROI];
				[outROIArray addObject:tempROI];
			}	
			
		}
	[NSBundle loadNibNamed:@"Contrast_Panel" owner:self];
	
	[NSApp beginSheet: window modalForWindow:[originalViewController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
//	[window setLevel: NSModalPanelWindowLevel];
	[neighborhoodModeMatrix setEnabled: NO];
	[inROIList setDataSource:self];	
	[outROIList setDataSource: self];
	return err;
	
}



- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if([inROIList isEqual:tableView])
	   {
		   return [inROIArray count];
	   }
	   else if([outROIList isEqual:tableView])
	   {
		   return [outROIArray count];
	   }
	return 0;

}

- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{
if( originalViewController == 0L) return 0L;
	if([inROIList isEqual:tableView])
	   {
		   
			if( [[tableColumn identifier] isEqualToString:@"NO."])
			{
				return [NSString stringWithFormat:@"%d", row+1];
			} 
		   if( [[tableColumn identifier] isEqualToString:@"Name"])
		   {
			   return [[inROIArray objectAtIndex:row] name];
		   }
		   if( [[tableColumn identifier] isEqualToString:@"Comment"])
		   {
			   return [NSNumber numberWithFloat:[[inROIArray objectAtIndex:row] roiArea]];
		   }
	   }
	   else if([outROIList isEqual:tableView])
		{
			if( [[tableColumn identifier] isEqualToString:@"Name"])
			{
				return [[outROIArray objectAtIndex:row] name];
			}
		   if( [[tableColumn identifier] isEqualToString:@"IfExport"])
		   {
			   if( [[outROIArray objectAtIndex:row] ROImode] == ROI_selected)
					return  [NSNumber numberWithBool:YES];
			   else
				    return   [NSNumber numberWithBool:NO];
			


		   }		
			
		}


	return 0L;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	if([outROIList isEqual:aTableView])
	{

		if( [[aTableColumn identifier] isEqualToString:@"IfExport"])
		{
			if( [anObject boolValue] == YES )
			{
				[[outROIArray objectAtIndex:rowIndex] setROIMode:ROI_selected];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object: [outROIArray objectAtIndex:rowIndex] userInfo: nil];
			}
			else
				[[outROIArray objectAtIndex:rowIndex] setROIMode:ROI_sleep];

		}		
		
	}	
}
- (long) seedPlantingfloat:(float *)inputData :(float *)outputData :(unsigned char *)colorData
{
	long seedNumber=0;
	int             x,y;
	int             isAStopSeed;
	NSMutableArray  *roiSeriesList;
	NSMutableArray  *roiImageList;
	ROI				*curROI = 0L;
	unsigned int			i,j;
	unsigned int    k;
	long            lefttopx, lefttopy,rightbottomx,rightbottomy;
	unsigned int            pointamount;
	int             tempxx,tempyy;
	
	
	
	// All rois contained in the current series
	roiSeriesList = [originalViewController roiList];
	for( j = 0; j < [roiSeriesList count]; j++)
	{
		// All rois contained in the current image
		roiImageList = [roiSeriesList objectAtIndex: j];
		
		
		for( i = 0; i < [roiImageList count]; i++)
		{
			curROI = [roiImageList objectAtIndex: i];
			unsigned char colorindex=0;
			isAStopSeed=0;
			for(k=0;k<[outROIArray count];k++)
			{
				if ([[curROI name] isEqualToString:[[outROIArray objectAtIndex: k] name]]==YES)
					colorindex=(unsigned char)k+1;

			}
			
			if([[curROI name] isEqualToString:[NSString stringWithString:@"barrier"]])
				isAStopSeed=1;			
			
			if(colorindex>0)
			{
				int roitype =[curROI type];
				if(roitype == tPlain)
				{
					unsigned char *textureBuffer= [curROI textureBuffer];
					int textureOriginX,textureOriginY,textureWidth,textureHeight;
					textureOriginX=lefttopx = [curROI textureUpLeftCornerX];
					textureOriginY=lefttopy = [curROI textureUpLeftCornerY];
					textureWidth=[curROI textureWidth];
					textureHeight=[curROI textureHeight];
					rightbottomx=lefttopx+textureWidth;
					rightbottomy=lefttopy+textureHeight;
					
					//rightbottomx = [curROI textureDownRightCornerX]+1;
					//rightbottomy = [curROI textureDownRightCornerY]+1;
					//textureWidth = rightbottomx-lefttopx;
					if(lefttopx>rightbottomx)
					{	
						lefttopx = [curROI textureDownRightCornerX];
						rightbottomx = [curROI textureUpLeftCornerX];						
					}
					if(lefttopy>rightbottomy)
					{
						lefttopy = [curROI textureDownRightCornerY];
						rightbottomy = [curROI textureUpLeftCornerY];
					}
					if(lefttopx<0)
						lefttopx=0;
					if(lefttopy<0)
						lefttopy=0;
					if(rightbottomx>=imageWidth)
						rightbottomx=imageWidth-1;
					if(rightbottomy>=imageHeight)
						rightbottomy=imageHeight-1;
					
										
					for( y = lefttopy; y < rightbottomy ; y++)
						for(x=lefttopx; x < rightbottomx ; x++)
							if(*(textureBuffer+(y-textureOriginY)*textureWidth+x-textureOriginX))
							{
								if(!isAStopSeed)
									*(outputData + j*imageWidth*imageHeight + y*imageWidth + x) =  *(inputData + j*imageWidth*imageHeight + y*imageWidth + x);
								*(colorData + j*imageWidth*imageHeight + y*imageWidth + x) = colorindex | 0x80;
								
								seedNumber++;
								
							}					
				
				}
				else if(roitype == tROI||roitype  == tOval)
				{
				   
				   
					NSMutableArray  *ptsTemp = [curROI points];
					pointamount = [ptsTemp count];
					if(pointamount > 3)
					{
						lefttopx = rightbottomx = (long)( [[ptsTemp objectAtIndex: 0] point].x);
						lefttopy = rightbottomy = (long)( [[ptsTemp objectAtIndex: 0] point].y);
						for( k = 1; k < pointamount; k++)
						{
							tempxx = (int)( [[ptsTemp objectAtIndex: k] point].x);
							tempyy = (int)( [[ptsTemp objectAtIndex: k] point].y);
							if(tempxx < lefttopx) 
								lefttopx = tempxx;
							if(tempxx > rightbottomx )
								rightbottomx = tempxx;
							if( tempyy < lefttopy )
								lefttopy = tempyy;
							if( tempyy > rightbottomy )
								rightbottomy = tempyy;
						}
						if(lefttopx<0)
							lefttopx=0;
						if(lefttopy<0)
							lefttopy=0;
						if(rightbottomx>=imageWidth)
							rightbottomx=imageWidth-1;
						if(rightbottomy>=imageHeight)
							rightbottomy=imageHeight-1;

						if( roitype == tROI)
						{
							for( y = lefttopy; y < rightbottomy ; y++)
								for(x=lefttopx; x < rightbottomx ; x++)
								{
									if(!isAStopSeed)
										*(outputData + j*imageWidth*imageHeight + y*imageWidth + x) =  *(inputData + j*imageWidth*imageHeight + y*imageWidth + x);
									*(colorData + j*imageWidth*imageHeight + y*imageWidth + x) = colorindex | 0x80;
									seedNumber++;
									
								}
									
						}
						else if(roitype  == tOval)
						{
							long a,b;
							a=(rightbottomx - lefttopx)/2;
							b=(rightbottomy - lefttopy)/2;
							a= a*a;
							b= b*b;
							for( y = lefttopy; y < rightbottomy ; y++)
								for(x=lefttopx; x < rightbottomx ; x++)
								{ 
									tempxx=x-(rightbottomx + lefttopx)/2;
									tempyy=y-(rightbottomy + lefttopy)/2;
									
									if(tempxx*tempxx*b+tempyy*tempyy*a<=a*b)
									{
										if(!isAStopSeed)
											*(outputData + j*imageWidth*imageHeight + y*imageWidth + x) =  *(inputData + j*imageWidth*imageHeight + y*imageWidth + x);
										*(colorData + j*imageWidth*imageHeight + y*imageWidth + x) = colorindex | 0x80;
										seedNumber++;
									}
								}
						}
					}
				}
			}
		}
	}
			
				 
			
	return seedNumber;
}

- (int) exportToImages:(float *)inputData :(float *)outputData :(unsigned char *)colorData
{
	
	int index;
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	
	unsigned int i;
	unsigned char colorIndex;
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	
	if(!outputData)
	{
		
		outputData = (float*) malloc( size);
		if( !outputData)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return 1;	
		}
	}
	
	// CREATE A NEW SERIES TO CONTAIN THIS NEW SERIES
	size = imageWidth * imageHeight * imageAmount;
	for( index = 0; index < size; index++)
	{
		int noMatch=1;
		for(i=0;i< [outputColorList count];i++)
		{
			
			colorIndex =(unsigned char) [[outputColorList objectAtIndex:i] intValue];
			if(((*(colorData+ index))&0x3f )== colorIndex)	
			{
				*(outputData+ index) = *(inputData+ index);
				noMatch=0;
			}
		}
		if(noMatch)
			*(outputData+ index) = minValueInCurSeries;
		
	}
				
	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	NSData	*newData = [NSData dataWithBytesNoCopy:outputData length: size freeWhenDone:YES];
	int z;
	for( z = 0 ; z < imageAmount; z ++)
	{
		curPix = [pixList objectAtIndex: z];
		DCMPix	*copyPix = [curPix copy];
		[newPixList addObject: copyPix];
		[copyPix release];
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
		[[newPixList lastObject] setfImage: (float*) (outputData + imageWidth * imageHeight * z)];
	}
	
	// CREATE A SERIES
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
													:newDcmList
													:newData];  
	outputData = nil;
	NSString* tempstr=[NSString stringWithString:@"Results of "];

	int newcolorIndex;
	for(i=0;i< [outputColorList count];i++)
	{
		newcolorIndex = [[outputColorList objectAtIndex:i] intValue];
		tempstr=[tempstr stringByAppendingFormat:@" %@",[[outROIArray objectAtIndex:newcolorIndex-1] name]];
	}
	[new2DViewer checkEverythingLoaded];
	[[new2DViewer window] setTitle:tempstr];
	NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey: @"VCList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
	}
	[temparray addObject:new2DViewer];
	temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
	}
	[temparray addObject:tempstr];
	[[self window] makeKeyAndOrderFront:parent];
	return 0;
	
}
- (int) exportToROIs:(float *)inputData :(float *)outputData :(unsigned char *)colorData
{

		
	long size= sizeof(float)*imageWidth * imageHeight * imageAmount;
	RGBColor	color;
	NSString *roiName;
	ROI* curROI;
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];

	if(!outputData)
	{
		
		outputData = (float*) malloc( size);
		if( !outputData)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return 1;	
		}
	}
	
	//creat a new series
	float* tempinput=[originalViewController volumePtr:0];
	memcpy(outputData,tempinput,size);
	
	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	NSData	*newData = [NSData dataWithBytesNoCopy:outputData length: size freeWhenDone:YES];
	int z;
	for( z = 0 ; z < imageAmount; z ++)
	{
		curPix = [pixList objectAtIndex: z];
		DCMPix	*copyPix = [curPix copy];
		[newPixList addObject: copyPix];
		[copyPix release];
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
		[[newPixList lastObject] setfImage: (float*) (outputData + imageWidth * imageHeight * z)];
	}
	
	// CREATE A SERIES
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
													:newDcmList
													:newData];  

	NSMutableArray      *roiList= [new2DViewer roiList];	
	unsigned char *textureBuffer;
	size= imageWidth * imageHeight * imageAmount;
	unsigned char *wholeTexTureBuffer=  (unsigned char *) malloc(size);
	if( !wholeTexTureBuffer)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return 1;
	}
	unsigned int rowIndex;
	unsigned char colorIndex;
	for(rowIndex = 0; rowIndex<[outputColorList count]; rowIndex++)
		{
			colorIndex =(unsigned char) [[outputColorList objectAtIndex:rowIndex] intValue];
			curROI = [outROIArray objectAtIndex:(int)colorIndex-1];
			int ii;
			for(ii=0;ii<size;ii++)
			{
				if(((*(colorData + ii))&0x3f)==colorIndex)
					*(wholeTexTureBuffer + ii) = 0xff;
				else 
					*(wholeTexTureBuffer + ii) = 0x00;
			}
			roiName = [curROI name];
			
			if([curROI respondsToSelector:@selector(rgbcolor)])
				color= [curROI rgbcolor];
			
			unsigned int i;	
			for(i=0;i<[roiList count];i++)
			{
				textureBuffer=wholeTexTureBuffer + imageWidth * imageHeight * i;
				ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:imageWidth textHeight:imageHeight textName:roiName positionX:0 positionY:0 spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
				[newROI reduceTextureIfPossible];
				[newROI setColor:color];
				[[roiList objectAtIndex: i] addObject:newROI];
				[newROI release];
				
			}
			
		}
	outputData=nil;
	
	free(wholeTexTureBuffer);
	
	NSString* tempstr=[NSString stringWithString:@"ROI results of "];
	
	int newcolorIndex;
	unsigned int i;
	for(i=0;i< [outputColorList count];i++)
	{
		newcolorIndex = [[outputColorList objectAtIndex:i] intValue];
		tempstr=[tempstr stringByAppendingFormat:@" %@",[[outROIArray objectAtIndex:newcolorIndex-1] name]];
	}
	
	
	[new2DViewer checkEverythingLoaded];
	[[new2DViewer window] setTitle:tempstr];
	NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey: @"VCList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
	}
	[temparray addObject:new2DViewer];
	temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
	}
	[temparray addObject:tempstr];
	[[self window] makeKeyAndOrderFront:parent];
	return 0;
}
- (int) exportToSeries:(float *)inputData :(float *)outputData :(unsigned char *)colorData
{
	int index,z;
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	
	unsigned int i;
	unsigned char colorIndex;
	long size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	
	
	for(i=0;i< [outputColorList count];i++)
	{
		
		colorIndex = (unsigned char) [[outputColorList objectAtIndex:i] intValue];
		
		if(!outputData)
		{
			
			outputData = (float*) malloc( size);
			if( !outputData)
			{
				NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
				return 1;	
			}
		}
		
		// CREATE A NEW SERIES TO CONTAIN THIS NEW SERIES
		size= imageWidth * imageHeight * imageAmount;
		for( index = 0; index <size; index++)
			if(((*(colorData+ index))&0x3f ) == colorIndex)	
				*(outputData+ index) = *(inputData+ index);
			else
				*(outputData+ index) = minValueInCurSeries;
		
		size = sizeof(float) * imageWidth * imageHeight * imageAmount;
		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
		NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
		NSData	*newData = [NSData dataWithBytesNoCopy:outputData length: size freeWhenDone:YES];
		for( z = 0 ; z < imageAmount; z ++)
		{
			curPix = [pixList objectAtIndex: z];
			DCMPix	*copyPix = [curPix copy];
			[newPixList addObject: copyPix];
			[copyPix release];
			[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
			
			[[newPixList lastObject] setfImage: (float*) (outputData + imageWidth * imageHeight * z)];
		}
		
		// CREATE A SERIES
		ViewerController *new2DViewer;
		new2DViewer = [originalViewController newWindow	:newPixList
														:newDcmList
														:newData];  
		
		
		outputData = nil;
		NSString* tempstr=[NSString stringWithString:@"Results of "];
		
		int newcolorIndex=(int)colorIndex;
		tempstr=[tempstr stringByAppendingFormat:@" %@",[[outROIArray objectAtIndex:newcolorIndex-1] name]];

		[new2DViewer checkEverythingLoaded];
		[[new2DViewer window] setTitle:tempstr];
		NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey: @"VCList"];
		if(!temparray)
		{
			temparray=[NSMutableArray arrayWithCapacity:0];
			[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
		}
		[temparray addObject:new2DViewer];
		temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
		if(!temparray)
		{
			temparray=[NSMutableArray arrayWithCapacity:0];
			[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
		}
		[temparray addObject:tempstr];
		
		
		
	}
	[[self window] makeKeyAndOrderFront:parent];
	return 0;
	
}
- (int) exportToCenterLines:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData
{
	
	long size= sizeof(float)*imageWidth * imageHeight * imageAmount;
	
	NSArray				*pixList = [originalViewController pixList];
	DCMPix				*curPix = [pixList objectAtIndex: 0];
	
	if(!outputData)
	{
		
		outputData = (float*) malloc( size);
		if( !outputData)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return 1;	
		}
	}
	
	//creat a new series
	float* tempinput=[originalViewController volumePtr:0];
	memcpy(outputData,tempinput,size);
	
	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	NSData	*newData = [NSData dataWithBytesNoCopy:outputData length: size freeWhenDone:YES];
	int z;
	for( z = 0 ; z < imageAmount; z ++)
	{
		curPix = [pixList objectAtIndex: z];
		DCMPix	*copyPix = [curPix copy];
		[newPixList addObject: copyPix];
		[copyPix release];
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
		[[newPixList lastObject] setfImage: (float*) (outputData + imageWidth * imageHeight * z)];
	}
	
	// CREATE A SERIES
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
													:newDcmList
													:newData];  
	
	NSMutableArray      *roiList= [new2DViewer roiList];
	int err=[self createCenterlines:tempinput :outputData:directData:colorData:roiList];
	memcpy(outputData,tempinput,size);
	
	NSString* tempstr=[NSString stringWithString:@"Centerlines"];
	NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey: @"VCList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
	}
	[temparray addObject:new2DViewer];
	temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
	if(!temparray)
	{
		temparray=[NSMutableArray arrayWithCapacity:0];
		[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
	}
	[temparray addObject:tempstr];
	[[self window] makeKeyAndOrderFront:parent];
	return err;
	
	
}
- (int) exportToTempFolder:(float *)inputData :(float *)outputData :(unsigned char *)colorData
{
	[parent cleanDataOfWizard];
	unsigned int i;
	unsigned int size= imageWidth * imageHeight * imageAmount;
	char colornum=(char)[outROIArray count];
	for(i=0;i<size;i++)
		if(*(colorData+i)>colornum)
			*(colorData+i)=0x00;
	size = sizeof(unsigned char ) * imageWidth * imageHeight * imageAmount;
	NSData	*newData = [[NSData alloc] initWithBytesNoCopy:colorData length: size freeWhenDone:NO];
	NSMutableDictionary* dic=[parent dataOfWizard];
	[dic setObject:newData forKey:@"MaskMap"];
	[dic setObject:[NSString stringWithString:@"MaskMap"] forKey:@"Step"];
	[dic setObject:[NSNumber numberWithInt:size] forKey:@"MaskMapSize"];
	NSMutableArray* seedsnamearray=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* seedscolorR=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* seedscolorG=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* seedscolorB=[NSMutableArray arrayWithCapacity:0];

	for(i=0;i<[outROIArray count];i++)
	{
		ROI* temproi=[outROIArray objectAtIndex:i];
		[seedsnamearray addObject:[temproi name]];
		RGBColor color= [temproi rgbcolor];
		[seedscolorR addObject:[NSNumber numberWithInt:color.red]];
		[seedscolorG addObject:[NSNumber numberWithInt:color.green]];
		[seedscolorB addObject:[NSNumber numberWithInt:color.blue]];
		
	}
	[dic setObject:seedsnamearray forKey:@"SeedNameArray"];
	[dic setObject:seedscolorR forKey:@"SeedsColorR"];
	[dic setObject:seedscolorG forKey:@"SeedsColorG"];
	[dic setObject:seedscolorB forKey:@"SeedsColorB"];
	[parent saveCurrentStep];
	[newData release];
	[parent cleanDataOfWizard];
	return 0;
}
- (int) createCenterlines:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData:(NSMutableArray*)roilist
{
	unsigned char* preservecolormap=(unsigned char*) malloc( sizeof(unsigned char) * imageWidth * imageHeight * imageAmount);
	memcpy(preservecolormap,colorData,sizeof(unsigned char) * imageWidth * imageHeight * imageAmount);
	DCMPix* curPix=[[originalViewController pixList] objectAtIndex:0];	
	float  pathWeightLength,lengthThreshold,weightThreshold;
	lengthThreshold=10.0;
	weightThreshold=100;
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	float minSpacing=[curPix pixelSpacingX];
	if(minSpacing>[curPix pixelSpacingY])minSpacing=[curPix pixelSpacingY];
	if(minSpacing>sliceThickness)minSpacing=sliceThickness;
	minSpacing/=2;
	lengthThreshold/=minSpacing;

	if(![self prepareForSkeletonizatin:inputData:outputData:directData:colorData])
	{	
		NSRunAlertPanel(NSLocalizedString(@"no root seeds are found, try seed planting again", nil), NSLocalizedString(@"no root seeds, can not create centerlines without root seeds", nil), NSLocalizedString(@"OK", nil), nil, nil);
				
		return 1;
	}
	
	

	//get spacing
	float spacing[3];
	
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	spacing[2]=sliceThickness;
	
	
	
	CMIVSegmentCore *segmentCoreFunc = [[CMIVSegmentCore alloc] init];
	NSMutableArray *centerlinesList=[[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableArray *centerlinesNameList=[[NSMutableArray alloc] initWithCapacity: 0];
	[segmentCoreFunc setImageWidth:imageWidth Height: imageHeight Amount: imageAmount Spacing:spacing];
	
	if([neighborhoodModeMatrix selectedRow])
		[segmentCoreFunc startShortestPathSearchAsFloatWith6Neighborhood:inputData Out:outputData Direction: directData];
	else 
		[segmentCoreFunc startShortestPathSearchAsFloat:inputData Out:outputData :colorData Direction: directData];

	free(colorData);
	colorData=0;
	unsigned short* pdismap=(unsigned short*) malloc( sizeof(unsigned short) * imageWidth * imageHeight * imageAmount);
	
	if(!pdismap)
	{	
		NSRunAlertPanel(NSLocalizedString(@"no root seeds are found, try seed planting again", nil), NSLocalizedString(@"no root seeds, can not create centerlines without root seeds", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 1;
	}	
	[self prepareForCaculateLength:pdismap:directData];
	[segmentCoreFunc localOptmizeConnectednessTree:inputData :outputData :pdismap Pointer: directData :minValueInCurSeries needSmooth:YES];
	
	free(pdismap);
	
	int* indexForEachSeeds=(int*)malloc(sizeof(int)*[outROIArray count]);
	unsigned int i;
	for(i=0;i<[outROIArray count];i++)
		*(indexForEachSeeds+i)=0;
	
	do
	{
		[self prepareForCaculateWeightedLength:outputData:directData];
		int endindex=[segmentCoreFunc caculatePathLengthWithWeightFunction:inputData:outputData Pointer: directData:weightThreshold:upperThreshold];
		pathWeightLength = *(outputData+endindex);
		if(endindex>0)
		{
			[centerlinesList addObject:[NSMutableArray arrayWithCapacity:0]];
			unsigned char colorindex;
			int len=[self searchBackToCreatCenterlines: centerlinesList: endindex:directData:&colorindex];
			if(colorindex<1)
			{
				[centerlinesList removeLastObject];
				continue;
			}
			NSString *pathName = [[outROIArray objectAtIndex:colorindex-1] name];
			*(indexForEachSeeds+colorindex-1)=*(indexForEachSeeds+colorindex-1)+1;
			[centerlinesNameList addObject: [pathName stringByAppendingFormat:@"%d",*(indexForEachSeeds+colorindex-1)] ];
			if(len < lengthThreshold)
			{
				[[centerlinesList lastObject] removeAllObjects];
				[centerlinesList removeLastObject];
				[centerlinesNameList removeLastObject];
				pathWeightLength=-1;
			}
		}
	}while( pathWeightLength>0);
	
	


	[segmentCoreFunc release];
	[self createROIfrom3DPaths:centerlinesList:centerlinesNameList:roilist];
	
	//[self enhanceCenterline:inputData:preservecolormap:centerlinesList];
	free(preservecolormap);

	[centerlinesList removeAllObjects];
	[centerlinesList release];
	[centerlinesNameList removeAllObjects];
	[centerlinesNameList release];
	
		
	
	return 0;
		
}
- (void) enhanceCenterline:(float *)inputData:(unsigned char *)colorData:(NSMutableArray *)pathlists
{
	unsigned int i,j;
	long size,index;
	unsigned char colorIndex;
	size = imageWidth * imageHeight * imageAmount;
	for( index = 0; index < size; index++)
	{
		int noMatch=1;
		for(i=0;i< [outputColorList count];i++)
		{
			
			colorIndex =(unsigned char) [[outputColorList objectAtIndex:i] intValue];
			if(((*(colorData+ index))&0x3f )== colorIndex)	
			{
				noMatch=0;
			}
		}
		if(noMatch)
			*(inputData+ index) = minValueInCurSeries;
		
	}
	
	for(i=0;i<[pathlists count];i++)
		for(j=0;j<[[pathlists objectAtIndex: i] count];j++)
		{
			CMIV3DPoint* aEndPoint=[[pathlists  objectAtIndex: i] objectAtIndex: j];
			int x,y,z;
			x = (int)[aEndPoint x] ;
			y = (int)[aEndPoint y] ;
			z = (int)[aEndPoint z] ;
			if(*(inputData + z*imageWidth * imageHeight + y*imageWidth +x)<5000)
				*(inputData + z*imageWidth * imageHeight + y*imageWidth +x)=5000;
			
		}
	
	
}
- (BOOL) prepareForSkeletonizatin:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData
{
	unsigned char* choosenColorList;
	int choosenColorNumber=[outputColorList count];
	int isAChoosenColor;
	int size;
	size=sizeof(unsigned char)*choosenColorNumber;
	choosenColorList=(unsigned char*)malloc(size);
	size=imageAmount*imageSize;
	int i,j;
	for(i=0;i<choosenColorNumber;i++)
		*(choosenColorList+i) = (unsigned char) [[outputColorList objectAtIndex:i] intValue];
	for(i=0;i<size;i++)
	{
		isAChoosenColor=0;
		for(j=0;j<choosenColorNumber;j++)
			if(*(choosenColorList+j)==((*(colorData+i))&0x3f))
				isAChoosenColor=1;
		if(!isAChoosenColor)
			*(directData+i)=(*(directData+i)) | 0x80;
		
		*(outputData+i)=minValueInCurSeries;
		
	}
	
	if([self plantRootSeeds:inputData :outputData :directData:colorData]<1)
		return NO;
	
		
	free(choosenColorList);
	return YES;
	
	
}

- (int)plantRootSeeds:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData
{
	int seedNumber=0;
	unsigned int i,j;
	NSArray* roiList= [originalViewController roiList] ;
	ROI* tempROI;
	
	int x,y;
	int lefttopx, lefttopy,rightbottomx,rightbottomy;
	int textureOriginX,textureOriginY,textureWidth;
	for(i=0;i<[roiList count];i++)
		for(j=0;j<[[roiList objectAtIndex:i] count];j++)
		{
			tempROI=[[roiList objectAtIndex: i] objectAtIndex: j];
			if([[tempROI comments] isEqualToString: @"root"]&&[tempROI type]==tPlain)
			{
				unsigned char *textureBuffer= [tempROI textureBuffer];
				
				textureOriginX=lefttopx = [tempROI textureUpLeftCornerX];
				textureOriginY=lefttopy = [tempROI textureUpLeftCornerY];
				rightbottomx = [tempROI textureDownRightCornerX]+1;
				rightbottomy = [tempROI textureDownRightCornerY]+1;
				textureWidth = rightbottomx-lefttopx;
				if(lefttopx>rightbottomx)
				{	
					lefttopx = [tempROI textureDownRightCornerX];
					rightbottomx = [tempROI textureUpLeftCornerX];						
				}
				if(lefttopy>rightbottomy)
				{
					lefttopy = [tempROI textureDownRightCornerY];
					rightbottomy = [tempROI textureUpLeftCornerY];
				}
				if(lefttopx<0)
					lefttopx=0;
				if(lefttopy<0)
					lefttopy=0;
				if(rightbottomx>=imageWidth)
					rightbottomx=imageWidth-1;
				if(rightbottomy>=imageHeight)
					rightbottomy=imageHeight-1;
				
				
				for( y = lefttopy; y < rightbottomy ; y++)
					for(x=lefttopx; x < rightbottomx ; x++)
						if(*(textureBuffer+(y-textureOriginY)*textureWidth+x-textureOriginX))
						{
							*(directData+i*imageWidth*imageHeight + y*imageWidth + x)=(*(colorData+i*imageWidth*imageHeight + y*imageWidth + x)) | 0x80;
							*(outputData+i*imageWidth*imageHeight + y*imageWidth + x)=*(inputData+i*imageWidth*imageHeight + y*imageWidth + x);		
							seedNumber++;
						}					
							
							
			}
		}
	return seedNumber;
}
- (void) prepareForCaculateLength:(unsigned short *)distanceMap :(unsigned char *)directData
{
	int size,i;
	size=imageAmount*imageWidth*imageHeight;
	for(i=0;i<size;i++)
	{
		if((*(directData+i)) & 0xC0)
			*(distanceMap+i)=1;
		else
			*(distanceMap+i)=0;
	}
}
- (void) prepareForCaculateWeightedLength:(float *)distanceMap :(unsigned char *)directData
{
	int size,i;
	size=imageAmount*imageWidth*imageHeight;
	for(i=0;i<size;i++)
	{
		if((*(directData+i)) & 0xC0)
			*(distanceMap+i)=1;
		else
			*(distanceMap+i)=0;
	}
	
}
- (int) searchBackToCreatCenterlines:(NSMutableArray *)pathsList:(int)endpointindex:(unsigned char*)directionData:(unsigned char*)color
{
	
	int branchlen=0;
	int x,y,z;
	unsigned char pointerToUpper;
	z = endpointindex/imageSize ;
	y = (endpointindex-imageSize*z)/imageWidth ;
	x = endpointindex-imageSize*z-imageWidth*y;
	
	
	CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
	[new3DPoint setX: x];
	[new3DPoint setY: y];
	[new3DPoint setZ: z];
	[[pathsList lastObject] addObject: new3DPoint];
	
	do{
		if(!(*(directionData + endpointindex)&0x40))
			branchlen++;
		pointerToUpper = ((*(directionData + endpointindex))&0x3f);
		*(directionData + endpointindex)=pointerToUpper|0x40;
		int itemp=0;
		switch(pointerToUpper)
		{
			case 1: itemp =  (-imageSize-imageWidth-1);
				x--;y--;z--;
				break;
			case 2: itemp =  (-imageSize-imageWidth);
				y--;z--;
				break;
			case 3: itemp = (-imageSize-imageWidth+1);
				x++;y--;z--;
				break;
			case 4: itemp = (-imageSize-1);
				x--;z--;
				break;
			case 5: itemp = (-imageSize);
				z--;
				break;
			case 6: itemp = (-imageSize+1);
				x++;z--;
				break;
			case 7: itemp = (-imageSize+imageWidth-1);
				x--;y++;z--;
				break;
			case 8: itemp = (-imageSize+imageWidth);
				y++;z--;
				break;
			case 9: itemp = (-imageSize+imageWidth+1);
				x++;y++;z--;
				break;
			case 10: itemp = (-imageWidth-1);
				x--;y--;
				break;
			case 11: itemp = (-imageWidth);
				y--;
				break;
			case 12: itemp = (-imageWidth+1);
				x++;y--;
				break;
			case 13: itemp = (-1);
				x--;
				break;
			case 14: itemp = 0;
				break;
			case 15: itemp = 1;
				x++;
				break;
			case 16: itemp = imageWidth-1;
				x--;y++;
				break;
			case 17: itemp = imageWidth;
				y++;
				break;
			case 18: itemp = imageWidth+1;
				x++;y++;
				break;
			case 19: itemp = imageSize-imageWidth-1;
				x--;y--;z++;
				break;
			case 20: itemp = imageSize-imageWidth;
				y--;z++;
				break;
			case 21: itemp = imageSize-imageWidth+1;
				x++;y--;z++;
				break;
			case 22: itemp = imageSize-1;
				x--;z++;
				break;
			case 23: itemp = imageSize;
				z++;
				break;
			case 24: itemp = imageSize+1;
				x++;z++;
				break;
			case 25: itemp = imageSize+imageWidth-1;
				x--;y++;z++;
				break;
			case 26: itemp = imageSize+imageWidth;
				y++;z++;
				break;
			case 27: itemp = imageSize+imageWidth+1;
				x++;y++;z++;
				break;
		}
		
		endpointindex+=itemp;
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: x];
		[new3DPoint setY: y];
		[new3DPoint setZ: z];
		[[pathsList lastObject] addObject: new3DPoint];
		
		
		
	}while(!((*(directionData + endpointindex))&0x80));
	
	*color=(*(directionData + endpointindex))&0x3f;
	
	return branchlen;
	
}
- (void)createROIfrom3DPaths:(NSArray*)pathsList:(NSArray*)namesList:(NSMutableArray*)roilist
{
	RGBColor color;
	color.red = 65535;
	color.blue = 0;
	color.green = 0;
	unsigned char * textureBuffer;
	DCMPix* curPix=nil;
	NSArray* pixList=[originalViewController pixList];
	CMIV3DPoint* temp3dpoint;
	NSString* roiName=nil;
	int x,y,z;
	int pointIndex=0;
	unsigned int i,j;
	for(i=0;i<[pathsList count];i++)
	{
		pointIndex=0;
		for(j=0;j<[[pathsList objectAtIndex:i] count];j++)
		{
			temp3dpoint=[[pathsList objectAtIndex:i] objectAtIndex: j];
			x=[temp3dpoint x];
			y=[temp3dpoint y];
			z=[temp3dpoint z];
			roiName=[namesList objectAtIndex: i];
			curPix = [pixList objectAtIndex: z];
			textureBuffer = (unsigned char *) malloc(sizeof(unsigned char ));
			*textureBuffer = 0xff;
			ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:1 textHeight:1 textName:roiName positionX:x positionY:y spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
			
			[[roilist objectAtIndex: z] addObject:newROI];
			[newROI setColor: color];
			NSString *indexstr=[NSString stringWithFormat:@"%d",pointIndex];
			[newROI setComments:indexstr];	
			pointIndex++;
			[newROI release];
		}
		temp3dpoint=[[pathsList objectAtIndex:i] objectAtIndex: 0];
		x=[temp3dpoint x];
		y=[temp3dpoint y];
		z=[temp3dpoint z];
		NSRect roiRect;
		roiRect.origin.x=x;
		roiRect.origin.y=y;
		roiRect.size.width=roiRect.size.height=1;
		ROI *endPointROI = [[ROI alloc] initWithType: t2DPoint :[curPix pixelSpacingX] :[curPix pixelSpacingY] : NSMakePoint( [curPix originX], [curPix originY])];
		[endPointROI setName:roiName];
		[endPointROI setROIRect:roiRect];
		[[roilist objectAtIndex: z] addObject:endPointROI];
		[endPointROI release];
	}
	
}

@end

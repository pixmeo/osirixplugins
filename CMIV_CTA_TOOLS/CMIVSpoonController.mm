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

#import "CMIVSpoonController.h"



@implementation CMIVSpoonController

- (IBAction)applyOperation:(id)sender
{
	
	vtkImageImport		*reader;
	
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	

	
	
	curPix = [pixList objectAtIndex: 0];
	
	float vectors[9];
	[curPix orientation:vectors];			
	float vtkOriginalX = ([curPix originX] ) * vectors[0] + ([curPix originY]) * vectors[1] + ([curPix originZ] )*vectors[2];
	float vtkOriginalY = ([curPix originX] ) * vectors[3] + ([curPix originY]) * vectors[4] + ([curPix originZ] )*vectors[5];
	float vtkOriginalZ = ([curPix originX] ) * vectors[6] + ([curPix originY]) * vectors[7] + ([curPix originZ] )*vectors[8];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	unsigned char *volumeData;
	long size=imageWidth*imageHeight*imageAmount*sizeof(unsigned char);

	
	volumeData= (unsigned char*)malloc(size);
	memset(volumeData,0,size);

	int x,y,z;
	unsigned int i;
	unsigned char *textureBuffer;
	
	for(z=0;z<imageAmount;z++)
	{
		
		[self updateROI:z];
		
		for(i=0;i<[[viewROIList objectAtIndex: z] count];i++)
		{
			
			ROI* tempROI=[[viewROIList objectAtIndex:z] objectAtIndex:i];
			textureBuffer=[tempROI textureBuffer];
			for(y=0;y<[tempROI textureHeight];y++)
				for(x=0;x<[tempROI textureWidth];x++)
					if(*(textureBuffer+y*[tempROI textureWidth]+x))
						*(volumeData+z*imageWidth*imageHeight+(y+[tempROI textureUpLeftCornerY])*imageWidth+x+[tempROI textureUpLeftCornerX])=0xff;
		}
	}
	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, imageWidth-1, 0, imageHeight-1, 0, imageAmount-1);
	reader->SetDataSpacing( [curPix pixelSpacingX], [curPix pixelSpacingY], sliceThickness);
	reader->SetDataOrigin( vtkOriginalX,vtkOriginalY,vtkOriginalZ );
	reader->SetDataExtentToWholeExtent();
	reader->SetDataScalarTypeToUnsignedChar();
	
	reader->SetImportVoidPointer(volumeData);
	
	x=[xRadius intValue];
	y=[yRadius intValue];
	z=[zRadius intValue];



		
	vtkImageOpenClose3D* opener=vtkImageOpenClose3D::New();
	opener->SetInputConnection(reader->GetOutputPort());
	opener->SetOpenValue(255);
	opener->SetCloseValue(0);
	opener->SetKernelSize(x,y,z);
	vtkImageOpenClose3D* closer=vtkImageOpenClose3D::New();
	closer->SetInputConnection(reader->GetOutputPort());
	closer->SetOpenValue(0);
	closer->SetCloseValue(255);
	closer->SetKernelSize(x,y,z);
	
	vtkImageDilateErode3D* eroder = vtkImageDilateErode3D::New();
	eroder->SetInputConnection(reader->GetOutputPort());
	eroder->SetErodeValue(255);
	eroder->SetDilateValue(0);
	eroder->SetKernelSize(x,y,z);

	vtkImageDilateErode3D* dilater = vtkImageDilateErode3D::New();
	dilater->SetInputConnection(reader->GetOutputPort());
	dilater->SetErodeValue(0);
	dilater->SetDilateValue(255);
	dilater->SetKernelSize(x,y,z);
	
	vtkImageData	*tempIm;
	int				imExtent[ 6];
	double		space[ 3], origin[ 3];
	if([operationOption selectedRow] == 2)
	{
		tempIm = opener->GetOutput();
	}
	else if([operationOption selectedRow] == 0)
	{
		tempIm= eroder->GetOutput();
	}
	else if([operationOption selectedRow] == 1)
	{
		tempIm= dilater->GetOutput();
	}
	else if([operationOption selectedRow] == 3)
	{
		tempIm= closer->GetOutput();
	}
	
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( space);
	tempIm->GetOrigin( origin);	
	
	unsigned char* outputVolumeData= (unsigned char*) tempIm->GetScalarPointer();
	
	//tempIm->Delete() ;
	



	NSString *roiName = [NSString stringWithString:@"result"];			
	[resultROIList removeAllObjects];

	for(i=0;i<[pixList count];i++)
	{
		
		textureBuffer=outputVolumeData + imageWidth * imageHeight * i;
		
		ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:imageWidth textHeight:imageHeight textName:roiName positionX:0 positionY:0 spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
		//[newROI reduceTextureIfPossible];
		
		color.red = 0;
		color.green = 0;
		color.blue = 65000;
		[newROI setColor:color];
		
		[resultROIList addObject:newROI];
		[newROI release];
		
	}

	
	free(volumeData);
	reader->Delete() ;
	opener->Delete() ;
	closer->Delete() ;
	eroder->Delete() ;
	dilater->Delete();

	free(outputVolumeData);
	
	[originalViewController endWaitWindow: waitWindow];
	
	[binaryOrROIOption deselectAllCells];
	[binaryOrROIOption selectCellWithTag:1];
	if([[existedROI itemArray] count] <= [existedMaskList count])
		[existedROI addItemWithTitle: roiName];
	[existedROI setEnabled: YES];
	[existedROI selectItemAtIndex:[[existedROI itemArray] count]-1];

	
	[self selectANewROI:nil];
    
	
}

- (IBAction)cancelDialog:(id)sender
{
	[window setReleasedWhenClosed:YES];
	[window close];
//	[window orderOut:sender];
	
    [NSApp endSheet:window returnCode:[sender tag]];
	[resultROIList removeAllObjects];
	[viewROIList removeAllObjects];
	[existedMaskList removeAllObjects];
	[resultROIList release];
	[viewROIList release];
	[existedMaskList release];

	unsigned int i;
	for( i = 0; i < [toolbarList count]; i++)
	{
		[[toolbarList objectAtIndex: i] setVisible: YES];
		
	}
	[toolbarList removeAllObjects];
	[toolbarList release];
	[parent exitCurrentDialog];

}
- (IBAction)exportImages:(id)sender
{

	if([exportOption selectedRow]==0)
	{	
		unsigned int i,j;	


		for(i=0;i<[pixList count];i++)
		{
			[self updateROI:i];
			

				for(j=0;j<[[controllorROIList objectAtIndex: i] count];j++)
					if([[[[controllorROIList objectAtIndex: i] objectAtIndex:  j] name] isEqualToString:[maskName stringValue]] ) 
					{
						[[controllorROIList objectAtIndex: i] removeObjectAtIndex:j];
						j--;
					}
	
			
			for(j=0;j<[[viewROIList objectAtIndex: i] count];j++)
			{
				ROI* tempROI=[[viewROIList objectAtIndex: i] objectAtIndex:j];
				[tempROI setName: [maskName stringValue]];
				[[controllorROIList objectAtIndex: i] addObject: tempROI];
			}
		}
	}
	else 
	{
		unsigned int i,j;
		long imageSize=imageWidth*imageHeight;
		ViewerController* new2DViewer ;
		unsigned char* maskBuffer= (unsigned char*)malloc(imageSize);
		unsigned char* textureBuffer;
		long size=sizeof(float)*imageSize*imageAmount;
		float *volumeData=(float*)malloc(size);
		
		if(!volumeData||!maskBuffer)
		{
			NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return;
		}
		
		float *inputData=[originalViewController volumePtr:0];
		memcpy(volumeData,inputData,size);

		float minValue=[curPix minValueOfSeries];
		int x,y;
		for(i=0;i<[pixList count];i++)
		{
			memset(maskBuffer,0,imageSize) ;
			[self updateROI:i];
			for(j=0;j<[[viewROIList objectAtIndex: i] count];j++)
			{
				
				ROI* tempROI=[[viewROIList objectAtIndex:i] objectAtIndex:j];
				textureBuffer=[tempROI textureBuffer];
				for(y=0;y<[tempROI textureHeight];y++)
					for(x=0;x<[tempROI textureWidth];x++)
						if(*(textureBuffer+y*[tempROI textureWidth]+x))
							*(maskBuffer + (y+[tempROI textureUpLeftCornerY])*imageWidth + x+[tempROI textureUpLeftCornerX])=0xff;
			}
			int ii;
			if([exportOption selectedRow]==2)
			{
				for(ii=0;ii<imageSize;ii++)
					if(*(maskBuffer+ii))
						*(volumeData+i*imageSize+ii)=minValue;
			}
			else if([exportOption selectedRow]==1)
			{
				for(ii=0;ii<imageSize;ii++)
					if((*(maskBuffer+ii))==0)
						*(volumeData+i*imageSize+ii)=minValue;
				
			}
		}
		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
		NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
		NSData	*newData = [NSData dataWithBytesNoCopy:volumeData length: size freeWhenDone:YES];
		int z;
		for( z = 0 ; z < imageAmount; z ++)
		{
			curPix = [pixList objectAtIndex: z];
			DCMPix	*copyPix = [curPix copy];
			[newPixList addObject: copyPix];
			[copyPix release];
			[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
			
			[[newPixList lastObject] setfImage: (float*) (volumeData + imageSize * z)];
		}
		new2DViewer = [originalViewController newWindow	:newPixList
														:newDcmList
														:newData];  
		
		[[originalViewController imageView] setIndex: [imageSlider intValue]];
		free(maskBuffer);
	}

	

	[self cancelDialog:nil];
	
}
- (IBAction)deleteCurrentMask:(id)sender
{
	if([binaryOrROIOption selectedRow]==1)
	{
		int index=[existedROI indexOfSelectedItem];
		if((unsigned int)index<[existedMaskList count])
		{
			unsigned int i,j;	
			
			
			for(i=0;i<[pixList count];i++)
			{
				
				
				for(j=0;j<[[controllorROIList objectAtIndex: i] count];j++)
					if([[[[controllorROIList objectAtIndex: i] objectAtIndex:  j] name] isEqualToString:[maskName stringValue]] ) 
					{
						[[controllorROIList objectAtIndex: i] removeObjectAtIndex:j];
						j--;
					}
			}
			[existedMaskList removeObjectAtIndex: index];
						
			
		}
		else
		{
			[resultROIList removeAllObjects];
			
		}
			
		[existedROI removeItemAtIndex:index];

		if(index>0)
			index--;
		[existedROI selectItemAtIndex:index];
		[self selectANewROI:nil];
			
	}
}
- (IBAction)goNextStep:(id)sender
{
}
- (int) showSpoonPanel:(ViewerController *) vc :(CMIV_CTA_TOOLS*) owner
{
	int err=0;
	isFirstTime=1;
	isShowingResult=0;
	originalViewController=vc;	
	parent = owner;
	curPix = [[originalViewController pixList] objectAtIndex: [[originalViewController imageView] curImage]];
	pixList = [originalViewController pixList];
	controllorROIList = [originalViewController roiList];
	NSArray             *fileList =[originalViewController fileList ];

	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [pixList count];
	
	if( [curPix isRGB])
	{
		NSRunAlertPanel(NSLocalizedString(@"no RGB Support", nil), NSLocalizedString(@"This plugin doesn't surpport RGB images, please convert this series into BW images first", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 0;
	}	
	[NSBundle loadNibNamed:@"Spoon_Panel" owner:self];
	
	viewROIList = [[NSMutableArray alloc] initWithCapacity: 0];
	resultROIList = [[NSMutableArray alloc] initWithCapacity: 0];
	unsigned int i;
	for( i = 0; i < [pixList count]; i++)
	{
		[viewROIList addObject:[NSMutableArray arrayWithCapacity:0]];
	}
	color.red = 0;
	color.green = 0;
	color.blue = 65000;
	
	[self initExistedMaskList];
	
	
	[viewer setDCM:pixList :fileList :viewROIList :0 :'i' :YES];
	[viewer setIndexWithReset: [pixList count]/2 :YES];
	[viewer setOrigin: NSMakePoint(0,0)];
	[viewer setCurrentTool:tWL];
	[viewer  scaleToFit];

	
	[xRadius setIntValue:10];
	[yRadius setIntValue:10];
	[zRadius setIntValue:10];
	
	[imageSlider setMaxValue: [pixList count]-1];
	
	[imageSlider setIntValue:[pixList count]/2];	
	float upperThreshold = [curPix maxValueOfSeries];
	float lowerThreshold = [curPix minValueOfSeries];
	
	[thresholdSlider setMaxValue:upperThreshold];
	[thresholdSlider setMinValue:lowerThreshold];
	[thresholdSlider setFloatValue: 100];
	[thresholdText setFloatValue: 100.0];
	
	[self pageDownorUp:0L];
	
	[NSApp beginSheet: window modalForWindow:[originalViewController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	NSArray				*winList = [NSApp windows];
	toolbarList = [[NSMutableArray alloc] initWithCapacity: 0];
	for( i = 0; i < [winList count]; i++)
	{
		if( [[winList objectAtIndex:i] toolbar])
		{
			NSToolbar *aToolbar=[[winList objectAtIndex:i] toolbar];
			if([aToolbar isVisible])
			{
				[toolbarList addObject: aToolbar];
				[aToolbar setVisible:NO];
			}
			
			
		}
		
	}
	[maskName setStringValue:[NSString stringWithString:@"result"]];
	return err;
	
}

- (IBAction)setThreshold:(id)sender
{
	[thresholdText setFloatValue: [thresholdSlider floatValue] ];
	[self pageDownorUp:0L];
}
- (IBAction)setBinaryOrROI:(id)sender
{

	if([binaryOrROIOption selectedRow]==0)
	{
		[existedROI setEnabled: NO];
		[deleteCurrentSeries setEnabled: NO];		
		color.red = 0;
		color.green = 0;
		color.blue = 65000;
		[maskName setStringValue:[NSString stringWithString:@"result"]];
		[self pageDownorUp:0L];
	}
	else
	{
		if([[existedROI itemArray] count]<=0)
		{
			[binaryOrROIOption deselectAllCells];
			[binaryOrROIOption selectCellWithTag:0];

			[self pageDownorUp:0L];
						
		}
		else
		{
			[existedROI setEnabled: YES];
			[deleteCurrentSeries setEnabled: YES];
			[self selectANewROI:nil];
			
		}
	}

}
- (IBAction)selectANewROI:(id)sender
{
	[maskName setStringValue:[existedROI titleOfSelectedItem] ];
	[self pageDownorUp:0L];
}

- (IBAction)pageDownorUp:(id)sender
{
	int index= [imageSlider intValue];
	[self updateROI:index];
	[viewer setIndex: index];
//	[viewer setIndex: index];
}
- (void) initExistedMaskList
{
	unsigned int i,j,k;
	int thereIsSameName ;
	NSMutableArray *curRoiList = [originalViewController roiList];
	ROI * tempROI;
	existedMaskList = [[NSMutableArray alloc] initWithCapacity: 0];
	[existedROI removeAllItems];
	
	for(i=0;i<[curRoiList count];i++)
		for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
		{
			tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
			if([tempROI type]==tPlain)
			{
				thereIsSameName=0;
				for(k=0;k<[existedMaskList count];k++)
				{ 
					if ([[tempROI name] isEqualToString:[existedMaskList objectAtIndex: k] ]==YES)
						thereIsSameName=1;
				}
				if(!thereIsSameName)
				{
					[existedMaskList addObject:[tempROI name]];
					[existedROI addItemWithTitle: [tempROI name]];
				}	
			}
				
		}
			if([existedMaskList count]>0)
				[existedROI selectItemAtIndex:0];
	
}
- (void)updateROI:(int)imageIndex
{

	if([binaryOrROIOption selectedRow]==0)
	{
		unsigned char *textureBuffer;

		[[viewROIList objectAtIndex: imageIndex] removeAllObjects];
		curPix = [pixList objectAtIndex: imageIndex];
		float *srcImage = [curPix  fImage];
		float thresholdValue = [thresholdSlider floatValue];
		thresholdValue = round ( thresholdValue );
		vImage_Buffer			srcf, dst8;
		srcf.data = srcImage;
		textureBuffer= (unsigned char*) malloc(imageWidth*imageHeight);
		srcf.height =  imageHeight;
		srcf.width = imageWidth;
		srcf.rowBytes = imageWidth*sizeof(float);
		dst8.data = textureBuffer;
		dst8.height =  imageHeight;
		dst8.width = imageWidth;
		dst8.rowBytes = imageWidth*sizeof(unsigned char);
		vImageConvert_PlanarFtoPlanar8( &srcf,&dst8, thresholdValue,thresholdValue-1,0);
		NSString *roiName = [NSString stringWithString:@"result"];	
		ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:imageWidth textHeight:imageHeight textName:roiName positionX:0 positionY:0 spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
		[newROI setColor:color];
		[[viewROIList objectAtIndex: imageIndex] addObject: newROI];	
		[newROI release];
		free(textureBuffer);
	}
	else
	{
		unsigned char *textureBuffer, *oldTexture;

		[[viewROIList objectAtIndex: imageIndex] removeAllObjects];
		curPix = [pixList objectAtIndex: imageIndex];
		float *srcImage = [curPix  fImage];
		float thresholdValue = [thresholdSlider floatValue];
		thresholdValue = round ( thresholdValue );
		unsigned int i;
		NSString *roiName;
		ROI *tempROI;
		
		if((unsigned int)[existedROI indexOfSelectedItem]<[existedMaskList count])
		{
			
			for(i=0;i<[[controllorROIList objectAtIndex: imageIndex] count];i++)
			{

				tempROI=[[controllorROIList objectAtIndex: imageIndex] objectAtIndex:i];
				roiName=[tempROI name];
				if([roiName isEqualToString:[existedMaskList objectAtIndex: [existedROI indexOfSelectedItem] ]] && [tempROI type]==tPlain)
				{
					textureBuffer=(unsigned char*)malloc([tempROI textureWidth]*[tempROI textureHeight]);
					int x,y;
					oldTexture=[tempROI textureBuffer];
					for(y=0;y<[tempROI textureHeight];y++)
						for(x=0;x<[tempROI textureWidth];x++)
							if((*(oldTexture+y*[tempROI textureWidth]+x))&&*(srcImage+(y+[tempROI textureUpLeftCornerY])*imageWidth+x+[tempROI textureUpLeftCornerX])>thresholdValue)
								*(textureBuffer+y*[tempROI textureWidth]+x)=0xff;
							else
								*(textureBuffer+y*[tempROI textureWidth]+x)=0x00;
					ROI *newROI= [[ROI alloc] initWithTexture:textureBuffer textWidth:[tempROI textureWidth] textHeight:[tempROI textureHeight]  textName:[tempROI name] positionX:[tempROI textureUpLeftCornerX] positionY:[tempROI textureUpLeftCornerY] spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
					
					if([tempROI respondsToSelector:@selector(rgbcolor)])
						color= [tempROI rgbcolor];
					[newROI setColor:color];

					[[viewROIList objectAtIndex: imageIndex] addObject: newROI];	
					[newROI release];
					free(textureBuffer);
				}

			}	
		}
		else
		{
			
				
			tempROI=[resultROIList objectAtIndex: imageIndex];
			roiName=[tempROI name];

			textureBuffer=(unsigned char*)malloc([tempROI textureWidth]*[tempROI textureHeight]);
			int x,y;
			oldTexture=[tempROI textureBuffer];
			for(y=0;y<[tempROI textureHeight];y++)
				for(x=0;x<[tempROI textureWidth];x++)
					if((*(oldTexture+y*[tempROI textureWidth]+x))&&*(srcImage+(y+[tempROI textureUpLeftCornerY])*imageWidth+x+[tempROI textureUpLeftCornerX])>thresholdValue)
						*(textureBuffer+y*[tempROI textureWidth]+x)=0xff;
					else
						*(textureBuffer+y*[tempROI textureWidth]+x)=0x00;
			ROI *newROI= [[ROI alloc] initWithTexture:textureBuffer textWidth:[tempROI textureWidth] textHeight:[tempROI textureHeight]  textName:[tempROI name] positionX:[tempROI textureUpLeftCornerX] positionY:[tempROI textureUpLeftCornerY] spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
			if([tempROI respondsToSelector:@selector(rgbcolor)])
				color= [tempROI rgbcolor];
			[newROI setColor:color];
			
			[[viewROIList objectAtIndex: imageIndex] addObject: newROI];	
			[newROI release];
			free(textureBuffer);

				

		}
	}
	

}

@end

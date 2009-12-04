/*=========================================================================
 Author: Chunliang Wang (chunliang.wang@imv.liu.se)
 
 
 Program:  CMIV CTA image processing Plugin for OsiriX
 
 This file is part of CMIV CTA image processing Plugin for OsiriX.
 
 Copyright (c) 2007,
 Center for Medical Image Science and Visualization (CMIV),
 Linköping University, Sweden, http://www.cmiv.liu.se/
 
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


#import "CMIV_AutoSeeding.h"
#import "CMIVAutoSeedingCore.h"
#import "CMIVSegmentCore.h"
#include <Accelerate/Accelerate.h>
#import "CMIV3DPoint.h"
#import "browserController.h"
#define TOPOTHERSEEDS 4
#define BOTTOMOTHERSEEDS 5
@implementation CMIV_AutoSeeding
-(int)runAutoSeeding:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(NSArray*)pixList:(float*)volumePtr:(BOOL)ribRemoval:(BOOL)centerlineTracking:(BOOL)needVesselEnhance
{
	parent=owner;
	if(vc)
	{
		originalViewController=vc;
		
	}
	else
	{
		originalViewController=nil;
		
	}
	[parent cleanDataOfWizard];
	int err=0;

	controllersPixList=pixList;
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];

	if( [curPix isRGB])
	{
		return 0;
	}	



	long origin[3],dimension[3],newdimension[3];
	float spacing[3];
	dimension[0] = [curPix pwidth];
	dimension[1] = [curPix pheight];
	dimension[2] = [controllersPixList count];	
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [controllersPixList count];	
	imageSize= imageWidth*imageHeight;
	
	origin[0]=origin[1]=origin[2]=0;
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;

	volumeData=volumePtr;
	unsigned char* markerdata=(unsigned char* )malloc(imageWidth*imageHeight*imageAmount*sizeof(unsigned char));
	if(markerdata==nil)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 0;
	}	
	memset(markerdata,0x00,imageWidth*imageHeight*imageAmount*sizeof(unsigned char));
//	[self readROIFromViewer:markerdata];
	id waitWindow;
	if(originalViewController)
	 waitWindow=[originalViewController startWaitWindow:@"processing"];
	CMIVAutoSeedingCore* coreAlgorithm=[[CMIVAutoSeedingCore alloc] init];
	float lungthreshold = [curPix minValueOfSeries];
	if(lungthreshold<-300)
		lungthreshold=-300;
	else
		lungthreshold=700;
	NSLog( @"heart segment ");
	if(ribRemoval)
	{
		[coreAlgorithm autoCroppingBasedOnLungSegment:volumeData:markerdata:lungthreshold:20:origin:dimension:spacing:1.0];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];
		[self replaceOriginImage:markerdata];
	}	
	
	float targetspacing=2.0;
	 newdimension[0]=dimension[0]*spacing[0]/targetspacing;
	 newdimension[1]=dimension[1]*spacing[1]/targetspacing;
	 newdimension[2]=dimension[2]*spacing[2]/targetspacing;
	float* smallVolumeData=(float*)malloc(newdimension[0]*newdimension[1]*newdimension[2]*sizeof(float));
	
	if(smallVolumeData)
	{
		NSLog( @"finding aortat ");
		
		[self resampleImage:volumeData:smallVolumeData:dimension:newdimension];
		float newspacing[3];
		newspacing[0]=newspacing[1]=newspacing[2]=targetspacing;
		float radius=[coreAlgorithm findAorta:smallVolumeData:origin:newdimension:newspacing];
		if(radius<=0)
			err=1;

		//CMIV3DPoint* aNewCircle=[[CMIV3DPoint alloc] init];
		//aNewCircle.x=origin[0]*targetspacing;
		//aNewCircle.y=origin[1]*targetspacing;
		//aNewCircle.z=origin[2]*targetspacing;
		//aNewCircle.fValue=radius*targetspacing;
		NSMutableDictionary* dic=[parent dataOfWizard];

		[dic setObject:[NSNumber numberWithFloat:origin[0]*targetspacing] forKey:@"AortaPointx"];
	
		[dic setObject:[NSNumber numberWithFloat:origin[1]*targetspacing] forKey:@"AortaPointy"];

		[dic setObject:[NSNumber numberWithFloat:origin[2]*targetspacing] forKey:@"AortaPointz"];

		[dic setObject:[NSNumber numberWithFloat:radius*targetspacing] forKey:@"AortaPointr"];

		//[aNewCircle release];
		free(smallVolumeData);
		radius=radius/2;
		aortaMaxHu=[coreAlgorithm caculateAortaMaxIntensity:(volumeData+imageSize*((int)(origin[2]*targetspacing/spacing[2]))):imageWidth:imageHeight:origin[0]*targetspacing/spacing[0]:origin[1]*targetspacing/spacing[1]:radius*targetspacing/spacing[0]];
		NSLog( @"tracing aortat ");
		unsigned short* seedData=(unsigned short*)malloc(dimension[0]*dimension[1]*dimension[2]*sizeof(unsigned short));

		if(seedData)
		{
			float aortaStartPt[3];
			aortaStartPt[0]=(float)origin[0]*targetspacing/spacing[0];
			aortaStartPt[1]=(float)origin[1]*targetspacing/spacing[1];
			aortaStartPt[2]=(float)origin[2]*targetspacing/spacing[2];
			float aortathreshold=150;
			if(aortaMaxHu>550)
				aortathreshold=aortaMaxHu-400;
			[coreAlgorithm crossectionGrowingWithinVolume:volumeData ToSeedVolume:seedData Dimension:dimension Spacing:spacing StartPt:aortaStartPt Threshold:aortathreshold Diameter:50.0];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];
			int lastVoxelIndex=dimension[0]*dimension[1]*dimension[2]-1;
			int i;
			for( i=0;i<imageSize;i++)
			{
				seedData[i]=TOPOTHERSEEDS;
				seedData[lastVoxelIndex-i]=BOTTOMOTHERSEEDS;
			}
			
			[self saveCurrentSeeds: seedData:dimension[0]*dimension[1]*dimension[2]*sizeof(short)];
			
			if(centerlineTracking||needVesselEnhance)
				err=[self createCoronaryVesselnessMap: vc:  owner:1.0:2.5:0.5:1.0:aortaMaxHu:YES];
			if(centerlineTracking)
			{
				vesselnessMapData=[dic objectForKey:@"VesselnessMap"];
				[vesselnessMapData retain];
				[self enhanceVolumeWithVesselness];
				[self runSegmentationAndSkeletonization:seedData:volumeData];
				[self deEnhanceVolumeWithVesselness];
				[vesselnessMapData release];
			}
			free(seedData);
		}
		
	}
	else
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
	//	return 0;
	}

	[coreAlgorithm release];
	if(vc)
		[originalViewController endWaitWindow: waitWindow];
	NSLog( @"finish up");
	//[self exportResults:markerdata:origin:dimension];

	
	
	free(markerdata);
	
//	err=[self createCoronaryVesselnessMap: vc:  owner:1.0:2.5:0.5:1.0:aortaMaxHu];
//	
//	NSMutableDictionary* dic=[parent dataOfWizard];
//	[dic setObject:[NSString stringWithString:@"Step1"] forKey:@"Step"];
//	[parent saveCurrentStep];
	[parent cleanDataOfWizard];
	return err;
	
	
	
}
- (void)saveCurrentSeeds: (unsigned short*)seedData:(int)size
{
	[parent cleanDataOfWizard];
	NSData	*newData = [NSData dataWithBytesNoCopy:seedData length:(NSUInteger)size freeWhenDone:NO];
	NSMutableDictionary* dic=[parent dataOfWizard];
	[dic setObject:newData forKey:@"SeedMap"];
	
	NSMutableArray* contrastList= [NSMutableArray arrayWithCapacity:0];
	NSMutableDictionary *contrast;
	contrast = [NSMutableDictionary dictionary];
	[contrast setObject:[NSString stringWithString:@"other"]  forKey:@"Name"];
	[contrast setObject: [NSColor yellowColor] forKey:@"Color"];
	[contrast setObject: [NSNumber numberWithFloat:3.0] forKey:@"BrushWidth"];
	[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
	[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
	[contrastList addObject: contrast];
	
	contrast = [NSMutableDictionary dictionary];
	[contrast setObject:[NSString stringWithString:@"barrier"]  forKey:@"Name"];
	[contrast setObject: [NSColor purpleColor] forKey:@"Color"];
	[contrast setObject: [NSNumber numberWithFloat:1.0] forKey:@"BrushWidth"];
	[contrast setObject: [NSNumber numberWithInt:6] forKey:@"CurrentTool"];
	[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
	[contrastList addObject: contrast];
	
	contrast = [NSMutableDictionary dictionary];
	[contrast setObject:[NSString stringWithString:@"Aorta"]  forKey:@"Name"];
	[contrast setObject: [NSColor greenColor] forKey:@"Color"];
	[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
	[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
	[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
	[contrastList addObject: contrast];
	
	
	[dic setObject:contrastList forKey:@"ContrastList"];

	
	NSMutableArray* seedsnamearray=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* rootseedsarray=[NSMutableArray arrayWithCapacity:0];
	[seedsnamearray addObject:[NSString stringWithString:@"Aorta"]];
	[seedsnamearray addObject:[NSString stringWithString:@"barrier"]];
	[seedsnamearray addObject:[NSString stringWithString:@"other"]];
	[seedsnamearray addObject:[NSString stringWithString:@"other"]];
	[seedsnamearray addObject:[NSString stringWithString:@"other"]];
	[rootseedsarray addObject:[NSNumber numberWithInt:0]];

	[dic setObject:seedsnamearray forKey:@"SeedNameArray"];
	[dic setObject:rootseedsarray forKey:@"RootSeedArray"];
	//[dic setObject:[NSNumber numberWithInt:uniIndex] forKey:@"UniIndex"];
	
	NSString* seriesUid=[[[controllersPixList objectAtIndex:0] seriesObj] valueForKey:@"seriesInstanceUID"];
	[parent saveIntermediateData:seriesUid];
	[parent cleanDataOfWizard];
}

-(void)replaceOriginImage:(unsigned char*)outData
{
	DCMPix* curPix;
	curPix = [controllersPixList objectAtIndex: 0];
	float minValueInCurSeries = [curPix minValueOfSeries];
	long size=imageAmount*imageWidth*imageHeight;
	long i;
	/*
	for(i=0;i<size;i++)
			volumeData[i]=outData[i];*/

	for(i=0;i<size;i++)
		if(!outData[i])
			volumeData[i]=minValueInCurSeries;
	if(originalViewController)
	{
		DCMView* origninImageView=[originalViewController imageView];
		float wl,ww;
		[origninImageView getWLWW:&wl :&ww];
		[origninImageView setWLWW:wl :ww];
	}
}


-(int)resampleImage:(float*)input:(float*)output:(long*)indimesion:(long*)outdimesion
{
	vImage_Buffer	srcVimage, dstVimage;
	int outImageWidth,outImageHeight,outImageSize,outImageAmount;
	int i;
	int inImageWidth=indimesion[0], inImageHeight=indimesion[1], inImageAmount=indimesion[2];
	outImageWidth=outdimesion[0];
	outImageHeight=outdimesion[1];
	outImageSize=outImageWidth*outImageHeight;
	outImageAmount=outdimesion[2];
	
	float* tempVolume=(float*)malloc(outImageWidth*outImageHeight*inImageAmount*sizeof(float));
	if(!tempVolume)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return 1;
	}
	
	for(i=0;i<inImageAmount;i++)
	{
		
		srcVimage.data = input+inImageWidth*inImageHeight*i;
		srcVimage.height =  inImageHeight;
		srcVimage.width = inImageWidth;
		srcVimage.rowBytes = inImageWidth*sizeof(float);
		
		dstVimage.data = tempVolume + outImageSize * i;
		dstVimage.height =  outImageHeight;
		dstVimage.width = outImageWidth;
		dstVimage.rowBytes = outImageWidth*sizeof(float);
		vImageScale_PlanarF( &srcVimage, &dstVimage, 0L,0);
	}
	
	srcVimage.data = tempVolume;
	srcVimage.height =  inImageAmount;
	srcVimage.width = outImageSize;
	srcVimage.rowBytes = outImageSize*sizeof(float);
	
	dstVimage.data = output;
	dstVimage.height =  outImageAmount;
	dstVimage.width = outImageSize;
	dstVimage.rowBytes = outImageSize*sizeof(float);
	vImageScale_PlanarF( &srcVimage, &dstVimage, 0L, 0);
	
	free(tempVolume);
	return 0;
	
}
- (void) runSegmentationAndSkeletonization:(unsigned short*)seedData:(float*)volumeData1
{
	
	long size =  imageWidth * imageHeight * imageAmount;
	
	size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	float               *inputData=0L, *outputData=0L;
	unsigned char       *colorData=0L, *directionData=0L;
	inputData = volumeData1;
	NSLog( @"start step 3");
	outputData = (float*) malloc( size);
	if( !outputData)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return ;	
	}
	size = sizeof(char) * imageWidth * imageHeight * imageAmount;
	colorData = (unsigned char*) malloc( size);
	if( !colorData)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free(outputData);
		return ;	
	}	
	directionData= (unsigned char*) malloc( size);
	if( !directionData)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free(outputData);
		free(colorData);
		
		return ;	
	}		
	

	
	memset(directionData,0,size);
	int i;
	size=imageWidth * imageHeight * imageAmount;
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];
	float minValueInCurSeries = [curPix minValueOfSeries]-1;
	float maxValueInCurSeries= [curPix maxValueOfSeries];
	float spacing[3];
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;
	float minSpacing=spacing[0];
	if(minSpacing>spacing[1])minSpacing=spacing[1];
	if(minSpacing>spacing[2])minSpacing=spacing[2];
	minSpacing/=2;
	for(i=0;i<size;i++)
		*(outputData+i)=minValueInCurSeries;
	
	[self useSeedDataToInitializeDirectionData:seedData:inputData:outputData:directionData:size];

	//start seed growing	
	CMIVSegmentCore *segmentCoreFunc = [[CMIVSegmentCore alloc] init];
	[segmentCoreFunc setImageWidth:imageWidth Height: imageHeight Amount: imageAmount Spacing:spacing];
	
	[segmentCoreFunc startShortestPathSearchAsFloat:inputData Out:outputData :colorData Direction: directionData];
	//initilize the out and color buffer
	memset(colorData,0,size);
	[segmentCoreFunc caculateColorMapFromPointerMap:colorData:directionData]; 
//	for(i=0;i<size;i++)
//	{
//		seedData[i]=colorData[i];
//	}
//	[self saveCurrentSeeds: seedData:imageWidth * imageHeight * imageAmount*sizeof(short)];
//		return;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"CMIVLeveIndicatorStep" object:self userInfo: nil];

	for(i=0;i<size;i++)
		if(colorData[i]!=AORTAMARKER)
		{
			directionData[i]=0x80|BARRIERMARKER;
			outputData[i]=minValueInCurSeries;
			//inputData[i]=-10000;
		}
	free(colorData);
	size=imageWidth * imageHeight * imageAmount*sizeof(short);
	memset(seedData,0,size);
	unsigned short*pdismap=seedData;
	{
		[self prepareForCaculateLength:pdismap:directionData];
		size=imageWidth * imageHeight * imageAmount*sizeof(float);
		memset(outputData,0x00,size);//localOptmizeConnectednessTree using outputData+=mean(inputData)
		[segmentCoreFunc localOptmizeConnectednessTree:inputData :outputData :pdismap Pointer: directionData :minValueInCurSeries needSmooth:YES];
		[self prepareForCaculateLength:pdismap:directionData];
		[segmentCoreFunc localOptmizeConnectednessTree:inputData :outputData :pdismap Pointer: directionData :minValueInCurSeries needSmooth:NO];
		[self prepareForCaculateLength:pdismap:directionData];
		[segmentCoreFunc localOptmizeConnectednessTree:inputData :outputData :pdismap Pointer: directionData :minValueInCurSeries needSmooth:NO];
	}
	int unknownCenterlineCounter=0;
	NSMutableArray* centerlinesList=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* centerlinesNameList=[NSMutableArray arrayWithCapacity:0];
	
	
	float skeletonParaLengthThreshold=[[NSUserDefaults standardUserDefaults] floatForKey:@"CMIVSkeletonParameterLengthThreshold"];
	float skeletonParaEndHuThreshold=[[NSUserDefaults standardUserDefaults] floatForKey:@"CMIVSkeletonParameterBranchEndThreshold"];
	if(skeletonParaLengthThreshold<5.0)
		skeletonParaLengthThreshold=10.0;
	if(skeletonParaEndHuThreshold<=0.0)
		skeletonParaEndHuThreshold=100.0;
	float pathWeightLength=0;
	float weightThreshold=skeletonParaEndHuThreshold;
	float lengthThreshold=skeletonParaLengthThreshold/minSpacing;
	{
		do
		{
			NSLog( @"finding new branches");
			[self prepareForCaculateWightedLength:outputData:directionData];
			int endindex=[segmentCoreFunc caculatePathLengthWithWeightFunction:inputData:outputData Pointer: directionData:weightThreshold:maxValueInCurSeries];
			pathWeightLength = *(outputData+endindex);
			if(endindex>0)
			{
				NSMutableArray* apath=[NSMutableArray arrayWithCapacity:0];
				int len=[self searchBackToCreatCenterlines: apath: endindex:directionData];
				if(len >= lengthThreshold)
				{
//					if(colorindex!=AORTAMARKER)
//						continue;
					[centerlinesNameList addObject: [NSString stringWithFormat:@"coronary%d",unknownCenterlineCounter++] ];
					[centerlinesList addObject:apath];
				}
				else
					break;
				
			}
		}while( pathWeightLength>0);
	}
	[segmentCoreFunc release];
	free(outputData);
	free(directionData);
	[self saveCenterlinesToPatientCoordinate:centerlinesList:centerlinesNameList];
	
	
}

- (void) saveCenterlinesToPatientCoordinate:(NSArray*)centerlines:(NSArray*)centerlinesNameList
{
	float inversedvector[9],vector[9];

	DCMPix	*curPix=[controllersPixList objectAtIndex: 0];
	[curPix orientation:vector];
	[self inverseMatrix:vector:inversedvector];
	
	float	vtkOriginalX = ([curPix originX] ) * vector[0] + ([curPix originY]) * vector[1] + ([curPix originZ] )*vector[2];
	float	vtkOriginalY = ([curPix originX] ) * vector[3] + ([curPix originY]) * vector[4] + ([curPix originZ] )*vector[5];
	float	vtkOriginalZ = ([curPix originX] ) * vector[6] + ([curPix originY]) * vector[7] + ([curPix originZ] )*vector[8];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}

	float	xSpacing=[curPix pixelSpacingX];
	float	ySpacing=[curPix pixelSpacingY];
	float	zSpacing=sliceThickness;
	
	CMIV3DPoint* temppoint;
	float x,y,z;
	unsigned int i,j;
	for(i=0;i<[centerlines count];i++)
		for(j=0;j<[[centerlines objectAtIndex: i] count];j++)
		{
			temppoint=[[centerlines objectAtIndex:i] objectAtIndex: j];
			x= [temppoint x];
			y= [temppoint y];
			z= [temppoint z];
			[temppoint setX: vtkOriginalX + x*xSpacing+xSpacing*0.5];
			[temppoint setY: vtkOriginalY + y*ySpacing+ySpacing*0.5];
			[temppoint setZ: vtkOriginalZ + z*zSpacing+zSpacing*0.5];
			
		}
	
	//////////////////////////////////////////////////////////////


	float originpat[3],origin[3];
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];

	NSMutableArray* cpr3DPathsForSave=[NSMutableArray arrayWithCapacity:0];
	for(i=0;i<[centerlines count];i++)
	{
		NSMutableArray* anewcenterline=[NSMutableArray arrayWithCapacity:0];
		for(j=0;j<[[centerlines objectAtIndex:i] count];j++)
		{
			CMIV3DPoint* apoint=[[centerlines objectAtIndex:i] objectAtIndex:j];
			float x,y,z,ptx,pty,ptz;
			x=[apoint x];
			y=[apoint y];
			z=[apoint z];
			ptx = x * inversedvector[0] + y * inversedvector[1] + z*inversedvector[2];
			pty = x * inversedvector[3] + y * inversedvector[4] + z*inversedvector[5];
			ptz = x * inversedvector[6] + y * inversedvector[7] + z*inversedvector[8];	
			[anewcenterline addObject:[NSNumber numberWithFloat:ptx]];
			[anewcenterline addObject:[NSNumber numberWithFloat:pty]];
			[anewcenterline addObject:[NSNumber numberWithFloat:ptz]];
		}
		[cpr3DPathsForSave addObject:anewcenterline];
	}
	[parent cleanDataOfWizard];
	NSMutableDictionary* dic=[parent dataOfWizard];
	
	[dic setObject:cpr3DPathsForSave forKey:@"CenterlineArrays"];
	[dic setObject:centerlinesNameList forKey:@"CenterlinesNames"];
	NSString* seriesUid=[[[controllersPixList objectAtIndex:0] seriesObj] valueForKey:@"seriesInstanceUID"];
	[parent saveIntermediateData:seriesUid];



	
}
- (int)inverseMatrix:(float*)inm :(float*)outm
{
	float detinm=inm[0]*inm[4]*inm[8]+inm[1]*inm[5]*inm[6]+inm[2]*inm[3]*inm[7]-inm[2]*inm[4]*inm[6]-inm[1]*inm[3]*inm[8]-inm[0]*inm[5]*inm[7];
	if(detinm==0) return 0;
	outm[0]=inm[4]*inm[8]-inm[5]*inm[7];
	outm[1]=inm[2]*inm[7]-inm[1]*inm[8];
	outm[2]=inm[1]*inm[5]-inm[2]*inm[4];
	outm[3]=inm[5]*inm[6]-inm[3]*inm[8];
	outm[4]=inm[0]*inm[8]-inm[2]*inm[6];
	outm[5]=inm[2]*inm[3]-inm[0]*inm[5];
	outm[6]=inm[3]*inm[7]-inm[5]*inm[6];
	outm[7]=inm[1]*inm[6]-inm[0]*inm[7];
	outm[8]=inm[0]*inm[4]-inm[1]*inm[3];
	return 1;
}

- (void) useSeedDataToInitializeDirectionData:(unsigned short*)seedData:(float*)inputData:(float*)outputData:(unsigned char*)directionData:(int)volumeSize
{
	int i;
	for(i=0;i<volumeSize;i++)
	{
		if(seedData[i])
		{
			unsigned char colorindex=seedData[i];
			directionData[i]=colorindex|0x80;
			if(colorindex!=BARRIERMARKER)
				outputData[i]=inputData[i];
			
		}
			
	}
	
}
- (void) prepareForCaculateLength:(unsigned short*)dismap:(unsigned char*)directionData
{
	int size,i;
	size=imageAmount*imageSize;
	for(i=0;i<size;i++)
	{
		if((*(directionData+i)) & 0xC0)
			*(dismap+i)=1;
		else
			*(dismap+i)=0;
		
	}

}
- (void) prepareForCaculateWightedLength:(float*)outputData:(unsigned char*)directionData
{
	int size,i;
	size=imageAmount*imageSize;
	for(i=0;i<size;i++)
	{
		if((*(directionData+i)) & 0xC0)
			*(outputData+i)=1;
		else
			*(outputData+i)=0;
	}
}

-(int)createCoronaryVesselnessMap:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(float)startscale:(float)endscale:(float)scalestep:(float)targetspacing:(float)rescaleMax :(BOOL)needSaveVesselnessMap
{	parent=owner;
	if(vc)
		originalViewController=vc;
	int err=0;
	if(vc)
		controllersPixList=[vc pixList];
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];
	

	
	long origin[3],dimension[3],newdimension[3];
	float spacing[3];
	dimension[0] = [curPix pwidth];
	dimension[1] = [curPix pheight];
	dimension[2] = [controllersPixList count];	
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [controllersPixList count];	
	imageSize= imageWidth*imageHeight;
	
	origin[0]=origin[1]=origin[2]=0;
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;
	
	if(vc)
		volumeData=[originalViewController volumePtr:0];


	CMIVAutoSeedingCore* coreAlgorithm=[[CMIVAutoSeedingCore alloc] init];
	NSLog( @"vesselness filter start");
	
	newdimension[0]=dimension[0]*spacing[0]/targetspacing;
	newdimension[1]=dimension[1]*spacing[1]/targetspacing;
	newdimension[2]=dimension[2]*spacing[2]/targetspacing;
	vesselnessMapSpacing=targetspacing;
	float newspacing[3];
	newspacing[0]=newspacing[1]=newspacing[2]=targetspacing;
	int size=newdimension[0]*newdimension[1]*newdimension[2]*sizeof(float);
	float* smallVolumeData=(float*)malloc(size);
	float* smalloutputVolumeData=(float*)malloc(size);
	if(smallVolumeData&&smalloutputVolumeData)
	{
		float skeletonParaCalciumThreshold=[[NSUserDefaults standardUserDefaults] floatForKey:@"CMIVSkeletonParameterCalciumThreshold"];
		if(skeletonParaCalciumThreshold<200.0)
			skeletonParaCalciumThreshold=650.0;
		
		[self resampleImage:volumeData:smallVolumeData:dimension:newdimension];
		int i,totalsize=newdimension[0]*newdimension[1]*newdimension[2];
		for(i=0;i<totalsize;i++)
		{
			if(smallVolumeData[i]<0||smallVolumeData[i]>skeletonParaCalciumThreshold)
				smallVolumeData[i]=0;
			smalloutputVolumeData[i]=0;
		}
		
		err=[coreAlgorithm vesselnessFilter:smallVolumeData:smalloutputVolumeData:newdimension:newspacing:startscale:endscale:scalestep];
		[self rescaleVolume:smalloutputVolumeData:totalsize:rescaleMax];
		//deal with calcium
		[self resampleImage:volumeData:smallVolumeData:dimension:newdimension];
		for(i=0;i<totalsize;i++)
		{
			if(smallVolumeData[i]>skeletonParaCalciumThreshold)
				smalloutputVolumeData[i]=-1000;
		}
	}
	else
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"OK", nil), nil, nil);
		if(smallVolumeData)
			free(smallVolumeData);
		return 1;

	}
	[coreAlgorithm release];
	free(smallVolumeData);

	NSLog( @"Saving Vesselness map");
	


	NSData	*newData = [[NSData alloc] initWithBytesNoCopy:smalloutputVolumeData length: size freeWhenDone:YES];
	NSMutableDictionary* dic=[parent dataOfWizard];
	[dic setObject:newData forKey:@"VesselnessMap"];
	[dic setObject:[NSNumber numberWithInt:size] forKey:@"VesselnessMapSize"];
	[dic setObject:[NSNumber numberWithFloat:targetspacing] forKey:@"VesselnessMapTargetSpacing"];
	float vector[9];
	[curPix orientation:vector];
	float	vtkOriginalX = ([curPix originX] ) * vector[0] + ([curPix originY]) * vector[1] + ([curPix originZ] )*vector[2];
	float	vtkOriginalY = ([curPix originX] ) * vector[3] + ([curPix originY]) * vector[4] + ([curPix originZ] )*vector[5];
	float	vtkOriginalZ = ([curPix originX] ) * vector[6] + ([curPix originY]) * vector[7] + ([curPix originZ] )*vector[8];
	NSMutableArray* originAndDimesnion=[NSMutableArray arrayWithCapacity:0];
	[originAndDimesnion addObject:[NSNumber numberWithFloat:vtkOriginalX]];
	[originAndDimesnion addObject:[NSNumber numberWithFloat:vtkOriginalY]];
	[originAndDimesnion addObject:[NSNumber numberWithFloat:vtkOriginalZ]];
	[originAndDimesnion addObject:[NSNumber numberWithInt:newdimension[0]]];
	[originAndDimesnion addObject:[NSNumber numberWithInt:newdimension[1]]];
	[originAndDimesnion addObject:[NSNumber numberWithInt:newdimension[2]]];
	[dic setObject:originAndDimesnion forKey:@"VesselnessMapOriginAndDimension"];

	[newData release];
	if(needSaveVesselnessMap)
	{
		NSString* seriesUid=[[[controllersPixList objectAtIndex:0] seriesObj] valueForKey:@"seriesInstanceUID"];
		[parent saveIntermediateData:seriesUid];
	}

	return err;
	
}
-(void)enhanceVolumeWithVesselness
{
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];
	
	
	
	long dimension[3];
	float spacing[3];
	dimension[0] = [curPix pwidth];
	dimension[1] = [curPix pheight];
	dimension[2] = [controllersPixList count];	
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;
	long newdimension[3];
	newdimension[0]=dimension[0]*spacing[0]/vesselnessMapSpacing;
	newdimension[1]=dimension[1]*spacing[1]/vesselnessMapSpacing;
	newdimension[2]=dimension[2]*spacing[2]/vesselnessMapSpacing;

	
	long size=dimension[0]*dimension[1]*dimension[2]*sizeof(float);
	float* vesselnessMap=(float*)malloc(size);
	if(!vesselnessMap)
	{
		if(originalViewController)
		NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"No enough memory for loading vesselness map, running segmentation withour it!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}

	float* smallVolumeData=(float*)[ vesselnessMapData bytes];

	if(![self resampleImage:smallVolumeData:vesselnessMap:newdimension:dimension])
	{
		size=dimension[0]*dimension[1]*dimension[2];
		int i;
		for(i=0;i<size;i++)
			volumeData[i]+=3*vesselnessMap[i];
	}	
	free(vesselnessMap);
}
-(void)deEnhanceVolumeWithVesselness
{
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];
	
	
	
	long dimension[3];
	float spacing[3];
	dimension[0] = [curPix pwidth];
	dimension[1] = [curPix pheight];
	dimension[2] = [controllersPixList count];	
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;
	long newdimension[3];
	newdimension[0]=dimension[0]*spacing[0]/vesselnessMapSpacing;
	newdimension[1]=dimension[1]*spacing[1]/vesselnessMapSpacing;
	newdimension[2]=dimension[2]*spacing[2]/vesselnessMapSpacing;
	
	
	long size=dimension[0]*dimension[1]*dimension[2]*sizeof(float);
	float* vesselnessMap=(float*)malloc(size);
	if(!vesselnessMap)
	{
		if(originalViewController)
			NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"No enough memory for loading vesselness map, running segmentation withour it!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	
	float* smallVolumeData=(float*)[ vesselnessMapData bytes];

	if(![self resampleImage:smallVolumeData:vesselnessMap:newdimension:dimension])
	{
		size=dimension[0]*dimension[1]*dimension[2];
		int i;
		for(i=0;i<size;i++)
			volumeData[i]-=3*vesselnessMap[i];
	}	
	free(vesselnessMap);
}
-(void)rescaleVolume:(float*)img:(int)size:(float)tagetscale
{
	int i;
	float originmax=-100000;
	for(i=0;i<size;i++)
		if(img[i]>originmax)
			originmax=img[i];
	float sfactor=tagetscale/originmax;
	for(i=0;i<size;i++)
		img[i]*=sfactor;
	return;
		
}
- (int) searchBackToCreatCenterlines:(NSMutableArray *)acenterline:(int)endpointindex:(unsigned char*)directionData
{
	
	int branchlen=0;
	unsigned char startpointcoloindex;
	int x,y,z;
	unsigned char pointerToUpper;
	z = endpointindex/imageSize ;
	y = (endpointindex-imageSize*z)/imageWidth ;
	x = endpointindex-imageSize*z-imageWidth*y;
	
	
	CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
	[new3DPoint setX: x];
	[new3DPoint setY: y];
	[new3DPoint setZ: z];
	[acenterline addObject: new3DPoint];
	[new3DPoint release];
	
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
		
		if(x<0||y<0||z<0||x>=imageWidth||y>=imageHeight||z>=imageAmount)
			break;
		
		endpointindex+=itemp;
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: x];
		[new3DPoint setY: y];
		[new3DPoint setZ: z];
		[acenterline addObject: new3DPoint];
		[new3DPoint release];

		
		
		
	}while(!((*(directionData + endpointindex))&0x80));
	
	startpointcoloindex=(*(directionData + endpointindex))&0x3f;
	
	return branchlen;
	
}
-(int)smoothingImages3D:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(int)iteration
{	
	id waitWindow;

	parent=owner;
	if(vc)
		originalViewController=vc;
	if(originalViewController)
		waitWindow=[originalViewController startWaitWindow:@"processing"];
	int err=0;
	if(vc)
		controllersPixList=[vc pixList];
	DCMPix* curPix = [controllersPixList objectAtIndex: 0];
	
	
	
	long origin[3],dimension[3];
	float spacing[3];
	dimension[0] = [curPix pwidth];
	dimension[1] = [curPix pheight];
	dimension[2] = [controllersPixList count];	
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [controllersPixList count];	
	imageSize= imageWidth*imageHeight;
	
	origin[0]=origin[1]=origin[2]=0;
	spacing[0]=[curPix pixelSpacingX];
	spacing[1]=[curPix pixelSpacingY];
	float sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	spacing[2]=sliceThickness;
	
	if(vc)
		volumeData=[originalViewController volumePtr:0];
	
	
	CMIVAutoSeedingCore* coreAlgorithm=[[CMIVAutoSeedingCore alloc] init];
	NSLog( @"vesselness filter start");
	
	err=[coreAlgorithm smoothingFilter:volumeData:volumeData:dimension:spacing:iteration];
	[coreAlgorithm release];
	if(vc)
		[originalViewController endWaitWindow: waitWindow];
	if(originalViewController)
	{
		DCMView* origninImageView=[originalViewController imageView];
		float wl,ww;
		[origninImageView getWLWW:&wl :&ww];
		[origninImageView setWLWW:wl :ww];
	}
	return err;
	
}
- (NSData*)loadImageFromSeries:(NSManagedObject*)series To:(NSMutableArray*)pixList
{
	unsigned long memsize=0, mem = 0;
	BOOL multiFrame=NO;
	
	NSManagedObject*  curFile;
	NSData*volumeNSData;
	NSArray	*fileList = [[series valueForKey:@"images"] allObjects] ;
	
	if(!fileList||[fileList count]<1||!pixList)
		return nil;
	
	@try
	{
		// Sort images with "instanceNumber"
		NSSortDescriptor * sort = [[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES];
		NSArray * sortDescriptors = [NSArray arrayWithObject: sort];
		[sort release];
		
		fileList = [fileList sortedArrayUsingDescriptors: sortDescriptors];
	}
	
	@catch (NSException * e)
	{
		NSLog( [e description]);
	}
	
	
	
	for( curFile in fileList )
	{
		long h = [[curFile valueForKey:@"height"] intValue];
		long w = [[curFile valueForKey:@"width"] intValue];
		
		w += 2;
		
		if( w*h < 256*256)
		{
			w = 256;
			h = 256;
		}
		
		memsize += w * h;
		
	}
	float* fVolumePtr = (float*)malloc( memsize * sizeof(float));
	
	
	if( fVolumePtr )
	{
		volumeNSData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:memsize*sizeof( float) freeWhenDone:YES];
		NSArray *loadList = fileList;
		{
			//multiframe==NO
			unsigned long i;
			for(i = 0; i < [loadList count]; i++ )
			{
				NSManagedObject*  curFile = [loadList objectAtIndex: i];
				DCMPix* dcmPix = [[DCMPix alloc] myinit: [curFile valueForKey:@"completePath"] :i :[loadList count] :fVolumePtr+mem :0 :[[curFile valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:curFile];
				
				if( dcmPix )
				{
					mem += [[curFile valueForKey:@"width"] intValue] * [[curFile valueForKey:@"height"] intValue];
					
					[pixList addObject: dcmPix];
					
					[dcmPix release];
				}
				else
				{
					NSLog( @"not readable: %@", [curFile valueForKey:@"completePath"] );
				}
			}
		}
		
		if( [pixList count] != [loadList count] && multiFrame == NO )
		{
			[volumeNSData release];
			return nil;
			
		}
		//opening images refered to in viewerPix[0] in the adequate viewer
		
		if( [pixList count] > 0 && multiFrame == NO)
		{
			NSAutoreleasePool   *pool = [[NSAutoreleasePool alloc] init];
			long				i;
			
			
			for( i = 0 ; i < [pixList count]; i++)
			{
				
				
				{
					if ([fileList count] == [pixList count]) // I'm not quite sure what this line does, but I'm afraid to take it out. 
						[[BrowserController currentBrowser] getLocalDCMPath:[fileList objectAtIndex: i] : 5]; // Anyway, we are not guarantied to have as many files as pixs, so that is why I put in the if() - Joel
					else
						[[BrowserController currentBrowser] getLocalDCMPath:[fileList objectAtIndex: 0] : 5]; 
					
					
					DCMPix* pix = [pixList objectAtIndex: i];
					
					[pix CheckLoad];
				}
				
							}
			
			
			
			//if( stopThreadLoadImage == NO)	 
			{	
				float maxValueOfSeries = -100000;
				float minValueOfSeries = 100000;
				
				
				for( i = 0 ; i < [pixList count]; i++)	 
				{
					DCMPix* pix = [pixList objectAtIndex: i];
					
					if( maxValueOfSeries < [pix fullwl] + [pix fullww]/2) maxValueOfSeries = [pix fullwl] + [pix fullww]/2;
					if( minValueOfSeries > [pix fullwl] - [pix fullww]/2) minValueOfSeries = [pix fullwl] - [pix fullww]/2;
				}
				
				
				
				for( i = 0 ; i < [pixList count]; i++)	 
				{
					[[pixList objectAtIndex: i] setMaxValueOfSeries: maxValueOfSeries];
					[[pixList objectAtIndex: i] setMinValueOfSeries: minValueOfSeries];
				}
				
			}
			[self computeIntervalAndFlipIfNeeded:  pixList];

			
			[pool release];
		}
		else
		{
			[volumeNSData release];
			volumeNSData=nil;
		}
		return volumeNSData;
	}
	else
		return nil;
	
}

-(void) computeIntervalAndFlipIfNeeded: (NSMutableArray*) pixList
{
	
	double				interval=0; 
	unsigned				i;
	
	if( [pixList count] > 1)
	{
		
		double		vectors[ 9], vectorsB[ 9];
		BOOL		equalVector = YES;
		
		[[pixList objectAtIndex:0] orientationDouble: vectors];
		[[pixList objectAtIndex:1] orientationDouble: vectorsB];
		
		for( i = 0; i < 9; i++)
		{
			const double epsilon = fabs(vectors[ i] - vectorsB[ i]);
			if (epsilon > 1e-6)
			{
				equalVector = NO;
				break;
			}
		}
		
		BOOL equalZero = YES;
		
		for( i = 0; i < 9; i++)
		{
			if( vectors[ i] != 0) { equalZero = NO; break;}
			if( vectorsB[ i] != 0) { equalZero = NO; break;}
		}
		
		if( equalVector == YES && equalZero == NO)
		{
			if( fabs( vectors[6]) > fabs(vectors[7]) && fabs( vectors[6]) > fabs(vectors[8]))
			{
				interval = [[pixList objectAtIndex:0] originX] - [[pixList objectAtIndex:1] originX];
				
				if( interval == 0 && [pixList count] > 2)
					interval = [[pixList objectAtIndex:1] originX] - [[pixList objectAtIndex:2] originX];
				
				if( vectors[6] > 0) interval = -( interval);
				else interval = ( interval);
				
			}
			
			if( fabs( vectors[7]) > fabs(vectors[6]) && fabs( vectors[7]) > fabs(vectors[8]))
			{
				interval = [[pixList objectAtIndex:0] originY] - [[pixList objectAtIndex:1] originY];
				
				if( interval == 0 && [pixList count] > 2)
					interval = [[pixList objectAtIndex:1] originY] - [[pixList objectAtIndex:2] originY];
				
				if( vectors[7] > 0) interval = -( interval);
				else interval = ( interval);
				
				
			}
			
			if( fabs( vectors[8]) > fabs(vectors[6]) && fabs( vectors[8]) > fabs(vectors[7]))
			{
				interval = [[pixList objectAtIndex:0] originZ] - [[pixList objectAtIndex:1] originZ];
				
				if( interval == 0 && [pixList count] > 2)
					interval = [[pixList objectAtIndex:1] originZ] - [[pixList objectAtIndex:2] originZ];
				
				if( vectors[8] > 0) interval = -( interval);
				else interval = ( interval);
				
				//			if( vectors[8] > 0) orientationVector = eAxialPos;
				//				else orientationVector = eAxialNeg;
				//				
				//				[orientationMatrix selectCellWithTag: 0];
				//				if( interval != 0) [orientationMatrix setEnabled: YES];
				//				currentOrientationTool = 0;
			}
			
			//		if( originalOrientation == -1)
			//			{
			//				switch( orientationVector)
			//				{
			//					case eAxialPos:
			//					case eAxialNeg:
			//						originalOrientation = 0;
			//						break;
			//						
			//					case eCoronalNeg:
			//					case eCoronalPos:
			//						originalOrientation = 1;
			//						break;
			//						
			//					case eSagittalNeg:
			//					case eSagittalPos:
			//						originalOrientation = 2;
			//						break;
			//				}
			//			}
			
			double interval3d;
			double xd = [[pixList objectAtIndex: 1] originX] - [[pixList objectAtIndex: 0] originX];
			double yd = [[pixList objectAtIndex: 1] originY] - [[pixList objectAtIndex: 0] originY];
			double zd = [[pixList objectAtIndex: 1] originZ] - [[pixList objectAtIndex: 0] originZ];
			
			interval3d = sqrt(xd*xd + yd*yd + zd*zd);
			
			if( interval3d == 0 && [pixList count] > 2)
			{
				xd = [[pixList objectAtIndex: 2] originX] - [[pixList objectAtIndex: 1] originX];
				yd = [[pixList objectAtIndex: 2] originY] - [[pixList objectAtIndex: 1] originY];
				zd = [[pixList objectAtIndex: 2] originZ] - [[pixList objectAtIndex: 1] originZ];
				
				interval3d = sqrt(xd*xd + yd*yd + zd*zd);
			}
			
			xd /= interval3d;
			yd /= interval3d;
			zd /= interval3d;
			
			if( interval == 0 && [[pixList objectAtIndex: 0] originX] == 0 && [[pixList objectAtIndex: 0] originY] == 0 && [[pixList objectAtIndex: 0] originZ] == 0)
			{
				interval = [[pixList objectAtIndex:0] spacingBetweenSlices];
				if( interval)
				{
					interval3d = -interval;
					
					
					float v[ 9], o[ 3];
					
					o[ 0] = 0; o[ 1] = 0; o[ 2] = 0;
					
					v[ 0] = 1;	v[ 1] = 0;	v[ 2] = 0;
					v[ 3] = 0;	v[ 4] = 1;	v[ 5] = 0;
					v[ 6] = 1;	v[ 7] = 0;	v[ 8] = 1;
					
					for( DCMPix *pix in pixList)
					{
						[pix setOrientation: v];
						[pix setOrigin: o];
						o[ 2] += interval;
					}
				}
			}
			
			// FLIP DATA !!!!!! FOR 3D TEXTURE MAPPING !!!!!
			if( interval < 0 )
			{
				BOOL sameSize = YES;
				
				DCMPix	*firstObject = [pixList objectAtIndex: 0];
				
				for(  i = 0 ; i < [pixList count]; i++)
				{
					if( [firstObject pheight] != [[pixList objectAtIndex: i] pheight] ) sameSize = NO;
					if( [firstObject pwidth] != [[pixList objectAtIndex: i] pwidth] ) sameSize = NO;
				}
				
				if( sameSize)
				{
					if( interval3d)
						interval = fabs( interval3d);	//interval3d;	//-interval;
					else
						interval = fabs( interval);
					
					firstObject = [pixList objectAtIndex: 0];
					
					float	*volumeDataPtr = [firstObject fImage];
					//	flipData
					[self flipData: (char*) volumeDataPtr :[pixList count] :[firstObject pwidth] :[firstObject pheight]];
					
					for(  i = 0 ; i < [pixList count]; i++)
					{
						long offset = ([pixList count]-1-i)*[firstObject pheight] * [firstObject pwidth];
						
						[[pixList objectAtIndex: i] setfImage: volumeDataPtr + offset];
						[[pixList objectAtIndex: i] setSliceInterval: interval];
					}
					
					id tempObj;
					
					for( i = 0; i < [pixList count]/2 ; i++)
					{
						tempObj = [[pixList objectAtIndex: i] retain];
						[pixList replaceObjectAtIndex: i withObject:[pixList objectAtIndex: [pixList count]-i-1]];
						[pixList replaceObjectAtIndex: [pixList count]-i-1 withObject: tempObj];
						[tempObj release];
						
					}
					
					
					
					for( i = 0; i < [pixList count]; i++)
					{
						[[pixList objectAtIndex: i] setArrayPix: pixList :i];
						[[pixList objectAtIndex: i] setID: i];
					}
					
				}
				else NSLog( @"sameSize = NO");
			}
			else
			{
				if( interval3d)
				{
					if( interval < 0) interval = -interval3d;
					else interval = interval3d;
				}
				else
				{
					if( interval < 0) interval = -interval;
					else interval = interval;
				}
				
				for( i = 0; i < [pixList count]; i++)
				{
					[[pixList objectAtIndex: i] setSliceInterval: interval];
				}
				
			}
			
			
		}
	}
	
	
	return ;
}
- (void) flipData:(char*) ptr :(long) no :(long) x :(long) y
{
		
	vImage_Buffer src, dest;
	src.height = dest.height = no;
	src.width = dest.width = x*y;
	src.rowBytes = dest.rowBytes = x*y*4;
	src.data = dest.data = ptr;
	vImageVerticalReflect_PlanarF ( &src, &dest, 0);

}

@end

//  ITKRegionGrowing3D.mm
//
//	Implements various region growing algorithms from the 
//
//  Created by Brian Jensen on 4/2/08.
//  Copyright 2008. All rights reserved.
//


#import "ITKRegionGrowing3D.h"

#define id Id

#include "itkConnectedThresholdImageFilter.h"
#include "itkNeighborhoodConnectedImageFilter.h"
#include "itkConfidenceConnectedImageFilter.h"
#include "itkCurvatureFlowImageFilter.h"
#include "itkCastImageFilter.h"
#include "itkBinaryMaskToNarrowBandPointSetFilter.h"
#include "itkResampleImageFilter.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkRelabelComponentImageFilter.h"

#include "itkConnectedGradientThresholdImageFilter.h"
#include "itkGradientThresholdImageFunction.h"

#undef id

#import "DCMPix.h"
#import "DCMView.h"
#import "ROI.h"
#import "MyPoint.h"

// Char Output image
typedef unsigned char OutputPixelType;
typedef ITKNS::Image< OutputPixelType, 3 > OutputImageType;
// Type Caster
typedef ITKNS::CastImageFilter<ImageType, OutputImageType > CastingFilterType;

//FILTERS
typedef ITKNS::ConnectedThresholdImageFilter<ImageType, ImageType > ConnectedThresholdFilterType;
typedef ITKNS::NeighborhoodConnectedImageFilter<ImageType, ImageType > NeighborhoodConnectedFilterType;
typedef ITKNS::ConfidenceConnectedImageFilter<ImageType, ImageType > ConfidenceConnectedFilterType;
typedef ITKNS::ImageToImageFilter<ImageType, ImageType> SegmentationInterfaceType;

//custom gradient filter
typedef ITKNS::ConnectedGradientThresholdImageFilter<ImageType, ImageType> ConnectedGradientThresholdFilterType;

//resampler
typedef ITKNS::ResampleImageFilter<ImageType, ImageType> ResamplerType;

//Iterator types
typedef ImageType::RegionType RegionType;
typedef ITKNS::ImageRegionConstIterator<ImageType> ConstIteratorType; 

//connected region types
typedef ITKNS::ConnectedComponentImageFilter<ImageType, OutputImageType> ConnectedType;
typedef ITKNS::RelabelComponentImageFilter<OutputImageType, OutputImageType> RelabelType;

@implementation ITKRegionGrowing3D

- (id) initWithViewer:(ViewerController*) viewer
{
	self = [super init];
	if(self != nil)
	{
		mainViewer = viewer;
		regViewer = nil;				//by convention, regViewer must be explicitly set to nil when it not being used
		itkImage = [[ITKImageWrapper alloc] initWithViewer:mainViewer slice:-1];
		ImageType::Pointer image = [itkImage image];
		
		outputOrigin = image->GetOrigin();
		outputSpacing = image->GetSpacing();
		outputSize[0] = [[[mainViewer pixList] objectAtIndex:0] pwidth];
		outputSize[1] = [[[mainViewer pixList] objectAtIndex:0] pheight];
		outputSize[2] = [[mainViewer pixList] count];
		
	}
	return self;
}

- (id) initWithMainViewer:(ViewerController*) mViewer regViewer:(ViewerController*) rViewer
{
	self = [super init];
	if(self != nil)
	{
		mainViewer = mViewer;
		regViewer = rViewer;
		itkImage = [[ITKImageWrapper alloc] initWithViewer:regViewer slice:-1];
		
		double	vector[9], outputOriginOriginal[3];
		DCMPix* outputPix = [[mainViewer pixList] objectAtIndex:0];
		[outputPix orientationDouble: vector];
		outputOriginOriginal[0] = [outputPix originX];
		outputOriginOriginal[1] = [outputPix originY];
		outputOriginOriginal[2] = [outputPix originZ];
		
		outputOrigin[0] = outputOriginOriginal[0] * vector[0] + outputOriginOriginal[1] * vector[1] + outputOriginOriginal[2] * vector[2];
		outputOrigin[1] = outputOriginOriginal[0] * vector[3] + outputOriginOriginal[1] * vector[4] + outputOriginOriginal[2] * vector[5];
		outputOrigin[2] = outputOriginOriginal[0] * vector[6] + outputOriginOriginal[1] * vector[7] + outputOriginOriginal[2] * vector[8];
		
		outputSpacing[0] = [outputPix pixelSpacingX];
		outputSpacing[1] = [outputPix pixelSpacingY];
		outputSpacing[2] = [outputPix sliceInterval];
		
		outputSize[0] = [outputPix pwidth];
		outputSize[1] = [outputPix pheight];
		outputSize[2] = [[mainViewer pixList] count];
		
	}
	return self;
}

- (void) dealloc
{
	[itkImage release];
	[super dealloc];
}

- (void) setRegViewer:(ViewerController*) rViewer
{
	if(itkImage != nil)
		[itkImage release];
		
	regViewer = rViewer;			//by default, if the registeredViewer is set, then it used for segmentation
	itkImage = [[ITKImageWrapper alloc] initWithViewer:rViewer slice:-1];
}

- (void) removeRegViewer
{
	if(regViewer != nil)		//use the mainViewer for segmentation since the registered Viewer is not set
	{
		regViewer = nil;
		[itkImage release]; //only create an ITK Image for the mainViewer when necessary (save RAM)
		itkImage = [[ITKImageWrapper alloc] initWithViewer:mainViewer slice:-1];		
	}
	
}

- (void) regionGrowing:(long) slice seedPoint:(int[3]) seed name:(NSString*) name color:(NSColor*) color algorithmNumber:(int) algorithmNumber 
		lowerThreshold:(float) lowerThreshold upperThreshold:(float) upperThreshold radius:(int[3]) radius confMultiplier:(float) confMultiplier
		iterations:(int) iterations gradient:(float) gradient
{
	float volume;
	
	// STARTING POINT
	ImageType::IndexType  index;
	index[0] = (long) seed[0];
	index[1] = (long) seed[1];
	if( slice == -1) 
		index[2] = seed[2];
	else 
		index[2] = 0;

	CastingFilterType::Pointer caster = CastingFilterType::New();
	ResamplerType::Pointer resampler = ResamplerType::New();
	
	ConnectedThresholdFilterType::Pointer thresholdFilter = 0L;
	NeighborhoodConnectedFilterType::Pointer neighborhoodFilter = 0L;
	ConfidenceConnectedFilterType::Pointer confidenceFilter = 0L;
	ConnectedGradientThresholdFilterType::Pointer gradientFilter = 0L;
	SegmentationInterfaceType::Pointer segmenationFilter = 0L;
	
	//setup the requested segmentation algorithm
	switch(algorithmNumber)
	{
		case 0:
			DebugLog(@"Using Connected Threshold filter");
			thresholdFilter = ConnectedThresholdFilterType::New();
			thresholdFilter->SetLower(lowerThreshold);
			thresholdFilter->SetUpper(upperThreshold);
			thresholdFilter->SetReplaceValue(255);
			thresholdFilter->SetSeed(index);
			thresholdFilter->SetInput([itkImage image]);
			segmenationFilter = thresholdFilter;
			break;
			
		case 1:
			DebugLog(@"Using Neighbor Connected Threshold filter");
			neighborhoodFilter = NeighborhoodConnectedFilterType::New();
			neighborhoodFilter->SetLower(lowerThreshold);
			neighborhoodFilter->SetUpper(upperThreshold);
			neighborhoodFilter->SetReplaceValue(255);
			neighborhoodFilter->SetSeed(index);
			neighborhoodFilter->SetInput([itkImage image]);
			ImageType::SizeType nhRadius;
			nhRadius[0] = radius[0];
			nhRadius[1] = radius[1];
			nhRadius[2] = radius[2];
			neighborhoodFilter->SetRadius(nhRadius);
			segmenationFilter = neighborhoodFilter;
			break;
			
		case 2:
			DebugLog(@"Using Confidence Connected filter");
			confidenceFilter = ConfidenceConnectedFilterType::New();
			confidenceFilter->SetMultiplier(confMultiplier);
			confidenceFilter->SetNumberOfIterations(iterations);
			confidenceFilter->SetInput([itkImage image]);
			confidenceFilter->SetInitialNeighborhoodRadius(radius[0]);
			confidenceFilter->SetReplaceValue(255);
			confidenceFilter->SetSeed(index);
			segmenationFilter = confidenceFilter;
			break;
			
		case 3:
			DebugLog(@"Using Gradient Magnitude Threshold filter");
			gradientFilter = ConnectedGradientThresholdFilterType::New();
			gradientFilter->SetInput([itkImage image]);
			gradientFilter->SetReplaceValue(255);
			gradientFilter->SetSeed(index);
			gradientFilter->SetGradientThreshold(gradient);
			gradientFilter->SetMaxSegmentationSize(iterations); //segmentation size is passed using iterations
			segmenationFilter = gradientFilter;
			break;
	} 
	
	//setup the resampler if required
	if(regViewer != nil)
	{
		DebugLog(@"Setting up resampler");
		resampler->SetInput(segmenationFilter->GetOutput());
		resampler->SetOutputOrigin(outputOrigin);
		resampler->SetOutputSpacing(outputSpacing);
		resampler->SetSize(outputSize);
		caster->SetInput(resampler->GetOutput());
	}
	else
		caster->SetInput(segmenationFilter->GetOutput());	// <- FLOAT TO CHAR

	NSLog(@"RegionGrowing starts...");
	
	try
	{
		caster->Update();
	}
	catch( ITKNS::ExceptionObject & excep )
	{
		NSLog(@"RegionGrowing failed...");
		return;
	}
	
	//Calculate the volume of the segmented region, first determine the number of segmented voxels
	ConnectedType::Pointer connComponent = ConnectedType::New();
	RelabelType::Pointer relabeler = RelabelType::New();
	connComponent->SetInput(segmenationFilter->GetOutput());	//counts the size in voxels of connected regions (we only have one connected region in the image)
	relabeler->SetInput(connComponent->GetOutput());			//reorders the counted regions, so the largest is first
	
	NSLog(@"Calculating the Volume");
	
	try
	{
		relabeler->Update();
	}
	catch (ITKNS::ExceptionObject &exccep) 
	{
		NSLog(@"Volume calculation failed");
		return;
	}

	if(relabeler->GetSizeOfObjectsInPixels().size() == 0)		//bail if no voxels were segmented
	{
		NSLog(@"Error Segmentation returned a volume of size 0, not drawing ROI");
		return;
	}
	
	NSLog(@"Segmented volume in voxels %d", relabeler->GetSizeOfObjectsInPixels()[0]);
	
	//calculate the volume from the number of voxels
	ImageType::Pointer image = [itkImage image];
	ImageType::SpacingType spacing = image->GetSpacing();
	volume = spacing[0] * spacing[1] * spacing[2] * relabeler->GetSizeOfObjectsInPixels()[0]; 
	NSLog(@"Segmented volume in mm3 %f", volume);
	
	//add the volume to the label (it would be really nice if we could write the fields ourselves)
	NSMutableString* volumeText = [NSMutableString stringWithCapacity:50];
	[volumeText setString:@" -> Volume: "];
	[volumeText appendString:[[NSNumber numberWithFloat:(volume / 1000)] stringValue]];
	[volumeText appendString:@" cm3"];
	NSString* roiText = [name stringByAppendingString:volumeText];
	
	unsigned char *buff = caster->GetOutput()->GetBufferPointer();
	
	DebugLog(@"Drawing the ROI");
	
	if(slice == -1)		//We performed a 3D segmenation
	{
		unsigned long i;
		
		RGBColor roiColor;
		roiColor.red = [color redComponent] * 65535;
		roiColor.blue =  [color blueComponent] * 65535;
		roiColor.green = [color greenComponent] * 65535;
		
		for( i = 0; i < [[mainViewer pixList] count]; i++)
		{
			int buffHeight = [[[mainViewer pixList] objectAtIndex: i] pheight];
			int buffWidth = [[[mainViewer pixList] objectAtIndex: i] pwidth];
			
			ROI *theNewROI = [[ROI alloc]	initWithTexture:buff
											textWidth:buffWidth
											textHeight:buffHeight
											textName:roiText
											positionX:0
											positionY:0
											spacingX:[[[mainViewer imageView] curDCM] pixelSpacingX]
											spacingY:[[[mainViewer imageView] curDCM] pixelSpacingY]
											imageOrigin:NSMakePoint([[[mainViewer imageView] curDCM] originX], [[[mainViewer imageView] curDCM] originY])];
											
			[theNewROI setComments:@"My comments here"];
			if( [theNewROI reduceTextureIfPossible] == NO)	// NO means that the ROI is NOT empty
			{
				[[[mainViewer roiList] objectAtIndex:i] addObject:theNewROI];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:theNewROI userInfo: 0L];	
				
				[theNewROI setColor: roiColor];
				[theNewROI setROIMode: ROI_selected];

				[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object:theNewROI userInfo: nil];
			}
			[theNewROI setSliceThickness:[[[mainViewer imageView] curDCM] sliceThickness]];
			[theNewROI release];
		
			//take next image
			buff+= buffHeight*buffWidth;		
		}
		
		
	}
	else
	{
		// result of the segmentation will only contain one slice.
		unsigned char *buff = caster->GetOutput()->GetBufferPointer();

		int buffHeight = [[[mainViewer pixList] objectAtIndex: 0] pheight];
		int buffWidth = [[[mainViewer pixList] objectAtIndex: 0] pwidth];

		ROI *theNewROI = [[ROI alloc]	initWithTexture:buff
										textWidth:buffWidth
										textHeight:buffHeight
										textName:roiText
										positionX:0
										positionY:0
										spacingX:[[[mainViewer imageView] curDCM] pixelSpacingX]
										spacingY:[[[mainViewer imageView] curDCM] pixelSpacingY]
										imageOrigin:NSMakePoint([[[mainViewer imageView] curDCM] originX], [[[mainViewer imageView] curDCM] originY])];
			[theNewROI reduceTextureIfPossible];
			[theNewROI setSliceThickness:[[[mainViewer imageView] curDCM] sliceThickness]];
			[[[mainViewer roiList] objectAtIndex:slice] addObject:theNewROI];
			[[mainViewer imageView] roiSet];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiChange" object:theNewROI userInfo: 0L];
			
			RGBColor roiColor;
			
			roiColor.red = [color redComponent] * 65535;
			roiColor.blue = [color blueComponent] * 65535;
			roiColor.green = [color greenComponent] * 65535;
			
			[theNewROI setColor: roiColor];

			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"mergeWithExistingROIs"])
			{
				[[mainViewer imageView] selectAll: self];
				[mainViewer mergeBrushROI: self];
			}
			
			[theNewROI setROIMode: ROI_selected];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"roiSelected" object:theNewROI userInfo: nil];
			
			[theNewROI release];
		
		}
}

- (float) findMaximum:(int[3]) rIndex region:(int[3]) rSize
{
	DebugLog(@"Performing a Max search");
	float max = 0.0, val;
	RegionType region;
	RegionType::IndexType regionIndex;
	RegionType::SizeType regionSize;
	
	regionIndex[0] = rIndex[0];
	regionIndex[1] = rIndex[1];
	regionIndex[2] = rIndex[2];
	regionSize[0] = rSize[0];
	regionSize[1] = rSize[1];
	regionSize[2] = rSize[2];
	
	region.SetSize(regionSize);
	region.SetIndex(regionIndex);
	
	//This iterator visits every point in the region
	ConstIteratorType maxIterator([itkImage image], region);
	
	//iterate over all points in the region, and save the max value
	for ( maxIterator.GoToBegin(); !maxIterator.IsAtEnd(); ++maxIterator)
    {
		val = maxIterator.Get();
		if(val > max)
			max = val;
    }

	DebugLog(@"Max found: %f", max);
	
	return max;
}


@end


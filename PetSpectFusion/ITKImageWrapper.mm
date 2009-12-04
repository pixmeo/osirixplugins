//
//  ITKImageWrapper.m
//  PetSpectFusion_Plugin
//
//  Created by Brian Jensen on 22.03.09.
//  Copyright 2009. All rights reserved.
//

#import <Foundation/NSDebug.h>

#import "ITKImageWrapper.h"

@implementation ITKImageWrapper

- (id) initWithViewer:(ViewerController*) sourceViewer slice:(int) slice
{
	if (self = [super init])
	{
		DebugLog(@"Creating new ITKImageWrapper");
		viewer = sourceViewer;
		sliceIndex = slice;
		volumeData = 0;
		[self update];
	}
	
	return self;
}

- (void) dealloc
{
	DebugLog(@"ITKImageWrapper dealloc");
	if(volumeData)
			free(volumeData);
	
	[super dealloc];
}

- (void) update
{
	DCMPix *firstPix = [[viewer	pixList] objectAtIndex:0];
	int slices = [[viewer pixList] count];
	long bufferSize;
	double originConverted[3], vector[9];
	
	ImportFilterType::Pointer importFilter = ImportFilterType::New();
	ImportFilterType::SizeType size;
	ImportFilterType::IndexType start;
	ImportFilterType::RegionType region;
	DebugEnable(importFilter->DebugOn());
	
	//make sure origin is correct
	origin[0] = [firstPix originX];
	origin[1] = [firstPix originY];
	origin[2] = [firstPix originZ];
	voxelSpacing[0] = [firstPix pixelSpacingX];
	voxelSpacing[1] = [firstPix pixelSpacingY];
	voxelSpacing[2] = [firstPix sliceInterval];
	
	[firstPix orientationDouble:vector];
	originConverted[ 0] = origin[ 0] * vector[ 0] + origin[ 1] * vector[ 1] + origin[ 2] * vector[ 2];
	originConverted[ 1] = origin[ 0] * vector[ 3] + origin[ 1] * vector[ 4] + origin[ 2] * vector[ 5];
	originConverted[ 2] = origin[ 0] * vector[ 6] + origin[ 1] * vector[ 7] + origin[ 2] * vector[ 8];
	
	size[0] = [firstPix pwidth];
	size[1] = [firstPix pheight];
	
	//first free any previously used buffers
	if(volumeData)
		free(volumeData);
	
	if(sliceIndex == -1) //import all slices
	{
		size[2] = slices;
		bufferSize = size[0] * size[1] * size[2];
		volumeData = (float *) malloc(bufferSize*sizeof(float));
		
		if(volumeData)
		{
			memcpy(volumeData, [viewer volumePtr], bufferSize*sizeof(float));
			DebugLog(@"ITK object size: %d", bufferSize*sizeof(float));
		}
		else
		{
			NSLog(@"ITKImageWrapper: unable to allocate new volume buffer!");
			return;
		}
		
		start.Fill( 0 );
	}
	else
	{
		size[2] = 1;
		voxelSpacing[2] = 0.1;
		bufferSize = size[0] * size[1];
		volumeData = (float *) malloc(bufferSize*sizeof(float));
		
		if(volumeData)
		{
			memcpy(volumeData, [viewer volumePtr]+ bufferSize*sliceIndex, bufferSize*sizeof(float));
			DebugLog(@"ITK object size: %d", bufferSize*sizeof(float));
			
		}
		else
		{
			NSLog(@"ITKImageWrapper: unable to allocate new volume buffer!");
			return;
		}
		
		start[0];
		start[1];
		start[2] = sliceIndex;
	}	
	
	region.SetIndex(start);
	region.SetSize(size);
	
	importFilter->SetRegion(region);
	importFilter->SetOrigin(origin);
	importFilter->SetSpacing(voxelSpacing); 
	importFilter->SetImportPointer(volumeData, bufferSize, false);

	image = importFilter->GetOutput();
	//DebugEnable(image->DebugOn());
	image->Update();
	
}

- (ImageType::Pointer) image
{
	return image;
}


@end

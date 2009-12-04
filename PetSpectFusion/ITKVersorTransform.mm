//
//  ITKVersorTransform.mm
//  PetSpectFusion_Plugin
//
//  Created by Brian Jensen on 26.03.09.
//  Copyright 2009. All rights reserved.
//

#import <Foundation/NSDebug.h>

#import "ITKVersorTransform.h"

#import "DCMPix.h"
#import "WaitRendering.h"
#import "AppController.h"
#import "ViewerController.h"

typedef VersorTransformType::VersorType VersorType;
typedef VersorType::VectorType VectorType;

@implementation ITKVersorTransform

- (id) initWithViewer: (ViewerController *) viewer;
{
	self = [super init];
	if (self != nil)
	{
		DebugLog(@"ITKVersorTransform constructor for single viewer called");
		sourceViewer = viewer;
		outputSpaceViewer = nil;
		itkImage = [[ITKImageWrapper alloc] initWithViewer:viewer slice:-1];
		sourceImage = [itkImage image];
		
		//since we don't have an output space, simply take the values from the input space
		outputOrigin = sourceImage->GetOrigin();
		outputSpacing = sourceImage->GetSpacing();
		
		outputSize[0] = [[[viewer pixList] objectAtIndex:0] pwidth];
		outputSize[1] = [[[viewer pixList] objectAtIndex:0] pheight];
		outputSize[2] = [[viewer pixList] count];
		
		//initialize the transform, set the qauternion axis of rotation
		transform = VersorTransformType::New();
		//DebugEnable(transform->DebugOn());
		VersorType rotation;
		VectorType axis;
		
		axis[0] = 0.0;
		axis[1] = 0.0;
		axis[2] = 1.0;
		const double angle = 0;
		rotation.Set(axis, angle);
		transform->SetRotation(rotation);
	}
	return self;
}


- (id) initWithViewer: (ViewerController *) sViewer resampleToViewer: (ViewerController *) oViewer;
{
	self = [super init];
	if(self != nil)
	{
		DebugLog(@"ITKVersorTransform constructor called");
		//setup the basic types, input parameters are calculated in ITKImageWrapper
		sourceViewer = sViewer;
		outputSpaceViewer = oViewer;
		itkImage = [[ITKImageWrapper alloc] initWithViewer:sViewer slice:-1];
		sourceImage = [itkImage image];
		
		//calculate the output space parameters
		double	vector[9], outputOriginOriginal[3];
		DCMPix* outputPix = [[oViewer pixList] objectAtIndex:0];
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
		outputSize[2] = [[oViewer pixList] count];
		
		//initialize the transform, set the qauternion axis of rotation
		transform = VersorTransformType::New();
		//DebugEnable(transform->DebugOn());
		VersorType rotation;
		VectorType axis;
		
		axis[0] = 0.0;
		axis[1] = 0.0;
		axis[2] = 1.0;
		const double angle = 0;
		rotation.Set(axis, angle);
		transform->SetRotation(rotation);
	}
	return self;
	
}

- (void) dealloc
{
	[itkImage release];
	[super dealloc];
}

- (float*) resampleWithParameters:(ParametersType &) theParameters  lengthOfBuffer:(long*) length  showWaitingMessage:(BOOL) showMessage 
{	
	DebugLog(@"Reampling image from viewer");
	transform->SetParameters(theParameters);
	ResampleFilterType::Pointer resample = ResampleFilterType::New();
	resample->SetTransform(transform);
	resample->SetInput(sourceImage);
	resample->SetDefaultPixelValue([[[sourceViewer pixList] objectAtIndex:0] minValueOfSeries]);
	resample->SetOutputSpacing(outputSpacing);
	resample->SetOutputOrigin(outputOrigin);
	resample->SetSize(outputSize);
	
	DebugEnable(resample->DebugOn());
	
	WaitRendering *splash = nil;
	
	if(showMessage)
	{
		splash = [[WaitRendering alloc] init:NSLocalizedString(@"Resampling...", nil)];
		[splash showWindow:self];
	}
	
	resample->Update();
	
	float* resultBuff = resample->GetOutput()->GetBufferPointer();
	long mem = outputSize[0] * outputSize[1] * outputSize[2] * sizeof(float);
	
	if(showMessage)
	{
		[splash close];
		[splash release];
	}
	
	float *fVolumePtr = (float*) malloc( mem);
	if( fVolumePtr && resultBuff) 
	{
		memcpy( fVolumePtr, resultBuff, mem);
		*length = mem;
		
		return fVolumePtr;
	}
	else return nil;
}

- (ViewerController*) createNewViewerFromTransformWithParameters: (ParametersType)theParameters showWaitingMessage: (BOOL)showMessage
{	
	long length;
	
	float *resultBuff = [self resampleWithParameters: theParameters lengthOfBuffer: &length showWaitingMessage: showMessage];
	return [self createViewerWithBuffer:resultBuff length: length];
}

- (ViewerController*) createViewerWithBuffer:(float*)fVolumePtr length: (long) length
{
	unsigned long				i;
	ViewerController	*new2DViewer = nil;
	float				wl, ww;
	ViewerController* referenceViewer;
	
	//check if we have set the viewer for the outputspace
	if(outputSpaceViewer == nil)
		referenceViewer = sourceViewer;
	else
		referenceViewer = outputSpaceViewer;
	
	NSArray	*pixList = [referenceViewer pixList];
	DCMPix	*curPix;
	
	if( fVolumePtr) 
	{
		// Create a NSData object to control the new pointer
		NSData	*volumeData = [NSData dataWithBytesNoCopy: fVolumePtr length: length freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new buffer
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray *newFileList = [NSMutableArray arrayWithCapacity:0];

		DCMPix	*originalPix = [[sourceViewer pixList] objectAtIndex: 0];
		wl = [originalPix wl];
		ww = [originalPix ww];
		
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * i)];
			
			// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
			[curPix setEchotime: [originalPix echotime]];
			[curPix setRepetitiontime: [originalPix repetitiontime]];
			
			[curPix setSavedWL: [originalPix savedWL]];
			[curPix setSavedWW: [originalPix savedWW]];
			[curPix changeWLWW: wl : ww];
			
			// SUV
			[curPix setDisplaySUVValue: [originalPix displaySUVValue]];
			[curPix setSUVConverted: [originalPix SUVConverted]];
			[curPix setRadiopharmaceuticalStartTime: [originalPix radiopharmaceuticalStartTime]];
			[curPix setPatientsWeight: [originalPix patientsWeight]];
			[curPix setRadionuclideTotalDose: [originalPix radionuclideTotalDose]];
			[curPix setRadionuclideTotalDoseCorrected: [originalPix radionuclideTotalDoseCorrected]];
			[curPix setAcquisitionTime: [originalPix acquisitionTime]];
			[curPix setDecayCorrection: [originalPix decayCorrection]];
			[curPix setDecayFactor: [originalPix decayFactor]];
			[curPix setUnits: [originalPix units]];
			[curPix setImageObj: [originalPix imageObj]];
			[curPix reloadAnnotations];
			
			[newPixList addObject: curPix];
			[newFileList addObject:[[sourceViewer fileList] objectAtIndex:0]];
		}
		
		if( [[[NSApplication sharedApplication] currentEvent] modifierFlags]  & NSAlternateKeyMask)
		{
			new2DViewer = [ViewerController newWindow:newPixList :newFileList :volumeData];
		}
		else
		{
			// Close original viewer
			BOOL prefTileWindows = [[NSUserDefaults standardUserDefaults] boolForKey: @"AUTOTILING"];
			
			//[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"AUTOTILING"];
			
			NSRect f = [[sourceViewer window] frame];
			[[sourceViewer window] close]; 
			
			new2DViewer = [ViewerController newWindow:newPixList :newFileList :volumeData frame: f];
			[new2DViewer needsDisplayUpdate];
			
			[[NSUserDefaults standardUserDefaults] setBool:prefTileWindows forKey: @"AUTOTILING"];
		}
		
		sourceViewer = new2DViewer;
		
		[[new2DViewer window] makeKeyAndOrderFront: self];
		[new2DViewer setWL: wl WW: ww];
		[new2DViewer propagateSettings];
		[new2DViewer setRegisteredViewer: referenceViewer];
	}

	
	return new2DViewer;
}
 
- (void) applyTransformToViewer: (ParametersType &) theParameters showWaitingMessage: (BOOL)showMessage
{
	DebugLog(@"Begin of applyTransformToViewer");

	DCMPix *outputPix, *inputPix;
	long i, length, sliceSize;
	float	wl, ww;
	
	inputPix = [[sourceViewer pixList] objectAtIndex:0];
	
	if(outputSpaceViewer != nil)	//if outputViewer is undefined, then the transform will be applied into same space
		outputPix = [[outputSpaceViewer pixList] objectAtIndex:0];
	else
		outputPix = inputPix;
		
	float *resultBuff = [self resampleWithParameters: theParameters lengthOfBuffer: &length showWaitingMessage: showMessage];
	
	DebugLog(@"Call to resampleWithParameters completed");
	
	if(resultBuff) 
	{
		//see if we have already readjusted the source viewers pix list
		if([inputPix pwidth] == [outputPix pwidth] &&
			[inputPix pheight] == [outputPix pwidth] &&
			[[sourceViewer pixList] count] == [[outputSpaceViewer pixList] count])
		{
			DebugLog(@"Input/Output viewers the same size, just modifying the existing pix list");
			
			//in this case we just need to copy the new image data to the existing buffers, no need to do expensive new pix list generation
			NSArray *curPixList = [sourceViewer pixList];	
			i = 0;
			sliceSize = [[curPixList objectAtIndex:0]pheight] * [[curPixList objectAtIndex:0] pwidth];
			for(DCMPix *curPix in curPixList)
			{
				memcpy([curPix fImage], resultBuff + i, sliceSize*sizeof(float));
				i += sliceSize;
			}
			
			//don't forget to release the buffer
			free(resultBuff);

		} 
		else	//the viewers have different dimension, need to create a new dcm pix list
		{
			DebugLog(@"Input/Output viewer spaces are different sizes, resize the moving viewer pix list");
			
			// Create a NSData object to control the new pointer
			NSData	*volumeData = [NSData dataWithBytesNoCopy: resultBuff length: length freeWhenDone:YES]; 
			
			// Now copy the DCMPix with the new buffer
			wl = [inputPix wl];
			ww = [inputPix ww];
			
			NSArray *pixList = [outputSpaceViewer pixList];
			float scaleValue = [sourceViewer scaleValue];
			NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
			NSMutableArray *newFileList = [NSMutableArray arrayWithCapacity:0];
			DCMPix* curPix;
			
			for(i = 0; ((unsigned) i) < [pixList count]; i++)
			{

				curPix = [[[pixList objectAtIndex: i] copy] autorelease];
				[curPix setfImage: (float*) (resultBuff + [curPix pheight] * [curPix pwidth] * i)];
				
				// to keep settings propagated for MRI we need the old values for echotime & repetitiontime
				[curPix setEchotime: [inputPix echotime]];
				[curPix setRepetitiontime: [inputPix repetitiontime]];
				
				[curPix setSavedWL: [inputPix savedWL]];
				[curPix setSavedWW: [inputPix savedWW]];
				[curPix changeWLWW: wl : ww];
				
				// SUV
				[curPix setDisplaySUVValue: [inputPix displaySUVValue]];
				[curPix setSUVConverted: [inputPix SUVConverted]];
				[curPix setRadiopharmaceuticalStartTime: [inputPix radiopharmaceuticalStartTime]];
				[curPix setPatientsWeight: [inputPix patientsWeight]];
				[curPix setRadionuclideTotalDose: [inputPix radionuclideTotalDose]];
				[curPix setRadionuclideTotalDoseCorrected: [inputPix radionuclideTotalDoseCorrected]];
				[curPix setAcquisitionTime: [inputPix acquisitionTime]];
				[curPix setDecayCorrection: [inputPix decayCorrection]];
				[curPix setDecayFactor: [inputPix decayFactor]];
				[curPix setUnits: [inputPix units]];
				
				[curPix setImageObj: [inputPix imageObj]];
				[curPix reloadAnnotations];
				
				[newPixList addObject: curPix];
				[newFileList addObject:[[sourceViewer fileList] objectAtIndex:0]];
			}
			
			//replace the objects, and keep the scaling parameter
			[sourceViewer replaceSeriesWith:newPixList :newFileList :volumeData];
			[sourceViewer setScaleValue:scaleValue];
			[sourceViewer propagateSettings];
			
		}
		
		//update the viewer!
		[sourceViewer needsDisplayUpdate];
	}
}

- (ImageType::Pointer) sourceImage
{
	return sourceImage;
}


@end

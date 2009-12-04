/*=========================================================================
 Program:  PetSpectFusion, an osirix plugin
 
 ITKVersorTransform.h: Wrapper class for an itk VersorRigid3DTransform 
 This class can map the transform into the source viewer's output space
 or in that of another viewers. This object is meant to be reused for the case
 that transform needs to be repeatedly applied to the source image. This class
 makes a persistent copy of the source viewer's image data, so that transforms
 can be performed without a loss of information.
 
 
 Copyright (c) Brian Jensen
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://home.in.tum.de/~jensen/projects/projects_en.shtml for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>

#import "Project_defs.h"

#import "DCMPix.h"
#import "ITKImageWrapper.h"
#import "ViewerController.h"

#define id Id
#include "itkResampleImageFilter.h"
#include "itkVersorRigid3DTransform.h"
#undef id

//use float values for interplation, because sse optimized code can do more than 2 times as many float ops as double ops
typedef ITKNS::VersorRigid3DTransform< float >  VersorTransformType;
typedef VersorTransformType::ParametersType ParametersType;
typedef ITKNS::ResampleImageFilter<ImageType, ImageType, float> ResampleFilterType;

/** /brief an objective-c Wrapper class for performing an ITK VersorRigid3DTransform
 *	on image and optionally resampling to another image's physical space
 */
@interface ITKVersorTransform : NSObject {
	ITKImageWrapper			*itkImage;
	ViewerController		*sourceViewer, *outputSpaceViewer; //moving, fixed image viewers
	ImageType::Pointer		sourceImage;						//for holding a persistent copy of the image
	VersorTransformType::Pointer	transform;
	ImageType::PointType	outputOrigin;
	ImageType::SpacingType  outputSpacing;
	ImageType::SizeType		outputSize;
}

/**
 *	This construction should be used when the transform's input and output space are the same (not used in registration)
 */
- (id) initWithViewer: (ViewerController *) viewer;

/**
 * This constructor should be used when performing a registration between two viewers
 */
- (id) initWithViewer: (ViewerController *) sViewer resampleToViewer: (ViewerController *) oViewer;

/**
 * Method performs the transform and creates a new viewerController object form the results
 */
- (ViewerController*) createNewViewerFromTransformWithParameters: (ParametersType)theParameters showWaitingMessage: (BOOL)showMessage; 

/**
 * Internal helper method
 */
- (ViewerController*) createViewerWithBuffer:(float*)aBuffer length: (long) length;

/**
 *	Method performs the transform and the stories the results in the source viewer
 */
- (void) applyTransformToViewer: (ParametersType &) theParameters showWaitingMessage: (BOOL)showMessage;

/**
 *	Helper method for performing the actual transform with resampling
 */
- (float*) resampleWithParameters:(ParametersType &) theParameters lengthOfBuffer:(long*) length showWaitingMessage:(BOOL) showMessage;

- (ImageType::Pointer) sourceImage;

@end

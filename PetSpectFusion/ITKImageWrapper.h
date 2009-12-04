/**
 * \brief This is an objective-c wrapper class for an itk image object
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@cs.tum.edu
 * \ingroup PetSpectFusion
 * \version 1.0
 * \date 22.03.2009
 *
 * \par License:
 * Copyright (c) 2007 - 2009,
 * This programm was created as part of a student research project in cooperation
 * with the Department for Computer Science, Chair XVI
 * and the Nuklearmedizinische Klinik, Klinikum Rechts der Isar
 *
 * <br>
 * <br>
 * All rights reserved.
 * <br>
 * <br>
 * See <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> for details.
 * <br>
 * <br>
 * This software is distributed WITHOUT ANY WARRANTY; without even 
 * <br>
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
 * <br>
 * PURPOSE.  See the <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> notice
 * for more information.
 *
 */

#import <Cocoa/Cocoa.h>

//necessary for the defining the itk namespace used as well the debug macros
#import "Project_defs.h"

#define id Id
#include "itkImage.h"
#include "itkImportImageFilter.h"
#undef id

typedef float itkPixelType;
typedef ITKNS::Image< itkPixelType, 3 > ImageType;
typedef ITKNS::ImportImageFilter< itkPixelType, 3 > ImportFilterType;

#import "DCMPix.h"
#import "ViewerController.h"

/**
 *	This is a wrapper class for an itk image that automatically duplicates the image from
 *	the viewerController object. A local copy is kept of the raw image data so that any 
 *  operations on the viewer do not affect this object.
 *
 */
@interface ITKImageWrapper : NSObject {

	ImageType::Pointer image;
	float	*volumeData;
	ViewerController* viewer;
	double origin[3];
	double voxelSpacing[3];
	int sliceIndex;
	
}

/**
 * Pointer to the itk image object that was imported
 */
- (ImageType::Pointer) image;

/**
 *	Method to create the new image image from the viewerController
 *
 */
- (id) initWithViewer:(ViewerController*) sourceViewer slice:(int) slice;

/**
 *	This method should be called if a change in the source Viewers data needs to be reflected in the itk image
 *
 */
- (void) update;

@end

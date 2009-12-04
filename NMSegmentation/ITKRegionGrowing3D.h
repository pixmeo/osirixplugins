/**
 * \brief This class is responsible for performing region growing segmentation variants on 3D volumes
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@in.tum.de
 * \ingroup PetSpectFusion
 * \version 1.0
 * \date 13.06.2008
 *
 * \par License:
 * Copyright (c) 2008 - 2009,
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

#import "Project_defs.h"

#import "ITKImageWrapper.h"
#import "ViewerController.h"

@interface ITKRegionGrowing3D : NSObject {

	ViewerController *mainViewer, *regViewer;
	ITKImageWrapper* itkImage;
	ImageType::PointType	outputOrigin;
	ImageType::SpacingType  outputSpacing;
	ImageType::SizeType		outputSize;

}

/**
 *	Performs the actual segmentation, calculates the segmented volume and generates a ROI on the main viewer
 */
- (void) regionGrowing:(long) slice seedPoint:(int[3]) seed name:(NSString*) name color:(NSColor*) color algorithmNumber:(int) algorithmNumber 
		lowerThreshold:(float) lowerThreshold upperThreshold:(float) upperThreshold radius:(int[3]) radius confMultiplier:(float) confMultiplier
		iterations:(int) iterations gradient:(float) gradient;

/**
 *	Create with a single viewer
 */
- (id) initWithViewer:(ViewerController*) viewer;

/**
 *	Create with a main display viewer, and a registered viewerer. All segmentation will performed in the registered viewer, but the ROI
 *	will be displayed in the main viewer
 */
- (id) initWithMainViewer:(ViewerController*) mViewer regViewer:(ViewerController*) rViewer;

/**
 *	Used to the change / add a registered viewer
 */
- (void) setRegViewer:(ViewerController*) rViewer;

/**
 * Turn off segmentation using the registered viewer
 */
- (void) removeRegViewer;

/**
 * Searches for the maximum intensity value of the registered viewer starting at the index rIndex (in px)
 * a region of size rSize (in px).
 */
- (float) findMaximum:(int[3]) rIndex region:(int[3]) rSize;


@end

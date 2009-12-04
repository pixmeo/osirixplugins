#ifndef REGISTRATION_H
#define REGISTRATION_H

#import "Project_defs.h"

#define id Id
#include "Typedefs.h"
#undef id

#include "RegObserver.h"

typedef RegistrationInterfaceCommand<MultiResRegistrationType> CommandType;

 /**
 * \brief These are the various functions for performing the actual registration
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@cs.tum.edu
 * \ingroup PetSpectFusion
 * \version 1.10
 * \date 16.04.2009
 *
 * \par License:
 * Copyright (c) 2007 - 2009
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

/**
 *	This function does a standard single resolution using mattes mututal information
 *
 */
RegistrationType::Pointer doMattesRegistration(ImageType::Pointer fixedImage, ImageType::Pointer movingImage, CommandIterationUpdate* observer, 
	int bins, float sampleRate, float minStepSize, float maxStepSize, int maxIterations, OptimizerScalesType& optimizerScales,
	TransformType::Pointer transform = NULL);
/**
 *	this function is responsible for setting the transforms initial parameters and most importantly, the center of rotation
 *
 */
void initializeTransform(TransformType::Pointer transform, ImageType::Pointer fixedImage, ImageType::Pointer movingImage);

/**
 *	This function performs several registrations using mattes mutual information and multiple reduced resolution images
 *
 */
MultiResRegistrationType::Pointer doMattesMultiRegistration(ImageType::Pointer fixedImage, ImageType::Pointer movingImage, 
		CommandIterationUpdate* observer, int bins, float sampleRate, float minStepSize, float maxStepSize, int maxIterations,
		OptimizerScalesType& optimizerScales, int levels = DEFAULT_MULTIRES_LEVELS, 
		CommandType* command = CommandType::New(), TransformType::Pointer transform = NULL);
		

#endif
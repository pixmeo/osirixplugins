/*
 *  Typedefs.h
 *  PetSpectFusion_Plugin
 *
 *  Created by Brian Jensen on 06.04.09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TYPEDEFS_H
#define TYPEDEFS_H

//Itk IO includes
#include "itkImage.h"
#include "itkImportImageFilter.h"

//itk resampling and filtering include
#include "itkResampleImageFilter.h"
#include "itkSubtractImageFilter.h"
#include "itkRescaleIntensityImageFilter.h"
#include "itkExtractImageFilter.h"
#include "itkNormalizeImageFilter.h"

//itk registration includes
#include "itkImageRegistrationMethod.h"
#include "itkLinearInterpolateImageFunction.h"
#include "itkMultiResolutionImageRegistrationMethod.h"
#include "itkRecursiveMultiResolutionPyramidImageFilter.h"
#include "itkMutualInformationImageToImageMetric.h"
#include "itkMattesMutualInformationImageToImageMetric.h"
#include "itkGradientDescentOptimizer.h"
#include "itkVersorRigid3DTransform.h"
#include "itkVersorRigid3DTransformOptimizer.h"
#include "itkCenteredTransformInitializer.h"
#include "itkCenteredVersorTransformInitializer.h"

//itk utilities include
#include "itkRealTimeClock.h"

#define ITKNS psfITK

//base types
typedef float itkPixelType;
typedef ITKNS::Image< itkPixelType, 3 > ImageType;

//transform types
typedef ITKNS::VersorRigid3DTransform< double >  TransformType;
typedef TransformType::ParametersType ParametersType;
//typedef itk::ResampleImageFilter<ImageType, ImageType, double> ResampleFilterType;
typedef TransformType::VersorType  VersorType;
typedef VersorType::VectorType     VectorType;

//now set up the types for the registration
typedef ITKNS::VersorRigid3DTransformOptimizer  OptimizerType;
typedef ITKNS::ImageRegistrationMethod<ImageType, ImageType> RegistrationType;
typedef OptimizerType::ScalesType OptimizerScalesType;

//Types for the multi resolution registration
typedef ITKNS::MultiResolutionImageRegistrationMethod<ImageType, ImageType> MultiResRegistrationType;
typedef ITKNS::MultiResolutionPyramidImageFilter<ImageType, ImageType> InternalImagePyramidType;


#endif


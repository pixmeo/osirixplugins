
#import <Foundation/NSDebug.h>

#include "Registration.h"
#include "RegObserver.h"



RegistrationType::Pointer doMattesRegistration(ImageType::Pointer fixedImage, ImageType::Pointer movingImage, 
		CommandIterationUpdate* observer, int bins, float sampleRate, float minStepSize, float maxStepSize, int maxIterations, 
		OptimizerScalesType& optimizerScales, TransformType::Pointer transform)
{	
	typedef ITKNS::MattesMutualInformationImageToImageMetric<ImageType, ImageType> MetricType;
	
	typedef ITKNS:: LinearInterpolateImageFunction< 
                                    ImageType,
                                    double          >    InterpolatorType;
	
	MetricType::Pointer         metric        = MetricType::New();
	OptimizerType::Pointer      optimizer     = OptimizerType::New();
	InterpolatorType::Pointer   interpolator  = InterpolatorType::New();
	RegistrationType::Pointer   registration  = RegistrationType::New();

		//if no default transform was specified, make sure to create and initialize a new one
	if(transform.IsNull())
	{
		transform = TransformType::New();
		initializeTransform(transform, fixedImage, movingImage);
	}
	
	DebugEnable(optimizer->DebugOn());
	DebugEnable(registration->DebugOn());
	
	ParametersType params(6);
	params = transform->GetParameters();
			
	DebugLog(@"number of bins: %d", bins);
	DebugLog(@"sample rate: %f", sampleRate);
	DebugLog(@"min step size: %f", minStepSize);
	DebugLog(@"max step size: %f", maxStepSize);
	DebugLog(@"max iterations: %d", maxIterations);
	DebugLog(@"optimizer scales: %f %f %f %f %f %f", optimizerScales[0], optimizerScales[1], optimizerScales[2],
		  optimizerScales[3], optimizerScales[4], optimizerScales[5]);
	DebugLog(@"transform params: %f %f %f %f %f %f", params[0], params[1], params[2], params[3], params[4], params[5]);
	
	registration->SetMetric(metric);
	registration->SetOptimizer(optimizer);
	registration->SetInterpolator(interpolator);
	registration->SetTransform( transform );
	
	registration->SetFixedImage(fixedImage);
	registration->SetMovingImage(movingImage);

	ImageType::RegionType fixedImageRegion = fixedImage->GetBufferedRegion();
	registration->SetFixedImageRegion(fixedImageRegion);

	//initialize the metric for Mattes MI
	metric->SetNumberOfHistogramBins(bins);
	
	const unsigned int numberOfPixels = fixedImageRegion.GetNumberOfPixels();
	const unsigned int numberOfSamples = static_cast< unsigned int >(sampleRate * numberOfPixels);
	metric->SetNumberOfSpatialSamples(numberOfSamples);
	registration->SetInitialTransformParameters(transform->GetParameters());
	
		//initialize the optimizer step values
	optimizer->SetScales(optimizerScales);
	optimizer->SetMaximumStepLength(maxStepSize); 
	optimizer->SetMinimumStepLength(minStepSize);
	optimizer->MinimizeOn();
	optimizer->SetNumberOfIterations(maxIterations);

	optimizer->AddObserver( ITKNS::IterationEvent(), observer );	
	
	//now do the registration!
	NSLog(@"Registration starting...");
	try 
    { 
		registration->StartRegistration(); 
    } 
	catch( ITKNS::ExceptionObject & err ) 
    { 
		NSLog(@"Error performing the registration!"); 
		std::cout << err << std::endl; 
		
		NSRunAlertPanel(@"PetSpectFusion Error", @"Error performing the registration, see the console log for more details", nil, nil, nil);
		
		return 0;
    } 
	
	params = registration->GetLastTransformParameters();
	NSLog(@"Registration completed");
	DebugLog(@"Final transform parameters: %f %f %f %f %f %f", params[0], params[1], params[2], params[3], params[4], params[5]);
	DebugLog(@"Iterations: %d", optimizer->GetCurrentIteration());
	DebugLog(@"Metric Value: %f", optimizer->GetValue());

	return registration;
}

void initializeTransform(TransformType::Pointer transform, ImageType::Pointer fixedImage, ImageType::Pointer movingImage)
{	
	typedef ITKNS::CenteredTransformInitializer< TransformType, 
                                            ImageType, 
											ImageType 
											 > TransformInitializerType;
	
	TransformInitializerType::Pointer initializer = 
                                          TransformInitializerType::New();

	initializer->SetTransform(transform);
	initializer->SetFixedImage(fixedImage);
	initializer->SetMovingImage(movingImage);
	initializer->GeometryOn();
	initializer->InitializeTransform();	

	VersorType     rotation;
	VectorType     axis;
  
	axis[0] = 0.0;
	axis[1] = 0.0;
	axis[2] = 1.0;

	const double angle = 0;
	rotation.Set(  axis, angle  );
	transform->SetRotation( rotation );
	
}

MultiResRegistrationType::Pointer doMattesMultiRegistration(ImageType::Pointer fixedImage, ImageType::Pointer movingImage, 
		CommandIterationUpdate* observer, int bins, float sampleRate, float minStepSize, float maxStepSize, int maxIterations,
		OptimizerScalesType& optimizerScales, int levels, CommandType* command, TransformType::Pointer transform)
{	
	typedef ITKNS::MattesMutualInformationImageToImageMetric<ImageType, ImageType> MetricType;
	
	typedef ITKNS:: LinearInterpolateImageFunction< 
                                    ImageType,
                                    double         >    InterpolatorType;

	
	MetricType::Pointer         metric        = MetricType::New();
	OptimizerType::Pointer      optimizer     = OptimizerType::New();
	InterpolatorType::Pointer   interpolator  = InterpolatorType::New();
	MultiResRegistrationType::Pointer registration = MultiResRegistrationType::New();
	
	InternalImagePyramidType::Pointer fixedImagePyramid = InternalImagePyramidType::New();
	InternalImagePyramidType::Pointer movingImagePyramid = InternalImagePyramidType::New();
	
	//if no default transform was specified, make sure to create and initialize a new one
	if(transform.IsNull())
	{
		transform = TransformType::New();
		initializeTransform(transform, fixedImage, movingImage);
	}
	
	DebugEnable(optimizer->DebugOn());
	DebugEnable(registration->DebugOn());
	
	ParametersType params(6);
	params = transform->GetParameters();
	
	DebugLog(@"number of bins: %d", bins);
	DebugLog(@"sample rate: %f", sampleRate);
	DebugLog(@"min step size: %f", minStepSize);
	DebugLog(@"max step size: %f", maxStepSize);
	DebugLog(@"max iterations: %d", maxIterations);
	DebugLog(@"optimizer scales: %f %f %f %f %f %f", optimizerScales[0], optimizerScales[1], optimizerScales[2],
		  optimizerScales[3], optimizerScales[4], optimizerScales[5]);
	DebugLog(@"transform params: %f %f %f %f %f %f", params[0], params[1], params[2], params[3], params[4], params[5]);
	DebugLog(@"multires levels: %d", levels);
	
	registration->SetMetric(metric);
	registration->SetOptimizer(optimizer);
	registration->SetInterpolator(interpolator);
	registration->SetTransform(transform);
	
	registration->SetFixedImagePyramid(fixedImagePyramid);
	registration->SetMovingImagePyramid(movingImagePyramid);
	
	registration->SetFixedImage(fixedImage);
	registration->SetMovingImage(movingImage);


	ImageType::RegionType fixedImageRegion = fixedImage->GetBufferedRegion();
	registration->SetFixedImageRegion(fixedImageRegion);

	//initialize the metric for Mattes MI
	metric->SetNumberOfHistogramBins(bins);
	metric->ReinitializeSeed(76926294);

	const unsigned int numberOfPixels = fixedImageRegion.GetNumberOfPixels();
	const unsigned int numberOfSamples = static_cast< unsigned int >(sampleRate * numberOfPixels);
	metric->SetNumberOfSpatialSamples(numberOfSamples);

	registration->SetInitialTransformParameters(params);
	
		//initialize the optimizer step values
	optimizer->SetScales(optimizerScales);
	optimizer->SetMaximumStepLength(maxStepSize); 
	optimizer->SetMinimumStepLength(minStepSize);
	optimizer->MinimizeOn();
	optimizer->SetNumberOfIterations(maxIterations);

	optimizer->AddObserver( ITKNS::IterationEvent(), observer );

	registration->AddObserver( ITKNS::IterationEvent(), command );
	
	registration->SetNumberOfLevels(levels);
	fixedImagePyramid->SetStartingShrinkFactors(8);
	movingImagePyramid->SetStartingShrinkFactors(8);


	//now do the registration!
	NSLog(@"Registration starting...");
	try 
    { 
		registration->StartRegistration(); 
    } 
	catch( ITKNS::ExceptionObject & err ) 
    { 
		NSLog(@"Error performing the registration!"); 
		std::cout << err << std::endl; 
		
		NSRunAlertPanel(@"Plugin Error", @"Error performing the registration, see the console log for more details", nil, nil, nil);
		
		return 0;
    } 
	
	params = registration->GetLastTransformParameters();
	NSLog(@"Registration completed");
	DebugEnable(@"Final transform parameters: %f %f %f %f %f %f", params[0], params[1], params[2], params[3], params[4], params[5]);
	DebugEnable(@"Iterations: %d", optimizer->GetCurrentIteration());
	DebugEnable(@"Metric Value: %f", optimizer->GetValue());

	return registration;
}


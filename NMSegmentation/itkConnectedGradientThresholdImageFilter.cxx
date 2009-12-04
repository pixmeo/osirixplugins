/**************************************************************************
 *
 *  itkConnectedGradientThresholdingImageFilter.cxx
 *  NMSegmentation
 *
 *  Created by Brian Jensen on 24.06.09.
 *  Copyright 2009. All rights reserved.
 *
 **************************************************************************/


#ifndef __itkConnectedGradientThresholdImageFilter_txx
#define __itkConnectedGradientThresholdImageFilter_txx

#include "itkConnectedGradientThresholdImageFilter.h"
#include "itkGradientThresholdImageFunction.h"
#include "itkFloodFilledImageFunctionConditionalIterator.h"
#include "itkProgressReporter.h"

#ifdef ITK_USE_REVIEW
#include "itkShapedFloodFilledImageFunctionConditionalIterator.h"
#endif

namespace ITKNS
{
	
	/**
	 * Standard Constructor
	 */
	template <class TInputImage, class TOutputImage>
	ConnectedGradientThresholdImageFilter<TInputImage, TOutputImage>
	::ConnectedGradientThresholdImageFilter()
	{
		m_MaxSegmentationSize = 0;
		m_ReplaceValue = NumericTraits<OutputImagePixelType>::One;
		this->m_Connectivity = FaceConnectivity;
		
		typename GradientThresholdObjectType::Pointer gradient = GradientThresholdObjectType::New();
		gradient->Set( 8.5 );
		this->ProcessObject::SetNthInput( 1, gradient );
	}
	
	/**
	 * Standard PrintSelf method.
	 */
	template <class TInputImage, class TOutputImage>
	void
	ConnectedGradientThresholdImageFilter<TInputImage, TOutputImage>
	::PrintSelf(std::ostream& os, Indent indent) const
	{
		this->Superclass::PrintSelf(os, indent);
		os << indent << "GradientThreshold: "
		<<  this->GetGradientThreshold()
		<< std::endl;
		os << indent << "ReplaceValue: "
		<< static_cast<typename NumericTraits<OutputImagePixelType>::PrintType>(m_ReplaceValue)
		<< std::endl;
		os << indent << "Connectivity: " << m_Connectivity << std::endl;
	}
	
	template <class TInputImage, class TOutputImage>
	void 
	ConnectedGradientThresholdImageFilter<TInputImage,TOutputImage>
	::GenerateInputRequestedRegion()
	{
		Superclass::GenerateInputRequestedRegion();
		if ( this->GetInput() )
		{
			InputImagePointer image = const_cast< InputImageType * >( this->GetInput() );
			image->SetRequestedRegionToLargestPossibleRegion();
		}
	}
	
	template <class TInputImage, class TOutputImage>
	void 
	ConnectedGradientThresholdImageFilter<TInputImage,TOutputImage>
	::EnlargeOutputRequestedRegion(DataObject *output)
	{
		Superclass::EnlargeOutputRequestedRegion(output);
		output->SetRequestedRegionToLargestPossibleRegion();
	}
	
	/**
	 *	Set the gradient magnitude threshold while wrapping it up in a DataObject
	 */
	template <class TInputImage, class TOutputImage>
	void
	ConnectedGradientThresholdImageFilter<TInputImage, TOutputImage>
	::SetGradientThreshold(const float threshold)
	{
		// first check to see if anything changed
		typename GradientThresholdObjectType::Pointer gradient = this->GetGradientThresholdInput();
		if (gradient && gradient->Get() == threshold)
		{
			return;
		}
		
		// create a data object to use as the input and to store this
		// threshold. we always create a new data object to use as the input
		// since we do not want to change the value in any current input
		// (the current input could be the output of another filter or the
		// current input could be used as an input to several filters)
		gradient = GradientThresholdObjectType::New();
		this->ProcessObject::SetNthInput(1, gradient);
		
		gradient->Set(threshold);
		this->Modified();
	}
	
	/**
	 *	Set the gradient magnitude threshold, used by other filters in the pipeline
	 */
	template <class TInputImage, class TOutputImage>
	void 
	ConnectedGradientThresholdImageFilter<TInputImage,TOutputImage>
	::SetGradientThresholdInput( const GradientThresholdObjectType *  input )
	{
		if (input != this->GetGradientThresholdInput())
		{
			this->ProcessObject::SetNthInput(1,
											 const_cast<GradientThresholdObjectType *>(input));
			this->Modified();
		}
	}
	
	template <class TInputImage, class TOutputImage>
	typename ConnectedGradientThresholdImageFilter<TInputImage, TOutputImage>::GradientThresholdObjectType *
	ConnectedGradientThresholdImageFilter<TInputImage,TOutputImage>
	::GetGradientThresholdInput()
	{
		typename GradientThresholdObjectType::Pointer gradient
		= static_cast<GradientThresholdObjectType *>(this->ProcessObject::GetInput(1));
		if (!gradient)
		{
			// no input object available, create a new one and set it to the
			// default threshold
			gradient = GradientThresholdObjectType::New();
			gradient->Set( 8.5 );
			this->ProcessObject::SetNthInput( 1, gradient );
		}
		
		return gradient;
	}
	
	template <class TInputImage, class TOutputImage>
	float
	ConnectedGradientThresholdImageFilter<TInputImage, TOutputImage>
	::GetGradientThreshold() const
	{
		typename GradientThresholdObjectType::Pointer gradient
		= const_cast<Self*>(this)->GetGradientThresholdInput();
		
		return gradient->Get();
	}
	
	/**
	 *	Perform the actual segmentation on the current input image using current threshold value
	 */
	template <class TInputImage, class TOutputImage>
	void 
	ConnectedGradientThresholdImageFilter<TInputImage,TOutputImage>
	::GenerateData()
	{
		InputImageConstPointer inputImage = this->GetInput();
		OutputImagePointer outputImage = this->GetOutput();
		
		typename GradientThresholdObjectType::Pointer gradient = this->GetGradientThresholdInput();
				
		// Zero the output
		OutputImageRegionType region =  outputImage->GetRequestedRegion();
		outputImage->SetBufferedRegion( region );
		outputImage->Allocate();
		outputImage->FillBuffer ( NumericTraits<OutputImagePixelType>::Zero );
		
		typedef GradientThresholdImageFunction<InputImageType, float> FunctionType;
		
		typename FunctionType::Pointer function = FunctionType::New();
		function->SetInputImage ( inputImage );
		function->SetGradientThreshold ( gradient->Get() );
		ProgressReporter progress(this, 0, region.GetNumberOfPixels());
		
		long maxRegionCount = region.GetNumberOfPixels() / m_MaxSegmentationSize;
		long count = 0;

		if (this->m_Connectivity == FaceConnectivity)
		{
			typedef FloodFilledImageFunctionConditionalIterator<OutputImageType, FunctionType> IteratorType;
			IteratorType it ( outputImage, function, m_SeedList );
			it.GoToBegin();
						
			while( !it.IsAtEnd())
			{
				it.Set(m_ReplaceValue);
				++it;
				progress.CompletedPixel();  // potential exception thrown here
				
				//break out of the loop if we have already segmented too many points (wrong threshold value set)
				if(++count > maxRegionCount) 
					break;
			}
		}
		
#ifdef ITK_USE_REVIEW
		else if (this->m_Connectivity == FullConnectivity)
		{
			// use the fully connected iterator here. The fully connected iterator 
			// below is a superset of the above. However, it is reported to be 20%
			// slower. Hence we use this "if" block to use the old iterator when
			// we don't need full connectivity.
			typedef ShapedFloodFilledImageFunctionConditionalIterator<OutputImageType, FunctionType> IteratorType;
			IteratorType it ( outputImage, function, m_SeedList );
			it.FullyConnectedOn();
			it.GoToBegin();
			
			while( !it.IsAtEnd())
			{
				it.Set(m_ReplaceValue);
				++it;
				progress.CompletedPixel();  // potential exception thrown here
				
				//break out of the loop if we have already segmented too many points (wrong threshold value set)
				if(++count > maxRegionCount) 
					break;
			}
		}
#endif
		
	}
	
	
} // end namespace psfITK

#endif

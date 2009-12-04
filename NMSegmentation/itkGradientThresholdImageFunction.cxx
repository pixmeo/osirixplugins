/**************************************************************************
 *
 *  itkConnectedGradientThresholdingImageFunction.cxx
 *  NMSegmentation
 *
 *  Created by Brian Jensen on 24.06.09.
 *  Copyright 2009. All rights reserved.
 *
 **************************************************************************/

#ifndef __itkGradientThresholdImageFunction_cxx
#define __itkGradientThresholdImageFunction_cxx

#include "itkGradientThresholdImageFunction.h"
#include "itkNeighborhoodInnerProduct.h"
#include "itkNeighborhoodOperator.h"
#include "itkNumericTraits.h"
#include "itkSobelOperator.h"

namespace ITKNS
{
	
	template <class TInputImage, class TCoordRep>
	GradientThresholdImageFunction<TInputImage,TCoordRep>
	::GradientThresholdImageFunction()
	{
		m_GradientThreshold = 8.0;	//Default threshold ratio
	}
	
	/**
	 * Returns true if the gradient magnitude lies below the threshold ratio
	 */
	template <class TInputImage, class TCoordRep>
	bool 
	GradientThresholdImageFunction<TInputImage,TCoordRep>
	::EvaluateAtIndex( const IndexType & index ) const
    {
		NeighborhoodInnerProduct<InputImageType, float> innerProduct;
		float gradientMagnitude = NumericTraits<PixelType>::Zero;;
		PixelType neighborhoodAvg = NumericTraits<PixelType>::Zero;;
		SobelOperator<PixelType, InputImageType::ImageDimension> sobelOperator;
		
		// Make sure to initialize the sobel operator before the iterator, otherwise the radius is 0
		sobelOperator.SetDirection(0);
		sobelOperator.CreateDirectional();
		
		//Create the neighborhood iterator with the neighborhood size matching the sobel operators radius
		ConstNeighborhoodIterator<InputImageType> it = ConstNeighborhoodIterator<InputImageType>(sobelOperator.GetRadius(),this->GetInputImage(),this->GetInputImage()->GetBufferedRegion());
		it.SetLocation(index);
				
		//Gradient Magnitude is calculated using: G = sqrt( (Gx)^2 + (Gy)^2 + (Gz)^2 )
		//Use the sobel operator as an approximation for the gradien in each direction
		for(unsigned char i = 0; i < TInputImage::ImageDimension; i++)
		{
			sobelOperator.SetDirection(i);
			sobelOperator.CreateDirectional();			
			gradientMagnitude += vnl_math_sqr( innerProduct(it, sobelOperator));
		}
		
		gradientMagnitude = vcl_sqrt(gradientMagnitude);
				
		//now determine the average intensity value in the neighborhood
		for(unsigned char i = 0; i < it.Size(); ++i)
		{
			neighborhoodAvg += it.GetPixel(i);
		}

		neighborhoodAvg /= it.Size();
		
		if(vnl_math_abs(gradientMagnitude / neighborhoodAvg) <= m_GradientThreshold)
			return true;

		return false;
    }
	
	
	template <class TInputImage, class TCoordRep>
	void 
	GradientThresholdImageFunction<TInputImage,TCoordRep>
	::PrintSelf(std::ostream& os, Indent indent) const
	{
		Superclass::PrintSelf( os, indent );
		
		os << indent << "Gradient Threshold: " << m_GradientThreshold << std::endl;
	}
	
} // end namespace ITKNS

#endif

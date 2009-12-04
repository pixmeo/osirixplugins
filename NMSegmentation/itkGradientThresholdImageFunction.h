/************************************************************************************************
 *
 *  itkConnectedGradientThresholdingImageFunction.h
 *  NMSegmentation
 *
 *	\brief an itkImageFunction that calculates if an image gradient magnitued exceeds
 *				a specific threshold factor
 * 
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@in.tum.de
 *
 * \ingroup NMSegmentation
 * \version 1.01
 * \date 24.06.2009
 *
 *	\description GradientThresholdImageFunction is a conditional image function
 *				that evaluates the input image at a specific location and determines
 *				if the gradient magnitude, which is weighted against the average
 *				intensity value of the neighborhood, exceeds a threshold ratio.
 *				It is most often used in with a ConnectedGradientThresholdImageFiler
 *				segmentation class.
 *
 *
 * \par License:
 * Copyright (c) 2008 - 2009,
 * This programm was created as part of a student research project in cooperation
 * with the Department for Computer Science, Chair XVI (http://campar.in.tum.de)
 * and the Nuklearmedizinische Klinik, Klinikum Rechts der Isar (http://www.nuk.med.tu-muenchen.de)
 * of the Technische Universität München
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
 *
 ********************************************************************************************/

#ifndef __itkGradientThresholdImageFunction_h
#define __itkGradientThresholdImageFunction_h

//Include the namespace definition (note this makes the file objective-c++)
#include "Project_defs.h"

#include "itkImageFunction.h"

namespace ITKNS
{
	
	/** \class GradientThresholdImageFunction
	 *
	 *	\brief an itkImageFunction that calculates if an image gradient magnitued 
	 *				exceeds a specific threshold factor
	 * 
	 * This ImageFunction returns true (or false) if the weighted
	 * gradient magnitude of the point is below a given threshold ratio.
	 * The gradient magnitude is calculated using a sobel convolution 
	 * kernel in each image dimension, which is then weighted against
	 * the average image intensity in the connected neighborhood.
	 * This filter is designed to detect large changes in the image
	 * intensity, mostly for lesion segmentation in PET / SPECT images.
	 * The input image is set via method SetInputImage().
	 *
	 * Methods Evaluate, EvaluateAtIndex and EvaluateAtContinuousIndex
	 * respectively evaluate the function at an geometric point, image index
	 * and continuous image index.
	 *
	 * \ingroup ImageFunctions
	 * 
	 */
	template <class TInputImage, class TCoordRep = float>
	class ITK_EXPORT GradientThresholdImageFunction : 
	public ImageFunction<TInputImage, bool, TCoordRep> 
	{
public:
	/** Standard class typedefs. */
	typedef GradientThresholdImageFunction            Self;
	typedef ImageFunction<TInputImage,bool,TCoordRep> Superclass;
	typedef SmartPointer<Self>                        Pointer;
	typedef SmartPointer<const Self>                  ConstPointer;
	
	/** Run-time type information (and related methods). */
	itkTypeMacro(GradientThresholdImageFunction, ImageFunction);
	
	/** Method for creation through the object factory. */
	itkNewMacro(Self);
	
	/** InputImageType typedef support. */
	typedef typename Superclass::InputImageType InputImageType;
	
	/** Typedef to describe the type of pixel. */
	typedef typename TInputImage::PixelType PixelType;
	
	/** Dimension underlying input image. */
	itkStaticConstMacro(ImageDimension, unsigned int,Superclass::ImageDimension);
	
	/** Point typedef support. */
	typedef typename Superclass::PointType PointType;
	
	/** Index typedef support. */
	typedef typename Superclass::IndexType IndexType;
	
	/** ContinuousIndex typedef support. */
	typedef typename Superclass::ContinuousIndexType ContinuousIndexType;
	
	/** Gradient Threshold the image at a point position
	 *
	 * Returns true if the image gradient magnitude at the specified point position
	 * satisfies the threshold criteria.  The point is assumed to lie within
	 * the image buffer.
	 *
	 * ImageFunction::IsInsideBuffer() can be used to check bounds before
	 * calling the method.
	 */
	virtual bool Evaluate( const PointType& point ) const
    {
		IndexType index;
		this->ConvertPointToNearestIndex( point, index );
		return ( this->EvaluateAtIndex( index ) );
    }
	
	/** Gradient Threshold the image at a continuous index position
	 *
	 * Returns true if the image gradeint magnitude at the specified point position
	 * satisfies the threshold criteria.  The point is assumed to lie within
	 * the image buffer.
	 *
	 * ImageFunction::IsInsideBuffer() can be used to check bounds before
	 * calling the method. 
	 */
	virtual bool EvaluateAtContinuousIndex( 
										   const ContinuousIndexType & index ) const
    {
		IndexType nindex;
		
		this->ConvertContinuousIndexToNearestIndex (index, nindex);
		return this->EvaluateAtIndex(nindex);
    }
	
	/** Gradient Threshold the image at an index position.
	 *
	 * Returns true if the image gradient magnitude at the specified point position
	 * satisfies the threshold criteria.  The point is assumed to lie within
	 * the image buffer.
	 *
	 * ImageFunction::IsInsideBuffer() can be used to check bounds before
	 * calling the method. 
	 */
	virtual bool EvaluateAtIndex( const IndexType & index ) const;	
	
	/* Methods for setting / getting the threshold ratio */
	itkSetMacro(GradientThreshold,float);
	itkGetMacro(GradientThreshold,float);

protected:
	GradientThresholdImageFunction();
	~GradientThresholdImageFunction(){};
	void PrintSelf(std::ostream& os, Indent indent) const;
	
private:
	GradientThresholdImageFunction( const Self& ); //purposely not implemented
	void operator=( const Self& ); //purposely not implemented
	
	/* The gradient theshold value used */
	float m_GradientThreshold;
	
};

} // end namespace ITKNS

//needed in order for the compiler to accept the template code
#if ITK_TEMPLATE_TXX
# include "itkGradientThresholdImageFunction.cxx"
#endif

#endif

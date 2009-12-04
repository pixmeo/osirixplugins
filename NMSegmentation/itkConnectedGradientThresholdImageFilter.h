/************************************************************************************************
 *
 *  itkConnectedGradientThresholdingImageFunction.h
 *  NMSegmentation
 *
 *	\brief an itkImagetoImageFilter that segments an image based upon thesholding of image 
 *				gradient magnitude values.
 * 
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@in.tum.de
 *
 * \ingroup NMSegmentation
 * \version 1.01
 * \date 24.06.2009
 *
 *	\description ConnectedGradientThresholdImageFilter is an image segmentation class
 *				that segments an image based upon weighted the gradient image magnitude
 *				of the image at every searched point. The class starts at a user specified
 *				seed point and calculates the gradient in every dimension, which is then
 *				weighted against the neighborhood average intensity value (9 in 2D, 27 in 3D).
 *				If the weighted gradient magnitude is below the threshold ratio, then all of the
 *				face connected neighbors are added to the list of points to be visited, thus
 *				the image domain is searched in a flood fashion. The algorithm terminates when
 *				there are no more points to be visited.
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

#ifndef __itkConnectedGradientThresholdImageFilter_h
#define __itkConnectedGradientThresholdImageFilter_h

#include "Project_defs.h"

#include "itkImage.h"
#include "itkImageToImageFilter.h"
#include "itkSimpleDataObjectDecorator.h"

namespace ITKNS {
	
	/** \class ConnectedGradientThresholdImageFilter
	 * \brief Label pixels that are connected to a seed and whose gradient magnitude 
	 *        does not exceed a ratio
	 * 
	 * ConnectedGradientThresholdImageFilter labels pixels with ReplaceValue that are
	 * connected to an initial Seed AND do  not exceed a gradient mangitude ratio.
	 *
	 * \ingroup RegionGrowingSegmentation 
	 */
	template <class TInputImage, class TOutputImage>
	class ITK_EXPORT ConnectedGradientThresholdImageFilter:
    public ImageToImageFilter<TInputImage,TOutputImage>
	{
	public:
		/** Standard class typedefs. */
		typedef ConnectedGradientThresholdImageFilter        Self;
		typedef ImageToImageFilter<TInputImage,TOutputImage> Superclass;
		typedef SmartPointer<Self>                           Pointer;
		typedef SmartPointer<const Self>                     ConstPointer;
		
		/** Method for creation through the object factory. */
		itkNewMacro(Self);
		
		/** Run-time type information (and related methods).  */
		itkTypeMacro(ConnectedGradientThresholdImageFilter,
					 ImageToImageFilter);
		
		/* Further useful types */
		typedef TInputImage                           InputImageType;
		typedef typename InputImageType::Pointer      InputImagePointer;
		typedef typename InputImageType::ConstPointer InputImageConstPointer;
		typedef typename InputImageType::RegionType   InputImageRegionType; 
		typedef typename InputImageType::PixelType    InputImagePixelType; 
		typedef typename InputImageType::IndexType    IndexType;
		typedef typename InputImageType::SizeType     SizeType;
		
		typedef TOutputImage                          OutputImageType;
		typedef typename OutputImageType::Pointer     OutputImagePointer;
		typedef typename OutputImageType::RegionType  OutputImageRegionType; 
		typedef typename OutputImageType::PixelType   OutputImagePixelType; 
		
		/** Standard print method */
		void PrintSelf ( std::ostream& os, Indent indent ) const;
		
		/** Set seed point. */
		void SetSeed ( const IndexType & seed )
		{
			this->ClearSeeds();
			this->AddSeed ( seed );
		}
		void AddSeed(const IndexType & seed)
		{
			m_SeedList.push_back ( seed );
			this->Modified();
		}
		
		/** Clear the seed list. */
		void ClearSeeds ()
		{
			if (m_SeedList.size() > 0)
			{
				m_SeedList.clear();
				this->Modified();
			}
		}
		
		
		/** 
		 * Set/Get value to replace thresholded pixels. Pixels that are 
		 *  segmented by this filter will be replaced with this value
		 *  The default is 1. 
		 */
		itkSetMacro(ReplaceValue, OutputImagePixelType);
		itkGetMacro(ReplaceValue, OutputImagePixelType);
		
		/**
		 *	Get Set the Max size in percent of the region that can be segmented
		 */
		itkSetMacro(MaxSegmentationSize, float);
		itkGetMacro(MaxSegmentationSize, float);
		
		/** Type of DataObjects to use for gradient magnitude ratio */
		typedef SimpleDataObjectDecorator<float> GradientThresholdObjectType;
		
		/** Get / Set The gradient magnitude ratio value */
		virtual void SetGradientThreshold( float );
		
		virtual void SetGradientThresholdInput(const GradientThresholdObjectType *);
		
		virtual float GetGradientThreshold() const;
		
		virtual GradientThresholdObjectType * GetGradientThresholdInput();
		
		/** Image dimension constants */
		itkStaticConstMacro(InputImageDimension, unsigned int,
							TInputImage::ImageDimension);
		itkStaticConstMacro(OutputImageDimension, unsigned int,
							TOutputImage::ImageDimension);
		
#ifdef ITK_USE_CONCEPT_CHECKING
		/** Begin concept checking */
		itkConceptMacro(OutputEqualityComparableCheck,
						(Concept::EqualityComparable<OutputImagePixelType>));
		itkConceptMacro(InputEqualityComparableCheck,
						(Concept::EqualityComparable<InputImagePixelType>));
		itkConceptMacro(InputConvertibleToOutputCheck,
						(Concept::Convertible<InputImagePixelType, OutputImagePixelType>));
		itkConceptMacro(SameDimensionCheck,
						(Concept::SameDimension<InputImageDimension, OutputImageDimension>));
		itkConceptMacro(IntConvertibleToInputCheck,
						(Concept::Convertible<int, InputImagePixelType>));
		itkConceptMacro(OutputOStreamWritableCheck,
						(Concept::OStreamWritable<OutputImagePixelType>));
		/** End concept checking */
#endif
		
		/** Face connectivity is 4 connected in 2D, 6  connected in 3D, 2*n   in ND
		 *  Full connectivity is 8 connected in 2D, 26 connected in 3D, 3^n-1 in ND
		 *  Default is to use FaceConnectivity. */
		typedef enum { FaceConnectivity, FullConnectivity } ConnectivityEnumType;
		
#ifdef ITK_USE_REVIEW
		/** Type of connectivity to use (fully connected OR 4(2D), 6(3D), 
		 * 2*N(ND) connectivity) */
		itkSetMacro( Connectivity, ConnectivityEnumType );
		itkGetMacro( Connectivity, ConnectivityEnumType );
#endif
		
	protected:
		ConnectedGradientThresholdImageFilter();
		~ConnectedGradientThresholdImageFilter(){};
		
		std::vector<IndexType> m_SeedList;
		OutputImagePixelType   m_ReplaceValue;
		float m_MaxSegmentationSize;
		
		// Override since the filter needs all the data for the algorithm
		void GenerateInputRequestedRegion();
		
		// Override since the filter produces the entire dataset
		void EnlargeOutputRequestedRegion(DataObject *output);
		
		void GenerateData();
		
		// Type of connectivity to use.
		ConnectivityEnumType m_Connectivity;
		
	private:
		ConnectedGradientThresholdImageFilter(const Self&); //purposely not implemented
		void operator=(const Self&); //purposely not implemented
		
	};
	
} // end namespace psfITK

//Make sure template code gets included by the objective-c++ compiler
#if ITK_TEMPLATE_TXX
# include "itkConnectedGradientThresholdImageFilter.cxx"
#endif


#endif

//
//  ITKCode.cpp
//  ITKPlugin
//
//  Created by Joël Spaltenstein on 2/3/12.
//  Copyright (c) 2012 Spaltenstein Natural Image. All rights reserved.
//

#include "vnl/algo/vnl_fft_1d.h"
// Software Guide : EndCodeSnippet

#include "itkPoint.h"
#include "itkVectorContainer.h"
#include "itkMultiThreader.h"

#include <fstream>
void itk_code(const char *path)
{
    itk::MultiThreader::SetGlobalDefaultNumberOfThreads( 4);

    //  Software Guide : BeginLatex
    //
    //  We should now instantiate the filter that will compute the Fourier
    //  transform of the set of coordinates.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    typedef vnl_fft_1d< double > FFTCalculator;
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  The points representing the curve are stored in a
    //  \doxygen{VectorContainer} of \doxygen{Point}.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    typedef itk::Point< double, 2 >  PointType;
    
    typedef itk::VectorContainer< unsigned int, PointType >  PointsContainer;
    
    PointsContainer::Pointer points = PointsContainer::New();
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  In this example we read the set of points from a text file.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    std::ifstream inputFile;
    inputFile.open(path);
//    
//    if( inputFile.fail() )
//    {
//        std::cerr << "Problems opening file " << argv[1] << std::endl;
//    }
    
    unsigned int numberOfPoints;
    inputFile >> numberOfPoints;
    
    points->Reserve( numberOfPoints );
    
    typedef PointsContainer::Iterator PointIterator;
    PointIterator pointItr = points->Begin();
    
    PointType point;
    for( unsigned int pt=0; pt<numberOfPoints; pt++)
    {
        inputFile >> point[0] >> point[1];
        pointItr.Value() = point;
        ++pointItr;
    }
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  This class will compute the Fast Fourier transform of the input an it will
    //  return it in the same array. We must therefore copy the original data into
    //  an auxiliary array that will in its turn contain the results of the
    //  transform.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    typedef vcl_complex<double>              FFTCoefficientType;
    typedef vcl_vector< FFTCoefficientType > FFTSpectrumType;
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    // The choice of the spectrum size is very important. Here we select to use
    // the next power of two that is larger than the number of points.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    const unsigned int powerOfTwo   =
    (unsigned int)vcl_ceil( vcl_log( (double)(numberOfPoints)) /
                           vcl_log( (double)(2.0)) );
    
    const unsigned int spectrumSize = 1 << powerOfTwo;
    
    //  Software Guide : BeginLatex
    //
    //  The Fourier Transform type can now be used for constructing one of such
    //  filters. Note that this is a VNL class and does not follows ITK notation
    //  for construction and assignment to SmartPointers.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    FFTCalculator  fftCalculator( spectrumSize );
    // Software Guide : EndCodeSnippet
    
    FFTSpectrumType signal( spectrumSize );
    
    pointItr = points->Begin();
    for(unsigned int p=0; p<numberOfPoints; p++)
    {
        signal[p] = FFTCoefficientType( pointItr.Value()[0], pointItr.Value()[1] );
        ++pointItr;
    }
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    // Fill in the rest of the input with zeros. This padding may have
    // undesirable effects on the spectrum if the signal is not attenuated to
    // zero close to their boundaries. Instead of zero-padding we could have used
    // repetition of the last value or mirroring of the signal.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    for(unsigned int pad=numberOfPoints; pad<spectrumSize; pad++)
    {
        signal[pad] = 0.0;
    }
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  Now we print out the signal as it is passed to the transform calculator
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    std::cout << "Input to the FFT transform" << std::endl;
    for(unsigned int s=0; s<spectrumSize; s++)
    {
        std::cout << s << " : ";
        std::cout << signal[s] << std::endl;
    }
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  The actual transform is computed by invoking the \code{fwd_transform}
    //  method in the FFT calculator class.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    fftCalculator.fwd_transform( signal );
    // Software Guide : EndCodeSnippet
    
    //  Software Guide : BeginLatex
    //
    //  Now we print out the results of the transform.
    //
    //  Software Guide : EndLatex
    
    // Software Guide : BeginCodeSnippet
    std::cout << std::endl;
    std::cout << "Result from the FFT transform" << std::endl;
    for(unsigned int k=0; k<spectrumSize; k++)
    {
        const double real = signal[k].real();
        const double imag = signal[k].imag();
        const double magnitude = vcl_sqrt( real * real + imag * imag );
        std::cout << k << "  " << magnitude << std::endl;
    }
    // Software Guide : EndCodeSnippet
}

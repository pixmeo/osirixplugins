//
//  EjectionFraction.m
//  EjectionFraction
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "EjectionFraction.h"
#import "ResultsCardiacController.h"
#import "Point2D.h"

static double cPipi	= 3.141592653589793238;

@implementation EjectionFraction

- (BOOL) checkData
{
 // Long axis length must be non zero
  if (fLengthDias == 0.0 || fLengthSys == 0.0)
  {
	NSRunInformationalAlertPanel(@"Ejection Fraction", @"Long axis length should be non zero for diastolic and systolic regions", @"OK", 0L, 0L);
    return NO;
  };//endif
  
  // MONOPLANE
  if (fLongAxisDias * fLongAxisSys > 0.0)
  {
    fMethod = efMonoplane;
    // compute ejection fraction
    fVolDias = (8.0 * fLongAxisDias * fLongAxisDias) /
  	       (3.0 * cPipi * fLengthDias);
    fVolSys  = (8.0 * fLongAxisSys * fLongAxisSys) /
  	       (3.0 * cPipi * fLengthSys);
    fEF = (int) ((fVolDias - fVolSys) * 100 / fVolDias);

    return YES;
  }//endif
    
  // BIPLANE
  if (fHorLongAxisDias * fHorLongAxisSys * fVerLongAxisDias * fVerLongAxisSys> 0.0)
  {
    fMethod = efBiplane;
    // compute ejection fraction
    fVolDias = (8.0 * fHorLongAxisDias * fVerLongAxisDias) /
  	       (3.0 * cPipi * fLengthDias);
    fVolSys  = (8.0 * fHorLongAxisSys * fVerLongAxisSys) /
  	       (3.0 * cPipi * fLengthSys);
    fEF = (int) ((fVolDias - fVolSys) * 100 / fVolDias);

    return YES;
  }//endif
    
  // HEMIELLIPSE
  if (fShortAxisDias * fShortAxisSys > 0.0)
  {
    fMethod = efHemiEllipse;
    // compute ejection fraction
    fVolDias = (5.0 * fShortAxisDias * fLengthDias) / 6.0;
    fVolSys  = (5.0 * fShortAxisSys * fLengthSys) / 6.0;
    fEF = (int) ((fVolDias - fVolSys) * 100 / fVolDias);

    return YES;
  }//endif
    
  // SIMPSON
  if (fMitralDias * fPapiDias * fMitralSys * fPapiSys > 0.0)
  {
    fMethod = efSimpson;
    // compute ejection fraction
    fVolDias = fLengthDias * (fMitralDias + 2.0 * fPapiDias / 3.0) / 2.0;
    fVolSys  = fLengthSys * (fMitralSys + 2.0 * fPapiSys / 3.0) / 2.0;
    fEF = (int) ((fVolDias - fVolSys) * 100 / fVolDias);

    return YES;
  }//endif
    
  // TEICHHOLZ
  fMethod = efTeichholz;
  fVolDias = 7.0 * fLengthDias*fLengthDias*fLengthDias / (2.4 + fLengthDias);
  fVolSys  = 7.0 * fLengthSys*fLengthSys*fLengthSys / (2.4 + fLengthSys);
  fEF = (int) ((fVolDias - fVolSys) * 100 / fVolDias);
  return YES;
}

- (long) filterImage:(NSString*) menuName
{
	NSArray			*viewersArray;
	NSMutableArray  *pixList;
	NSMutableArray  *roiSeriesList;
	NSMutableArray  *roiImageList;
	DCMPix			*curPix;
	long			i, j, k;
	float			area;
	
	// In this plugin, we will take the search for named ROIs on all available series (2D Viewers)
	// and try to compute the ejection fraction !
	
	fLengthDias = 0.0; //0.00001;
	fLengthSys  = 0.0; //0.00001;

	// MONOPLANE
	fLongAxisDias	   = 0.0;
	fLongAxisSys	   = 0.0;

	// BIPLANE
	fHorLongAxisDias = 0.0;
	fVerLongAxisDias = 0.0;
	fHorLongAxisSys  = 0.0;
	fVerLongAxisSys  = 0.0;

	// HEMI ELLIPSE/CYLINDER
	fShortAxisDias   = 0.0;
	fShortAxisSys	 = 0.0;

	// SIMPSON (simplified)
	fMitralDias	   = 0.0;
	fPapiDias	   = 0.0;
	fMitralSys	   = 0.0;
	fPapiSys	   = 0.0;

	// RESULTS
	fVolDias	   = 0.0;
	fVolSys		   = 0.0;
	fEF 		   = 0;
	fMethod 	   = efNone;
	
	// ROIS ARRAY
	NSMutableArray *roisArray;	// contains the ROIs that will figure on the ejection fraction window
	roisArray = [[NSMutableArray alloc] initWithCapacity:0];
	// IMAGES ARRAY
	NSMutableArray *imagesArray;
	imagesArray = [[NSMutableArray alloc] initWithCapacity:0];
	// SCALES ARRAY
	float scalesArray[10];
	float rotation[10];
	
	int index = 0;
	
	// IMAGES ARRAY
	NSMutableArray *originArray;
	originArray = [[NSMutableArray alloc] initWithCapacity:0];
	
	//patient info. Assuming that all images are from the same patient...
	//NSMutableDictionary *dicomElements = nil;
	NSManagedObject *dicomElements = nil;

	// Get an array with ALL displayed 2D Viewer Windows
	viewersArray = [self viewerControllersList];

	for( i = 0 ; i < [viewersArray count] ; i++)
	{
		// All DCMPix contained in the current series
		pixList = [[viewersArray objectAtIndex: i] pixList];
		
		// All rois contained in the current series
		roiSeriesList = [[viewersArray objectAtIndex: i] roiList];
		
		//patient info. Assuming that all images are from the same patient...
		if (dicomElements==nil)
		{
			//dicomElements = [[[[viewersArray objectAtIndex: i] fileList] objectAtIndex: 0] dicomElements];
			dicomElements = [[[viewersArray objectAtIndex: i] fileList] objectAtIndex: 0];
		}
		
		for( j = 0 ; j < [pixList count]; j++)
		{
			curPix = [pixList objectAtIndex: j];
			fPixelSize = [curPix pixelSpacingX];
			
			// All rois contained in the current image
			roiImageList = [roiSeriesList objectAtIndex: j];
			
			for( k = 0 ; k < [roiImageList count]; k++)
			{
				ROI *roi = [roiImageList objectAtIndex: k];
				BOOL add = NO;
				switch( [roi type])
				{
					case tMesure:
						if( [[roi name] isEqualToString:@"DiasLength"] ||
							[[roi name] isEqualToString:@"DiasDiam"])
							fLengthDias = [roi MesureLength:0L];//*10.;
							add = YES;
							
						if( [[roi name] isEqualToString:@"SystLength"] ||
							[[roi name] isEqualToString:@"SystDiam"])
							fLengthSys = [roi MesureLength:0L];//*10.;
							add = YES;
					break;
					
					case tOPolygon:
					case tCPolygon:
					case tPencil:
						area = [roi roiArea];
						
						if( [[roi name] isEqualToString:@"DiasLong"])
						{
							// diastolic info, take the biggest
							if (area > fLongAxisDias) 
							{
								fLongAxisDias = area;
								fOverDias1 = roi;
							}
							add = YES;
						}
						
						if( [[roi name] isEqualToString:@"SystLong"])
						{
							// systolic info, take the smallest
							if (area < fLongAxisSys || fLongAxisSys == 0.0)
							{
							  fLongAxisSys = area;
							  fOverSys1 = roi;
							}
							add = YES;
						}
						
						// BIPLANE
						if( [[roi name] isEqualToString:@"DiasHorLong"])
						{
							// diastolic info, take the biggest
							if (area > fHorLongAxisDias)
							{
								fHorLongAxisDias = area;
								fOverDias1 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"SystHorLong"])
						{
							// systolic info, take the smallest
							if (area < fHorLongAxisSys || fHorLongAxisSys == 0.0)
							{ 
								fHorLongAxisSys = area;
								fOverSys1 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"DiasVerLong"])
						{
							// diastolic info, take the biggest
							if (area > fVerLongAxisDias) {
								fVerLongAxisDias = area;
								fOverDias2 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"SystVerLong"])
						{
							// systolic info, take the smallest
							if (area < fVerLongAxisSys || fVerLongAxisSys == 0.0) {
								fVerLongAxisSys = area;
								fOverSys2 = roi;
							}
							add = YES;
						}//endif

						// HEMI ELLIPSE/CYLINDER
						if( [[roi name] isEqualToString:@"DiasShort"])
						{
							// diastolic info, take the biggest
							if (area > fShortAxisDias) {
								fShortAxisDias = area;
								fOverDias1 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"SystShort"])
						{
							// systolic info, take the smallest
							if (area < fShortAxisSys || fShortAxisSys == 0.0) {
								fShortAxisSys = area;
								fOverSys1 = roi;
							}
							add = YES;
						}//endif

						// SIMPSON (simplified)
						if( [[roi name] isEqualToString:@"DiasMitral"])
						{
							// diastolic info, take the biggest
							if (area > fMitralDias) {
								fMitralDias = area;
								fOverDias1 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"SystMitral"])
						{
							// systolic info, take the smallest
							if (area < fMitralSys || fMitralSys == 0.0) {
								fMitralSys = area;
								fOverSys1 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"DiasPapi"])
						{
							// diastolic info, take the biggest
							if (area > fPapiDias) {
								fPapiDias = area;
								fOverDias2 = roi;
							}
							add = YES;
						}//endif
						
						if( [[roi name] isEqualToString:@"SystPapi"])
						{
							// systolic info, take the smallest
							if (area < fPapiSys || fPapiSys == 0.0) {
								fPapiSys = area;
								fOverSys2 = roi;
							}
							add = YES;
						}//endif
					break;
				}
				if(add)
				{
					//roi
					[roisArray addObject:roi]; // adding current ROI to list
					// image
					short curIndex = [[[viewersArray objectAtIndex: i] imageView] curImage]; // index of current image displayed on DCMView
					[[[viewersArray objectAtIndex: i] imageView] setIndex:(short)j];
					[[[viewersArray objectAtIndex: i] imageView] display];
					NSImage * imm = [[[viewersArray objectAtIndex: i] imageView] nsimage :NO];
					[imagesArray addObject:imm]; // adding image where the ROI is
					[[[viewersArray objectAtIndex: i] imageView] setIndex:curIndex];
					[[[viewersArray objectAtIndex: i] imageView] display];
					// scale
					scalesArray[index] = [[[viewersArray objectAtIndex: i] imageView] scaleValue];
					// rotation
					rotation[index] = [[[viewersArray objectAtIndex: i] imageView] rotation];
					// origin
					[originArray addObject:[[Point2D alloc] initWithPoint:[[[viewersArray objectAtIndex: i] imageView] origin]]];

					index = index + 1;
				}
			}
		}
	}

	if( [self checkData] == NO) return 0;
	//Now create our results window
	ResultsCardiacController* resultsWin = [[ResultsCardiacController alloc] init];
	[resultsWin setDICOMElements: dicomElements];

	switch( fMethod)
	{
		case efMonoplane:
			[resultsWin setResults  :@"MonoPlane"
									:@"long axis"
									:[NSString stringWithFormat:@"%0.2f ml", fVolDias]
									:[NSString stringWithFormat:@"%0.2f ml", fVolSys]
									:[NSString stringWithFormat:@"%d %%", fEF]
									:@"MonoplaneDiagram"
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		case efBiplane:
			[resultsWin setResults  :@"Bi-Plane"
									:@"long axes"
									:[NSString stringWithFormat:@"%0.2f ml", fVolDias]
									:[NSString stringWithFormat:@"%0.2f ml", fVolSys]
									:[NSString stringWithFormat:@"%d %%", fEF]
									:@"BiplaneDiagram"
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		case efHemiEllipse:
			[resultsWin setResults  :@"Hemi-Ellipse" 
									:@"1 long axis + 1 short axis"
									:[NSString stringWithFormat:@"%0.2f ml", fVolDias]
									:[NSString stringWithFormat:@"%0.2f ml", fVolSys]
									:[NSString stringWithFormat:@"%d %%", fEF]
									:@"CylinderDiagram"
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		case efSimpson:
			[resultsWin setResults  :@"Simpson"
									:@"1 long axis + 2 short axes"
									:[NSString stringWithFormat:@"%0.2f ml", fVolDias]
									:[NSString stringWithFormat:@"%0.2f ml", fVolSys]
									:[NSString stringWithFormat:@"%d %%", fEF]
									:@"SimpsonDiagram"
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		case efTeichholz:
			[resultsWin setResults  :@"Teichholz"
									:@"Teichholz table estimation"
									:[NSString stringWithFormat:@"%0.2f ml", fVolDias]
									:[NSString stringWithFormat:@"%0.2f ml", fVolSys]
									:[NSString stringWithFormat:@"%d %%", fEF]
									:@""
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		case efNone:
			[resultsWin setResults  :@"None"
									:@"None"
									:@"None"
									:@"None"
									:@"None"
									:@""
									:imagesArray
									:roisArray
									:scalesArray
									:rotation
									:originArray];
		break;
		
	}
	
	[resultsWin showWindow:self];
	return 0;
}


@end

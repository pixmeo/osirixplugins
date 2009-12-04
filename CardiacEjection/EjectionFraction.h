//
//  EjectionFraction.h
//  EjectionFraction
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

enum teEF { efMonoplane, efBiplane, efHemiEllipse, efSimpson, efTeichholz, efNone};
// list of different calculus methods for the ejection fraction		       

@interface EjectionFraction : PluginFilter
{

     float	fPixelSize;
     
     // INPUT DATA
     float	fLengthDias;	  // diastolic long axis length
     float	fLengthSys;		  // systolic  long axis length
 
     // MONOPLANE
     float	fLongAxisDias;	  // diastolic long axis area
     float	fLongAxisSys;	  // systolic  long axis area
     
     // BIPLANE
     float	fHorLongAxisDias; // diastolic horizontal long axis area
     float	fVerLongAxisDias; // diastolic vertical   long axis area
     float	fHorLongAxisSys;  // systolic  horizontal long axis area
     float	fVerLongAxisSys;  // systolic  vertical   long axis area
     
     // HEMI ELLIPSE/CYLINDER
     float	fShortAxisDias;   // diastolic short axis area
     float	fShortAxisSys;    // systolic  short axis area

     // SIMPSON (simplified)
     float	fMitralDias;      // diastolic mitral valve area
     float	fPapiDias;        // diastolic papillary muscle area
     float	fMitralSys;       // systolic  mitral valve area
     float	fPapiSys;         // systolic  papillary muscle area

     // RESULTS
     float	fVolDias;	  // diastolic volume
     float	fVolSys;	  // systolic  volume
     int	fEF;		  // ejection fraction
	 int    fMethod;	  // ejection fraction method
	 
     // ROIs used to display diastolic and systolic shapes
     ROI*	fOverDias1;
     ROI*	fOverSys1;
     ROI*	fOverDias2;
     ROI*	fOverSys2;
}

- (long) filterImage:(NSString*) menuName;

@end

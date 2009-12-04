//
//  DCMViewAnnotationCategory.h
//  WindowAnchoredAnnotations
//
//  Created by ibook on 2007-01-07.
//  Copyright 2007 jacques.fauquex@opendicom.com All rights reserved.
//

//#import <Cocoa/Cocoa.h>
//#import <Foundation/Foundation.h>
#import "DCMView.h"
#import "DCMViewCategoryNumberProxy.h"
#import "DCMPix.h"
#import "DCMPixCategoryNumberProxy.h"
@interface DCMView (DCMViewAnnotationCategory)

-(void) processorOfLayout:(NSArray *)curLayout;
-(void) DrawNSStringGLPlugin:(NSString*)str position:(int)pos;
-(NSString *) patientSex;

@end
/*
	//==============STUDY INSTANCE============================================================================
	NSString        *StudyInstanceUID;			//MO valueForKeyPath:@"series.study.studyInstanceUID"
	//--------------STUDY DEPENDANT---------------------------------------------------------------------------

	//Patient
	NSString        *PatientName;				//MO valueForKeyPath:@"series.study.name"
	NSDate          *BirthDate;					//MO valueForKeyPath:@"series.study.dateOfBirth"   ---> for now... string
	NSString        *PatientSex;				//MO valueForKeyPath:@"series.study.patientSex"
	NSString        *PatientID;					//MO valueForKeyPath:@"series.study.patientID"
	//Study
	NSDate          *StudyDateTime;				//MO valueForKeyPath:@"series.study.date"

	//==============SERIES INSTANCE===========================================================================
	NSString        *SeriesInstanceUID;			//MO valueForKeyPath:@"series.seriesDICOMUID" (in angiography, all the secuences share the same seriesInstanceUID...)
	NSNumber        *SeriesNumber;				//MO valueForKeyPath:@"series.id"             (...and are diferenciated by the seriesID
	//--------------SERIES DEPENDANT--------------------------------------------------------------------------
	NSString        *SOPclassUID;				//MO valueForKeyPath:@"series.seriesSOPClassUID"
	NSString        *Modality;					//MO valueForKeyPath:@"series.modality"
	NSString        *SeriesTime;				//MO valueForKeyPath:@"series.date"
	NSNumber        *WindowLevel;				//MO valueForKeyPath:@"series.windowLevel"
	NSNumber        *WindowWidth;				//MO valueForKeyPath:@"series.windowWidth"


	//==============FILE INSTANCE=============================================================================
	NSString        *SOPInstanceUID;			//(each file has one) MO valueForKey:@"sopInstanceUID"
	//--------------FILE DEPENDANT----------------------------------------------------------------------------


	//==============FRAME INSTANCE============================================================================
	NSNumber        *CurFrame;					//[NSNumber numberWithInt:  curImage+1];

*/
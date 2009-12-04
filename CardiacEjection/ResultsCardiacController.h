//
//  ResultsController.h
//  ResultsController
//
//  Created by rossetantoine on Tue Jun 15 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebView.h>
#import "ROI.h"
#import "DCMPix.h"
#import "ViewerController.h"
#import "DCMView.h"
#import "ZoomMatrix.h"

//NSWindowController
@interface ResultsCardiacController : NSWindowController
{
	IBOutlet	NSTextField		*method;
	IBOutlet	NSBox			*resultTextBox;
	IBOutlet	NSTextField		*volDiast;
	IBOutlet	NSTextField		*volSyst;
	IBOutlet	NSTextField		*EF;
	
	IBOutlet	NSBox			*imagesBox;
	IBOutlet	NSImageView		*diagram;
	IBOutlet	ZoomMatrix		*thumbnails;

	//NSMutableDictionary			*dicomElements;
	IBOutlet	NSTextField		*patientInfos;
	IBOutlet	NSTextField		*patientID;
	IBOutlet	NSTextField		*patientName;
	IBOutlet	NSTextField		*patientBirthDate;
}

-(void) setResults:(NSString*) m :(NSString*) d :(NSString*) vD :(NSString*) vS :(NSString*) ef : (NSString*) dia :(NSMutableArray*) imArray: (NSMutableArray*) roiArray: (float[]) scalesArray: (float[]) rotationArray: (NSMutableArray*) originArray;
-(void) setDICOMElements:(NSManagedObject*) dE;
-(void) print:(id)sender;

@end

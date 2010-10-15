//
//  Controller.h
//  Mapping
//
//  Created by Antoine Rosset on Mon Aug 02 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Graph.h"

@interface ControllerCMIRT2Fit : NSWindowController {

					CMIR_T2_Fit_MapFilter	*filter;
					ViewerController	*blendedWindow;

					float				TEValues[ 1000];

	IBOutlet		NSTextField			*factorText, *meanT2Value, *backgroundSignal;
	IBOutlet		NSTextField			*excludeSignal, *numberOfEchos, *numberOfSlides, *currentSlideNumber;
	IBOutlet		NSSlider			*currentSlide;
	IBOutlet		NSComboBox			*currentROI;

	IBOutlet		GraphCMIRT2Fit		*resultView;
	IBOutlet		NSMatrix			*mode;
	IBOutlet		NSButton			*logScale;
	IBOutlet		NSTableView			*TETable;
	
					ViewerController	*new2DViewer;
					ROI					*curROI;
					float				slope, intercept;
	
					NSMutableArray		*currentROIs;
					NSMutableSet		*excludedPoints;
	
	IBOutlet		NSWindow			*fillWindow;
	IBOutlet		NSTextField			*startFill, *endFill, *intervalFill;
	IBOutlet		NSMatrix			*fillMode;
	
					NSMutableArray		*pixListArrays;
					
					NSMutableArray		*pixListResult;
					NSMutableArray		*fileListResult;
	
					int maxNumberOfEchos;
					int XYZ_shift, TE_shift;	
					BOOL setROIFocus;
	
					// tags hard coded in Interface Builder
					int TAG_FILL_INTERVAL;				//1
					int TAG_CURRENT_SLIDE;				//2
					int TAG_CURRENT_SLIDE_NUMBER;		//6
					int TAG_NUMBER_OF_ECHOS;			//4
					int TAG_CURRENT_ROI;				//5
					int TAG_LOG_SCALE;					//10
	
}

-(IBAction) compute:(id) sender;
- (id) init:(CMIR_T2_Fit_MapFilter*) f ;
//- (IBAction) refreshGraph:(id) sender, ...;
- (IBAction) refreshGraph:(id) sender;
-(IBAction) endFill:(id) sender;
- (IBAction) startFill:(id) sender;

- (void) getCurrentImageROIs:(int) selectedImageNo;
- (void) showCurrentROI:(ROI*) roi;
- (void) updateCurrentROIs;
- (id) roiIdentifier: (ROI*) roi;
- (BOOL) roiIdentifierCompare: (ROI*) roi :(id) roiFromList;
- (ROI*) selectedROI;
- (int) getSlideNumber: (int) imageNumber;

@end

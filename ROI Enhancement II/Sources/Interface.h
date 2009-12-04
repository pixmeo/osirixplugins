#pragma once

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
@class ViewerController;
@class ROIList;
@class Chart;
@class Options;
@class UserDefaults;
@class DicomSaveDialog;

@interface Interface : NSWindowController {
	ViewerController* _viewer;
	UserDefaults* _userDefaults;
	IBOutlet ROIList* _roiList;
	IBOutlet Chart* _chart;
	IBOutlet Options* _options;
	IBOutlet NSButton* _csvSaveOptionsIncludeHeaders;
	IBOutlet NSView* _dicomSaveOptions;
		IBOutlet NSColorWell* _dicomSaveOptionsBackgroundColor;
	IBOutlet DicomSaveDialog* _dicomSaveDialog;
	IBOutlet NSNumberFormatter* _decimalFormatter;
	IBOutlet NSNumberFormatter* _floatFormatter;
}

@property(readonly) ViewerController* viewer;
@property(readonly) ROIList* roiList;
@property(readonly) Chart* chart;
@property(readonly) Options* options;
@property(readonly) NSNumberFormatter* decimalFormatter;
@property(readonly) NSNumberFormatter* floatFormatter;
@property(readonly) UserDefaults* userDefaults;

-(id)initForViewer:(ViewerController*)viewer;
-(IBAction)saveDICOM:(id)sender;
-(IBAction)saveAsPDF:(id)sender;
-(IBAction)saveAsTIFF:(id)sender;
-(IBAction)saveAsDICOM:(id)sender;
-(IBAction)saveAsCSV:(id)sender;

@end

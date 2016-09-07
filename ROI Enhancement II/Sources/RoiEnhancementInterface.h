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
@class RoiEnhancementROIList;
@class RoiEnhancementChart;
@class RoiEnhancementOptions;
@class RoiEnhancementUserDefaults;
@class RoiEnhancementDicomSaveDialog;

@interface RoiEnhancementInterface : NSWindowController {
	ViewerController* _viewer;
	RoiEnhancementUserDefaults* _userDefaults;
	IBOutlet RoiEnhancementROIList* _roiList;
	IBOutlet RoiEnhancementChart* _chart;
	IBOutlet RoiEnhancementOptions* _options;
	IBOutlet NSButton* _csvSaveOptionsIncludeHeaders;
	IBOutlet NSView* _dicomSaveOptions;
	IBOutlet NSColorWell* _dicomSaveOptionsBackgroundColor;
	IBOutlet RoiEnhancementDicomSaveDialog* _dicomSaveDialog;
	IBOutlet NSNumberFormatter* _decimalFormatter;
	IBOutlet NSNumberFormatter* _floatFormatter;
}

@property(readonly) ViewerController* viewer;
@property(readonly) RoiEnhancementROIList* roiList;
@property(readonly) RoiEnhancementChart* chart;
@property(readonly) RoiEnhancementOptions* options;
@property(readonly) NSNumberFormatter* decimalFormatter;
@property(readonly) NSNumberFormatter* floatFormatter;
@property(readonly) RoiEnhancementUserDefaults* userDefaults;

-(id)initForViewer:(ViewerController*)viewer;
-(IBAction)saveDICOM:(id)sender;
-(IBAction)saveAsPDF:(id)sender;
-(IBAction)saveAsTIFF:(id)sender;
-(IBAction)saveAsCSV:(id)sender;

@end

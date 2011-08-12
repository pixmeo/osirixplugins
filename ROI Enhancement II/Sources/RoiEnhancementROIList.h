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

enum ROISel {
	ROIMin, ROIMean, ROIMax
};

#import <Cocoa/Cocoa.h>
@class RoiEnhancementInterface, RoiEnhancementROIList;
@class ROI;
@class GRDataSet, GRLineDataSet, RoiEnhancementAreaDataSet;

@interface RoiEnhancementROIRec : NSObject {
	RoiEnhancementROIList* _roiList;
	ROI* _roi;
	NSMenuItem* _menuItem;
	GRLineDataSet *_minDataSet, *_meanDataSet, *_maxDataSet;
	RoiEnhancementAreaDataSet *_minmaxDataSet;
	BOOL _displayed;
}

@property(readonly) ROI* roi;
@property(readonly) NSMenuItem* menuItem;
@property(readonly) GRLineDataSet *minDataSet, *meanDataSet, *maxDataSet;
@property(readonly) RoiEnhancementAreaDataSet *minmaxDataSet;
@property BOOL displayed;

-(id)init:(ROI*)roi forList:(RoiEnhancementROIList*)_roiList;
-(void)updateDisplayed;
@end;


@interface RoiEnhancementROIList : NSObject {
	IBOutlet RoiEnhancementInterface* _interface;
	IBOutlet NSButton* _button;
	IBOutlet NSMenu* _menu;
	IBOutlet NSMenuItem* _all;
	IBOutlet NSMenuItem* _selected;
	IBOutlet NSMenuItem* _checked;
	IBOutlet NSMenuItem* _separator;
	NSMutableArray* _records;
	BOOL _display_all, _display_selected, _display_checked;
}

@property(readonly) RoiEnhancementInterface* interface;

-(void)awakeFromNib;
-(void)loadViewerROIs;

-(unsigned)countOfDisplayedROIs;
-(RoiEnhancementROIRec*)displayedROIRec:(unsigned)index;
-(RoiEnhancementROIRec*)findRecordByROI:(ROI*)roi;
-(RoiEnhancementROIRec*)findRecordByMenuItem:(NSMenuItem*)menuItem;
-(RoiEnhancementROIRec*)findRecordByDataSet:(GRDataSet*)dataSet sel:(ROISel*)sel;
-(RoiEnhancementROIRec*)findRecordByDataSet:(GRDataSet*)dataSet;

-(void)roiChange:(NSNotification*)notification;
-(void)removeROI:(NSNotification*)notification;

-(void)displayAllROIs;
-(IBAction)displayAllROIs:(id)sender;
-(void)displaySelectedROIs;
-(IBAction)displaySelectedROIs:(id)sender;
-(IBAction)displayCheckedROIs:(id)sender;

-(void)changedMin:(BOOL)min mean:(BOOL)mean max:(BOOL)max fill:(BOOL)fill;

@end


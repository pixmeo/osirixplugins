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

enum XRangeMode {
	XRangeEntireStack, XRangeFromCurrentToEnd, XRange4thDimension, XRangeDefinedByUser
};

enum LegendPositionX {
	LegendPositionLeft = 0, LegendPositionRight = 1
};

enum LegendPositionY {
	LegendPositionTop = 0, LegendPositionBottom = 1
};

#import <Cocoa/Cocoa.h>
@class RoiEnhancementInterface;
@class RoiEnhancementUserDefaults;

@interface RoiEnhancementOptions : NSObject {
	IBOutlet RoiEnhancementInterface* _interface;
	// curves
	IBOutlet NSButton *_meanCurve, *_minCurve, *_maxCurve, *_minmaxFill;
	// ranges
	IBOutlet NSPopUpButton* _xRangeMode;
	IBOutlet NSMenuItem *_xRangeEntireStack, *_xRangeFromCurrentToEnd, *_xRange4thDimension, *_xRangeDefinedByUser;
	IBOutlet NSTextField *_xRangeMin, *_xRangeMax;
	IBOutlet NSButton* _logscaleYRange;
	IBOutlet NSButton* _constrainYRange;
	IBOutlet NSTextField *_yRangeMin, *_yRangeMax;
	// legend
	IBOutlet NSButton* _legend;
	IBOutlet NSMatrix *_leftRight, *_topBottom;
	IBOutlet NSCell *_left, *_right, *_top, *_bottom;
	// decorations
	IBOutlet NSButton *_xAxis, *_xTicks, *_xGrid, *_xLabels, *_yAxis, *_yTicks, *_yGrid, *_yLabels, *_background;
	IBOutlet NSColorWell *_majorLineColor, *_minorLineColor, *_backgroundColor;
}


@property(readonly) NSColor* backgroundColor;
@property(readonly) NSColor* majorColor;
@property(readonly) BOOL min, mean, max, fill;
@property(readonly) LegendPositionX legendPositionX;
@property(readonly) LegendPositionY legendPositionY;

-(void)loadUserDefaults;

-(IBAction)curvesChanged:(id)sender;
-(IBAction)xRangeChanged:(id)sender;
-(void)updateXRange;
-(IBAction)yRangeChanged:(id)sender;
-(XRangeMode)xRangeMode;
-(void)updateYRange;
-(IBAction)legendChanged:(id)sender;
-(IBAction)decorationsChanged:(id)sender;

@end

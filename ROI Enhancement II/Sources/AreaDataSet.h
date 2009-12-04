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
@class GRLineDataSet, GRChartView, Chart;

@interface AreaDataSet : NSObject {
	GRLineDataSet* _min;
	GRLineDataSet* _max;
	Chart* _chart;
	BOOL _displayed;
}

@property(readonly) GRLineDataSet* min;
@property(readonly) GRLineDataSet* max;
@property BOOL displayed;

-(id)initWithOwnerChart:(Chart*)chart min:(GRLineDataSet*)min max:(GRLineDataSet*)max;
-(void)drawRect:(NSRect)dirtyRect;

@end

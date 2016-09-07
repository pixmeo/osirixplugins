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
#import <GRChartView.h>
@class RoiEnhancementInterface, RoiEnhancementROIRec;
@class GRLineDataSet;
@class RoiEnhancementAreaDataSet;

@interface RoiEnhancementChart : GRChartView {
	IBOutlet RoiEnhancementInterface* _interface;
	int _xMin, _xMax;
	NSMutableArray* _areaDataSets;
	BOOL _drawsBackground, _drawsLegend;
	BOOL _tracking;
	NSPoint _mousePoint;
	NSMutableArray* _plotValues;
	float _newPlotValue;
	NSMutableDictionary* _cache;
	BOOL _stopDraw;
}

@property(readonly) int xMin, xMax;
@property(nonatomic) BOOL drawsBackground, drawsLegend, stopDraw;

-(GRLineDataSet*)createOwnedLineDataSet;
-(RoiEnhancementAreaDataSet*)createOwnedAreaDataSetFrom:(GRLineDataSet*)min to:(GRLineDataSet*)max;
-(void)refresh:(RoiEnhancementROIRec*)dataSet;
-(void)constrainXRangeFrom:(unsigned)from to:(unsigned)to;
-(void)freeYRange;
-(void)constrainYRangeFrom:(float)min;
-(void)constrainYRangeFrom:(float)min to:(float)max;
-(void)addAreaDataSet:(RoiEnhancementAreaDataSet*)dataSet;
-(void)removeAreaDataSet:(RoiEnhancementAreaDataSet*)dataSet;

-(NSInteger)chart:(GRChartView*)chart numberOfElementsForDataSet:(GRDataSet*)dataSet;
-(double)chart:(GRChartView*)chart yValueForDataSet:(GRDataSet*)dataSet element:(NSInteger)element;

-(NSString*)csv:(BOOL)includeHeaders;

@end

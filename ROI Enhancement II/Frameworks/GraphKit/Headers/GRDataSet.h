//
//  GRDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 06/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRChartView.h"

@class GRAxes;

extern NSString* GRDataSetActualSample;
extern NSString* GRDataSetAutoMarkerColor;
extern NSString* GRDataSetAutoMarkerGlyph;
extern NSString* GRDataSetAutoPlotColor;
extern NSString* GRDataSetAutoSelectionColor;
extern NSString* GRDataSetCalloutMergeThreshold;
extern NSString* GRDataSetCategoryGapFraction;
extern NSString* GRDataSetColorCircle;
extern NSString* GRDataSetColorRectangle;
extern NSString* GRDataSetDeltaLineMode;
extern NSString*	GRDataSetDeltaLineHasBaseline;
extern NSString*	GRDataSetDeltaLineWidth;
extern NSString* GRDataSetDisableFillIfObscuredByLine;
extern NSString* GRDataSetDisableLineFactor;
extern NSString* GRDataSetDrawFlat;
extern NSString* GRDataSetDrawMarkers;
extern NSString* GRDataSetDrawPlotFill;
extern NSString* GRDataSetDrawPlotLine;
extern NSString* GRDataSetDrawPlotOutline;
extern NSString* GRDataSetDrawShadow;
extern NSString* GRDataSetElementMergeThreshold;
extern NSString* GRDataSetHidden;
extern NSString* GRDataSetInheritChartDataSource;
extern NSString* GRDataSetInheritChartDelegate;
extern NSString* GRDataSetLegendLabel;
extern NSString* GRDataSetLegendSampleMode;
extern NSString* GRDataSetMarkerColor;
extern NSString* GRDataSetMarkerFont;
extern NSString* GRDataSetMarkerGlyph;
extern NSString* GRDataSetMarkerMergeThreshold;
extern NSString* GRDataSetMaximumNumberOfPointsWithCallouts;
extern NSString* GRDataSetMinimumNumberOfElementsForCompression;
extern NSString* GRDataSetMinimumNumberOfElementsPerPixelForCompression;
extern NSString* GRDataSetPlotColor;
extern NSString* GRDataSetPlotFillColor;
extern NSString* GRDataSetPlotLineCapStyle;
extern NSString* GRDataSetPlotLineColor;
extern NSString* GRDataSetPlotLineDashPattern;
extern NSString* GRDataSetPlotLineFlatness;
extern NSString* GRDataSetPlotLineJoinStyle;
extern NSString* GRDataSetPlotLineMiterLimit;
extern NSString* GRDataSetPlotLineWidth;
extern NSString* GRDataSetPlotOutlineColor;
extern NSString* GRDataSetSelectionColor;
extern NSString* GRDataSetSelectionLineWidth;
extern NSString* GRDataSetShadowAngle;
extern NSString* GRDataSetShadowBlur;
extern NSString* GRDataSetShadowColor;
extern NSString* GRDataSetShadowOffset;
extern NSString* GRDataSetSumValue;
extern NSString* GRDataSetXMax;
extern NSString* GRDataSetXMin;
extern NSString* GRDataSetYMax;
extern NSString* GRDataSetYMin;

@interface GRDataSet : NSObject <NSCoding, NSCopying>
{
	unsigned int numElements;	// 4 = 0x4
	void *dataPoints;	// 8 = 0x8
	id _dataSource;	// 12 = 0xc
	id _delegate;	// 16 = 0x10
	GRChartView *_chart;	// 20 = 0x14
	GRAxes *_axes;	// 24 = 0x18
	BOOL _customSelection;	// 28 = 0x1c
	NSMutableDictionary *_dataSetProperties;	// 32 = 0x20
	NSRange _selectedRange;	// 36 = 0x24
	id _identifier;	// 44 = 0x2c
	unsigned int elementCapacity;	// 48 = 0x30
	unsigned int _autoPlotColorIndex;	// 52 = 0x34
	int _selectionAnchorPoint;	// 56 = 0x38
	unsigned int _reserved11;	// 60 = 0x3c
}

+ (void)initialize;	// IMP=0x4d59a00c
+ (id)defaultProperties;	// IMP=0x4d59a0c4
+ (id)defaultPropertyForKey:(id)fp8;	// IMP=0x4d59a148
+ (void)setDefaultProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d59a198
+ (void)setDefaultProperties:(id)fp8;	// IMP=0x4d59a2e4
+ (id)defaultColors;	// IMP=0x4d59a37c
+ (void)setDefaultColors:(id)fp8;	// IMP=0x4d59a454
+ (Class)axesClass;	// IMP=0x4d59a4dc
+ (BOOL)accessInstanceVariablesDirectly;	// IMP=0x4d59ae0c
- (void)_setOwnerChart:(id)fp8;	// IMP=0x4d59a4f0
- (id)initWithOwnerChart:(id)fp8;	// IMP=0x4d59a5f8
- (id)init;	// IMP=0x4d59a730
- (void)dealloc;	// IMP=0x4d59a798
- (void)finalize;	// IMP=0x4d59a824
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d59a888
- (id)initWithCoder:(id)fp8;	// IMP=0x4d59aa78
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d59ad28
- (id)_literalPropertyForKey:(id)fp8;	// IMP=0x4d59ae14
- (void)_setLiteralProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d59ae24
- (id)propertyForKey:(id)fp8;	// IMP=0x4d59af14
- (id)valueForUndefinedKey:(id)fp8;	// IMP=0x4d59af7c
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d59af88
- (void)setProperty:(id)fp8 forKey:(id)fp12 andRefresh:(BOOL)fp16;	// IMP=0x4d59b1d0
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d59c4d0
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d59b4c4
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d59b4c8
- (void)setValue:(id)fp8 forUndefinedKey:(id)fp12;	// IMP=0x4d59b4d8
- (void)setProperties:(id)fp8;	// IMP=0x4d59b4e4
- (id)properties;	// IMP=0x4d59b4f4
- (void)_updateTextProperties;	// IMP=0x4d59b534
- (id)_defaultLabelAttributes;	// IMP=0x4d59b538
- (unsigned int)numberOfElements;	// IMP=0x4d59b7f0
- (void)reloadDataInRange:(NSRange)fp8;	// IMP=0x4d59b7f8
- (void)reloadData;	// IMP=0x4d59c45c
- (void)setDataSource:(id)fp8;	// IMP=0x4d59b828
- (id)dataSource;	// IMP=0x4d59b8c4
- (void)setDelegate:(id)fp8;	// IMP=0x4d59b8cc
- (id)delegate;	// IMP=0x4d59b9e0
- (void)setAxes:(id)fp8;	// IMP=0x4d59b9e8
- (id)axes;	// IMP=0x4d59ba54
- (id)_activeAxes;	// IMP=0x4d59ba5c
- (id)chart;	// IMP=0x4d59baf4
- (void)setIdentifier:(id)fp8;	// IMP=0x4d59bafc
- (id)identifier;	// IMP=0x4d59bb58
- (NSRange)selectedRange;	// IMP=0x4d59bb60
- (BOOL)_setSelectedRangeWithoutChangingAnchorPoint:(NSRange)fp8;	// IMP=0x4d59bb74
- (BOOL)setSelectedRange:(NSRange)fp8;	// IMP=0x4d59bc5c
- (BOOL)selectPrevious;	// IMP=0x4d59bca0
- (BOOL)selectPreviousByExtendingSelection;	// IMP=0x4d59bd54
- (BOOL)selectNext;	// IMP=0x4d59be3c
- (BOOL)selectNextByExtendingSelection;	// IMP=0x4d59bef8
- (void)clearSelectedRange;	// IMP=0x4d59bfb0
- (BOOL)_supportsCopyOnScroll;	// IMP=0x4d59bfd0
- (void)resetAutoPlotColor;	// IMP=0x4d59c00c
- (id)autoPlotColor;	// IMP=0x4d59c064
- (void)drawDataSetRect:(NSRect)fp8;	// IMP=0x4d59c0fc
- (void)drawLegendSampleInRect:(NSRect)fp8;	// IMP=0x4d59c110
- (void)_addCursorRects;	// IMP=0x4d59c3b8
- (id)description;	// IMP=0x4d59c3bc
- (double)_maximumUsefulZoomForRealAxis:(BOOL)fp8;	// IMP=0x4d59c450

@end

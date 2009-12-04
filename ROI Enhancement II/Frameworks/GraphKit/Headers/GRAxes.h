//
//  GRAxes.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 10/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GRChartView;

extern NSString* GRAxesBackgroundColor;
extern NSString* GRAxesBezelBorder;
extern NSString* GRAxesBorderType;
extern NSString*	GRAxesNoBorder;
extern NSString*	GRAxesLineBorder;
extern NSString*	GRAxesGrooveBorder;
extern NSString* GRAxesBottomMargin;
extern NSString* GRAxesDrawBackground;
extern NSString* GRAxesDrawPlotFrame;
extern NSString* GRAxesDrawXAxis;
extern NSString* GRAxesDrawXLabels;
extern NSString* GRAxesDrawXMajorLines;
extern NSString* GRAxesDrawXMajorTicks;
extern NSString* GRAxesDrawXMinorLines;
extern NSString* GRAxesDrawXMinorTicks;
extern NSString* GRAxesDrawYAxis;
extern NSString* GRAxesDrawYLabels;
extern NSString* GRAxesDrawYMajorLines;
extern NSString* GRAxesDrawYMajorTicks;
extern NSString* GRAxesDrawYMinorLines;
extern NSString* GRAxesDrawYMinorTicks;
extern NSString* GRAxesFixedXLabelFormat;
extern NSString* GRAxesFixedXMajorUnit;
extern NSString* GRAxesFixedXMinorUnit;
extern NSString* GRAxesFixedXPlotMax;
extern NSString* GRAxesFixedXPlotMin;
extern NSString* GRAxesFixedYLabelFormat;
extern NSString* GRAxesFixedYMajorUnit;
extern NSString* GRAxesFixedYMinorUnit;
extern NSString* GRAxesFixedYPlotMax;
extern NSString* GRAxesFixedYPlotMin;
extern NSString* GRAxesGridBack;
extern NSString* GRAxesGridFront;
extern NSString* GRAxesGridOrder;
extern NSString* GRAxesInheritOwnerDelegate;
extern NSString* GRAxesLabelFont;
extern NSString* GRAxesLeftMargin;
extern NSString* GRAxesMajorLineColor;
extern NSString* GRAxesMajorLineDashPattern;
extern NSString* GRAxesMajorLineWidth;
extern NSString* GRAxesMajorTickLength;
extern NSString* GRAxesMaxNonScientificValue;
extern NSString* GRAxesMaxPrecision;
extern NSString* GRAxesMinNonScientificValue;
extern NSString* GRAxesMinPlotRectHeightFraction;
extern NSString* GRAxesMinPlotRectWidthFraction;
extern NSString* GRAxesMinorLineColor;
extern NSString* GRAxesMinorLineDashPattern;
extern NSString* GRAxesMinorLineWidth;
extern NSString* GRAxesMinorTickLength;
extern NSString* GRAxesRightMargin;
extern NSString* GRAxesSkipOverlappingLabels;
extern NSString* GRAxesSubTitle;
extern NSString* GRAxesSubTitleFont;
extern NSString* GRAxesTopMargin;
extern NSString* GRAxesWindowSize;
extern NSString* GRAxesXAxisScale;
extern NSString*	GRAxesLinearScale;
extern NSString*	GRAxesLog10Scale;
extern NSString* GRAxesXAxisType;
extern NSString*	GRAxesValueAxis;
extern NSString*	GRAxesCategoryAxis;
extern NSString* GRAxesXAxisWindowSize;
extern NSString* GRAxesXLabelFormat;
extern NSString* GRAxesXLabelPrefix;
extern NSString* GRAxesXLabelRotation;
extern NSString* GRAxesXLabelSuffix;
extern NSString* GRAxesXMajorTicksPosition;
extern NSString* GRAxesXMajorUnit;
extern NSString* GRAxesXMajorUnitPhase;
extern NSString* GRAxesXMaxTicks;
extern NSString* GRAxesXMinSpace;
extern NSString* GRAxesXMinTicks;
extern NSString* GRAxesXMinorTicksPosition;
extern NSString* GRAxesXMinorUnit;
extern NSString* GRAxesXPlotMax;
extern NSString* GRAxesXPlotMin;
extern NSString* GRAxesXSpaceAfter;
extern NSString* GRAxesXSpaceBefore;
extern NSString* GRAxesXTitle;
extern NSString* GRAxesXTitleFont;
extern NSString* GRAxesXTitleRotation;
extern NSString* GRAxesXTitleSpacing;
extern NSString* GRAxesYAxisScale; // see GRAxesXAxisScale
extern NSString* GRAxesYAxisType; // see GRAxesXAxisType
extern NSString* GRAxesYAxisWindowSize;
extern NSString* GRAxesYHeadroomFraction;
extern NSString* GRAxesYLabelFormat;
extern NSString* GRAxesYLabelPrefix;
extern NSString* GRAxesYLabelRotation;
extern NSString* GRAxesYLabelSuffix;
extern NSString* GRAxesYMajorTicksPosition;
extern NSString* GRAxesYMajorUnit;
extern NSString* GRAxesYMajorUnitPhase;
extern NSString* GRAxesYMaxTicks;
extern NSString* GRAxesYMinSpace;
extern NSString* GRAxesYMinTicks;
extern NSString* GRAxesYMinorTicksPosition;
extern NSString* GRAxesYMinorUnit;
extern NSString* GRAxesYPlotMax;
extern NSString* GRAxesYPlotMin;
extern NSString* GRAxesYSpaceAfter;
extern NSString* GRAxesYSpaceBefore;
extern NSString* GRAxesYTitle;
extern NSString* GRAxesYTitleFont;
extern NSString* GRAxesYTitleRotation;
extern NSString* GRAxesYTitleSpacing;

extern NSString* GRAxesDrawLegend;
extern NSString* GRAxesDrawLegendBackground;
extern NSString* GRAxesLegendBackgroundColor;
extern NSString* GRAxesLegendBorderType;
extern NSString*	GRAxesLegendNoBorder;
extern NSString*	GRAxesLegendLineBorder;
extern NSString*	GRAxesLegendBezelBorder;
extern NSString*	GRAxesLegendGrooveBorder;
extern NSString* GRAxesLegendBottomPosition;
extern NSString* GRAxesLegendChartMargin;
extern NSString* GRAxesLegendEdgeMargin;
extern NSString* GRAxesLegendFont;
extern NSString* GRAxesLegendGutter;
extern NSString* GRAxesLegendHorizontalSpacing;
extern NSString* GRAxesLegendInsideBottomMargin;
extern NSString* GRAxesLegendInsideLeftMargin;
extern NSString* GRAxesLegendInsideRightMargin;
extern NSString* GRAxesLegendInsideTopMargin;
extern NSString* GRAxesLegendLayoutAutomatic;
extern NSString* GRAxesLegendLayoutDirection;
extern NSString* GRAxesLegendLayoutHorizontal;
extern NSString* GRAxesLegendLayoutVertical;
extern NSString* GRAxesLegendLeftPosition;
extern NSString* GRAxesLegendPosition;
extern NSString* GRAxesLegendRightPosition;
extern NSString* GRAxesLegendSampleWidth;
extern NSString* GRAxesLegendSpacing;
extern NSString* GRAxesLegendTopPosition;
extern NSString* GRAxesLegendUniformSpacing;
extern NSString* GRAxesLegendVerticalSpacing;

@interface GRAxes : NSObject <NSCoding, NSCopying>
{
	NSRect _canvasRect;	// 4 = 0x4
	NSRect _plotRect;	// 20 = 0x14
	NSMutableDictionary *_axesProperties;	// 36 = 0x24
	NSMutableDictionary *_subTitleTextAttributes;	// 40 = 0x28
	id _owner;	// 44 = 0x2c
	id _delegate;	// 48 = 0x30
	GRChartView *_chart;	// 52 = 0x34
	id _identifier;	// 56 = 0x38
	BOOL _needsLayout;	// 60 = 0x3c
	struct {
		NSRect rect;
		NSSize sz;
		NSRect * prect;
		NSArray * arr;
		NSMutableDictionary * md;
		char ch;
	} *_extraData;	// 64 = 0x40
	unsigned int _reserved1;	// 68 = 0x44
	unsigned int _reserved2;	// 72 = 0x48
	unsigned int _reserved3;	// 76 = 0x4c
}

+ (void)initialize;	// IMP=0x4d58ac7c
+ (id)defaultProperties;	// IMP=0x4d58b6b8
+ (id)defaultPropertyForKey:(id)fp8;	// IMP=0x4d58b73c
+ (void)setDefaultProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d58b78c
+ (void)setDefaultProperties:(id)fp8;	// IMP=0x4d58b8d8
+ (BOOL)accessInstanceVariablesDirectly;	// IMP=0x4d58c444
- (void)_setOwner:(id)fp8;	// IMP=0x4d58b970
- (id)initWithOwner:(id)fp8;	// IMP=0x4d58bad4
- (void)dealloc;	// IMP=0x4d58bc20
- (void)finalize;	// IMP=0x4d58bcf8
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d58bd68
- (id)initWithCoder:(id)fp8;	// IMP=0x4d58bf00
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d58c1b0
- (id)owner;	// IMP=0x4d58c30c
- (id)chart;	// IMP=0x4d58c314
- (void)setDelegate:(id)fp8;	// IMP=0x4d58c31c
- (id)delegate;	// IMP=0x4d58c3d8
- (void)setIdentifier:(id)fp8;	// IMP=0x4d58c3e0
- (id)identifier;	// IMP=0x4d58c43c
- (id)_literalPropertyForKey:(id)fp8;	// IMP=0x4d58c44c
- (id)propertyForKey:(id)fp8;	// IMP=0x4d58c45c
- (id)valueForUndefinedKey:(id)fp8;	// IMP=0x4d58c4c4
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d58c4d0
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d58ccd0
- (void)dataSet:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d58cea8
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d58d02c
- (void)setValue:(id)fp8 forUndefinedKey:(id)fp12;	// IMP=0x4d58d290
- (id)properties;	// IMP=0x4d58d29c
- (void)setProperties:(id)fp8;	// IMP=0x4d58d2dc
- (void)_updateTextProperties;	// IMP=0x4d58d2ec
- (void)setCanvasRect:(NSRect)fp8;	// IMP=0x4d58d42c
- (NSRect)canvasRect;	// IMP=0x4d58d5b8
- (NSRect)plotRect;	// IMP=0x4d58d5dc
- (void)setPlotRect:(NSRect)fp8;	// IMP=0x4d590530
- (id)legendLabels;	// IMP=0x4d58d600
- (NSRect)legendRect;	// IMP=0x4d58ec88
- (BOOL)computeLayout;	// IMP=0x4d58d614
- (void)setNeedsLayout:(BOOL)fp8;	// IMP=0x4d58dd2c
- (BOOL)needsLayout;	// IMP=0x4d58dd8c
- (BOOL)_supportsCopyOnScroll;	// IMP=0x4d58dd98
- (void)drawLegendSampleInRect:(NSRect)fp8 forDataSet:(unsigned int)fp24 withHighlight:(BOOL)fp28;	// IMP=0x4d58dda0
- (void)drawLegendRect:(NSRect)fp8;	// IMP=0x4d5907f8
- (void)drawBackgroundInRect:(NSRect)fp8;	// IMP=0x4d58ddb4
- (void)drawGridRect:(NSRect)fp8;	// IMP=0x4d58e0c0
- (void)drawAxesRect:(NSRect)fp8;	// IMP=0x4d58e130
- (BOOL)_zoomInRect:(NSRect)fp8;	// IMP=0x4d58e490
- (BOOL)_zoomOut;	// IMP=0x4d58e4a8
- (BOOL)_autoscale;	// IMP=0x4d58e4b0
- (BOOL)deselectAllPoints;	// IMP=0x4d58e4b8
- (BOOL)selectPoint:(NSPoint)fp8 byExtendingSelection:(BOOL)fp16;	// IMP=0x4d58e5d0
- (BOOL)clickPoint:(NSPoint)fp8;	// IMP=0x4d58e5e0
- (double)_pixelValueForAxis:(unsigned short)fp8;	// IMP=0x4d58e5f0
- (double)xPixelValue;	// IMP=0x4d58e78c
- (double)yPixelValue;	// IMP=0x4d58e79c
- (double)_valueAtPoint:(NSPoint)fp8 axis:(unsigned short)fp16;	// IMP=0x4d58e7ac
- (double)xValueAtPoint:(NSPoint)fp8;	// IMP=0x4d58e9c8
- (double)yValueAtPoint:(NSPoint)fp8;	// IMP=0x4d58e9e0
- (NSPoint)locationForXValue:(double)fp8 yValue:(double)fp16;	// IMP=0x4d58e9f8

@end

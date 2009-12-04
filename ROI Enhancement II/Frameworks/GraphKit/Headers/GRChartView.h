//
//  GRChartView.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 06/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GRAxes;
@class GRDataSet;

extern NSString* GRChartAllowClick;
extern NSString* GRChartAllowHorizontalZoom;
extern NSString* GRChartAllowMultipleSelection;
extern NSString* GRChartAllowSelection;
extern NSString* GRChartAllowVerticalZoom;
extern NSString* GRChartAutoDisableVisualCompressionIfPossible;
extern NSString* GRChartAutoscaleFonts;
extern NSString* GRChartBackgroundColor;
extern NSString* GRChartBorderColor;
extern NSString* GRChartBorderType;
extern NSString*	GRChartNoBorder;
extern NSString*	GRChartLineBorder;
extern NSString*	GRChartBezelBorder;
extern NSString*	GRChartGrooveBorder;
extern NSString* GRChartDefaultValueLabelAttributes;
extern NSString* GRChartDrawBackground;
extern NSString* GRChartDrawValueCallouts;
extern NSString* GRChartDrawValueLabels;
extern NSString* GRChartExactRegion;
extern NSString* GRChartFrameColor;
extern NSString* GRChartIndependentlySelectTiledDataSets;
extern NSString* GRChartIndependentlyZoomTiledDataSets;
extern NSString* GRChartItemsEnclosedByRegion;
extern NSString* GRChartLayoutType;
extern NSString*	GRChartOverlayLayout;
extern NSString*	GRChartVerticalTileLayout;
extern NSString*	GRChartHorizontalTileLayout;
extern NSString* GRChartMainTitle;
extern NSString* GRChartMainTitleFont;
extern NSString* GRChartMaximumXZoom;
extern NSString* GRChartMaximumYZoom;
extern NSString* GRChartOverlayType;
extern NSString*	GRChartStackedFractionOverlay;
extern NSString*	GRChartStackedValueOverlay;
extern NSString*	GRChartIndependentOverlay;
extern NSString* GRChartPassMouseEventsThrough;
extern NSString* GRChartRegionZoomMode; // see GRChartZoomMode
extern NSString* GRChartSamePlotRegion;
extern NSString* GRChartTitleColor;
extern NSString* GRChartVisualCompression;
extern NSString* GRChartZoomMode;
extern NSString*	GRChartZoomPlotOnly;
extern NSString*	GRChartZoomWholeChart;

@interface GRChartView : NSView <NSCoding>
{
	IBOutlet id dataSource;	// 80 = 0x50
	IBOutlet id delegate;	// 84 = 0x54
	NSRect _plotRect;	// 88 = 0x58
	NSRect _canvasRect;	// 104 = 0x68
	GRAxes *_axes;	// 120 = 0x78
	NSMutableArray *_dataSets;	// 124 = 0x7c
	unsigned int _numOwnedDataSets;	// 128 = 0x80
	NSWindow *_zoomWindow;	// 132 = 0x84
	int _zoomDirection;	// 136 = 0x88
	BOOL _zooming;	// 140 = 0x8c
	NSPoint _zoomRectStartScreen;	// 144 = 0x90
	NSPoint _zoomRectEndScreen;	// 152 = 0x98
	NSRange _dirtyDataRange;	// 160 = 0xa0
	NSPoint _reserved2;	// 168 = 0xa8
	NSTimer *_delayedRedrawTimer;	// 176 = 0xb0
	BOOL _forceRedraw;	// 180 = 0xb4
	NSMutableArray *_zoomHistory;	// 184 = 0xb8
	int _interaction;	// 188 = 0xbc
	int _selectionType;	// 192 = 0xc0
	NSScrollView *_scrollView;	// 196 = 0xc4
	double _avgDrawTime;	// 200 = 0xc8
	NSMutableDictionary *_chartProperties;	// 208 = 0xd0
	NSMutableDictionary *_mainTitleTextAttributes;	// 212 = 0xd4
	BOOL _customTileLayout;	// 216 = 0xd8
	BOOL _reserved4;	// 217 = 0xd9
	BOOL _needsLayout;	// 218 = 0xda
	int _tag;	// 220 = 0xdc
	NSArray *_defaultPlotColors;	// 224 = 0xe0
	unsigned int _nextAutoPlotColor;	// 228 = 0xe4
	unsigned int _zoomHistoryPosition;	// 232 = 0xe8
	unsigned int _reserved7;	// 236 = 0xec
}

+ (void)initialize;	// IMP=0x4d588dec
+ (id)defaultCursor;	// IMP=0x4d57e960
+ (id)selectCursor;	// IMP=0x4d57e96c
+ (id)zoomInCursor;	// IMP=0x4d57e978
+ (id)zoomOutCursor;	// IMP=0x4d57e984
+ (id)defaultProperties;	// IMP=0x4d57e990
+ (id)defaultPropertyForKey:(id)fp8;	// IMP=0x4d57ea14
+ (void)setDefaultProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d57ea64
+ (void)setDefaultProperties:(id)fp8;	// IMP=0x4d57ebb0
+ (BOOL)accessInstanceVariablesDirectly;	// IMP=0x4d57faec
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d57ec48
- (id)initWithCoder:(id)fp8;	// IMP=0x4d57f060
- (id)initWithFrame:(NSRect)fp8;	// IMP=0x4d57f4ec
- (void)awakeFromNib;	// IMP=0x4d57f794
- (void)dealloc;	// IMP=0x4d57f97c
- (id)defaultPlotColors;	// IMP=0x4d57fa58
- (void)setDefaultPlotColors:(id)fp8;	// IMP=0x4d57fa60
- (void)resetAutoPlotColors;	// IMP=0x4d57fab8
- (unsigned int)nextAutoPlotColor;	// IMP=0x4d57fad8
- (Class)valueClassForBinding:(id)fp8;	// IMP=0x4d57faf4
- (id)propertyForKey:(id)fp8;	// IMP=0x4d57fda0
- (id)valueForUndefinedKey:(id)fp8;	// IMP=0x4d57fe8c
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d57fe98
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d5802d0
- (void)dataSet:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d5802d4
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d58045c
- (void)setValue:(id)fp8 forUndefinedKey:(id)fp12;	// IMP=0x4d580774
- (id)properties;	// IMP=0x4d580780
- (void)setProperties:(id)fp8;	// IMP=0x4d5807c0
- (void)_updateTextProperties;	// IMP=0x4d5807d0
- (void)setTag:(int)fp8;	// IMP=0x4d5808f4
- (int)tag;	// IMP=0x4d5808fc
- (void)reloadData;	// IMP=0x4d580904
- (void)reloadDataInRange:(NSRange)fp8;	// IMP=0x4d58096c
- (void)setNeedsToReloadData:(BOOL)fp8;	// IMP=0x4d580a2c
- (BOOL)needsToReloadData;	// IMP=0x4d580a5c
- (void)setNeedsToReloadData:(BOOL)fp8 inRange:(NSRange)fp12;	// IMP=0x4d580a6c
- (BOOL)needsToReloadDataInRange:(NSRange)fp8;	// IMP=0x4d580c68
- (void)setDataSource:(id)fp8;	// IMP=0x4d580cb0
- (id)dataSource;	// IMP=0x4d580d60
- (void)setDelegate:(id)fp8;	// IMP=0x4d580d68
- (id)delegate;	// IMP=0x4d580ec0
- (void)setAxes:(id)fp8;	// IMP=0x4d580ec8
- (GRAxes*)axes;	// IMP=0x4d58100c
- (NSRect)canvasRect;	// IMP=0x4d588a10
- (NSRect)plotRect;	// IMP=0x4d5886a0
- (NSRect)canvasRectForDataSetAtIndex:(unsigned int)fp8;	// IMP=0x4d581014
- (BOOL)computeLayout;	// IMP=0x4d58136c
- (void)resizeWithOldSuperviewSize:(NSSize)fp8;	// IMP=0x4d58194c
- (void)setFrameSize:(NSSize)fp8;	// IMP=0x4d5819bc
- (void)setNeedsLayout:(BOOL)fp8;	// IMP=0x4d581a80
- (BOOL)needsLayout;	// IMP=0x4d581a9c
- (void)_updateCopyOnScrollSetting;	// IMP=0x4d581aa8
- (void)viewDidEndLiveResize;	// IMP=0x4d581b70
- (void)delayedRedraw:(id)fp8;	// IMP=0x4d581bf0
- (void)drawRect:(NSRect)fp8;	// IMP=0x4d581c80
- (BOOL)acceptsFirstResponder;	// IMP=0x4d582b00
- (BOOL)canBecomeKeyView;	// IMP=0x4d582bdc
- (BOOL)isOpaque;	// IMP=0x4d582cb8
- (BOOL)_crossDataSetDependenciesExist;	// IMP=0x4d582dac
- (unsigned int)numberOfDataSets;	// IMP=0x4d582e60
- (unsigned int)indexOfDataSet:(id)fp8;	// IMP=0x4d582e70
- (unsigned int)numberOfDataSetsOfKindOfClass:(Class)fp8;	// IMP=0x4d582e80
- (unsigned int)classIndexOfDataSet:(id)fp8;	// IMP=0x4d582f00
- (id)dataSetOfKindOfClass:(Class)fp8 atClassIndex:(unsigned int)fp12;	// IMP=0x4d582fa8
- (id)dataSets;	// IMP=0x4d583034
- (void)addDataSets:(id)fp8 loadData:(BOOL)fp12;	// IMP=0x4d58303c
- (void)addDataSet:(id)fp8 loadData:(BOOL)fp12;	// IMP=0x4d583114
- (void)moveDataSetAtIndex:(unsigned int)fp8 toIndex:(unsigned int)fp12;	// IMP=0x4d583244
- (void)removeAllDataSets;	// IMP=0x4d583438
- (void)removeDataSet:(id)fp8;	// IMP=0x4d583480
- (void)removeDataSetAtIndex:(unsigned int)fp8;	// IMP=0x4d583538
- (void)_addOwnedDataSet:(id)fp8;	// IMP=0x4d583668
- (void)_removeOwnedDataSet:(id)fp8;	// IMP=0x4d583678
- (unsigned int)_numberOfOwnedDataSets;	// IMP=0x4d583688
- (BOOL)_scrollToCenterXValue:(double)fp8;	// IMP=0x4d583690
- (BOOL)_scrollToLeftXValue:(double)fp8;	// IMP=0x4d5838b0
- (BOOL)_scrollToRightXValue:(double)fp8;	// IMP=0x4d583a88
- (BOOL)_scrollToCenterYValue:(double)fp8;	// IMP=0x4d583c9c
- (BOOL)_scrollToBottomYValue:(double)fp8;	// IMP=0x4d583ebc
- (BOOL)_scrollToTopYValue:(double)fp8;	// IMP=0x4d5840a4
- (void)_justifyFromSelection:(int)fp8;	// IMP=0x4d5842b8
- (void)centerSelection;	// IMP=0x4d5845fc
- (void)leftJustifySelection;	// IMP=0x4d58460c
- (void)rightJustifySelection;	// IMP=0x4d58461c
- (void)removeFromSuperview;	// IMP=0x4d58462c
- (void)removeFromSuperviewWithoutNeedingDisplay;	// IMP=0x4d5846c0
- (void)viewDidMoveToSuperview;	// IMP=0x4d584754
- (id)scrollView;	// IMP=0x4d584880
- (id)_createCurrentZoomHistoryEntry;	// IMP=0x4d584888
- (void)_applyZoomHistoryAtIndex:(unsigned int)fp8;	// IMP=0x4d584a48
- (void)_clipViewBoundsChanged:(id)fp8;	// IMP=0x4d584c20
- (void)_rememberCurrentPositionAndZoomClearingSuccessiveEntries:(BOOL)fp8;	// IMP=0x4d58aaa4
- (void)_restorePreviousPositionAndZoom;	// IMP=0x4d58a980
- (void)_restoreNextPositionAndZoom;	// IMP=0x4d584d2c
- (void)_setZoomX:(double)fp8 Y:(double)fp16;	// IMP=0x4d584dd8
- (double)currentXZoom;	// IMP=0x4d5852c4
- (double)currentYZoom;	// IMP=0x4d5853a4
- (double)_maximumUsefulZoomForRealAxis:(BOOL)fp8;	// IMP=0x4d585484
- (double)_maxZoom;	// IMP=0x4d58551c
- (double)_currentXZoom;	// IMP=0x4d58552c
- (double)_currentYZoom;	// IMP=0x4d585538
- (void)_zoomToPercent:(id)fp8;	// IMP=0x4d58a294
- (void)zoomIn:(id)fp8;	// IMP=0x4d585544
- (void)zoomOut:(id)fp8;	// IMP=0x4d585550
- (BOOL)zoomOut;	// IMP=0x4d58555c
- (void)previous:(id)fp8;	// IMP=0x4d5855b8
- (void)next:(id)fp8;	// IMP=0x4d5855c4
- (void)horizontalZoomTo:(id)fp8;	// IMP=0x4d5855d0
- (void)verticalZoomTo:(id)fp8;	// IMP=0x4d585624
- (void)zoomTo:(id)fp8;	// IMP=0x4d58567c
- (void)_log2HorizontalZoomTo:(id)fp8;	// IMP=0x4d5856c8
- (void)_log2VerticalZoomTo:(id)fp8;	// IMP=0x4d58572c
- (void)_log2ZoomTo:(id)fp8;	// IMP=0x4d585794
- (BOOL)zoomInRect:(NSRect)fp8;	// IMP=0x4d5857f0
- (void)zoomToRect:(NSRect)fp8;	// IMP=0x4d585834
- (BOOL)autoscale;	// IMP=0x4d586074
- (void)_updateScrollers;	// IMP=0x4d58616c
- (void)createSelectionRectangle;	// IMP=0x4d5869d8
- (void)sizeSelectionRectangle;	// IMP=0x4d586b78
- (void)removeSelectionRectangle;	// IMP=0x4d587044
- (void)flagsChanged:(id)fp8;	// IMP=0x4d5870b8
- (void)moveLeft:(id)fp8;	// IMP=0x4d587274
- (void)moveLeftAndModifySelection:(id)fp8;	// IMP=0x4d587300
- (void)moveDown:(id)fp8;	// IMP=0x4d5873cc
- (void)moveDownAndModifySelection:(id)fp8;	// IMP=0x4d5873d8
- (void)moveRight:(id)fp8;	// IMP=0x4d5873e4
- (void)moveRightAndModifySelection:(id)fp8;	// IMP=0x4d587470
- (void)moveUp:(id)fp8;	// IMP=0x4d58753c
- (void)moveUpAndModifySelection:(id)fp8;	// IMP=0x4d587548
- (void)keyDown:(id)fp8;	// IMP=0x4d587554
- (void)resetCursorRects;	// IMP=0x4d587984
- (void)mouseDown:(id)fp8;	// IMP=0x4d587b5c
- (void)mouseDragged:(id)fp8;	// IMP=0x4d587d48
- (void)mouseUp:(id)fp8;	// IMP=0x4d587fd0

@end

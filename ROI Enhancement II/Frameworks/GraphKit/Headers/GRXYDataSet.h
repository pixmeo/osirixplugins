//
//  GRXYDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 07/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRDataSet.h"

extern NSString* GRDataSetXYValueLabelAlignBottom;
extern NSString* GRDataSetXYValueLabelAlignCenter;
extern NSString* GRDataSetXYValueLabelAlignLeft;
extern NSString* GRDataSetXYValueLabelAlignRight;
extern NSString* GRDataSetXYValueLabelAlignTop;
extern NSString* GRDataSetXYValueLabelClippingNone;
extern NSString* GRDataSetXYValueLabelClippingPlotRegion;
extern NSString* GRDataSetXYValueLabelClippingVisibleRegion;
extern NSString* GRDataSetXYValueLabelClippingVisibleRegionAllPoints;
extern NSString* GRDataSetXYValueLabelHorizontalAlignment;
extern NSString* GRDataSetXYValueLabelOffset;
extern NSString* GRDataSetXYValueLabelPositionFactor;
extern NSString* GRDataSetXYValueLabelVerticalAlignment;
extern NSString* GRDataSetXYValueLabelXClipping;
extern NSString* GRDataSetXYValueLabelYClipping;
// plot marks
extern NSString* GRBlackCircle;
extern NSString* GRBlackDiamondSuit;
extern NSString* GRBlackMediumSquare;
extern NSString* GRBlackRightPointingTriangle;
extern NSString* GRBlackStar;
extern NSString* GRBlackUpPointingTriangle;
extern NSString* GRCircledBullet;
extern NSString* GRFishEye;
extern NSString* GRFourBalloonSpokedAsterisk;
extern NSString* GRHeavyAsterisk;
extern NSString* GRHeavyGreekCross;
extern NSString* GRHeavyMultiplicationX;
extern NSString* GRMalteseCross;
extern NSString* GRPlusSign;
extern NSString* GRSquaredSquare;
extern NSString* GRSquaredTimes;
extern NSString* GRWhiteCircle;
extern NSString* GRWhiteDiamondContainingBlack;
extern NSString* GRWhiteDiamondMinusWhiteX;
extern NSString* GRWhiteDiamondSuit;
extern NSString* GRWhiteMediumSquare;
extern NSString* GRWhiteRightPointingTriangle;
extern NSString* GRWhiteStar;
extern NSString* GRWhiteUpPointingTriangle;

typedef struct 
	{
    double _field1;
    double _field2;
	} CDAnonymousStruct1;

@interface GRXYDataSet : GRDataSet <NSCoding, NSCopying>
{
	SEL _numElementsSEL;	// 64 = 0x40
	void *_numElementsIMP;	// 68 = 0x44
	SEL _yValueAtIndexSEL;	// 72 = 0x48
	void *_yValueAtIndexIMP;	// 76 = 0x4c
	struct {
		SEL sel;
		void * p;
		char ch;
		double d;
	} *_extraData;	// 80 = 0x50
	SEL _xIntervalAtIndexSEL;	// 84 = 0x54
	void *_xIntervalAtIndexIMP;	// 88 = 0x58
	BOOL _customColors;	// 92 = 0x5c
	SEL _colorAtIndexSEL;	// 96 = 0x60
	void *_colorAtIndexIMP;	// 100 = 0x64
	BOOL _customCallouts;	// 104 = 0x68
	SEL _calloutAtIndexSEL;	// 108 = 0x6c
	void *_calloutAtIndexIMP;	// 112 = 0x70
}

+ (void)initialize;	// IMP=0x4d5a34dc
+ (Class)axesClass;	// IMP=0x4d5a36c8
- (id)initWithOwnerChart:(id)fp8;	// IMP=0x4d5a36dc
- (void)dealloc;	// IMP=0x4d5a374c
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d5a37bc
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d5a4c48
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d5a3ae4
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d5a3c00
- (id)initWithCoder:(id)fp8;	// IMP=0x4d5a3c48
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d5a3cb8
- (void)setDataSource:(id)fp8;	// IMP=0x4d5a3d00
- (BOOL)supportsRangesOnAxis:(unsigned short)fp8;	// IMP=0x4d5a3f58
- (CDAnonymousStruct1)xIntervalAtIndex:(unsigned int)fp8;	// IMP=0x4d5a4000
- (double)yValueAtIndex:(unsigned int)fp8;	// IMP=0x4d5a40fc
- (BOOL)setSelectedRange:(NSRange)fp8;	// IMP=0x4d5a44a8
- (unsigned int)indexOfXvalue:(double)fp8 yValue:(double)fp16 exactMatch:(BOOL)fp24;	// IMP=0x4d5a41c8
- (void)_removeAllTooltips;	// IMP=0x4d5a41d0
- (void)reloadDataInRange:(NSRange)fp8;	// IMP=0x4d5a4dac
- (BOOL)_supportsCopyOnScroll;	// IMP=0x4d5a4264
- (double)_maximumUsefulZoomForRealAxis:(BOOL)fp8;	// IMP=0x4d5a43a8

@end

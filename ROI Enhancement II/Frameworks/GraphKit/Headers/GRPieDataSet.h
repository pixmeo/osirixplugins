//
//  GRPieDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 06/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRDataSet.h"

extern NSString* GRDataSetPieLabelPositionFactor;
extern NSString* GRDataSetPieStartAngle;

@interface GRPieDataSet : GRDataSet <NSCoding, NSCopying>
{
	double _sum;	// 64 = 0x40
	NSMutableArray *_wedgePaths;	// 72 = 0x48
	SEL _numElementsSEL;	// 76 = 0x4c
	void *_numElementsIMP;	// 80 = 0x50
	SEL _yValueAtIndexSEL;	// 84 = 0x54
	void *_yValueAtIndexIMP;	// 88 = 0x58
	SEL _colorAtIndexSEL;	// 92 = 0x5c
	void *_colorAtIndexIMP;	// 96 = 0x60
	SEL _calloutAtIndexSEL;	// 100 = 0x64
	struct {
		void * p;
		double d;
	} *_extraData;	// 104 = 0x68
}

+ (void)initialize;	// IMP=0x4d59c5fc
+ (Class)axesClass;	// IMP=0x4d59c790
- (id)initWithOwnerChart:(id)fp8;	// IMP=0x4d59c7a4
- (void)dealloc;	// IMP=0x4d59c84c
- (void)finalize;	// IMP=0x4d59c8e4
- (id)propertyForKey:(id)fp8;	// IMP=0x4d59c94c
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d59ca9c
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d59cd84
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d59ce44
- (id)initWithCoder:(id)fp8;	// IMP=0x4d59ce8c
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d59cf34
- (void)setDataSource:(id)fp8;	// IMP=0x4d59cff4
- (void)reloadDataInRange:(NSRange)fp8;	// IMP=0x4d59d1a4
- (void)drawLegendSampleInRect:(NSRect)fp8 forWedgeIndex:(unsigned int)fp24;	// IMP=0x4d59d7f4
- (void)drawDataSetRect:(NSRect)fp8;	// IMP=0x4d59de94
- (BOOL)setSelectedRange:(NSRange)fp8;	// IMP=0x4d59d9d8
- (id)view:(id)fp8 stringForToolTip:(int)fp12 point:(NSPoint)fp16 userData:(void *)fp24;	// IMP=0x4d59da58
- (unsigned int)indexOfAngle:(double)fp8;	// IMP=0x4d59dc24
- (double)_maximumUsefulZoomForRealAxis:(BOOL)fp8;	// IMP=0x4d59dda0

@end

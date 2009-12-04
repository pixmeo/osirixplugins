//
//  GRLineDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 07/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRXYDataSet.h"

extern NSString* GRLineDataSetPlotFill;
extern NSString* GRLineDataSetPlotStroke;
extern NSString* GRLineDataSetPlotStyle;

@interface GRLineDataSet : GRXYDataSet <NSCoding, NSCopying>
{
	void *_reservedGRLineDataSet;	// 116 = 0x74
	NSMutableDictionary *_markerTextAttributes;	// 120 = 0x78
}

+ (void)initialize;	// IMP=0x4d59e720
+ (id)defaultMarkers;	// IMP=0x4d59f05c
+ (void)setDefaultMarkers:(id)fp8;	// IMP=0x4d59f0a0
- (id)initWithOwnerChart:(id)fp8;	// IMP=0x4d59f0f8
- (void)dealloc;	// IMP=0x4d59f1d8
- (void)finalize;	// IMP=0x4d59f250
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d59f2b8
- (id)initWithCoder:(id)fp8;	// IMP=0x4d59f300
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d59f364
- (id)propertyForKey:(id)fp8;	// IMP=0x4d59f3e4
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d59f77c
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d59fcf8
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d59ff00
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d59ffc4
- (BOOL)supportsRangesOnAxis:(unsigned short)fp8;	// IMP=0x4d5a0170
- (void)_updateTextProperties;	// IMP=0x4d5a0178
- (void)drawLegendSampleInRect:(NSRect)fp8;	// IMP=0x4d5a0264
- (void)drawDataSetRect:(NSRect)fp8;	// IMP=0x4d5a0608
- (id)view:(id)fp8 stringForToolTip:(int)fp12 point:(NSPoint)fp16 userData:(void *)fp24;	// IMP=0x4d5a2d84
- (unsigned int)indexOfXvalue:(double)fp8 yValue:(double)fp16 exactMatch:(BOOL)fp24;	// IMP=0x4d5a308c

@end
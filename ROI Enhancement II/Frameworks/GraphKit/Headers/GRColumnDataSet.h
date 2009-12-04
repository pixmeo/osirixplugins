//
//  GRColumnDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 07/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRXYDataSet.h"

extern NSString* GRColumnDataSetFillMode;
extern NSString*	GRColumnDataSetFillIndividualElements;
extern NSString*	GRColumnDataSetFillUnionOfElements;

@interface GRColumnDataSet : GRXYDataSet <NSCoding, NSCopying>
{
}

+ (void)initialize;	// IMP=0x4d5960c8
- (void)dealloc;	// IMP=0x4d596328
- (void)finalize;	// IMP=0x4d596390
- (id)propertyForKey:(id)fp8;	// IMP=0x4d5963f8
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d59667c
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d596d24
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d596e1c
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d596f00
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d5970ac
- (id)initWithCoder:(id)fp8;	// IMP=0x4d5970f4
- (id)copyWithZone:(NSZone *)fp8;	// IMP=0x4d59713c
- (BOOL)supportsRangesOnAxis:(unsigned short)fp8;	// IMP=0x4d597184
- (void)drawLegendSampleInRect:(NSRect)fp8;	// IMP=0x4d59718c
- (void)drawDataSetRect:(NSRect)fp8;	// IMP=0x4d59789c
- (id)view:(id)fp8 stringForToolTip:(int)fp12 point:(NSPoint)fp16 userData:(void *)fp24;	// IMP=0x4d597328
- (unsigned int)indexOfXvalue:(double)fp8 yValue:(double)fp16 exactMatch:(BOOL)fp24;	// IMP=0x4d597600

@end
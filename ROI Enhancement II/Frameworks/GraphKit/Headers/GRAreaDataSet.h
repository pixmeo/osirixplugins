//
//  GRAreaDataSet.h
//  GraphKitDemo
//
//  Created by Dave Jewell on 07/11/2008.
//  Copyright 2008 Cocoa Secrets. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GRXYDataSet.h"



@interface GRAreaDataSet : GRXYDataSet <NSCoding>
{
}

+ (void)initialize;	// IMP=0x4d5926e8
- (void)dealloc;	// IMP=0x4d592828
- (void)finalize;	// IMP=0x4d592890
- (id)propertyForKey:(id)fp8;	// IMP=0x4d5928f8
- (void)didSetProperty:(id)fp8 forKey:(id)fp12 replacingOldValue:(id)fp16 andShouldReload:(char *)fp20 andRelayout:(char *)fp24 andRedisplay:(char *)fp28;	// IMP=0x4d592b7c
- (void)setProperty:(id)fp8 forKey:(id)fp12;	// IMP=0x4d59307c
- (void)chart:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d593174
- (void)axes:(id)fp8 propertyChangedForKey:(id)fp12 from:(id)fp16 to:(id)fp20;	// IMP=0x4d593238
- (void)encodeWithCoder:(id)fp8;	// IMP=0x4d5933e4
- (id)initWithCoder:(id)fp8;	// IMP=0x4d59342c
- (BOOL)supportsRangesOnAxis:(unsigned short)fp8;	// IMP=0x4d593474
- (void)drawLegendSampleInRect:(NSRect)fp8;	// IMP=0x4d59347c
- (void)drawDataSetRect:(NSRect)fp8;	// IMP=0x4d593618
- (id)view:(id)fp8 stringForToolTip:(int)fp12 point:(NSPoint)fp16 userData:(void *)fp24;	// IMP=0x4d595c00
- (unsigned int)indexOfXvalue:(double)fp8 yValue:(double)fp16 exactMatch:(BOOL)fp24;	// IMP=0x4d595f14

@end
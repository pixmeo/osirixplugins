//
//  untitled.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EjectionFractionWorkflow+OsiriX.h"

extern NSString* DiasLength;
extern NSString* SystLength;

@interface EjectionFractionAlgorithm : NSObject

@property(readonly) NSArray* groupedRoiIds;
@property(readonly) NSArray* roiIds;

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId;
-(BOOL)typeForRoiId:(NSString*)roiId acceptsTag:(long)tag;
-(NSUInteger)countOfNeededRois;

-(CGFloat)compute:(NSDictionary*)rois;
-(CGFloat)ejectionFractionWithDiastoleVolume:(CGFloat)diasVol systoleVolume:(CGFloat)sysVol;

-(BOOL)needsRoiWithId:(NSString*)roi tag:(long)tag;

@end

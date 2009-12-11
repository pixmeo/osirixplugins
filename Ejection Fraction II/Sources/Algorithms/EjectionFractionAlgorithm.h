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
@property(readonly) NSArray* pairedRoiIds;
@property(readonly) NSArray* roiIds;
-(NSArray*)roiIdsGroupContainingRoiId:(NSString*)roiId;

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId;
-(BOOL)typeForRoiId:(NSString*)roiId acceptsTag:(long)tag;
-(NSUInteger)countOfNeededRois;

-(CGFloat)compute:(NSDictionary*)rois;
-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume;
-(CGFloat)ejectionFractionWithDiastoleVolume:(CGFloat)diasVol systoleVolume:(CGFloat)sysVol;

-(BOOL)needsRoiWithId:(NSString*)roi tag:(long)tag;

-(NSImage*)image;

@end

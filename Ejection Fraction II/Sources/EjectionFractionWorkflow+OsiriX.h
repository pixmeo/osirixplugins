//
//  EjectionFractionWorkflow+OsiriX.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 17.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "EjectionFractionWorkflow.h"

extern NSString* EjectionFractionWorkflowExpectedROIChangedNotification;
extern NSString* EjectionFractionWorkflowROIAssignedNotification;
extern NSString* EjectionFractionWorkflowROIIdInfo;

enum EjectionFractionROIType {
	EjectionFractionROIAny = 0,
	EjectionFractionROIArea,
	EjectionFractionROILength
};

@class ROI;

@interface EjectionFractionWorkflow (OsiriX) 

+(NSArray*)roiTypesForType:(EjectionFractionROIType)roiType;
-(void)initOsiriX;
-(void)deallocOsiriX;
-(void)selectOrOpenViewerForRoiWithId:(NSString*)roi;
-(ROI*)roiForId:(NSString*)roiId;
-(NSArray*)roisForIds:(NSArray*)roiIds;
-(void)showDetails;
-(CGFloat)computeAndOutputDiastoleVolume:(CGFloat&)diasVol systoleVolume:(CGFloat&)systVol;

@end

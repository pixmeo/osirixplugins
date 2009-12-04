//
//  EjectionFractionAlgorithm.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionAlgorithm.h"
#import "EjectionFractionWorkflow.h"
#import <OsiriX Headers/DCMView.h>

NSString* DiasLength = @"Diastole length";
NSString* SystLength = @"Systole length";

@implementation EjectionFractionAlgorithm

-(NSArray*)groupedRoiIds {
	[NSException raise:NSGenericException format:@"EjectionFractionAlgorithm subclass must implement method neededRoiIds"];
	return NULL;
}

-(NSArray*)roiIds {
	NSMutableArray* ret = [NSMutableArray arrayWithCapacity:8];
	
	for (NSArray* group in [self groupedRoiIds])
		[ret addObjectsFromArray:group];
	
	return [[ret copy] autorelease];
}

-(NSUInteger)countOfNeededRois {
	NSUInteger count = 0;

	for (NSArray* group in [self groupedRoiIds])
		count += [group count];
	
	return count;
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasLength] ||
		[roiId isEqualToString:SystLength])
			return EjectionFractionROILength;
	return EjectionFractionROIAny;
}

-(BOOL)typeForRoiId:(NSString*)roiId acceptsTag:(long)tag {
	for (NSNumber* iTag in [EjectionFractionWorkflow roiTypesForType:[self typeForRoiId:roiId]])
		if ([iTag longValue] == tag)
			return YES;
	return NO;
}

-(BOOL)needsRoiWithId:(NSString*)roiId tag:(long)tag {
	for (NSArray* group in [self groupedRoiIds])
		for (NSString* rid in group)
			if ([rid isEqualToString:roiId] && [self typeForRoiId:roiId acceptsTag:tag])
				return YES;

	return NO;
}

-(CGFloat)compute:(NSDictionary*)rois {
	[NSException raise:NSGenericException format:@"EjectionFractionAlgorithm subclass must implement method process:"];
	return 0;
}

-(CGFloat)ejectionFractionWithDiastoleVolume:(CGFloat)diasVol systoleVolume:(CGFloat)sysVol {
	return (diasVol-sysVol)/diasVol;
}

@end

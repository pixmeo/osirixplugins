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
#import "EjectionFractionPlugin.h"
#import <algorithm>

NSString* DiasLength = @"Diastole length";
NSString* SystLength = @"Systole length";

@implementation EjectionFractionAlgorithm
@synthesize workflow = _workflow;

-(NSImage*)image {
	return [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:@"%@-Preview", [self description]] ofType:@"pdf"]] autorelease];
}

-(NSArray*)groupedRoiIds {
	[NSException raise:NSGenericException format:@"EjectionFractionAlgorithm subclass must implement method groupedRoiIds"];
	return NULL;
}

-(NSArray*)pairedRoiIds {
	[NSException raise:NSGenericException format:@"EjectionFractionAlgorithm subclass must implement method pairedRoiIds"];
	return NULL;
}

-(NSArray*)roiIds {
	NSMutableArray* ret = [NSMutableArray arrayWithCapacity:8];
	
	for (NSArray* group in [self groupedRoiIds])
		[ret addObjectsFromArray:group];
	
	return [[ret copy] autorelease];
}

-(NSArray*)roiIdsGroupContainingRoiId:(NSString*)roiId {
	for (NSArray* group in [self groupedRoiIds])
		if ([group containsObject:roiId])
			return group;
	return NULL;
}

-(NSUInteger)countOfNeededRois {
	NSUInteger count = 0;

	for (NSArray* group in [self groupedRoiIds])
		count += [group count];
	
	return count;
}

-(NSColor*)colorForRoiId:(NSString*)roiId {
	NSArray* groups = [self groupedRoiIds];
	for (NSUInteger i = 0; i < [groups count]; ++i)
		if ([[groups objectAtIndex:i] containsObject:roiId])
			return i==0 ? [_workflow diasColor] : [_workflow systColor];
	return [NSColor blackColor];
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
	CGFloat dV, sV;
	return [self compute:rois diastoleVolume:dV systoleVolume:sV];
}

-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	[NSException raise:NSGenericException format:@"EjectionFractionAlgorithm subclass must implement method compute:diastoleVolume:systoleVolume"];
	return 0;
}

-(CGFloat)ejectionFractionWithDiastoleVolume:(CGFloat)diasVol systoleVolume:(CGFloat)sysVol {
	return (diasVol-sysVol)/diasVol;
}

-(CGFloat)roiArea:(ROI*)roi { // if roi is tMesure return area of circle with diameter [roi length]
	if ([roi type] == tMesure)
		return pi*std::pow([roi MesureLength:NULL]/2, 2);
	return [roi roiArea];
}

@end

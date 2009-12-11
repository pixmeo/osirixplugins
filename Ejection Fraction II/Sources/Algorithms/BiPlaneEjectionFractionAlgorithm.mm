//
//  BiPlaneEjectionFractionAlgorithm.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "BiPlaneEjectionFractionAlgorithm.h"
#import "EjectionFractionWorkflow.h"
#import <OsiriX Headers/ROI.h>

NSString* DiasHorLong = @"Diastole horizontal long axis area";
NSString* SystHorLong = @"Systole horizontal long axis area";
NSString* DiasVerLong = @"Diastole vertical long axis area";
NSString* SystVerLong = @"Systole vertical long axis area";

@implementation BiPlaneEjectionFractionAlgorithm

-(NSString*)description {
	return @"Biplane";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasHorLong, DiasVerLong, DiasLength, NULL], [NSArray arrayWithObjects: SystHorLong, SystVerLong, SystLength, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasHorLong, SystHorLong, NULL], [NSArray arrayWithObjects: DiasVerLong, SystVerLong, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasHorLong] ||
		[roiId isEqualToString:SystHorLong] ||
		[roiId isEqualToString:DiasVerLong] ||
		[roiId isEqualToString:SystVerLong])
			return EjectionFractionROIArea;
		
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithHorizontalLongAxisArea:(CGFloat)horLongAxisArea verticalLongAxisArea:(CGFloat)verLongAxisArea length:(CGFloat)length {
	return (horLongAxisArea * verLongAxisArea * 8) / (pi * length * 3);
}

-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithHorizontalLongAxisArea:[[rois objectForKey:DiasHorLong] roiArea]
																						 verticalLongAxisArea:[[rois objectForKey:DiasVerLong] roiArea]
																									   length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithHorizontalLongAxisArea:[[rois objectForKey:SystHorLong] roiArea]
																						verticalLongAxisArea:[[rois objectForKey:SystVerLong] roiArea]
																									  length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

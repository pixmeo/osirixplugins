//
//  MonoPlaneEjectionFractionAlgorithm.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "MonoPlaneEjectionFractionAlgorithm.h"
#import "EjectionFractionWorkflow.h"
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMView.h>

NSString* DiasLong = @"Diastole long axis area";
NSString* SystLong = @"Systole long axis area";

@implementation MonoPlaneEjectionFractionAlgorithm

-(NSString*)description {
	return @"Monoplane";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasLength, DiasLong, NULL], [NSArray arrayWithObjects: SystLength, SystLong, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasLong, SystLong, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasLong] ||
		[roiId isEqualToString:SystLong])
			return EjectionFractionROIArea;
	
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithLongAxisArea:(CGFloat)longAxisArea length:(CGFloat)length {
	return (powf(longAxisArea, 2) * 8) / (pi * length * 3);
}

-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithLongAxisArea:[[rois objectForKey:DiasLong] roiArea]
																							 length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithLongAxisArea:[[rois objectForKey:SystLong] roiArea]
																							length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

//
//  SimpsonEjectionFractionAlgorithm.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "SimpsonEjectionFractionAlgorithm.h"
#import "EjectionFractionWorkflow.h"
#import <OsiriX Headers/ROI.h>

NSString* DiasMitral = @"Diastole base short axis";
NSString* SystMitral = @"Systole base short axis";
NSString* DiasPapi = @"Diastole middle short axis";
NSString* SystPapi = @"Systole middle short axis";

@implementation SimpsonEjectionFractionAlgorithm

-(NSString*)description {
	return @"Simpson";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasMitral, DiasPapi, DiasLength, NULL], [NSArray arrayWithObjects: SystMitral, SystPapi, SystLength, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasMitral, SystMitral, NULL], [NSArray arrayWithObjects: DiasPapi, SystPapi, NULL], [NSArray arrayWithObjects: DiasLength, SystLength, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasMitral] ||
		[roiId isEqualToString:SystMitral] ||
		[roiId isEqualToString:DiasPapi] ||
		[roiId isEqualToString:SystPapi])
		return EjectionFractionROIArea;
		
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithMitralArea:(CGFloat)mitralArea papiArea:(CGFloat)papiArea length:(CGFloat)length {
	return (mitralArea + papiArea * 2 / 3) * length / 2;
}



-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithMitralArea:[[rois objectForKey:DiasMitral] roiArea]
																						 papiArea:[[rois objectForKey:DiasPapi] roiArea]
																						   length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithMitralArea:[[rois objectForKey:SystMitral] roiArea]
																						papiArea:[[rois objectForKey:SystPapi] roiArea]
																						  length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

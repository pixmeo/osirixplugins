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

NSString* DiasMitral = @"Diastole base short axis area/diameter";
NSString* SystMitral = @"Systole base short axis area/diameter";
NSString* DiasPapi = @"Diastole middle short axis area/diameter";
NSString* SystPapi = @"Systole middle short axis area/diameter";

@implementation SimpsonEjectionFractionAlgorithm

-(NSString*)description {
	return @"Simpson";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasLength, DiasMitral, DiasPapi, NULL], [NSArray arrayWithObjects: SystLength, SystMitral, SystPapi, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasMitral, SystMitral, NULL], [NSArray arrayWithObjects: DiasPapi, SystPapi, NULL], [NSArray arrayWithObjects: DiasLength, SystLength, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasMitral] ||
		[roiId isEqualToString:SystMitral] ||
		[roiId isEqualToString:DiasPapi] ||
		[roiId isEqualToString:SystPapi])
		return EjectionFractionROIAreaOrLength;
		
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithMitralArea:(CGFloat)mitralArea papiArea:(CGFloat)papiArea length:(CGFloat)length {
	return (mitralArea + papiArea * 2 / 3) * length / 2;
}



-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithMitralArea:[self roiArea:[rois objectForKey:DiasMitral]]
																						 papiArea:[self roiArea:[rois objectForKey:DiasPapi]]
																						   length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithMitralArea:[self roiArea:[rois objectForKey:SystMitral]]
																						papiArea:[self roiArea:[rois objectForKey:SystPapi]]
																						  length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

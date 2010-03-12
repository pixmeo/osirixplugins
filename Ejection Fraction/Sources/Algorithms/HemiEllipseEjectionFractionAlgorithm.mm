//
//  HemiEllipseEjectionFractionAlgorithm.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 05.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "HemiEllipseEjectionFractionAlgorithm.h"
#import "EjectionFractionWorkflow.h"
#import <OsiriX Headers/ROI.h>

NSString* DiasShort = @"Diastole short axis area/diameter";
NSString* SystShort = @"Systole short axis area/diameter";

@implementation HemiEllipseEjectionFractionAlgorithm

-(NSString*)description {
	return @"Hemi-ellipse";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasLength, DiasShort, NULL], [NSArray arrayWithObjects: SystLength, SystShort, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasShort, SystShort, NULL], [NSArray arrayWithObjects: DiasLength, SystLength, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasShort] ||
		[roiId isEqualToString:SystShort])
			return EjectionFractionROIAreaOrLength;
		
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithShortAxisArea:(CGFloat)shortAxisArea length:(CGFloat)length {
	return (shortAxisArea * length * 5) / 6;
}

-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithShortAxisArea:[self roiArea:[rois objectForKey:DiasShort]]
																							  length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithShortAxisArea:[self roiArea:[rois objectForKey:SystShort]]
																							 length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

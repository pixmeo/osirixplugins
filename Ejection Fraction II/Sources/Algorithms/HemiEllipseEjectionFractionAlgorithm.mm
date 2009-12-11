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

NSString* DiasShort = @"Diastole short axis diameter";
NSString* SystShort = @"Systole short axis diameter";

@implementation HemiEllipseEjectionFractionAlgorithm

-(NSString*)description {
	return @"Hemi-ellipse";
}

-(NSArray*)groupedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasShort, DiasLength, NULL], [NSArray arrayWithObjects: SystShort, SystLength, NULL], NULL];
}

-(NSArray*)pairedRoiIds {
	return [NSArray arrayWithObjects: [NSArray arrayWithObjects: DiasShort, SystShort, NULL], NULL];
}

-(EjectionFractionROIType)typeForRoiId:(NSString*)roiId {
	if ([roiId isEqualToString:DiasShort] ||
		[roiId isEqualToString:SystShort])
			return EjectionFractionROIArea;
		
	return [super typeForRoiId:roiId];
}

-(CGFloat)volumeWithShortAxisArea:(CGFloat)shortAxisArea length:(CGFloat)length {
	return (shortAxisArea * length * 5) / 6;
}

-(CGFloat)compute:(NSDictionary*)rois diastoleVolume:(CGFloat&)diastoleVolume systoleVolume:(CGFloat&)systoleVolume {
	return [self ejectionFractionWithDiastoleVolume: (diastoleVolume = [self volumeWithShortAxisArea:[[rois objectForKey:DiasShort] roiArea]
																							  length:[[rois objectForKey:DiasLength] MesureLength:NULL]])
									  systoleVolume: (systoleVolume = [self volumeWithShortAxisArea:[[rois objectForKey:SystShort] roiArea]
																							 length:[[rois objectForKey:SystLength] MesureLength:NULL]]) ];
}

@end

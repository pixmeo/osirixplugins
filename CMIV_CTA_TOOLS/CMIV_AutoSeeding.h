/*=========================================================================
 CMIVSaveResult
 
 Auto Cropping and Auto Seeding
 
 Author: Chunliang Wang (chunliang.wang@imv.liu.se)
 
 
 Program:  CMIV CTA image processing Plugin for OsiriX
 
 This file is part of CMIV CTA image processing Plugin for OsiriX.
 
 Copyright (c) 2007,
 Center for Medical Image Science and Visualization (CMIV),
 Linköping University, Sweden, http://www.cmiv.liu.se/
 
 CMIV CTA image processing Plugin for OsiriX is free software;
 you can redistribute it and/or modify it under the terms of the
 GNU General Public License as published by the Free Software 
 Foundation, either version 3 of the License, or (at your option)
 any later version.
 
 CMIV CTA image processing Plugin for OsiriX is distributed in
 the hope that it will be useful, but WITHOUT ANY WARRANTY; 
 without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 =========================================================================*/

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "CMIV_CTA_TOOLS.h"

@interface CMIV_AutoSeeding : NSObject {
	ViewerController     *originalViewController;
	NSArray* controllersPixList;
	CMIV_CTA_TOOLS* parent;
	long      imageWidth,imageHeight,imageAmount,imageSize;
	float aortaMaxHu;
	float*	volumeData;
	NSData* vesselnessMapData;
	float vesselnessMapSpacing;

}
-(int)runAutoSeeding:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(NSArray*)pixList:(float*)volumePtr:(BOOL)ribRemoval:(BOOL)centerlineTracking:(BOOL)needVesselEnhance;
-(void)replaceOriginImage:(unsigned char*)outData;
-(int)resampleImage:(float*)input:(float*)output:(long*)indimesion:(long*)outdimesion;
-(int)createCoronaryVesselnessMap:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(float)startscale:(float)endscale:(float)scalestep:(float)targetspacing:(float)rescaleMax:(BOOL)needSaveVesselnessMap;
-(void)rescaleVolume:(float*)img:(int)size:(float)tagetscale;
- (void)saveCurrentSeeds: (unsigned short*)seedData:(int)size;
- (void) runSegmentationAndSkeletonization:(unsigned short*)seedData:(float*)volumeData1;
- (void) useSeedDataToInitializeDirectionData:(unsigned short*)seedData:(float*)inputData:(float*)outputData:(unsigned char*)directionData:(int)volumeSize;
- (void) prepareForCaculateLength:(unsigned short*)dismap:(unsigned char*)directionData;
- (void) prepareForCaculateWightedLength:(float*)outputData:(unsigned char*)directionData;
- (int)inverseMatrix:(float*)inm :(float*)outm;
- (void) saveCenterlinesToPatientCoordinate:(NSArray*)centerlines:(NSArray*)centerlinesNameList;
- (int) searchBackToCreatCenterlines:(NSMutableArray *)acenterline:(int)endpointindex:(unsigned char*)directionData;
-(void)enhanceVolumeWithVesselness;
-(void)deEnhanceVolumeWithVesselness;
-(int)smoothingImages3D:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner:(int)iteration;
- (NSData*)loadImageFromSeries:(NSManagedObject*)series To:(NSMutableArray*)pixList;
-(void) computeIntervalAndFlipIfNeeded: (NSMutableArray*) pixList;
- (void) flipData:(char*) ptr :(long) no :(long) x :(long) y;
@end

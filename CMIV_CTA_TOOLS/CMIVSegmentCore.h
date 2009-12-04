/*=========================================================================

CMIVSegmentCore

the corefunction of this plugin, which is based on competing fuzzy
connectedness tree algorithm

Reference:
1. Tizon X, Smedby …. Segmentation with gray-scale connectedness
can separate arteries and veins in MRA. J Magn Reson Imaging 2002;
15(4):438-45.
2. Lšfving A, Tizon X, Persson P, Smedby …. Angiographic 
visualization of the coronary arteries in computed tomography
angiography with virtual contrast injection. The Internet Journal
of Radiology 2006;4(2)
3. Wang C, Smedby …. Coronary artery Segmentation and Skeletonization
In Volumetric Medical Images based on Competing Fuzzy Connectedness
Tree. Accepted by MICCAI 2007.

Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

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


@interface CMIVSegmentCore : NSObject {
long imageWidth,imageHeight,imageAmount,imageSize;
float *inputData;
float *outputData;
unsigned char* directionOfData;
unsigned char* colorOfData;
float minValueInCurSeries;
float weightThreshold,weightWholeValue;
unsigned short* distanceMap;
float xSpacing,ySpacing,zSpacing;
}
- (void) setImageWidth:(long) width Height:(long) height Amount: (long) amount Spacing:(float*)spacing;  
- (void) startShortestPathSearchAsFloat:(float *) pIn Out:(float *) pOut :(unsigned char*) pMarker Direction: (unsigned char*) pPointers;
- (void) startShortestPathSearchAsFloatWith6Neighborhood:(float *) pIn Out:(float *) pOut Direction: (unsigned char*) pPointers;
- (void) optimizedContinueLoop:(float *) pIn Out:(float *) pOut :(unsigned char*) pMarker Direction: (unsigned char*) pPointers;
- (void) caculatePathLength:(unsigned short *) pDistanceMap Pointer: (unsigned char*) pPointers;
- (unsigned short) lengthOfParent:(int)pointer;
- (int) caculatePathLengthWithWeightFunction:(float *) pIn:(float *) pOut Pointer: (unsigned char*) pPointers:(float) threshold: (float)wholeValue;
- (float) lengthOfParentWithWeightFunction:(int)pointer;
- (void) caculateColorMapFromPointerMap: (unsigned char*) pColor: (unsigned char*) pPointers;
- (unsigned char) colorOfParent:(int)pointer;
- (void) localOptmizeConnectednessTree:(float *)pIn :(float *)pOut:(unsigned short*)pDistanceMap Pointer:(unsigned char*) pPointers :(float)minAtEdge needSmooth:(BOOL)isNeedSmooth;
- (void) runFirstRoundFasterWith26Neigbhorhood;
- (void) checkSaturatedPoints;
- (int) enhanceInputData:(float *)inputData;
-(BOOL)checkForCircle:(int)pointer:(int)target:(int*)deepth;
-(void)refineCenterline:(NSMutableArray*)apath:(float*)weightmap;
-(int)searchLocalMaximum:(int)index;
-(NSMutableArray*) pathToLocalMaximun:(int)index reverse:(BOOL)needreverse;
-(int)onedimensionIndexLookUp:(int)direction;
-(int)ifTwoPointsIsNeighbors:(int)index1:(int)index2;
-(int)findNextUpperNeighborInDirectionMap:(int)index;
-(int)dungbeetleSearching:(NSMutableArray*)apath:(float*)weightmap Pointer:(unsigned char*) pPointers;
-(void)calculateFuzzynessMap:(float*)inData Out:(float*)outData  withDirection:(unsigned char*) dData Minimum:(float)minf;
-(float)getUpperNeighborValueOf:(int)index;
@end

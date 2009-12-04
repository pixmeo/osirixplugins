/*=========================================================================
 CMIVSaveResult
 
 Kernel Algorithms for Auto Cropping and Auto Seeding
 
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
#define AORTAMARKER 1
#define BARRIERMARKER 2
#define OTHERMARKER 3

@interface CMIVAutoSeedingCore : NSObject {
	float* inputData;
	unsigned char* outputData;
	long imageWidth,imageHeight,imageAmount,imageSize;
	float lungThreshold;
	float curveWeightFactor,distanceWeightFactor,intensityWeightFactor,gradientWeightFactor;
	unsigned char* directorMapBuffer;
	long* weightMapBuffer;
	float* curSliceWeightMapBuffer;
	float* lastSliceWeightMapBuffer;
	long* costMapBuffer;
	float zoomFactor;
	float xSpacing,ySpacing,zSpacing;
	float xOrigin,yOrigin,zOrigin;

}
-(int)autoCroppingBasedOnLungSegment:(float*)inData :(unsigned char*)outData:(float)threshold:(float)diameter: (long*)origin:(long*)dimension:(float*)spacing:(float)zoomfactor;
-(void)lungSegmentation:(float*)inData :(unsigned char*)outData:(float)diameter;
-(void)closingVesselHoles:(unsigned char*)img2d8bit :(float)diameter;
-(int)findingHeart:(float*)inData:(unsigned char*)outData:(long*)origin:(long*)dimension;
-(int)createParameterFunctionWithCenter:(long)x:(long)y:(float)diameter:(unsigned char*)img2d8bit:(float*)curve:(float*)precurve;
-(int)convertParameterFunctionIntoCircle:(long)x:(long)y:(float*)curve:(float*)precurve:(unsigned char*)img2d8bit:(float*)image;
-(void)fillAreaInsideCircle:(long*)pcenterx:(long*)pcentery:(unsigned char*)img2d8bit:(float*)curve:(float*)precurve;
//-(int)relabelConnectedArea2D:(unsigned char)binaryimg;
-(int)finding2DMinimiumCostPath:(long)centerx:(long)centery:(float*)curve:(float*)precurve:(unsigned char*)img2d8bit:(float*)image:(long)startangle:(long)endangle;
-(long)dijkstraAlgorithm:(long)width:(long)height:(long)costrange:(long*)weightmap:(unsigned char*)directormap;//return the bridge point between two seeds
-(void)intensityRelatedWeightMap:(long)width:(long)height:(long*)weightmap;
-(void)distanceReleatedWeightMap:(long)startangle:(long)minradius:(long)width:(long)height:(float*)precurve:(float*)weightmap;
-(int)connectedComponetsLabeling2D:(unsigned char*)img2d8bit:(unsigned char*)preSlice:(long*)buffer;
-(void)smoothOutput:(unsigned char*)outData;
-(float)findAorta:(float*)inData:(long*)origin:(long*)dimension:(float*)spacing;
-(int)removeUnrelatedCircles:(NSMutableArray*)circles;
-(int)detectCircles:(NSMutableArray*) circlesArray:(int)nslices;
-(void)exportCircles:(NSArray*)circles;
-(int)findFirstCenter:(unsigned char*)firstSlice;
//-(void)noiseRemoveUsingOpeningAtHighResolution:(unsigned char*)inputData:(int)width:(int)height:(int)amount:(int)kenelsize;
//-(void)closeVesselHolesIn2D:(unsigned char*)imgdata:(int)width:(int)height:(int)amount:(int)kernelsize;
//-(void)fillCirleKernel:(unsigned char*)buf:(int)size;
//-(void)erode2DBinaryImage:(unsigned char*)img:(unsigned char*)imgbuffer:(int)width:(int)height:(unsigned char*)kernel:(int)kernelsize;
//-(void)dilate2DBinaryImage:(unsigned char*)img:(unsigned char*)imgbuffer:(int)width:(int)height:(unsigned char*)kernel:(int)kernelsize;
//-(int)closeVesselHoles:(unsigned char*)inData:(int)width:(int)height:(int)amount:(float*)samplespacing:(int)kenelsize;
- (int) vesselnessFilter:(float *)inputData:(float*)outData:(long*)dimension:(float*)imgspacing:(float)startscale:(float)endscale:(float)scalestep;
-(float)caculateAortaMaxIntensity:(float*)img:(int)imgwidth:(int)imgheight:(int)centerx:(int)centery:(int)radius;
-(int)crossectionGrowingWithinVolume:(float*)volumeData ToSeedVolume:(unsigned short*)seedData Dimension:(long*)dim Spacing:(float*)spacing StartPt:(float*)ptxyz Threshold:(float)threshold Diameter:(float)diameter;
-(float)compareOverlappedRegion:(unsigned char*)firstRegion:(unsigned char*)secondRegion:(int)regionSize;
-(float)findingIncirleCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center;
-(void)findingGravityCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center;
-(int) LinearRegression:(double*)data :(int)rows:(double*)a:(double*)b;
- (void) fixHolesInBarrierInVolume:(unsigned short*)contrastVolumeData:(int)minx :(int)maxx :(int)miny :(int)maxy :(int)minz :(int)maxz :(short unsigned int) marker;
-(float)findingMaxDistanceToGravityCenterOfRegion:(unsigned char*)buffer:(int)width:(int)height:(int*)center;
-(BOOL) detectAorticValve:(float*)inputimg:(unsigned char*)segmenresult:(int)width:(int)height:(int*)center:(float)radius:(double*)spacing;
- (int) smoothingFilter:(float *)inData:(float*)outData:(long*)dimension:(float*)imgspacing:(int)iteration;
@end

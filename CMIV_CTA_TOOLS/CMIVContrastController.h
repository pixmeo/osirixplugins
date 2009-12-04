
/*=========================================================================
CMIVContrastController

Reed Seeds information stored in current series as ROIs, and 
prepare the parameters for the "CMIVSegmentCore" and pass down
the segment result to "CMIVContrastPreview" to show the results.

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
#import "PluginFilter.h"
#import "CMIV_CTA_TOOLS.h"

@interface CMIVContrastController : NSObject
{

    IBOutlet NSTableView *inROIList;
    IBOutlet NSTableView *outROIList;
    IBOutlet NSWindow *window;
	IBOutlet NSButton *exportIntoOneChechBox;
	IBOutlet NSButton *exportIntoSeparateChechBox;
	IBOutlet NSButton *exportIntoMaskChechBox;
	IBOutlet NSButton *exportCenterlineChechBox;
	IBOutlet NSButton *exportConnectednessChechBox;
	IBOutlet NSMatrix *neighborhoodModeMatrix;
	NSMutableArray *inROIArray,*outROIArray,*outputColorList;
	int imageWidth,imageHeight,imageAmount,imageSize;
	float minValueInCurSeries,upperThreshold,lowerThreshold;
	ViewerController     *originalViewController;
	int   ifUseSmoothFilter;
	CMIV_CTA_TOOLS* parent;
}
- (IBAction)addToRight:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onPreview:(id)sender;
- (IBAction)onOk:(id)sender;
- (IBAction)removeFromRight:(id)sender;
- (int) showContrastPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner;
- (long) seedPlantingfloat:(float *)inputData :(float *)outputData :(unsigned char *)colorData;
- (int) exportToImages:(float *)inputData :(float *)outputData :(unsigned char *)colorData;
- (int) exportToROIs:(float *)inputData :(float *)outputData :(unsigned char *)colorData;
- (int) exportToSeries:(float *)inputData :(float *)outputData :(unsigned char *)colorData;
- (int) exportToCenterLines:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData;
- (int) exportToTempFolder:(float *)inputData :(float *)outputData :(unsigned char *)colorData;
- (int) createCenterlines:(float *)inputData :(float *)outputData :(unsigned char *)directData :(unsigned char *)colorData :(NSMutableArray*)roilist;
- (BOOL) prepareForSkeletonizatin:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData;
- (int)plantRootSeeds:(float *)inputData :(float *)outputData :(unsigned char *)directData:(unsigned char *)colorData;
- (void) prepareForCaculateLength:(unsigned short *)distanceMap :(unsigned char *)directData;
- (void) prepareForCaculateWeightedLength:(float *)distanceMap :(unsigned char *)directData;

- (int) searchBackToCreatCenterlines:(NSMutableArray *)pathsList:(int)endpointindex:(unsigned char*)directionData:(unsigned char*)color;
- (void)createROIfrom3DPaths:(NSArray*)pathsList:(NSArray*)namesList:(NSMutableArray*)roilist;
- (void) runSegmentation:(float **)ppInData :(float **)ppOutData :(unsigned char **)ppColorData:(unsigned char **)ppDirectionData;
- (void) enhanceCenterline:(float *)inputData:(unsigned char *)colorData:(NSMutableArray *)pathlists;
	// Table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex;
@end

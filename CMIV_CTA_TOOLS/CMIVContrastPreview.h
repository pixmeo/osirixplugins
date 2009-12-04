/*=========================================================================
CMIVContrastPreview

Show the segment result and allow the users to adjust the seeds
interactively. Also run the skeletonization algorithm to find 
the centerlines of the segment results, pass down those
centerlines to "CMIVScissorController"

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
#import "VRView.h"
#import "CMIV_CTA_TOOLS.h"
#import "CMIVWindow.h"
#import "CMIVDCMView.h"
#define id Id
#include <vtkColorTransferFunction.h>
#include <vtkRenderer.h>
#include <vtkVolumeCollection.h>
#include <vtkVolume.h>
#include <vtkVolumeProperty.h>
#include <vtkImageImport.h>
#include <vtkTransform.h>
#include <vtkImageReslice.h>
#include <vtkVolumeMapper.h>
#include <vtkImageData.h>
#include <vtkTransformFilter.h>
#undef id

@interface CMIVContrastPreview : NSWindowController
{
    IBOutlet CMIVDCMView *mprView;
    IBOutlet NSTableView *seedList;
    IBOutlet CMIVDCMView *resultView;
	IBOutlet NSWindow	*skeletonWindow;
    IBOutlet NSSlider *mprPageSlider;
	IBOutlet NSSlider *resultPageSlider;
	IBOutlet NSSlider *thresholdSlider;
	IBOutlet NSTextField *brushWidthText;
	
	IBOutlet NSTextField *thresholdForDistalEnd;	
	IBOutlet NSTextField *thresholdForBranch;
	
	IBOutlet NSTextField *thresholdForConnectedness;	
	
	IBOutlet NSSlider *mprXRotateSlider;
    IBOutlet NSSlider *mprYRotateSlider;
	IBOutlet NSButton *crossShowButton;	
	IBOutlet NSButton *centerLock;
	
	IBOutlet NSButton *vrColorLock;
    IBOutlet NSMatrix *vrMode;
	IBOutlet NSTextField *wizardTips;
	
	IBOutlet NSButton *updateButton;
	IBOutlet NSButton *skeletonztionButton;
	IBOutlet NSPopUpButton *exportButton;
	
	IBOutlet NSSlider *brushWidthSlider;
	IBOutlet NSTabView *tab2D3DView;
	IBOutlet VRView   *vrView;
	
	IBOutlet NSButton *saveBeforeSkeletonization;
	IBOutlet NSTextField *oViewRotateXText;
	IBOutlet NSTextField *oViewRotateYText;
	
	IBOutlet NSMatrix	*toolsMatrix;
	IBOutlet NSTextField *skeletonParaCalciumThreshold;
	IBOutlet NSTextField *vesselEnhancedNotice;

	
	ViewerController     *originalViewController;
	NSData               *originalViewVolumeData;
	NSArray              *originalViewPixList;

	BOOL     roiShowNameOnly, roiShowTextOnlyWhenSeleted;
	float *inputData ;
	float *outputData ;
	unsigned short *volumeDataOfVR;
	unsigned char *colorData,*directionData;
	int      imageWidth,imageHeight,imageAmount,imageSize;
	float    minValueInCurSeries, maxValueInCurSeries;
	
	float    sliceThickness;
	float	 vtkOriginalX,vtkOriginalY,vtkOriginalZ;
	float    xSpacing,ySpacing,zSpacing,minSpacing;
	float    centerX,centerY,centerZ; //for lock center , not useful now
	unsigned short int*   newSeedsBuffer;
	float    mprViewRotateAngleX,mprViewRotateAngleY;
	int      centerIsLocked;
	double	 mprViewSpace[3], mprViewOrigin[3];
	float    lastMPRViewTranslate;
	float    lastMPRViewXAngle,lastMPRViewYAngle;
	vtkImageReslice		*mprViewSlice,*mprViewROISlice;
	vtkImageImport		*reader,*roiReader;
	vtkTransform		*mprViewBasicTransform,*mprViewUserTransform;
	vtkTransform		*inverseTransform;
	
	vtkRenderer *renderOfVRView;
	vtkVolumeCollection *volumeCollectionOfVRView;
	vtkVolume   *volumeOfVRView;
	vtkVolumeMapper *volumeMapper;
	vtkImageData *volumeImageData;	
	
	NSMutableArray *choosenSeedsArray,*showSeedsArray;
	NSMutableArray *centerlinesList;
	NSMutableArray *centerlinesNameList;
	NSMutableArray      *MPRPixList;
	NSArray             *MPRFileList;
	NSMutableArray      *MPRROIList;
	NSMutableArray		*resultPixList;
	NSMutableArray		*resultROIList;
	NSMutableArray		*resultPrivateROIList;
	NSMutableArray		*resultFileList;
	DCMPix* firstPix;	
	int                 isRemoveROIBySelf;
	NSMutableArray		*newSeedsROIList;
	int                 uniIndex;
	int                 resultViewROIMode;
	int                 segmentNeighborhood;

	int  lastResultSliderPos;
	int interpolationMode;
	

	float osirixOffset;
	float osirixValueFactor;
	CMIV_CTA_TOOLS* parent;
	BOOL isInWizardMode;
	NSRect screenrect;
	NSData*            parentSeedData;
	NSData*            parentInputData;
	NSData*            parentOutputData;
	NSData*            parentColorData;
	NSData*            parentDirectionData;
	NSMutableArray* endPointsArray;
	NSMutableArray* endPointROIsArray;
	NSMutableArray* manualCenterlinesArray;
	NSMutableArray* manualCenterlineROIsArray;
	float               defaultROIThickness;
	float  maxHuofRootSeeds;
	float skeletonParaLengthThreshold,skeletonParaEndHuThreshold,skeletonParaCalThreshold;
	

}
- (IBAction)chooseASeed:(id)sender;
- (IBAction)chooseATool:(id)sender;
- (IBAction)setBrushWidth:(id)sender;
- (IBAction)setBrushMode:(id)sender;

- (IBAction)continueTheLoop:(id)sender;
- (IBAction)finishAdjustion:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)pageMPRView:(id)sender;
- (IBAction)pageResultView:(id)sender;
- (IBAction)setConnectnessMapThreshold:(id)sender;
- (IBAction)exportResults:(id)sender;
- (IBAction)rotateXMPRView:(id)sender;
- (IBAction)rotateYMPRView:(id)sender;
- (IBAction)changMPRViewDirection:(id)sender;
- (IBAction)resetMPRView:(id)sender;
- (IBAction)showCross:(id)sender;
- (IBAction)createSkeleton:(id)sender;
- (IBAction)showSkeletonDialog:(id)sender;
- (IBAction)endSkeletonDialog:(id)sender;

- (IBAction)changeVRMode:(id)sender;
- (IBAction)changeVRColor:(id)sender;
- (IBAction)changeVRDirection:(id)sender;
- (IBAction)loadAEndPointForCenterline:(id)sender;

- (void)    rotateZMPRView:(float)angle;
- (id) showPreviewPanel:(ViewerController *) vc:(float*)inData:(float*)outData:(unsigned char*)colData:(unsigned char*)direData;
- (id)showPanelAsWizard:(ViewerController *) vc:(	CMIV_CTA_TOOLS*) owner;
- (int) initViews;
- (void)setSeedLists:(NSMutableArray *)choosenseedList: (NSMutableArray *)showSeedList;
- (void)resultViewUpdateROI:(int)index;
- (void) roiChanged: (NSNotification*) note;
- (void) roiAdded: (NSNotification*) note;
- (void) roiRemoved: (NSNotification*) note;
- (void) defaultToolModified: (NSNotification*) note;
- (void) changeWLWW: (NSNotification*) note;
- (void) crossMove:(NSNotification*) note;
- (void) exportToROIs;
- (void) exportToPreResult;
- (void) exportUnderMaskToImages;
- (void) exportToSeparateSeries;
- (void) updateMPRView;
- (void) updateResultView;
- (void) updateMPRPageSlider;
- (void) resetMPRSliders;
- (void) synchronizeMPRView:(int)page;
- (void) updateVRView;
- (void) creatROIListFromSlices:(NSMutableArray*) roiList :(int) width:(int)height:(short unsigned int*)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY;
- (void) createVolumDataUnderMask:(float*)volumeData:(NSArray*)exportList;
- (void) createUnsignedShortVolumDataUnderMask:(unsigned short*)volumeData;
- (void) Display3DPoint:(NSNotification*) note;
- (BOOL) prepareForSkeletonizatin;
- (void) prepareForCaculateLength:(unsigned short*)dismap;
- (void) prepareForCaculateWightedLength;

- (int) searchBackToCreatCenterlines:(NSMutableArray *)pathsList:(int)endpointindex:(unsigned char*)color;
- (void) replaceDistanceMap;
- (float)valueAfterConvolutionAt:(int)x:(int)y:(int)z;

- (int)plantNewSeeds;
- (int)plantRootSeeds;

- (void)createROIfrom3DPaths:(NSArray*)pathsList:(NSArray*)namesList;

	// Table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex;
- (void) checkRootSeeds:(NSArray*)roiList;
- (void)creatNewResultROI:(int)index;
- (void)saveNewPlantedSeeds;
- (void) updateAllCenterlines;
- (void) reCaculateCPRPath:(NSMutableArray*) roiList :(int) width :(int)height :(float)spaceX: (float)spaceY : (float)spaceZ :(float)originX :(float)originY:(float)originZ;
- (void) convertCenterlinesToVTKCoordinate:(NSArray*)centerlines;

//only to cheat vrView
- (float) minimumValue;
- (float) maximumValue;
- (ViewerController*) viewer2D;
-(NSMutableArray*) curPixList;
- (NSMatrix*) toolsMatrix;
- (NSMutableArray*) curPixList;
- (NSString*) style;


@end

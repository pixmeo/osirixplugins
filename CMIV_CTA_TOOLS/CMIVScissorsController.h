
/*=========================================================================
CMIVScissorsController

Handle most common 2d image processing task, such as MPR, CPR.
Another important job is to create the seeds marker for the 
segmentation.

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
#import "CMIVSlider.h"
#import "CMIVWindow.h"
#import "CMIVDCMView.h"
#import "CMIVVesselPlotView.h"
#define id Id
#include <vtkImageImport.h>
#include <vtkTransform.h>
#include <vtkImageReslice.h>
#include <vtkImageData.h>
#include <vtkMath.h>
#include <vtkContourFilter.h>
#include <vtkPolyDataConnectivityFilter.h>
#include <vtkPolyData.h>
#include "spline.h"
#undef id

@interface CMIVScissorsController : NSWindowController
{


	IBOutlet NSWindow	*exportCPRWindow;
	IBOutlet NSWindow	*exportMPRWindow;
	IBOutlet NSWindow	*polygonMeasureWindow;
    IBOutlet NSTextField *resampleText;
	IBOutlet NSPopUpButton *pathListButton;
    IBOutlet CMIVSlider *axImageSlider;
    IBOutlet CMIVSlider *cImageSlider;
    IBOutlet CMIVDCMView *cPRView;
    IBOutlet CMIVDCMView *crossAxiasView;
    IBOutlet CMIVSlider *cYRotateSlider;
    IBOutlet CMIVSlider *oImageSlider;
    IBOutlet CMIVDCMView *originalView;
    IBOutlet CMIVSlider *oXRotateSlider;
    IBOutlet CMIVSlider *oYRotateSlider;
    IBOutlet NSColorWell *seedColor;
    IBOutlet NSTextField *seedName;
    IBOutlet NSTableView *seedsList;
	IBOutlet NSButton *centerLock;
    IBOutlet NSSlider *brushWidthSlider;
    IBOutlet NSSegmentedControl *brushStatSegment;
    IBOutlet NSTextField *brushWidthText;
	IBOutlet NSButton *oViewCrossShowButton;	
	IBOutlet NSButton *cViewCrossShowButton;
	IBOutlet NSButton *axViewCrossShowButton;
	IBOutlet NSButton *showAnnotationButton;
	IBOutlet NSButton *nextButton;
	IBOutlet NSButton *previousButton;
	IBOutlet NSButton *convertToSeedButton;
	IBOutlet NSButton *continuePlantingButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSButton *saveButton;
	IBOutlet NSButton *autoSeedingButton;
    IBOutlet NSTableView *centerlinesList;
	IBOutlet NSMenuItem *straightenedCPRSwitchMenu;
	IBOutlet NSButton *straightenedCPRButton;
	IBOutlet NSMatrix *seedingToolMatrix;

    IBOutlet NSSlider *exportStepSlider;
    IBOutlet NSSlider *exportOViewFromSlider;
    IBOutlet NSSlider *exportOViewToSlider;
    IBOutlet NSSlider *exportCViewFromSlider;
    IBOutlet NSSlider *exportCViewToSlider;
    IBOutlet NSSlider *exportAxViewFromSlider;
    IBOutlet NSSlider *exportAxViewToSlider;
	IBOutlet NSTextField *exportSpacingXText;
	IBOutlet NSTextField *exportSpacingYText;	
	IBOutlet NSTextField *exportStepText;
	IBOutlet NSTextField *exportOViewFromText;
	IBOutlet NSTextField *exportOViewToText;
	IBOutlet NSTextField *exportOViewAmountText;	
	IBOutlet NSTextField *exportCViewFromText;
	IBOutlet NSTextField *exportCViewToText;
	IBOutlet NSTextField *exportCViewAmountText;
	IBOutlet NSTextField *exportAxViewFromText;
	IBOutlet NSTextField *exportAxViewToText;
	IBOutlet NSTextField *exportAxViewAmountText;
	IBOutlet NSSlider *exportAxViewCPRStepSlider;
	IBOutlet NSTextField *exportAxViewCPRStepText;
	IBOutlet NSTextField *exportAxViewCPRAmountText;
	IBOutlet NSTextField *axViewLengthText;
	IBOutlet NSButton *captureOViewButton;
	IBOutlet NSButton *captureCViewButton;
	IBOutlet NSButton *captureAxViewButton;
	
	IBOutlet NSButton *exportOViewCurrentOnlyButton;	
	IBOutlet NSButton *exportOViewAllButton;
	

	IBOutlet NSButton *exportCViewCurrentOnlyButton;	
	IBOutlet NSButton *exportCViewAllButton;
	

	IBOutlet NSButton *exportAxViewCurrentOnlyButton;	
	IBOutlet NSButton *exportAxViewAllButton;
	
	IBOutlet NSButton *exportAxViewBrushROIButton;
	IBOutlet NSButton *exportAxViewPolygonROIButton;
	
	IBOutlet NSTextField *currentTips;
	IBOutlet NSTabView *seedToolTipsTabView;
    IBOutlet NSSlider *resampleRatioSlider;
    IBOutlet NSTextField *resampleRatioText;
	
	IBOutlet NSMatrix *howManyAngleToExport;
	IBOutlet NSTextField *howManyImageToExport;
	IBOutlet NSTextField *pathName;	
	IBOutlet NSTextField *oViewRotateXText;
	IBOutlet NSTextField *oViewRotateYText;
	IBOutlet NSTextField *cViewRotateYText;
	IBOutlet NSButton *ifExportCrossSectionButton;
	
	
	IBOutlet NSButton *caculateAreaButton;	
	IBOutlet NSButton *caculateMinDiameterButton;
	IBOutlet NSButton *caculateMaxDiameterButton;	
	IBOutlet NSButton *caculateMeanDiameterButton;
	IBOutlet NSButton *caculateMinHuButton;	
	IBOutlet NSButton *caculateMaxHuButton;
	IBOutlet NSButton *caculateMeanHuButton;	
	
	IBOutlet NSButton *autoSaveButton;	
	
		
	IBOutlet NSMatrix *basketMatrix;
	IBOutlet NSScrollView *basketScrollView;
	
	IBOutlet NSTextField *vesselAnalysisParaStr1;
	IBOutlet NSTextField *vesselAnalysisParaStr2;
	IBOutlet NSTextField *vesselAnalysisParaStr3;
	IBOutlet NSTextField *vesselAnalysisParaStr4;
	IBOutlet NSTextField *vesselAnalysisParaStr5;
	IBOutlet NSTextField *vesselAnalysisParaStr6;

	IBOutlet NSTextField *vesselAnalysisParaStepText;

	IBOutlet NSSlider *vesselAnalysisParaStepSlider;	
	IBOutlet NSButton *vesselAnalysisParaShowShortAxisOption;
	IBOutlet NSButton *vesselAnalysisParaShowLongAxisOption;
	IBOutlet NSButton *vesselAnalysisParaShowMeanAxisOption;
	IBOutlet NSButton *vesselAnalysisParaSmoothOption;
	IBOutlet NSButton *vesselAnalysisParaAutoRefineOption;
	IBOutlet NSSlider *axViewAreaSlider;
	IBOutlet NSTextField *axViewAreathText;
	IBOutlet NSSlider *axViewSigemaSlider;
	IBOutlet NSTextField *axViewSigemaText;	
	IBOutlet NSSlider *axViewUpperThresholdSlider;
	IBOutlet NSTextField *axViewUpperThresholdText;
	IBOutlet NSSlider *axViewLowerThresholdSlider;
	IBOutlet NSTextField *axViewLowerThresholdText;
	IBOutlet NSComboBox *vesselAnalysisParaSetNameCombo;
	IBOutlet NSButton *vesselAnalysisShowAllParaButton;
	IBOutlet CMIVVesselPlotView *plotView;
	IBOutlet NSView* vesselAnalysisPanel;
	IBOutlet NSPopUpButton *vesselAnalysisPlotSourceButton;
	IBOutlet NSButton *creatCenterlineButton;
	IBOutlet NSButton *removeCenterlineButton;
	IBOutlet NSButton *exportCenterlineButton;
	IBOutlet NSButton *exportCPRButton;
	IBOutlet NSTextField *centerlineTapTips;
	IBOutlet NSButton *ClipUpperCenterlineButton;
	IBOutlet NSButton *CliplowerCenterlineButton;
	IBOutlet NSButton *repulsorButton;
	IBOutlet NSView *exportView;
	
	IBOutlet NSButton *cancelSegmentationButton;
	
	int      imageWidth,imageHeight,imageAmount,imageSize;
	float    sliceThickness;
	float	 vtkOriginalX,vtkOriginalY,vtkOriginalZ;
	float    xSpacing,ySpacing,zSpacing,minSpacing;
	float    centerX,centerY,centerZ; //for lock center , not useful now
	float    preOViewXAngle,PreOViewYAngle,preOViewPosition;
	float    oViewRotateAngleX,oViewRotateAngleY,cViewRotateAngleY;
	float    axViewLowerThresholdFloat,axViewUpperThresholdFloat;
	float    *axViewConnectednessCostMap;
	unsigned char *connectednessROIBuffer;
	int     connectednessROIBufferMaxSize;
	int     axViewConnectednessCostMapMaxSize;
	int		axViewCostMapWidth,axViewCostMapHeight;
	
	NSArray             *fileList;	
	ViewerController     *originalViewController;
	NSData               *originalViewVolumeData;
	NSArray              *originalViewPixList;

	DCMPix* curPix;

	BOOL     roiShowNameOnly, roiShowTextOnlyWhenSeleted;
	int     isInWizardMode;
	BOOL     isInitialWithCPRMode;
	BOOL     isStraightenedCPR;
	float               *volumeData,*fuzzyConectednessMap;
	unsigned short int  *contrastVolumeData;
	vtkImageReslice		*oViewSlice;
	vtkImageImport		*reader,*roiReader,*axROIReader,*axLevelSetMapReader;
	vtkTransform		*oViewBasicTransform,*oViewUserTransform;
	vtkTransform		*inverseTransform,*inverseAxViewTransform;
	vtkTransform		*cViewTransform;
	vtkTransform        *axViewTransform,*axViewTransformForStraightenCPR, *avViewinverseTransform;
	vtkImageReslice     *cViewSlice;
	vtkImageReslice     *axViewSlice;
	vtkImageReslice     *oViewROISlice;
	vtkImageReslice     *axViewROISlice;
	vtkContourFilter	*axROIOutlineFilter;
	vtkPolyDataConnectivityFilter	*axViewPolygonfilter;
	vtkPolyDataConnectivityFilter	*axViewPolygonfilter2;
	///////////////
	ROI                 *curvedMPR2DPath;
	NSMutableArray      *curvedMPR3DPath;
	NSMutableArray      *curvedMPREven3DPath;
	NSMutableArray      *curvedMPRProjectedPaths;
	ROI                 *curvedMPRReferenceLineOfAxis;	
	float				*cprImageBuffer;
	float               defaultROIThickness;

	
	float                minValueInSeries;
	
	NSMutableArray      *oViewPixList,*oViewROIList;
	NSMutableArray      *cViewPixList,*cViewROIList;
	NSMutableArray      *axViewPixList,*axViewROIList;	
	
	NSMutableArray      *contrastList;	
	NSMutableArray      *totalROIList;
	
	NSMutableArray      *cpr3DPaths;
	NSMutableArray      *centerlinesNameArrays;
	NSMutableArray      *centerlinesLengthArrays;
	int                  uniIndex;
	int                  isRemoveROIBySelf;
	int                  isChangingWWWLBySelf;
	long		annotations	;
	
	int      currentTool;
	int      currentPathMode;
	NSRect   cPRROIRect;
	NSRect   axCircleRect;
	int      centerIsLocked;
	float    lastOViewXAngle,lastOViewYAngle,lastOViewTranslate,lastCViewYAngle;
	float    lastCViewTranslate,lastAxViewTranslate;
	float    lastOViewZAngle,lastCViewZAngle,lastAxViewZAngle;
	double	 oViewSpace[3], oViewOrigin[3];
	double	 cViewSpace[3], cViewOrigin[3];
	double   axViewSpace[3],axViewOrigin[3];
	NSPoint  cPRViewCenter,cViewArrowStartPoint;
	float    oViewToCViewZAngle,cViewToAxViewZAngle;
	CMIV_CTA_TOOLS* parent;
	NSColor* currentSeedColor;
	NSString *currentSeedName;
	int currentStep;
	int totalSteps;
	NSString* howToContinueTip;
	BOOL isNeedShowReferenceLine;
	
	int       soomthedpathlen;
	double*   soomthedpath;
	int interpolationMode;
	ROI* oViewArrow;
	ROI* cViewArrow;
	ROI* axViewMeasurePolygon;
	ROI* cViewMeasurePolygon;
	ROI* axViewNOResultROI;
	NSMutableArray  *arrowPointsArray;
	NSMutableArray  *cViewArrowPointsArray;
	ROI* oViewMeasureLine;
	NSMutableArray  *measureLinePointsArray;
	NSRect screenrect;
	NSMutableArray* seriesNeedToExport;
	float maxSpacing;
	int aortamarker;
	float* vesselnessMap;
	NSData	*parentVesselnessMap;
	NSData	*parentFuzzyConectednessData;
	int needShowSegmentROI;
	NSMutableArray* basketImageArray;
	NSMutableArray* basketImageROIArray;
	int axViewROIMode;
	int cViewMPRorCPRMode;
	float maxWidthofCPR;
	int currentViewMode;
	
	NSMutableArray   *vesselAnalysisMeanHu;
	NSMutableArray   *vesselAnalysisMaxHu;
	NSMutableArray   *vesselAnalysisArea;
	NSMutableArray   *vesselAnalysisLongDiameter;
	NSMutableArray   *vesselAnalysisShortDiameter;
	NSMutableArray   *vesselAnalysisCentersInLongtitudeSection;
	float vesselAnalysisLongitudeStep,vesselAnalysisCrossSectionStep;
	float vesselAnalysisMaxLongitudeDiameter;
	int isDrawingACenterline;
	BOOL isNeedSmoothImgBeforeSegment;
	float levelsetCurvatureScaling;

	NSMutableArray   *reference3Dpoints;
	ROI               *referenceCurvedMPR2DPath;
	
	float lastLevelsetDiameter;//not useful at all but further test should be done
	NSRect axViewLevelsetRect;
	
	BOOL cViewMeasureNeedToUpdate;
	BOOL axViewMeasureNeedToUpdate;
	id activeView;
	BOOL needSaveCenterlines;

	
	NSTimer* autoSegmentTimer;
	int timeCountDown;
	BOOL needSaveSeeds;
}



- (IBAction)addSeed:(id)sender;
- (IBAction)changeSeedingTool:(id)sender;
- (IBAction)changeDefaultTool:(id)sender;
- (IBAction)changeSeedColor:(id)sender;
- (IBAction)changeSeedName:(id)sender;
- (IBAction)changOriginalViewDirection:(id)sender;
- (IBAction)onCancel:(id)sender;
- (IBAction)onOK:(id)sender;
- (IBAction)pageAxView:(id)sender;
- (IBAction)pageCView:(id)sender;
- (void)	onlyPageAxView:(id)sender;
- (void)	onlyPageCView:(id)sender;
- (IBAction)pageOView:(id)sender;
- (IBAction)removeSeed:(id)sender;
- (IBAction)rotateXCView:(id)sender;
- (IBAction)rotateYCView:(id)sender;
- (void)	rotateZCView:(float)angle;
- (void)	rotateZAxView:(float)angle;
- (IBAction)rotateXOView:(id)sender;
- (IBAction)rotateYOView:(id)sender;
- (void)    rotateZOView:(float)angle;
- (IBAction)resetOriginalView:(id)sender;
- (IBAction)lockCenter:(id)sender;
- (IBAction)selectAContrast:(id)sender;
- (IBAction)setBrushWidth:(id)sender;
- (IBAction)setBrushMode:(id)sender;
- (IBAction)crossShow:(id)sender;
- (IBAction)showAnnotations:(id)sender;
- (IBAction)covertRegoinToSeeds:(id)sender;

- (IBAction)goNextStep:(id)sender;
- (IBAction)goPreviousStep:(id)sender;
- (IBAction)continuePlanting:(id)sender;
- (IBAction)selectANewCenterline:(id)sender;
- (IBAction)showCPRImageDialog:(id)sender;
- (IBAction)endCPRImageDialog:(id)sender;
- (IBAction)setResampleRatio:(id)sender;
- (IBAction)exportCenterlines:(id)sender;
- (IBAction)removeCenterline:(id)sender;
- (IBAction)switchStraightenedCPR:(id)sender;
- (IBAction)exportOrthogonalDataset:(id)sender;
- (IBAction)batchExport:(id)sender;
- (IBAction)setExportDialogFromToSlider:(id)sender;
- (IBAction)setExportDialogStepSlider:(id)sender;
- (IBAction)setExportDialogFromToButton:(id)sender;
- (IBAction)whyNoThickness:(id)sender;
- (IBAction)setAxViewThreshold:(id)sender;
- (IBAction)changAxViewCPRStep:(id)sender;
- (IBAction)changAxViewROIArea:(id)sender;
- (IBAction)changLeveSetSigema:(id)sender;
- (IBAction)endPolygonMeasureDialog:(id)sender;
- (IBAction)refineCenterlineWithCrossSection:(id)sender;
//- (IBAction)startCrossSectionRegionGrowing:(id)sender;
- (IBAction)openABPointFile:(id)sender;
- (IBAction)exportCenterlineToText:(id)sender;
- (IBAction)exportSingleImageToBasket:(id)sender;
- (IBAction)deleteImageInBasket:(id)sender;
- (IBAction)emptyImageInBasket:(id)sender;
- (IBAction)saveImagesInBasket:(id)sender;

- (IBAction)vesselAnalysisSetStep:(id)sender;
- (IBAction)vesselAnalysisChoiceADefaultParaset:(id)sender;
- (IBAction)vesselAnalysisStart:(id)sender;
- (IBAction)vesselAnalysisShowAllPara:(id)sender;
- (IBAction)vesselAnalysisSetNeedRefineCenterline:(id)sender;
- (IBAction)vesselAnalysisSetUseSmoothFilter:(id)sender;
- (IBAction)vesselAnalysisParaInitialize:(id)sender;
- (IBAction)vesselAnalysisSetNewSource:(id)sender;

- (IBAction)creatCenterLine:(id)sender;
- (IBAction)clipCenterLine:(id)sender;

- (IBAction)cancelAutoSegmentaion:(id)sender;

- (IBAction)changeROIShowingInAxView:(id)sender;
- (IBAction)quicktimeExport:(id)sender;
- (id) showPanelAfterROIChecking:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner;
- (id) showScissorsPanel:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner;
- (int) showPolygonMeasurementPanel:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner;
- (id)showPanelAsWizard:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner;
- (id)showPanelAsCPROnly:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner;
- (int) initViews;
- (int) initSeedsList;
- (int) reloadSeedsFromExportedROI;
- (void) updateOView;
- (void) updateCView;
- (void) updateCViewAsCurvedMPR;
- (void) updateCViewAsMPR;
- (void) updateAxView;
- (void) recaculateAxViewForCPR;
- (void) recaculateAxViewForStraightenedCPR;
- (void) updatePageSliders;
- (void) resetSliders;
- (void) roiChanged: (NSNotification*) note;
- (void) roiAdded: (NSNotification*) note;
- (void) roiRemoved: (NSNotification*) note;
- (void) defaultToolModified: (NSNotification*) note;
- (void) changeWLWW: (NSNotification*) note;
- (void) crossMove:(NSNotification*) note;
- (void) cAndAxViewReset;
- (void) defaultToolModified: (NSNotification*) note;
- (void) creatROIListFromSlices:(NSMutableArray*) roiList :(int) width:(int)height:(short unsigned int*)im :(float)spaceX:(float)spaceY:(float)originX:(float)originY;
- (void) creatCPRROIListFromFuzzyConnectedness:(NSMutableArray*) roiList :(int) width:(int)height:(float *)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY;
- (void) creatAxROIListFromFuzzyConnectedness:(NSMutableArray*) roiList :(int) width:(int)height:(float *)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY;
- (void) reCaculateCPRPath:(NSMutableArray*) roiList :(int) width :(int)height :(float)spaceX: (float)spaceY : (float)spaceZ :(float)originX :(float)originY:(float)originZ;
- (void) changeCurrentTool:(int) tag;
- (void) fixHolesInBarrier:(int)minx :(int)maxx :(int)miny :(int)maxy :(int)minz :(int)maxz :(short unsigned int) marker;
- (NSMutableArray *) create3DPathFromROIs:(NSString*) roiName;
- (void) resample3DPath:(float)step:(NSMutableArray*)apath;
- (void)changAmongMPRCPRAndAnalysis:(int)modeindex;
	//for tableview
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row;
- (void)tableView:(NSTableView *)aTableView
 setObjectValue:(id)anObject
 forTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex;

- (float*) caculateCurvedMPRImage :(int*)pwidth :(int*)pheight ;
- (float*) caculateStraightCPRImage :(int*)pwidth :(int*)pheight ;
- (void) checkRootSeeds:(NSArray*)roiList;
- (void) runSegmentation;
- (int) plantSeeds:(float*)inData:(float*)outData:(unsigned char *)directData;
- (void) showPreviewResult:(float*)inData:(float*)outData:(unsigned char *)directData :(unsigned char *)colorData;
- (void) goSubStep:(int)step:(bool)needResetViews;
- (void) setCurrentCPRPathWithPath:(NSArray*)path:(float)resampelrate;
- (void) convertCenterlinesToVTKCoordinate:(NSArray*)centerlines;
- (void) creatROIfrom3DPath:(NSArray*)path:(NSString*)name:(NSMutableArray*)newViewerROIList;
- (void)relocateAxViewSlider;
- (float)TriCubic : (float*) p :(float *)volume : (int) xDim : (int) yDim :(int) zDim;
- (ViewerController *) exportCrossSectionImages:(float)start:(float)step:(int)slicenumber;
- (ViewerController *) exportCViewImages:(float)start:(float)step:(int)slicenumber;
- (ViewerController *) exportOViewImages:(float)start:(float)step:(int)slicenumber;
- (int) generateSlidingNormals:(int)npts:(double*)pointsxyz:(double*)ptnormals;
- (int) generateUnitRobbin:(int)npts:(double*)inputpointsxyz:(double*)ptnormals:(double*)outputpointsxyz:(double)angle:(double)width;
-(int) thresholdLeveLSetAlgorithm:(float*)imgdata :(int)imgwidth: (int)imgheight :(int)offsetx :(int)offsety :(float)spaceX :(float)spaceY :(float)curscale :(float)lowerthreshold: (float)upperthreshold :(float)initdis :(unsigned char*)outrgndata :(ROI*)outroi:(int)seedmode;
-(NSPoint)polygonCenterOfMass:(NSArray*)ptarray;
- (float)signedPolygonArea:(NSArray*)ptarray;
- (void)  creatPolygonROIsMeasurementROIsForViewController;
- (void)  exportPolygonROIsInformation;
-(void) removeMeasurementROIs;
-(float) measureAPolygonROI:(ROI*)aPolygon:(NSMutableArray*)axisesPoints;
//-(void)crossSectionRegionGrowing:(id)parameters;
-(float)findingCenterOfSegment:(unsigned char*)buffer:(int)width:(int)height:(int*)center;
//-(void)createAortaRootSeeds:(int)centerx:(int)centery;
//-(void)createVentricleRootSeeds;
- (id)showPanelAsAutomaticWizard:(ViewerController *) vc:(	CMIV_CTA_TOOLS*) owner;
//-(void)plantSeedsForTopAndBottom;
//-(int) LinearRegression:(double*)data :(int)rows:(double*)a:(double*)b;
-(void)findingGravityCenterOfSegment:(unsigned char*)buffer:(int)width:(int)height:(int*)center;
//-(void)plantExtraSeedsForRightCoronaryArtery;
//-(void)plantExtraSeedsForLeftCoronaryArtery;
- (void)saveCurrentSeeds;
- (void)loadSavedSeeds;
- (DCMPix*)getCurPixFromOView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs;
- (DCMPix*)getCurPixFromCView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs;
- (DCMPix*)getCurPixFromAxView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs;
- (void) createEven3DPathForCPR:(int*)pwidth :(int*)pheight;
- (void)showMPRExportDialog;
- (void)syncWithPlot;
- (void)initCenterList;
- (void)initVesselAnalysis;
- (float) measureDiameterOfLongitudePolygon:(ROI*)aroi:(float)step:(float)length:(float)xspace :(NSMutableArray*)diameterarray:(NSMutableArray*)centerptarray;
-(void) recaculateAllCenterlinesLength;
-(double)caculateLengthOfAPath:(NSArray*)apath;
- (void)loadVesselnessMap;
-(void)mergeVesselnessAndIntensityMap:(float*)img:(float*)vesselimg:(int)size;
//- (IBAction)loadSegmentationResult:(id)sender;
-(void)loadDirectionData:(unsigned char*)outData;
- (void) saveDirectionMap:(unsigned char*)outData;
-(void)creatPolygonROIsMeasurementROIsForAImage:(NSMutableArray*)imgroilist:(DCMPix*) curImage:(BOOL)addMin:(BOOL)addMax:(BOOL)addMean;
-(void)performLongitudeSectionAnalysis;
- (IBAction)refineCenterlineWithLongitudeSection:(id)sender;
- (IBAction)refineCenterline:(id)sender;
- (void) dcmViewMouseDown: (NSNotification*) note;
-(void) dcmViewMouseUp: (NSNotification*) note;
-(void)updateCViewMeasureAfterROIChanged;
-(void)updateAxViewMeasureAfterROIChanged;
- (int)inverseMatrix:(float*)inm :(float*)outm;
-(BOOL)saveCenterlinesInPatientsCoordination;
-(BOOL)loadCenterlinesInPatientsCoordination;
-(void)changeSegmentButtonTitle:(id)sender;
-(NSImage*) imageForQuickTime:(NSNumber*) cur maxFrame:(NSNumber*) max;
@end

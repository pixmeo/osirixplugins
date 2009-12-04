/*=========================================================================
CMIV_CTA_TOOLS.h

CMIV_CTA_TOOLS is the main entry of this plugin, which handle the
"plugins" menu action and invoke corresponding windows.

The menu item and corresponding classes are listed as following:
menu text                       class name
---------------------------------------------------------------
VOI Cutter                      CMIVChopperController
MathMorph Tool                  CMIVSpoonController
2D Views                        CMIVScissorsController
Interactive Segmentation        CMIVContrastController
Segmental VR                    CMIVVRcontroller
Save Results                    CMIVSaveResult
Wizard For Coronary CTA         invoke CMIVChopperController,
                                CMIVScissorsController,
                                CMIVContrastPreview,
                                CMIVScissorsController in turn

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


#import <Foundation/Foundation.h>
#import "PluginFilter.h"


@interface CMIV_CTA_TOOLS : PluginFilter {
	
	IBOutlet NSWindow	*window;
	IBOutlet NSWindow	*aboutWindow;
	IBOutlet NSWindow	*advanceSettingWindow;
	IBOutlet NSLevelIndicator *autoSeedingIndicator;
	IBOutlet NSButton	*autoRibCageRemovalButton;
	IBOutlet NSButton	*autoSegmentButton;
	IBOutlet NSButton	*autoVesselEnhanceButton;
	IBOutlet NSButton	*autoCenterlineButton;
	IBOutlet NSButton	*autoWatchOnReceivingButton;
	IBOutlet NSTextField *autoWatchOnReceivingKeyWordTextField1;
	IBOutlet NSTextField *autoWatchOnReceivingKeyWordTextField2;
	IBOutlet NSTextField *autoCleanCachDaysText;
	NSString* autoWatchOnReceivingSeriesDesciptionFilterString;
	NSString* autoWatchOnReceivingStudyDesciptionFilterString;
	NSMutableDictionary* dataOfWizard;
	NSObject* currentController;
	NSObject* autosaver;
	int autoSaveSeriesNumber;
	BOOL ifAutoSeedingOnReceive;
	int performRibCageRemoval;
	int performCenterlineTracking;
	int performVesselEnhance;
	BOOL ifVesselEnhanced;
	int autoCleanCachDays;
	NSMutableArray* seriesNeedToAutomaticProcess;
	BOOL isAutoSeeding;
	unsigned int minimumImagesForEachSeriesToAutoSeeding;

}
@property BOOL ifVesselEnhanced;
- (IBAction)closeAboutDlg:(id)sender;
- (IBAction)openCMIVWebSite:(id)sender;
- (IBAction)mailToAuthors:(id)sender;
- (IBAction) showAboutDlg:(id)sender;
- (void) showAutoSeedingDlg;
- (void) autoSeedingIndicatorStep:(NSNotification *)note;
- (IBAction)clickAutoSeeding:(id)sender;
- (IBAction)closeAutoSeedingDlg:(id)sender;
- (IBAction) showAdvancedSettingDlg:(id)sender;
- (IBAction)closeAdvancedSettingDlg:(id)sender;

- (long) filterImage:(NSString*) menuName;
- (int)  startChopper:(ViewerController *) vc;
//- (int)  startSpoon:(ViewerController *) vc;
- (int)  startScissors:(ViewerController *) vc;
- (int)  startContrast:(ViewerController *) vc;
- (int)  startPolygonMeasure:(ViewerController *) vc;
- (int)  startVR:(ViewerController *) vc;
- (int)  saveResult:(ViewerController *) vc;

- (void) gotoStepNo:(int)stage;
- (NSMutableDictionary*) dataOfWizard;
- (void) setDataofWizard:(NSMutableDictionary*) dic;
- (void) cleanDataOfWizard;
- (void) cleanSharedData;

- (int)  startAutomaticSeeding:(ViewerController *) vc;
- (NSString*)osirixDocumentPath;

- (void)cleanUpCachFolder;
- (void)notifyExportFinished;
- (void)addedToDB:(NSNotification *)note;
- (int)saveIntermediateData:(NSString*)seriesUid;

- (int)compressSeedsData:(NSData*)seedsData:(NSMutableArray*)compressedArray;
-(int)uncompressSeedsData:(NSData*)seedsData:(NSMutableArray*)compressedArray;
- (int)loadIntermediateDataForVolumeCropping:(NSMutableDictionary*)savedData;
- (int)loadIntermediateDataForSeedPlanting:(NSMutableDictionary*)savedData;
- (int)loadIntermediateDataForCPRViewing:(NSMutableDictionary*)savedData;
- (int)checkIntermediatDataForFreeMode:(int)userRespond;
- (int)checkIntermediatDataForWizardMode:(int)userRespond;
- (void)saveCurrentStep;
- (BOOL)loadVesselnessMap:(float*)volumeData:(float*)origin:(float*)spacing:(long*)dimension;
-(void)checkMaxValueForSeedingIndicator;

-(void) startAutoProg:(id) sender;

@end

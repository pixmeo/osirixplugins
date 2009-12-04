/**
 * \brief NMRegionGrowingControllwer.h, is the controller class for the NMSegmentation Osirix plugin.  
 *
 * \authors Brian Jensen
 *          <br>
 *          {jensen}\@in.tum.de
 * \ingroup NMSegmentation
 * \version 1.01
 * \date 01.05.2008
 *
 *	\description NMRegionGrowingController is responsible for managing the parameters window and 
 *				triggering the actual segmentation. It maintains control over and the state of the 
 *				segmentation class.
 *
 *
 * \par License:
 * Copyright (c) 2008 - 2009,
 * This programm was created as part of a student research project in cooperation
 * with the Department for Computer Science, Chair XVI
 * and the Nuklearmedizinische Klinik, Klinikum Rechts der Isar
 *
 * <br>
 * <br>
 * All rights reserved.
 * <br>
 * <br>
 * See <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> for details.
 * <br>
 * <br>
 * This software is distributed WITHOUT ANY WARRANTY; without even 
 * <br>
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
 * <br>
 * PURPOSE.  See the <a href="COPYRIGHT.txt">COPYRIGHT.txt</a> notice
 * for more information.
 *
 */

#import <Cocoa/Cocoa.h>

#import "Project_defs.h"

@class ITKRegionGrowing3D;

@interface NMRegionGrowingController : NSWindowController {
	
	//Types needed for the segmentation
	ViewerController *mainViewer, *registeredViewer;
	ITKRegionGrowing3D* segmenter;
	
	//Viewer box
	IBOutlet NSTextField* mainViewerLabel;
	IBOutlet NSTextField* regViewerLabel;
	IBOutlet NSButton *showSeedButton;
	IBOutlet NSButton *showMaxRegionButton;
	IBOutlet NSTextField *seedLabel;
	IBOutlet NSButton *enableRegViewerButton;
	IBOutlet NSButton *disableClickButton;
	int posX, posY, posZ;
	float mmPosX, mmPosY, mmPosZ;
	float intensityValue;
	bool seedPointSelected;
	
	//Parameters box
	IBOutlet NSBox* paramsBox;
	NSArray	*algorithms;
	IBOutlet NSPopUpButton* algorithmPopUp;
	IBOutlet NSTabView* parameterView;
	IBOutlet NSTextField* lowerThresholdBox;
	IBOutlet NSTextField* upperThresholdBox;
	IBOutlet NSMatrix* manualRadioGroup;
	IBOutlet NSSlider* cutOffSlider;
	IBOutlet NSTextField* cutOffBox;
	IBOutlet NSTextField* searchRegionBox;
	IBOutlet NSTextField *nhRadiusX, *nhRadiusY, *nhRadiusZ;

	IBOutlet NSTextField* confMultBox;
	IBOutlet NSTextField *confNeighborhood;
	IBOutlet NSTextField *confIterationsBox;
	
	IBOutlet NSTextField* gradientBox;
	IBOutlet NSSlider* gradientSlider;
	IBOutlet NSTextField* gradientMaxSegmentationBox;
	float lowerThreshol, upperThreshold;
	
	//results box
	IBOutlet NSTextField* roiNameBox;
	IBOutlet NSColorWell* colorBox;

}

@property (nonatomic, readwrite) int posX;
@property (nonatomic, readwrite) int posY;
@property (nonatomic, readwrite) int posZ;
@property (nonatomic, readwrite) float mmPosX;
@property (nonatomic, readwrite) float mmPosY;
@property (nonatomic, readwrite) float mmPosZ;
@property (nonatomic, readwrite) float intensityValue;
@property (readonly) ViewerController* mainViewer;
@property (readonly) ViewerController* registeredViewer;

/**
 *	Instantiates the class, loads the window nib file, and creates the segmentation object for the viewer combination
 */
- (id) initWithMainViewer:(ViewerController*) mViewer registeredViewer:(ViewerController*) rViewer;

/**
 *	Returns a dictionary with the factory defaults used by the application
 */
- (NSMutableDictionary*) getDefaults;

- (void) fillAlgorithmsPopUp;

/**
 *	Method triggered by one of the viewers, should close the window associated with this controller
 */
- (void) CloseViewerNotification:(NSNotification*) note;

/**
 *	Called by the main viewer when the user has clicked in the window
 */
- (void) mouseViewerDown:(NSNotification*) note;

/**
 *	Triggers the segmentation
 */
- (IBAction) calculate: (id) sender;

/**
 *	Called when the user switched between manual and cut off based thresholding
 */
- (IBAction) manualRadioSelChanged:(id) sender;

/**
 *	Called after the user changes the cut off percent, or the user has selected a new seed point
 */
- (IBAction) updateThresholds:(id) sender;

/**
 *	Triggered after the user has changed whether the registered viewer is used for segmentation or not
 */
- (IBAction) updateRegEnabled:(id) sender;

/**
 * Causes the parameters tab view to change and the window to resize
 */
- (IBAction) updateAlgorithm:(id) sender;

/**
 * Removes all the ROIs associated with the max search region, called upon intialization and after the user selects a new seed point
 */
- (void) removeMaxRegionROI;

/**
 * Removes all the ROIs associated with seed selection, called upon initialization and after the user selects a new seed point
 */
- (void) removeSeedPointROI;

/**
 *	Triggers the Max region ROI to be show or deletee, depending upon the user's selection
 */
- (IBAction) showMaxRegionEnable:(id) sender;

/**
 *	Triggers the Seed point ROI to be shown or deleted, depending upon the user's selection
 */
- (IBAction) showSeedEnable:(id) sender;

/**
 *	Resets all of the User defaults used by the application to be reset to our internal factory defaults
 */
- (IBAction) resetDefaults:(id) sender;

@end

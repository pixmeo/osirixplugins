//
//  SettingsWindowController.h
//  PetSpectFusion
//
//  Created by Brian on 4/1/09.
//  Copyright 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "Project_defs.h"

#define	id Id
#include "Typedefs.h"
#undef id

#include "RegObserver.h"
#include "Registration.h"
#import "ITKImageWrapper.h"
#import "ITKVersorTransform.h"
#import "ViewerController.h"

@class PetSpectFusion;

@interface PSFSettingsWindowController : NSWindowController {
	
	//our viewers
	ViewerController *fixedImageViewer, *movingImageViewer;
	
	//registration types
	ITKVersorTransform *transform;
	TransformType::Pointer itkTransform;
	ITKImageWrapper *fixedImageWrapper;
	ImageType::Pointer fixedImage, movingImage;
	CommandIterationUpdate::Pointer observer;
	
	float rotX, rotY, rotZ, transX, transY, transZ;
	BOOL regIsRunning;
	
	//rotations
	IBOutlet NSTextField* rotationBoxX;
	IBOutlet NSTextField* rotationBoxY;
	IBOutlet NSTextField* rotationBoxZ;
	
	//translations
	IBOutlet NSTextField* translationBoxX;
	IBOutlet NSTextField* translationBoxY;
	IBOutlet NSTextField* translationBoxZ;	
	
	//Spinners
	IBOutlet NSStepper* rotStepperX;
	IBOutlet NSStepper* rotStepperY;
	IBOutlet NSStepper* rotStepperZ;
	IBOutlet NSStepper* transStepperX;
	IBOutlet NSStepper* transStepperY;
	IBOutlet NSStepper* transStepperZ;
	
	//similarity measure
	IBOutlet NSTextField* binsBox;
	IBOutlet NSTextField* sampleRateBox;
	
	//optimizer parameters
	IBOutlet NSTextField* minStepBox;
	IBOutlet NSTextField* maxStepBox;
	IBOutlet NSTextField* multiResLevelsBox;
	IBOutlet NSButton* multiResEnableButton;
	
	//optimizer weightings
	IBOutlet NSTextField* wTransBoxX;	
	IBOutlet NSTextField* wTransBoxY;
	IBOutlet NSTextField* wTransBoxZ;
	IBOutlet NSTextField* wRotBoxX;	
	IBOutlet NSTextField* wRotBoxY;
	IBOutlet NSTextField* wRotBoxZ;
	
	//labels
	IBOutlet NSTextField* metricLabel;
	IBOutlet NSTextField* iterationsLabel;
	IBOutlet NSTextField* levelLabel;
	
	//Tab box
	IBOutlet NSTabView* settingsTabView;
	
	//buttons
	IBOutlet NSButton* defaultsButton;
	IBOutlet NSButton* registrationButton;
	IBOutlet NSButton* metricButton;

}

//used as binding objects to synchronize the NSSteppers and the NSTextFields
@property (nonatomic, readwrite) float rotX;
@property (nonatomic, readwrite) float rotY;
@property (nonatomic, readwrite) float rotZ;
@property (nonatomic, readwrite) float transX;
@property (nonatomic, readwrite) float transY;
@property (nonatomic, readwrite) float transZ;
@property (readonly) ViewerController* fixedImageViewer;
@property (readonly) ViewerController* movingImageViewer;

/**
 *	Creates a new registration panel using the data from the two viewers
 */
- (id) initWithFixedImageViewer:(ViewerController*) fViewer movingImageViewer:(ViewerController *) mViewer;

- (void) enableInputs:(BOOL) enable;

/**
 *	Kick off the registration process with the current parameters
 */
- (void) startRegistration;

/**
 *	Tell the optimizer to terminate the registration
 */
- (void) stopRegistration;

/**
 * Action triggered by the 'start' button'
 */
- (IBAction) performRegistration: (id) sender;

/**
 *	Action triggered by the 'metric' button
 */
- (IBAction) calculateMetric: (id) sender;

/**
 *	Action triggered by any of the Parameters' TextFields or Spinners
 */
- (IBAction) updateParameters: (id) sender;

- (IBAction) enableMultiresolution: (id) sender;

/**
 *	Unfreezes the panel
 */
- (void) registrationFinished;

/**
 *	Called to trigger an update in the parameters and the viewers during the registration
 */
- (void) registrationUpdate:(RegUpdate*) updateParams;

- (void) levelChanged:(RegUpdate*) updateParams;

/**
 *	Reapply the transform witht the current parameters to the moving image viewer, and refresh both viewers
 */
- (void) updateDisplay:(ParametersType &) params;

/**
 *	Triggered when the user switches between tabs, redraws the window to the appropriate size
 */
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

/**
 *	Resets the registration settings to their factory defaults
 */
- (IBAction) applyDefaults:(id) sender;

- (NSMutableDictionary*) getDefaults;

@end

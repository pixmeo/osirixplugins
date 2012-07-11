//
//  ArthroplastyTemplatingStepsController.h
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class N2Step, N2Steps, N2StepsView, ROI, ArthroplastyTemplate, ViewerController;
@class ArthroplastyTemplatingPlugin;

@interface ArthroplastyTemplatingStepsController : NSWindowController {
	ArthroplastyTemplatingPlugin* _plugin;
	ViewerController* _viewerController;
	
	IBOutlet N2Steps* _steps;
	IBOutlet N2StepsView* _stepsView;
	N2Step *_stepCalibration, *_stepAxes, *_stepLandmarks, *_stepCutting, *_stepCup, *_stepStem, *_stepPlacement, *_stepSave;
	IBOutlet NSView *_viewCalibration, *_viewAxes, *_viewLandmarks, *_viewCutting, *_viewCup, *_viewStem, *_viewPlacement, *_viewSave;
	IBOutlet NSButton *doneCalibration, *doneAxes, *doneLandmarks, *doneCutting, *doneCup, *doneStem, *donePlacement, *doneSave;
	
	NSMutableSet* _knownRois;
	ROI *_magnificationLine, *_horizontalAxis, *_femurAxis, *_landmark1, *_landmark2, *_femurRoi;
	ROI *_landmark1Axis, *_landmark2Axis, *_legInequality, *_originalLegInequality, *_originalFemurOpacityLayer, *_femurLayer, *_cupLayer, *_stemLayer, *_distalStemLayer, *_infoBox;
	ROI *_femurLandmark, *_femurLandmarkAxis, *_femurLandmarkOther, *_femurLandmarkOriginal;
	
	CGFloat _legInequalityValue, _originalLegInequalityValue, _lateralOffsetValue;
	
	// calibration
	IBOutlet NSMatrix *_magnificationRadio;
	IBOutlet NSTextField* _magnificationCustomFactor;
    IBOutlet NSTextField* _magnificationCalibrateLength;
	CGFloat _appliedMagnification;
	// axes
	float _horizontalAngle, _femurAngle;
	// cup
	IBOutlet NSTextField* _cupAngleTextField;
	float _cupAngle;
	BOOL _cupRotated;
	ArthroplastyTemplate *_cupTemplate;
	// stem
	IBOutlet NSTextField* _stemAngleTextField;
	float _stemAngle;
	BOOL _stemRotated;
	ArthroplastyTemplate *_stemTemplate;
    // distal stem
	ArthroplastyTemplate *_distalStemTemplate;
	// placement
	IBOutlet NSPopUpButton* _neckSizePopUpButton;
	IBOutlet NSTextField* _verticalOffsetTextField;
	IBOutlet NSTextField* _horizontalOffsetTextField;
	unsigned _stemNeckSizeIndex;

	IBOutlet NSTextField* _plannersNameTextField;
	
	NSPoint _planningOffset;
	NSDate* _planningDate;
	BOOL _userOpenedTemplates;
	
	IBOutlet NSButton* _sendToPACSButton;
	NSString* _imageToSendName;
	NSEvent* _isMyMouse;
    NSInteger _isMyRoiManupulation;
}


@property(readonly) ViewerController* viewerController;
//@property(readonly) CGFloat magnification;

-(id)initWithPlugin:(ArthroplastyTemplatingPlugin*)plugin viewerController:(ViewerController*)viewerController;

#pragma mark Templates

- (IBAction)showTemplatesPanel:(id)sender;
-(void)hideTemplatesPanel;

#pragma mark General Methods

- (IBAction)resetSBS:(id)sender;
- (void)resetSBSUpdatingView:(BOOL)updateView;

#pragma mark StepByStep Delegate Methods

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step;
-(void)advanceAfterInput:(id)change;
-(void)steps:(N2Steps*)steps valueChanged:(id)sender;
-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step;
-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step;
-(BOOL)handleViewerEvent:(NSEvent*)event;

#pragma mark Steps specific Methods

-(void)adjustStemToCup;

#pragma mark Result

-(void)computeValues;
-(void)updateInfo;

@end

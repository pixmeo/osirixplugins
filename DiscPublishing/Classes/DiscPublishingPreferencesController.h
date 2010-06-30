//
//  DiscPublishingPreferencesController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface DiscPublishingPreferencesController : NSPreferencePane {
	IBOutlet NSMatrix* burnModeMatrix;
	IBOutlet NSBox* burnModeOptionsBox;
//	IBOutlet NSTextField* mediaCapacityTextField;
//	IBOutlet NSPopUpButton* mediaCapacityMeasurePopUpButton;
	
	IBOutlet NSView* patientModeOptionsView;
	IBOutlet NSView* archivingModeOptionsView;
	
	IBOutlet NSImageView* patientModeZipPasswordWarningView;
	IBOutlet NSImageView* archivingModeZipPasswordWarningView;
	IBOutlet NSImageView* patientModeAuxiliaryDirWarningView;
	IBOutlet NSImageView* archivingModeAuxiliaryDirWarningView;
	IBOutlet NSButton* patientModeLabelTemplateEditButton;
	IBOutlet NSButton* archivingModeLabelTemplateEditButton;
	IBOutlet NSPathControl* patientModeLabelTemplatePathControl;
	IBOutlet NSPathControl* archivingModeLabelTemplatePathControl;
	
	NSSize deltaFromPathControlBRToButtonTL;
	
	// RobotOptions
	IBOutlet NSBox* robotOptionsBox;
	NSView* unavailableRobotOptionsView;
	IBOutlet NSTextField* unavailableRobotOptionsTextView;
	NSTimer* robotOptionsTimer;
	NSMutableArray* robotOptionsBins;
}

-(IBAction)showPatientModeAnonymizationOptionsSheet:(id)sender;

-(IBAction)showPatientModeAuxiliaryDirSelectionSheet:(id)sender;
-(IBAction)showArchivingModeAuxiliaryDirSelectionSheet:(id)sender;

-(IBAction)showPatientModeDiscCoverFileSelectionSheet:(id)sender;
-(IBAction)showArchivingModeDiscCoverFileSelectionSheet:(id)sender;

-(IBAction)editPatientModeDiscCoverFile:(id)sender;
-(IBAction)editArchivingModeDiscCoverFile:(id)sender;

-(IBAction)mediaCapacityValueChanged:(id)sender;

@end

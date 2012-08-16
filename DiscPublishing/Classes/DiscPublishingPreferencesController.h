//
//  DiscPublishingPreferencesController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface DiscPublishingPreferencesController : NSPreferencePane {
	IBOutlet NSBox* burnModeOptionsBox;
//	IBOutlet NSTextField* mediaCapacityTextField;
//	IBOutlet NSPopUpButton* mediaCapacityMeasurePopUpButton;
	
	IBOutlet NSView* patientModeOptionsView;
	IBOutlet NSView* archivingModeOptionsView; // currently unused
    
    IBOutlet NSPopUpButton* servicesPopUpButton;
	
	IBOutlet NSImageView* patientModeZipPasswordWarningView;
	IBOutlet NSImageView* archivingModeZipPasswordWarningView;
	IBOutlet NSImageView* patientModeAuxiliaryDirWarningView;
	IBOutlet NSImageView* archivingModeAuxiliaryDirWarningView;
	IBOutlet NSButton* patientModeLabelTemplateEditButton;
	IBOutlet NSButton* archivingModeLabelTemplateEditButton;
	IBOutlet NSPathControl* patientModeLabelTemplatePathControl;
	IBOutlet NSPathControl* patientModeAuxDirPathControl;
	IBOutlet NSPathControl* archivingModeLabelTemplatePathControl;
	
    IBOutlet NSWindow* servicesWindow;
    
	NSSize deltaFromPathControlBRToButtonTL;
	
    //
    
    NSString* _serviceControllerId;
    id _serviceController;
    NSArrayController* _services;

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

-(IBAction)manageServices:(id)sender;
-(IBAction)selectService:(id)sender;

-(NSString*)selectedServiceId;
-(IBAction)addService:(id)sender;
-(IBAction)removeService:(id)sender;

-(IBAction)endSheet:(id)sender;

@end

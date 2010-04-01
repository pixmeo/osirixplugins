//
//  DiscPublishingPrefsViewController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingUserDefaultsController;

@interface DiscPublishingPrefsViewController : NSViewController {
	NSMatrix* burnModeMatrix;
	NSBox* selectedModeOptionsBox;
	NSView* patientModeOptions;
	NSView* archivingModeOptions;
	IBOutlet NSImageView* patientModeZipPasswordWarningView;
	IBOutlet NSImageView* archivingModeZipPasswordWarningView;
	IBOutlet NSImageView* patientModeAuxiliaryDirWarningView;
	IBOutlet NSImageView* archivingModeAuxiliaryDirWarningView;
}

@property(readonly) DiscPublishingUserDefaultsController* defaultsController;
@property(readonly) IBOutlet NSMatrix* burnModeMatrix;
@property(readonly) IBOutlet NSBox* selectedModeOptionsBox;
@property(readonly) IBOutlet NSView* patientModeOptions;
@property(readonly) IBOutlet NSView* archivingModeOptions;

-(IBAction)showPatientModeAnonymizationOptionsSheet:(id)sender;
-(IBAction)showPatientModeAuxiliaryDirSelectionSheet:(id)sender;
-(IBAction)showArchivingModeAuxiliaryDirSelectionSheet:(id)sender;

@end

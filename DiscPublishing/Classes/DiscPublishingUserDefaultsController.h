//
//  DiscPublishingUserDefaultsController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscBurningOptions;

enum BurnMode {
	BurnModeArchiving = 0,
	BurnModePatient = 1
};

@interface DiscPublishingUserDefaultsController : NSUserDefaultsController {
	BurnMode mode;
	UInt32 media;
	NSUInteger patientModeDelay;
	DiscBurningOptions* patientModeBurnOptions;
	DiscBurningOptions* archivingModeBurnOptions;
}

extern const NSString* const DiscPublishingBurnModeDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaDefaultsKey;

extern const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeReportsFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey;
extern const NSString* const DiscPublishingPatientModeCompressionDefaultsKey;
extern const NSString* const DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey;
extern const NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey;

extern const NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressionDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey;

@property BurnMode mode;
@property UInt32 media;
@property NSUInteger patientModeDelay;
@property(readonly) DiscBurningOptions* patientModeBurnOptions;
@property(readonly) DiscBurningOptions* archivingModeBurnOptions;

+(DiscPublishingUserDefaultsController*)sharedUserDefaultsController;

@end



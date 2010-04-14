//
//  DiscPublishingUserDefaultsController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions;

enum BurnMode {
	BurnModeArchiving = 0,
	BurnModePatient = 1
};

@interface DiscPublishingUserDefaultsController : NSUserDefaultsController {
	BurnMode mode;
	UInt32 mediaType;
	NSUInteger patientModeDelay;
	DiscPublishingOptions* patientModeOptions;
	DiscPublishingOptions* archivingModeOptions;
}

extern const NSString* const DiscPublishingBurnModeDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaTypeDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaCapacityDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey;

extern const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey;
extern const NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey;
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

extern const NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressionDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey;

// these are readonly because in order for the bindings to work correctly the setters should generate KVO notifications
@property(readonly) BurnMode mode;
@property(readonly) UInt32 mediaType;
@property(readonly) NSUInteger patientModeDelay;
@property(readonly) DiscPublishingOptions* patientModeOptions;
@property(readonly) DiscPublishingOptions* archivingModeOptions;

+(DiscPublishingUserDefaultsController*)sharedUserDefaultsController;

// often we need to compose the string constants declared earlier in this file with a values key path - these functions/methods make that easier
extern NSString* valuesKeyPath(NSString* key);
-(id)valueForValuesKey:(NSString*)keyPath;
-(void)setValue:(id)value forValuesKey:(NSString*)keyPath;

-(CGFloat)mediaCapacityBytes;

@end

@interface NSObject (DiscPublishing)

-(void)bind:(NSString*)binding toObject:(id)observable withValuesKeyPath:(NSString*)keyPath options:(NSDictionary*)options;

@end;


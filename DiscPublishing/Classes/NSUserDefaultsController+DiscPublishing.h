//
//  NSUserDefaultsController+DiscPublishing.h
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

@interface NSUserDefaultsController (DiscPublishing)

extern const NSString* const DiscPublishingActiveFlagDefaultsKey;

extern const NSString* const DiscPublishingBurnModeDefaultsKey;
//extern const NSString* const DiscPublishingBurnMediaTypeDefaultsKey;
//extern const NSString* const DiscPublishingBurnMediaCapacityDefaultsKey;
//extern const NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey;

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

extern const NSString* const DiscPublishingMediaTypeTagSuffix;
+(NSString*)discPublishingMediaTypeTagBindingKeyForBin:(NSUInteger)bin;
+(NSString*)discPublishingMediaCapacityBindingKeyForBin:(NSUInteger)bin;
+(NSString*)discPublishingMediaCapacityMeasureTagBindingKeyForBin:(NSUInteger)bin;

+(void)discPublishingInitialize;

-(BOOL)discPublishingIsActive;

-(BurnMode)discPublishingMode;
//-(UInt32)discPublishingMediaType;
-(NSUInteger)discPublishingPatientModeDelay;
-(DiscPublishingOptions*)discPublishingPatientModeOptions;
-(DiscPublishingOptions*)discPublishingArchivingModeOptions;

-(NSUInteger)discPublishingMediaTypeTagForBin:(NSUInteger)bin;
-(NSDictionary*)discPublishingMediaCapacities;

+(BOOL)discPublishingIsValidPassword:(NSString*)password;
+(NSString*)discPublishingDefaultDiscCoverPath;

@end



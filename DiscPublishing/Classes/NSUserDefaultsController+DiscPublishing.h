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

extern NSString* const DiscPublishingActiveFlagDefaultsKey;

extern NSString* const DiscPublishingBurnModeDefaultsKey;
extern NSString* const DiscPublishingBurnSpeedDefaultsKey;
//extern NSString* const DiscPublishingBurnMediaTypeDefaultsKey;
//extern NSString* const DiscPublishingBurnMediaCapacityDefaultsKey;
//extern NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey;

extern NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey;
extern NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey;
extern NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey;
extern NSString* const DiscPublishingPatientModeIncludeWeasisFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeIncludeReportsFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey;
extern NSString* const DiscPublishingPatientModeCompressionDefaultsKey;
extern NSString* const DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey;
extern NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey;

extern NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey;
extern NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern NSString* const DiscPublishingArchivingModeCompressionDefaultsKey;
extern NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey;

extern NSString* const DiscPublishingMediaTypeTagSuffix;
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



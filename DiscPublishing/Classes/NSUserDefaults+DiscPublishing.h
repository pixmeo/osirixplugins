//
//  NSUserDefaultsController+DiscPublishing.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions;

//extern NSString* const DiscPublishingActiveFlagDefaultsKey; // moved into the Service group (DiscPublishingPatientMode*)

extern NSString* const DiscPublishingBurnSpeedDefaultsKey;

extern NSString* const DiscPublishingServicesListDefaultsKey;

extern NSString* const DiscPublishingBurnModeDefaultsKey; // kind of unused....

extern NSString* const DiscPublishingPatientModeActiveFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeMatchedAETsDefaultsKey;
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
extern NSString* const DiscPublishingPatientModeZipFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey;
extern NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey;

/*
extern NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey;
extern NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern NSString* const DiscPublishingArchivingModeCompressionDefaultsKey;
extern NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey;
extern NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey;
*/

extern NSString* const DPMediaTypeTagKVOKeySuffix;

@interface NSUserDefaults (DiscPublishing)

+ (NSString*)transformKeyPath:(NSString*)okp forDPServiceId:(NSString*)sid;
+ (NSDictionary*)initialValuesForDPServiceWithId:(NSString*)sid;
+ (NSDictionary*)initialValuesForDP;

+ (NSString*)DPMediaTypeTagKVOKeyForBin:(NSUInteger)bin;
+ (NSString*)DPMediaCapacityKVOKeyForBin:(NSUInteger)bin;
+ (NSString*)DPMediaCapacityMeasureTagKVOKeyForBin:(NSUInteger)bin;

+ (NSString*)DPDefaultDiscCoverPath;

@end



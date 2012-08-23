//
//  NSUserDefaultsController+DiscPublishing.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions;

//extern NSString* const DPActiveFlagDefaultsKey; // moved into the Service group (DiscPublishingPatientMode*)

extern NSString* const DPBurnSpeedDefaultsKey;

extern NSString* const DPServicesListDefaultsKey;

extern NSString* const DPBurnModeDefaultsKey; // kind of unused....

extern NSString* const DPServiceDefaultsKeyPrefix;
extern NSString* const DPServiceActiveFlagDefaultsKey;
extern NSString* const DPServiceMatchedAETsDefaultsKey;
extern NSString* const DPServiceBurnDelayDefaultsKey;
extern NSString* const DPServiceDiscCoverTemplatePathDefaultsKey;
extern NSString* const DPServiceAnonymizeFlagDefaultsKey;
extern NSString* const DPServiceAnonymizationTagsDefaultsKey;
extern NSString* const DPServiceIncludeWeasisFlagDefaultsKey;
extern NSString* const DPServiceIncludeOsirixLiteFlagDefaultsKey;
extern NSString* const DPServiceIncludeHTMLQTFlagDefaultsKey;
extern NSString* const DPServiceIncludeReportsFlagDefaultsKey;
extern NSString* const DPServiceIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern NSString* const DPServiceAuxiliaryDirectoryPathDefaultsKey;
extern NSString* const DPServiceCompressionDefaultsKey;
extern NSString* const DPServiceCompressJPEGNotJPEG2000DefaultsKey;
extern NSString* const DPServiceZipFlagDefaultsKey;
extern NSString* const DPServiceZipEncryptFlagDefaultsKey;
extern NSString* const DPServiceZipEncryptPasswordDefaultsKey;
extern NSString* const DPServiceFSMatchFlagDefaultsKey;
extern NSString* const DPServiceFSMatchMountPathDefaultsKey;
extern NSString* const DPServiceFSMatchTokensDefaultsKey;
extern NSString* const DPServiceFSMatchConditionDefaultsKey;
extern NSString* const DPServiceFSMatchDeleteDefaultsKey;
extern NSString* const DPServiceDeletePublishedDefaultsKey;

/*
extern NSString* const DPArchivingModeDiscCoverTemplatePathDefaultsKey;
extern NSString* const DPArchivingModeIncludeReportsFlagDefaultsKey;
extern NSString* const DPArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern NSString* const DPArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern NSString* const DPArchivingModeCompressionDefaultsKey;
extern NSString* const DPArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern NSString* const DPArchivingModeZipEncryptFlagDefaultsKey;
extern NSString* const DPArchivingModeZipEncryptPasswordDefaultsKey;
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



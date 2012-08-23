//
//  NSUserDefaultsController+DiscPublishing.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSUserDefaultsController+DiscPublishing.h"
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#import <OsiriXAPI/N2UserDefaults.h>
#import <OsiriXAPI/Anonymization.h>
#import <OsiriX/DCMAttributeTag.h>
#import <JobManager/PTJobManager.h>
#import "DiscPublishingOptions.h"
#import "DiscPublishing.h"
#import "DicomTag.h"
#import <OsiriXAPI/NSFileManager+N2.h>
#import "DiscPublishingUtils.h"


//NSString* const DPActiveFlagDefaultsKey = @"DiscPublishingActiveFlag";

NSString* const DPBurnSpeedDefaultsKey = @"DiscPublishingBurnSpeed";

NSString* const DPServicesListDefaultsKey = @"DiscPublishingServicesList";

NSString* const DPBurnModeDefaultsKey = @"DiscPublishingBurnMode"; // kind of unused....

NSString* const DPServiceDefaultsKeyPrefix = @"DiscPublishingPatientMode";
NSString* const DPServiceActiveFlagDefaultsKey = @"DiscPublishingPatientModeActiveFlag";
NSString* const DPServiceMatchedAETsDefaultsKey = @"DiscPublishingPatientModeMatchedAETs";
NSString* const DPServiceBurnDelayDefaultsKey = @"DiscPublishingPatientModeBurnDelay";
NSString* const DPServiceDiscCoverTemplatePathDefaultsKey = @"DiscPublishingPatientModeDiscCoverTemplatePath";
NSString* const DPServiceDeletePublishedDefaultsKey = @"DiscPublishingPatientModeDeletePublished";
NSString* const DPServiceAnonymizeFlagDefaultsKey = @"DiscPublishingPatientModeAnonymizeFlag";
NSString* const DPServiceAnonymizationTagsDefaultsKey = @"DiscPublishingPatientModeAnonymizationTags";
NSString* const DPServiceIncludeWeasisFlagDefaultsKey = @"DiscPublishingPatientModeIncludeWeasisFlag";
NSString* const DPServiceIncludeOsirixLiteFlagDefaultsKey = @"DiscPublishingPatientModeIncludeOsirixLiteFlag";
NSString* const DPServiceIncludeHTMLQTFlagDefaultsKey = @"DiscPublishingPatientModeIncludeHTMLQTFlag";
NSString* const DPServiceIncludeReportsFlagDefaultsKey = @"DiscPublishingPatientModeIncludeReportsFlag";
NSString* const DPServiceIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlag";
NSString* const DPServiceAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingPatientModeAuxiliaryDirectoryPathData";
NSString* const DPServiceCompressionDefaultsKey = @"DiscPublishingPatientModeCompression";
NSString* const DPServiceCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingPatientModeCompressJPEGNotJPEG2000";
NSString* const DPServiceZipFlagDefaultsKey = @"DiscPublishingPatientModeZipFlag";
NSString* const DPServiceZipEncryptFlagDefaultsKey = @"DiscPublishingPatientModeZipEncryptFlag";
NSString* const DPServiceZipEncryptPasswordDefaultsKey = @"DiscPublishingPatientModeZipEncryptPassword";
NSString* const DPServiceFSMatchFlagDefaultsKey = @"DiscPublishingPatientModeFSMatchFlag";
NSString* const DPServiceFSMatchMountPathDefaultsKey = @"DiscPublishingPatientModeFSMatchMountPath";
NSString* const DPServiceFSMatchTokensDefaultsKey = @"DiscPublishingPatientModeFSMatchTokens";
NSString* const DPServiceFSMatchConditionDefaultsKey = @"DiscPublishingPatientModeFSMatchCondition";
NSString* const DPServiceFSMatchDeleteDefaultsKey = @"DiscPublishingPatientModeFSMatchDelete";
NSString* const DPServiceFSMatchDelayDefaultsKey = @"DiscPublishingPatientModeFSMatchDelay";

/*
NSString* const DPArchivingModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingArchivingModeDiscCoverTemplatePath";
NSString* const DPArchivingModeIncludeReportsFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeReportsFlag";
NSString* const DPArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlag";
NSString* const DPArchivingModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingArchivingModeAuxiliaryDirectoryPathData";
NSString* const DPArchivingModeCompressionDefaultsKey = @"DiscPublishingArchivingModeCompression";
NSString* const DPArchivingModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingArchivingModeCompressJPEGNotJPEG2000";
NSString* const DPArchivingModeZipFlagDefaultsKey = @"DiscPublishingArchivingModeZipFlag";
NSString* const DPArchivingModeZipEncryptFlagDefaultsKey = @"DiscPublishingArchivingModeZipEncryptFlag";
NSString* const DPArchivingModeZipEncryptPasswordDefaultsKey = @"DiscPublishingArchivingModeZipEncryptPassword";
*/

@implementation NSUserDefaults (DiscPublishing)

+ (NSString*)transformKeyPath:(NSString*)okp forDPServiceId:(NSString*)sid {
    NSRange r = [okp rangeOfString:DPServiceDefaultsKeyPrefix];
    if (r.location == NSNotFound)
        return nil;
    
    NSString* sk = [okp substringFromIndex:r.location+r.length];
    NSInteger skspace = [sk rangeOfString:@"_" options:NSBackwardsSearch].location;
    if (skspace != NSNotFound)
        sk = [sk substringFromIndex:skspace+1];
    
    NSString* prefix = [okp substringToIndex:r.location+r.length];
    if (sid.length)
        prefix = [NSString stringWithFormat:@"%@_%@_", prefix, [sid stringByReplacingOccurrencesOfString:@"-" withString:@"_"]];
    
    return [prefix stringByAppendingString:sk];
}

+ (NSDictionary*)initialValuesForDPServiceWithId:(NSString*)sid {
    NSDictionary* theValues = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:NO], DPServiceActiveFlagDefaultsKey,
                                [NSNumber numberWithUnsignedInt:60], DPServiceBurnDelayDefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceAnonymizeFlagDefaultsKey,
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Anonymous", @"PatientsName",
                                /*		@"", @"PatientsSex",
                                @"", @"PatientsWeight",
                                @"", @"ReferringPhysiciansName",
                                @"", @"PerformingPhysiciansName",*/
                                NULL], DPServiceAnonymizationTagsDefaultsKey,
                                [NSNumber numberWithBool:YES], DPServiceIncludeOsirixLiteFlagDefaultsKey,
                                [NSNumber numberWithBool:YES], DPServiceIncludeWeasisFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceIncludeHTMLQTFlagDefaultsKey,
                                [NSNumber numberWithBool:YES], DPServiceIncludeReportsFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceIncludeAuxiliaryDirectoryFlagDefaultsKey,
                                //		[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DPServiceAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
                                [NSNumber numberWithUnsignedInt:CompressionCompress], DPServiceCompressionDefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceCompressJPEGNotJPEG2000DefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceZipFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DPServiceZipEncryptFlagDefaultsKey,
                               nil];
    if (!sid.length)
        return theValues;
    
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    
    for (NSString* key in theValues)
        [d setObject:[theValues objectForKey:key] forKey:[self transformKeyPath:key forDPServiceId:sid]];
    
    return d;
}

+ (NSDictionary*)initialValuesForDP {
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithUnsignedInt:BurnModePatient], DPBurnModeDefaultsKey,
            [NSNumber numberWithUnsignedInt:100], DPBurnSpeedDefaultsKey,
            [NSNumber numberWithUnsignedInt:DISCTYPE_CD], [self DPMediaTypeTagKVOKeyForBin:0],           // this value is related to...
            [NSNumber numberWithFloat:700], [self DPMediaCapacityKVOKeyForBin:0],							// this one and...
            [NSNumber numberWithUnsignedInt:1000000], [self DPMediaCapacityMeasureTagKVOKeyForBin:0], // ...this one, together they mean "CD capacity is 700 MB" (see +mediaCapacityBytesForMediaType)
            [NSNumber numberWithUnsignedInt:DISCTYPE_DVD], [self DPMediaTypeTagKVOKeyForBin:1],           // this value is related to...
            [NSNumber numberWithFloat:4.7], [self DPMediaCapacityKVOKeyForBin:1],							// this one and...
            [NSNumber numberWithUnsignedInt:1000000000], [self DPMediaCapacityMeasureTagKVOKeyForBin:1], // ...this one, together they mean "DVD capacity is 4.7 GB" (see +mediaCapacityBytesForMediaType)
            // patient mode
    /*		// archiving mode
     [NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey,
     [NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey,
     //		[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
     [NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingArchivingModeCompressionDefaultsKey,
     [NSNumber numberWithBool:NO], DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey,
     [NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipFlagDefaultsKey,
     [NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipEncryptFlagDefaultsKey,*/
            NULL];
}

#pragma mark Bins

+ (NSString*)DPKVOBinPrefixForBin:(NSUInteger)bin {
	return [NSString stringWithFormat:@"DiscPublishingBin%u", (uint32)bin];
}

NSString* const DPMediaTypeTagKVOKeySuffix = @"_MediaTypeTag";
NSString* const DPMediaCapacityKVOKeySuffix = @"_MediaCapacity";
NSString* const DPMediaCapacityMeasureTagKVOKeySuffix = @"_MediaCapacityMeasureTag";

+ (NSString*)DPMediaTypeTagKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPMediaTypeTagKVOKeySuffix];
}

+ (NSString*)DPMediaCapacityKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPMediaCapacityKVOKeySuffix];
}

+ (NSString*)DPMediaCapacityMeasureTagKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPMediaCapacityMeasureTagKVOKeySuffix];
}

+ (NSString*)DPDefaultDiscCoverPath {
	return [[[NSBundle bundleForClass:[DiscPublishing class]] resourcePath] stringByAppendingPathComponent:@"Standard.dcover"];
}




@end


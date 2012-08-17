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


NSString* const DiscPublishingActiveFlagDefaultsKey = @"DiscPublishingActiveFlag";

NSString* const DiscPublishingBurnSpeedDefaultsKey = @"DiscPublishingBurnSpeed";

NSString* const DiscPublishingServicesListDefaultsKey = @"DiscPublishingServicesList";

NSString* const DiscPublishingBurnModeDefaultsKey = @"DiscPublishingBurnMode";

NSString* const DiscPublishingPatientModeMatchedAETsDefaultsKey = @"DiscPublishingPatientModeMatchedAETs";
NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey = @"DiscPublishingPatientModeBurnDelay";
NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingPatientModeDiscCoverTemplatePath";
NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey = @"DiscPublishingPatientModeAnonymizeFlag";
NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey = @"DiscPublishingPatientModeAnonymizationTags";
NSString* const DiscPublishingPatientModeIncludeWeasisFlagDefaultsKey = @"DiscPublishingPatientModeIncludeWeasisFlag";
NSString* const DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey = @"DiscPublishingPatientModeIncludeOsirixLiteFlag";
NSString* const DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey = @"DiscPublishingPatientModeIncludeHTMLQTFlag";
NSString* const DiscPublishingPatientModeIncludeReportsFlagDefaultsKey = @"DiscPublishingPatientModeIncludeReportsFlag";
NSString* const DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlag";
NSString* const DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingPatientModeAuxiliaryDirectoryPathData";
NSString* const DiscPublishingPatientModeCompressionDefaultsKey = @"DiscPublishingPatientModeCompression";
NSString* const DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingPatientModeCompressJPEGNotJPEG2000";
NSString* const DiscPublishingPatientModeZipFlagDefaultsKey = @"DiscPublishingPatientModeZipFlag";
NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey = @"DiscPublishingPatientModeZipEncryptFlag";
NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey = @"DiscPublishingPatientModeZipEncryptPassword";

/*
NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingArchivingModeDiscCoverTemplatePath";
NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeReportsFlag";
NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlag";
NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingArchivingModeAuxiliaryDirectoryPathData";
NSString* const DiscPublishingArchivingModeCompressionDefaultsKey = @"DiscPublishingArchivingModeCompression";
NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingArchivingModeCompressJPEGNotJPEG2000";
NSString* const DiscPublishingArchivingModeZipFlagDefaultsKey = @"DiscPublishingArchivingModeZipFlag";
NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey = @"DiscPublishingArchivingModeZipEncryptFlag";
NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey = @"DiscPublishingArchivingModeZipEncryptPassword";
*/

@implementation NSUserDefaults (DiscPublishing)

+ (NSString*)transformKeyPath:(NSString*)okp forDPServiceId:(NSString*)sid {
    NSRange r = [okp rangeOfString:@"DiscPublishingPatientMode"];
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
                                [NSNumber numberWithUnsignedInt:60], DiscPublishingPatientModeBurnDelayDefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeAnonymizeFlagDefaultsKey,
                                [NSDictionary dictionaryWithObjectsAndKeys:
                                @"Anonymous", @"PatientsName",
                                /*		@"", @"PatientsSex",
                                @"", @"PatientsWeight",
                                @"", @"ReferringPhysiciansName",
                                @"", @"PerformingPhysiciansName",*/
                                NULL], DiscPublishingPatientModeAnonymizationTagsDefaultsKey,
                                [NSNumber numberWithBool:YES], DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey,
                                [NSNumber numberWithBool:YES], DiscPublishingPatientModeIncludeWeasisFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey,
                                [NSNumber numberWithBool:YES], DiscPublishingPatientModeIncludeReportsFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey,
                                //		[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
                                [NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingPatientModeCompressionDefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeZipFlagDefaultsKey,
                                [NSNumber numberWithBool:NO], DiscPublishingPatientModeZipEncryptFlagDefaultsKey,
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
            [NSNumber numberWithUnsignedInt:BurnModePatient], DiscPublishingBurnModeDefaultsKey,
            [NSNumber numberWithUnsignedInt:100], DiscPublishingBurnSpeedDefaultsKey,
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
NSString* const DPKVOMediaCapacitySuffix = @"_MediaCapacity";
NSString* const DPKVOMediaCapacityMeasureTagSuffix = @"_MediaCapacityMeasureTag";

+ (NSString*)DPMediaTypeTagKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPMediaTypeTagKVOKeySuffix];
}

+ (NSString*)DPMediaCapacityKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPKVOMediaCapacitySuffix];
}

+ (NSString*)DPMediaCapacityMeasureTagKVOKeyForBin:(NSUInteger)bin {
	return [[self DPKVOBinPrefixForBin:bin] stringByAppendingString:DPKVOMediaCapacityMeasureTagSuffix];
}

+ (NSString*)DPDefaultDiscCoverPath {
	return [[[NSBundle bundleForClass:[DiscPublishing class]] resourcePath] stringByAppendingPathComponent:@"Standard.dcover"];
}




@end


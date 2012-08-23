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


@interface NSUserDefaultsControllerDiscPublishingHelper : NSObject
@end
@implementation NSUserDefaultsControllerDiscPublishingHelper

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	/*if ([keyPath isEqual:DP_valuesKeyPath(DiscPublishingBurnMediaTypeDefaultsKey)]) {
		CGFloat bytes = [defaults discPublishingMediaCapacityBytes];
		NSUInteger measure = bytes<1000000000? 1000000 : 1000000000;
		[defaults setValue:[NSNumber numberWithFloat:bytes/measure] forKeyPath:DP_valuesKeyPath(DiscPublishingBurnMediaCapacityDefaultsKey)];
		[defaults setValue:[NSNumber numberWithUnsignedInt:measure] forKeyPath:DP_valuesKeyPath(DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey)];
	} else*/
	if ([keyPath isEqual:DP_valuesKeyPath(DPServiceAnonymizeFlagDefaultsKey)]) {
		if ([[defaults valueForValuesKey:keyPath] boolValue])
			[defaults setValue:[NSNumber numberWithBool:NO] forValuesKey:DPServiceIncludeReportsFlagDefaultsKey];
	}
}

@end


@implementation NSUserDefaultsController (DiscPublishing)

static NSUserDefaultsControllerDiscPublishingHelper* helper = NULL;

+(void)discPublishingInitialize {
	//DLog(@"+[NSUserDefaultsController+DiscPublishing discPublishingInitialize]");
	
	NSUserDefaultsController* defaults = [self sharedUserDefaultsController];
	
	// merge our initial values with the existing ones
    NSMutableDictionary* iv = [[[defaults initialValues] mutableCopy] autorelease];
    [iv addEntriesFromDictionary:[NSUserDefaults initialValuesForDP]];
    [iv addEntriesFromDictionary:[NSUserDefaults initialValuesForDPServiceWithId:nil]];
	for (NSDictionary* d in [[NSUserDefaults standardUserDefaults] valueForKey:DPServicesListDefaultsKey])
        [iv addEntriesFromDictionary:[NSUserDefaults initialValuesForDPServiceWithId:[d objectForKey:@"id"]]];
    [defaults setInitialValues:iv];
	
	helper = [[NSUserDefaultsControllerDiscPublishingHelper alloc] init];
//	[defaults addObserver:helper forValuesKey:DiscPublishingBurnMediaTypeDefaultsKey options:NULL context:NULL];
	[defaults addObserver:helper forValuesKey:DPServiceAnonymizeFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

/*-(BOOL)discPublishingIsActive {
	return [[self valueForValuesKey:DiscPublishingActiveFlagDefaultsKey] boolValue];
}*/

- (NSString*)DPServiceNameForId:(NSString*)sid {
	for (NSDictionary* d in [[NSUserDefaults standardUserDefaults] valueForKey:DPServicesListDefaultsKey])
        if ([[d objectForKey:@"id"] isEqualToString:sid])
            return [d objectForKey:@"name"];
    return nil;
}

- (NSUInteger)DPDelayForServiceId:(NSString*)sid {
	return [[self.values valueForKey:[NSUserDefaults transformKeyPath:DPServiceBurnDelayDefaultsKey forDPServiceId:sid]] unsignedIntValue];
}

-(DiscPublishingOptions*)DPOptionsForServiceId:(NSString*)sid {
	DiscPublishingOptions* options = [[[DiscPublishingOptions alloc] init] autorelease];
	
//	NSLog(@"dic %@", self.defaults.dictionaryRepresentation.description);
	
//	id xxx = [self valueForValuesKey:DPServiceAnonymizationTagsDefaultsKey];
	
	options.anonymize = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceAnonymizeFlagDefaultsKey forDPServiceId:sid]];
	options.anonymizationTags = [Anonymization tagsValuesArrayFromDictionary:[self dictionaryForKey:[NSUserDefaults transformKeyPath:DPServiceAnonymizationTagsDefaultsKey forDPServiceId:sid]]];
	options.includeWeasis = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceIncludeWeasisFlagDefaultsKey forDPServiceId:sid]];
	options.includeOsirixLite = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceIncludeOsirixLiteFlagDefaultsKey forDPServiceId:sid]];
	options.includeHTMLQT = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceIncludeHTMLQTFlagDefaultsKey forDPServiceId:sid]];
	options.includeReports = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceIncludeReportsFlagDefaultsKey forDPServiceId:sid]];
	options.includeAuxiliaryDir = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceIncludeAuxiliaryDirectoryFlagDefaultsKey forDPServiceId:sid]];
	options.auxiliaryDirPath = [self stringForKey:[NSUserDefaults transformKeyPath:DPServiceAuxiliaryDirectoryPathDefaultsKey forDPServiceId:sid]];
	options.compression = (Compression)[self integerForKey:[NSUserDefaults transformKeyPath:DPServiceCompressionDefaultsKey forDPServiceId:sid]];
	options.compressJPEGNotJPEG2000 = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceCompressJPEGNotJPEG2000DefaultsKey forDPServiceId:sid]];
	options.zip = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceZipFlagDefaultsKey forDPServiceId:sid]];
	options.zipEncrypt = [self boolForKey:[NSUserDefaults transformKeyPath:DPServiceZipEncryptFlagDefaultsKey forDPServiceId:sid]];
	options.zipEncryptPassword = [self stringForKey:[NSUserDefaults transformKeyPath:DPServiceZipEncryptPasswordDefaultsKey forDPServiceId:sid]];
	
	options.discCoverTemplatePath = [self stringForKey:[NSUserDefaults transformKeyPath:DPServiceDiscCoverTemplatePathDefaultsKey forDPServiceId:sid]];
	if (!options.discCoverTemplatePath) options.discCoverTemplatePath = [NSUserDefaults DPDefaultDiscCoverPath];
	
	return options;
}

/*
-(DiscPublishingOptions*)discPublishingArchivingModeOptions {
	DiscPublishingOptions* options = [[DiscPublishingOptions alloc] init];
	
	options.anonymize = NO;
	options.includeOsirixLite = NO;
	options.includeHTMLQT = NO;
	options.includeReports = [self boolForKey:DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey];
	options.includeAuxiliaryDir = [self boolForKey:DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey];
	options.auxiliaryDirPath = [self stringForKey:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey];
	options.compression = (Compression)[self integerForKey:DiscPublishingArchivingModeCompressionDefaultsKey];
	options.compressJPEGNotJPEG2000 = [self boolForKey:DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey];
	options.zip = [self boolForKey:DiscPublishingArchivingModeZipFlagDefaultsKey];
	options.zipEncrypt = [self boolForKey:DiscPublishingArchivingModeZipEncryptFlagDefaultsKey];
	options.zipEncryptPassword = [self stringForKey:DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey];
	
	options.discCoverTemplatePath = [self stringForKey:DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey];
	if (!options.discCoverTemplatePath) options.discCoverTemplatePath = [NSUserDefaults DPDefaultDiscCoverPath];

	return [options autorelease];
}*/

+(BOOL)discPublishingIsValidPassword:(NSString*)value {
	return value.length >= 8;	
}

-(CGFloat)discPublishingMediaCapacityBytesForBin:(NSUInteger)bin {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	CGFloat a = [[defaultsController valueForValuesKey:[NSUserDefaults DPMediaCapacityKVOKeyForBin:bin]] floatValue];
	CGFloat b = [[defaultsController valueForValuesKey:[NSUserDefaults DPMediaCapacityMeasureTagKVOKeyForBin:bin]] floatValue];
	return a * b;
}

-(NSUInteger)discPublishingMediaTypeTagForBin:(NSUInteger)bin {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	return [[defaultsController valueForValuesKey:[NSUserDefaults DPMediaTypeTagKVOKeyForBin:bin]] unsignedIntValue];
}

-(NSDictionary*)discPublishingMediaCapacities {
	NSXMLDocument* doc = NULL;
	@try {
		NSString* xml = [DiscPublishing.instance.tool getStatusXML];
		doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
	} @catch (...) {
		if ([NSProcessInfo.processInfo.arguments containsObject:@"--TestDiscPublishing"]) // for testing purposes
            return [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithFloat:700*1000000], [NSNumber numberWithUnsignedInt:0], [NSNumber numberWithFloat:4.7*1000000000], [NSNumber numberWithUnsignedInt:1], nil];
        [NSException raise:NSGenericException format:@"%@", NSLocalizedString(@"Unable to communicate with robot.", NULL)];
	}
	
	NSMutableDictionary* dic = [NSMutableDictionary dictionary];
	NSArray* bins = [doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL];
	NSLog(@"bins %@", bins);
//	for (NSUInteger i = 0; i < 2; ++i) {
//#warning: this MUST be enabled when releasing
	for (NSUInteger i = 0; i < bins.count; ++i) {
		[dic setObject:[NSNumber numberWithFloat:[self discPublishingMediaCapacityBytesForBin:i]] forKey:[NSNumber numberWithUnsignedInt:[self discPublishingMediaTypeTagForBin:i]]];
	}
	
	[doc release];
	
	return dic;
}

@end


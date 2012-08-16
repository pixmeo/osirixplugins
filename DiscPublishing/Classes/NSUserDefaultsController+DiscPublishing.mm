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
	if ([keyPath isEqual:DP_valuesKeyPath(DiscPublishingPatientModeAnonymizeFlagDefaultsKey)]) {
		if ([[defaults valueForValuesKey:keyPath] boolValue])
			[defaults setValue:[NSNumber numberWithBool:NO] forValuesKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];	
	}
}

@end


@implementation NSUserDefaultsController (DiscPublishing)

NSString* const DiscPublishingActiveFlagDefaultsKey = @"DiscPublishingActiveFlag";

NSString* const DiscPublishingBurnModeDefaultsKey = @"DiscPublishingBurnMode";
NSString* const DiscPublishingBurnSpeedDefaultsKey = @"DiscPublishingBurnSpeed";
//NSString* const DiscPublishingBurnMediaTypeDefaultsKey = @"DiscPublishingBurnMediaType";
//NSString* const DiscPublishingBurnMediaCapacityDefaultsKey = @"DiscPublishingBurnMediaCapacity";
//NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey = @"DiscPublishingBurnMediaCapacityMeasureTag";

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

NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingArchivingModeDiscCoverTemplatePath";
NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeReportsFlag";
NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlag";
NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingArchivingModeAuxiliaryDirectoryPathData";
NSString* const DiscPublishingArchivingModeCompressionDefaultsKey = @"DiscPublishingArchivingModeCompression";
NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingArchivingModeCompressJPEGNotJPEG2000";
NSString* const DiscPublishingArchivingModeZipFlagDefaultsKey = @"DiscPublishingArchivingModeZipFlag";
NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey = @"DiscPublishingArchivingModeZipEncryptFlag";
NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey = @"DiscPublishingArchivingModeZipEncryptPassword";

//typedef NSUserDefaultsController_DiscPublishing_Data {
//	BurnMode mode;
//	UInt32 mediaType;
//	NSUInteger patientModeDelay;
//	DiscPublishingOptions* patientModeOptions;
//	DiscPublishingOptions* archivingModeOptions;
//}

//static NSUserDefaultsController_DiscPublishing_Data 

//@synthesize mode;
//@synthesize mediaType;
//@synthesize patientModeDelay;
//@synthesize patientModeOptions;
//@synthesize archivingModeOptions;

static NSUserDefaultsControllerDiscPublishingHelper* helper = NULL;

+(void)discPublishingInitialize {
	//DLog(@"+[NSUserDefaultsController+DiscPublishing discPublishingInitialize]");
	
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	// merge our initial values with the existing ones
	NSMutableDictionary* initialValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:BurnModePatient], DiscPublishingBurnModeDefaultsKey,
		[NSNumber numberWithUnsignedInt:100], DiscPublishingBurnSpeedDefaultsKey,
		[NSNumber numberWithUnsignedInt:DISCTYPE_CD], [self discPublishingMediaTypeTagBindingKeyForBin:0],           // this value is related to...
		[NSNumber numberWithFloat:700], [self discPublishingMediaCapacityBindingKeyForBin:0],							// this one and...
		[NSNumber numberWithUnsignedInt:1000000], [self discPublishingMediaCapacityMeasureTagBindingKeyForBin:0], // ...this one, together they mean "CD capacity is 700 MB" (see +mediaCapacityBytesForMediaType)										  
		[NSNumber numberWithUnsignedInt:DISCTYPE_DVD], [self discPublishingMediaTypeTagBindingKeyForBin:1],           // this value is related to...
		[NSNumber numberWithFloat:4.7], [self discPublishingMediaCapacityBindingKeyForBin:1],							// this one and...
		[NSNumber numberWithUnsignedInt:1000000000], [self discPublishingMediaCapacityMeasureTagBindingKeyForBin:1], // ...this one, together they mean "DVD capacity is 4.7 GB" (see +mediaCapacityBytesForMediaType)
		// patient mode
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
		// archiving mode
		[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey,
		[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey,
//		[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
		[NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingArchivingModeCompressionDefaultsKey,
		[NSNumber numberWithBool:NO], DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey,
		[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipFlagDefaultsKey,
		[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipEncryptFlagDefaultsKey,
	NULL];
	[initialValues addEntriesFromDictionary:[defaults initialValues]];
	[defaults setInitialValues:[NSDictionary dictionaryWithDictionary:initialValues]];
	
	helper = [[NSUserDefaultsControllerDiscPublishingHelper alloc] init];
//	[defaults addObserver:helper forValuesKey:DiscPublishingBurnMediaTypeDefaultsKey options:NULL context:NULL];
	[defaults addObserver:helper forValuesKey:DiscPublishingPatientModeAnonymizeFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(BOOL)discPublishingIsActive {
	return [[self valueForValuesKey:DiscPublishingActiveFlagDefaultsKey] boolValue];
}

-(BurnMode)discPublishingMode {
	return (BurnMode)[[self valueForValuesKey:DiscPublishingBurnModeDefaultsKey] unsignedIntValue];
}

/*-(UInt32)discPublishingMediaType {
	return [[self valueForValuesKey:DiscPublishingBurnMediaTypeDefaultsKey] unsignedIntValue];
}*/

-(NSUInteger)discPublishingPatientModeDelay {
	return [[self valueForValuesKey:DiscPublishingPatientModeBurnDelayDefaultsKey] unsignedIntValue];
}

-(DiscPublishingOptions*)discPublishingPatientModeOptions {
	DiscPublishingOptions* options = [[DiscPublishingOptions alloc] init];
	
//	NSLog(@"dic %@", self.defaults.dictionaryRepresentation.description);
	
//	id xxx = [self valueForValuesKey:DiscPublishingPatientModeAnonymizationTagsDefaultsKey];
	
	options.anonymize = [self boolForKey:DiscPublishingPatientModeAnonymizeFlagDefaultsKey];
	options.anonymizationTags = [Anonymization tagsValuesArrayFromDictionary:[self dictionaryForKey:DiscPublishingPatientModeAnonymizationTagsDefaultsKey]];
	options.includeWeasis = [self boolForKey:DiscPublishingPatientModeIncludeWeasisFlagDefaultsKey];
	options.includeOsirixLite = [self boolForKey:DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey];
	options.includeHTMLQT = [self boolForKey:DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey];
	options.includeReports = [self boolForKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];
	options.includeAuxiliaryDir = [self boolForKey:DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey];
	options.auxiliaryDirPath = [self stringForKey:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey];
	options.compression = (Compression)[self integerForKey:DiscPublishingPatientModeCompressionDefaultsKey];
	options.compressJPEGNotJPEG2000 = [self boolForKey:DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey];
	options.zip = [self boolForKey:DiscPublishingPatientModeZipFlagDefaultsKey];
	options.zipEncrypt = [self boolForKey:DiscPublishingPatientModeZipEncryptFlagDefaultsKey];
	options.zipEncryptPassword = [self stringForKey:DiscPublishingPatientModeZipEncryptPasswordDefaultsKey];
	
	options.discCoverTemplatePath = [self stringForKey:DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey];
	if (!options.discCoverTemplatePath) options.discCoverTemplatePath = [NSUserDefaultsController discPublishingDefaultDiscCoverPath];
	
	return [options autorelease];
}

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
	if (!options.discCoverTemplatePath) options.discCoverTemplatePath = [NSUserDefaultsController discPublishingDefaultDiscCoverPath];

	return [options autorelease];
}

+(BOOL)discPublishingIsValidPassword:(NSString*)value {
	return value.length >= 8;	
}

+(NSString*)discPublishingDefaultDiscCoverPath {
	return [[[NSBundle bundleForClass:[DiscPublishing class]] resourcePath] stringByAppendingPathComponent:@"Standard.dcover"];
}

+(NSString*)discPublishingBaseBindingKeyForBin:(NSUInteger)bin {
	return [NSString stringWithFormat:@"DiscPublishingBin%u", (uint32)bin];
}

NSString* const DiscPublishingMediaTypeTagSuffix = @"_MediaTypeTag";

+(NSString*)discPublishingMediaTypeTagBindingKeyForBin:(NSUInteger)bin {
	return [NSString stringWithFormat:@"%@%@", [self discPublishingBaseBindingKeyForBin:bin], DiscPublishingMediaTypeTagSuffix];
}

+(NSString*)discPublishingMediaCapacityBindingKeyForBin:(NSUInteger)bin {
	return [NSString stringWithFormat:@"%@_MediaCapacity", [self discPublishingBaseBindingKeyForBin:bin]];
}

+(NSString*)discPublishingMediaCapacityMeasureTagBindingKeyForBin:(NSUInteger)bin {
	return [NSString stringWithFormat:@"%@_MediaCapacityMeasureTag", [self discPublishingBaseBindingKeyForBin:bin]];
}

-(CGFloat)discPublishingMediaCapacityBytesForBin:(NSUInteger)bin {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	CGFloat a = [[defaultsController valueForValuesKey:[NSUserDefaultsController discPublishingMediaCapacityBindingKeyForBin:bin]] floatValue];
	CGFloat b = [[defaultsController valueForValuesKey:[NSUserDefaultsController discPublishingMediaCapacityMeasureTagBindingKeyForBin:bin]] floatValue];
	return a * b;
}

-(NSUInteger)discPublishingMediaTypeTagForBin:(NSUInteger)bin {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	return [[defaultsController valueForValuesKey:[NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:bin]] unsignedIntValue];
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


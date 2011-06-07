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
#import "DiscPublishing+Tool.h"
#import "DicomTag.h"
#import <OsiriXAPI/NSFileManager+N2.h>


@interface NSUserDefaultsControllerDiscPublishingHelper : NSObject
@end
@implementation NSUserDefaultsControllerDiscPublishingHelper

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	/*if ([keyPath isEqual:valuesKeyPath(DiscPublishingBurnMediaTypeDefaultsKey)]) {
		CGFloat bytes = [defaults discPublishingMediaCapacityBytes];
		NSUInteger measure = bytes<1000000000? 1000000 : 1000000000;
		[defaults setValue:[NSNumber numberWithFloat:bytes/measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityDefaultsKey)];
		[defaults setValue:[NSNumber numberWithUnsignedInt:measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey)];
	} else*/
	if ([keyPath isEqual:valuesKeyPath(DiscPublishingPatientModeAnonymizeFlagDefaultsKey)]) {
		if ([[defaults valueForValuesKey:keyPath] boolValue])
			[defaults setValue:[NSNumber numberWithBool:NO] forValuesKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];	
	}
}

@end


@implementation NSUserDefaultsController (DiscPublishing)

const NSString* const DiscPublishingActiveFlagDefaultsKey = @"DiscPublishingActiveFlag";

const NSString* const DiscPublishingBurnModeDefaultsKey = @"DiscPublishingBurnMode";
const NSString* const DiscPublishingBurnSpeedDefaultsKey = @"DiscPublishingBurnSpeed";
//const NSString* const DiscPublishingBurnMediaTypeDefaultsKey = @"DiscPublishingBurnMediaType";
//const NSString* const DiscPublishingBurnMediaCapacityDefaultsKey = @"DiscPublishingBurnMediaCapacity";
//const NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey = @"DiscPublishingBurnMediaCapacityMeasureTag";

const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey = @"DiscPublishingPatientModeBurnDelay";
const NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingPatientModeDiscCoverTemplatePath";
const NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey = @"DiscPublishingPatientModeAnonymizeFlag";
const NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey = @"DiscPublishingPatientModeAnonymizationTags";
const NSString* const DiscPublishingPatientModeIncludeWeasisFlagDefaultsKey = @"DiscPublishingPatientModeIncludeWeasisFlag";
const NSString* const DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey = @"DiscPublishingPatientModeIncludeOsirixLiteFlag";
const NSString* const DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey = @"DiscPublishingPatientModeIncludeHTMLQTFlag";
const NSString* const DiscPublishingPatientModeIncludeReportsFlagDefaultsKey = @"DiscPublishingPatientModeIncludeReportsFlag";
const NSString* const DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlag";
const NSString* const DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingPatientModeAuxiliaryDirectoryPathData";
const NSString* const DiscPublishingPatientModeCompressionDefaultsKey = @"DiscPublishingPatientModeCompression";
const NSString* const DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingPatientModeCompressJPEGNotJPEG2000";
const NSString* const DiscPublishingPatientModeZipFlagDefaultsKey = @"DiscPublishingPatientModeZipFlag";
const NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey = @"DiscPublishingPatientModeZipEncryptFlag";
const NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey = @"DiscPublishingPatientModeZipEncryptPassword";

const NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingArchivingModeDiscCoverTemplatePath";
const NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeReportsFlag";
const NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlag";
const NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingArchivingModeAuxiliaryDirectoryPathData";
const NSString* const DiscPublishingArchivingModeCompressionDefaultsKey = @"DiscPublishingArchivingModeCompression";
const NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingArchivingModeCompressJPEGNotJPEG2000";
const NSString* const DiscPublishingArchivingModeZipFlagDefaultsKey = @"DiscPublishingArchivingModeZipFlag";
const NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey = @"DiscPublishingArchivingModeZipEncryptFlag";
const NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey = @"DiscPublishingArchivingModeZipEncryptPassword";

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

const NSString* const DiscPublishingMediaTypeTagSuffix = @"_MediaTypeTag";

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
		NSString* xml = [DiscPublishing GetStatusXML];
		doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
	} @catch (...) {
		[NSException raise:NSGenericException format:NSLocalizedString(@"Unable to communicate with robot.", NULL)];
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


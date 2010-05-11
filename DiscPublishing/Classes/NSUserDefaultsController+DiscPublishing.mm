//
//  NSUserDefaultsController+DiscPublishing.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSUserDefaultsController+DiscPublishing.h"
#import <OsiriX Headers/N2UserDefaults.h>
#import <OsiriX/DCMAttributeTag.h>
#import <JobManager/PTJobManager.h>
#import "DiscPublishingOptions.h"
#import "DiscPublishing.h"
#import "DicomTag.h"
#import "NSFileManager+DiscPublisher.h"


@interface NSUserDefaultsControllerDiscPublishingHelper : NSObject
@end
@implementation NSUserDefaultsControllerDiscPublishingHelper

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	if ([keyPath isEqual:valuesKeyPath(DiscPublishingBurnMediaTypeDefaultsKey)]) {
		CGFloat bytes = [NSUserDefaultsController mediaCapacityBytesForMediaType:[defaults mediaType]];
		NSUInteger measure = bytes<1000000000? 1000000 : 1000000000;
		[defaults setValue:[NSNumber numberWithFloat:bytes/measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityDefaultsKey)];
		[defaults setValue:[NSNumber numberWithUnsignedInt:measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey)];
	} else if ([keyPath isEqual:valuesKeyPath(DiscPublishingPatientModeAnonymizeFlagDefaultsKey)]) {
		if ([[defaults valueForValuesKey:keyPath] boolValue])
			[defaults setValue:[NSNumber numberWithBool:NO] forValuesKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];	
	}
}

@end


@implementation NSUserDefaultsController (DiscPublishing)

const NSString* const DiscPublishingBurnModeDefaultsKey = @"DiscPublishingBurnMode";
const NSString* const DiscPublishingBurnMediaTypeDefaultsKey = @"DiscPublishingBurnMediaType";
const NSString* const DiscPublishingBurnMediaCapacityDefaultsKey = @"DiscPublishingBurnMediaCapacity";
const NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey = @"DiscPublishingBurnMediaCapacityMeasureTag";

const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey = @"DiscPublishingPatientModeBurnDelay";
const NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey = @"DiscPublishingPatientModeDiscCoverTemplatePath";
const NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey = @"DiscPublishingPatientModeAnonymizeFlag";
const NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey = @"DiscPublishingPatientModeAnonymizationTags";
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

+(void)initializeDiscPublishing {
	NSLog(@"+[NSUserDefaultsController+DiscPublishing initialize]");
	
	NSUserDefaultsController* defaults = [NSUserDefaultsController sharedUserDefaultsController];
	
	// merge our initial values with the existing ones
	NSMutableDictionary* initialValues = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithUnsignedInt:BurnModePatient], DiscPublishingBurnModeDefaultsKey,
		[NSNumber numberWithUnsignedInt:DISCTYPE_CD], DiscPublishingBurnMediaTypeDefaultsKey,           // this value is related to...
		[NSNumber numberWithFloat:700], DiscPublishingBurnMediaCapacityDefaultsKey,                     // this one and...
		[NSNumber numberWithUnsignedInt:1000000], DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey, // ...this one, together they mean "CD capacity is 700 MB" (see +mediaCapacityBytesForMediaType)
		// patient mode
		[NSNumber numberWithUnsignedInt:60], DiscPublishingPatientModeBurnDelayDefaultsKey,
		[NSNumber numberWithBool:NO], DiscPublishingPatientModeAnonymizeFlagDefaultsKey,
		[NSArray arrayWithObjects:
			[NSArray arrayWithObjects: [DCMAttributeTag tagWithName:@"PatientsName"], @"Anonymous", NULL],
			NULL], DiscPublishingPatientModeAnonymizationTagsDefaultsKey,
		[NSNumber numberWithBool:YES], DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey,
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
	[defaults addObserver:helper forValuesKey:DiscPublishingBurnMediaTypeDefaultsKey options:NULL context:NULL];
	[defaults addObserver:helper forValuesKey:DiscPublishingPatientModeAnonymizeFlagDefaultsKey options:NSKeyValueObservingOptionInitial context:NULL];
}

-(BurnMode)mode {
	return (BurnMode)[[self valueForValuesKey:DiscPublishingBurnModeDefaultsKey] unsignedIntValue];
}

-(UInt32)mediaType {
	return [[self valueForValuesKey:DiscPublishingBurnMediaTypeDefaultsKey] unsignedIntValue];
}

-(NSUInteger)patientModeDelay {
	return [[self valueForValuesKey:DiscPublishingPatientModeBurnDelayDefaultsKey] unsignedIntValue];
}

+(CGFloat)mediaCapacityBytesForMediaType:(UInt32)mediaType {
	switch (mediaType) {
		case DISCTYPE_CD: return 700*1000000; // 700 MB
		case DISCTYPE_DVD: return 4.7*1000000000; // 4.7 GB
		case DISCTYPE_DVDDL: return 8.5*1000000000; // 8.5 GB
		case DISCTYPE_BR: return 25*1000000000; // 25 GB
		case DISCTYPE_BR_DL: return 50*1000000000; // 50 GB
		default: return 0;
	}
}

-(CGFloat)mediaCapacityBytes {
	return [[self valueForValuesKey:DiscPublishingBurnMediaCapacityDefaultsKey] floatValue] * [[self valueForValuesKey:DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey] unsignedIntValue];
}

-(DiscPublishingOptions*)patientModeOptions {
	DiscPublishingOptions* options = [[DiscPublishingOptions alloc] init];
	
	options.anonymize = [self.defaults boolForKey:DiscPublishingPatientModeAnonymizeFlagDefaultsKey];
	options.anonymizationTags = [self.defaults arrayForKey:DiscPublishingPatientModeAnonymizationTagsDefaultsKey];
	options.includeOsirixLite = [self.defaults boolForKey:DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey];
	options.includeHTMLQT = [self.defaults boolForKey:DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey];
	options.includeReports = [self.defaults boolForKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];
	options.includeAuxiliaryDir = [self.defaults boolForKey:DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey];
	options.auxiliaryDirPath = [self.defaults stringForKey:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey];
	options.compression = (Compression)[self.defaults integerForKey:DiscPublishingPatientModeCompressionDefaultsKey];
	options.compressJPEGNotJPEG2000 = [self.defaults boolForKey:DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey];
	options.zip = [self.defaults boolForKey:DiscPublishingPatientModeZipFlagDefaultsKey];
	options.zipEncrypt = [self.defaults boolForKey:DiscPublishingPatientModeZipEncryptFlagDefaultsKey];
	options.zipEncryptPassword = [self.defaults stringForKey:DiscPublishingPatientModeZipEncryptPasswordDefaultsKey];
	options.discCoverTemplatePath = [self.defaults stringForKey:DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey];
	
	return [options autorelease];
}

-(DiscPublishingOptions*)archivingModeOptions {
	DiscPublishingOptions* options = [[DiscPublishingOptions alloc] init];
	
	options.anonymize = NO;
	options.includeOsirixLite = NO;
	options.includeHTMLQT = NO;
	options.includeReports = [self.defaults boolForKey:DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey];
	options.includeAuxiliaryDir = [self.defaults boolForKey:DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey];
	options.auxiliaryDirPath = [self.defaults stringForKey:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey];
	options.compression = (Compression)[self.defaults integerForKey:DiscPublishingArchivingModeCompressionDefaultsKey];
	options.compressJPEGNotJPEG2000 = [self.defaults boolForKey:DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey];
	options.zip = [self.defaults boolForKey:DiscPublishingArchivingModeZipFlagDefaultsKey];
	options.zipEncrypt = [self.defaults boolForKey:DiscPublishingArchivingModeZipEncryptFlagDefaultsKey];
	options.zipEncryptPassword = [self.defaults stringForKey:DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey];
	options.discCoverTemplatePath = [self.defaults stringForKey:DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey];
	
	return [options autorelease];
}

+(BOOL)isValidDiscPublishingPassword:(NSString*)value {
	return value.length >= 8;	
}

+(NSString*)defaultDiscCoverPath {
	return [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Standard.dcover"];
}

@end


@implementation NSObject (DiscPublishing)

NSString* valuesKeyPath(NSString* key) {
	return [NSString stringWithFormat:@"values.%@", key];
}

-(id)valueForValuesKey:(NSString*)keyPath {
	return [self valueForKeyPath:valuesKeyPath(keyPath)];
}

-(void)setValue:(id)value forValuesKey:(NSString*)keyPath {
	[self setValue:value forKeyPath:valuesKeyPath(keyPath)];
}

-(void)bind:(NSString*)binding toObject:(id)observable withValuesKey:(NSString*)key options:(NSDictionary*)options {
	[self bind:binding toObject:observable withKeyPath:valuesKeyPath(key) options:options];
}

-(void)addObserver:(NSObject*)observer forValuesKey:(NSString*)key options:(NSKeyValueObservingOptions)options context:(void*)context {
	[self addObserver:observer forKeyPath:valuesKeyPath(key) options:options context:context];
}

-(void)removeObserver:(NSObject*)observer forValuesKey:(NSString*)key {
	[self removeObserver:observer forKeyPath:valuesKeyPath(key)];
}

@end


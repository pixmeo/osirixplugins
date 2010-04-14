//
//  DiscPublishingUserDefaultsController.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingUserDefaultsController.h"
#import <OsiriX Headers/N2UserDefaults.h>
#import <OsiriX/DCMAttributeTag.h>
#import <JobManager/PTJobManager.h>
#import "DiscPublishingOptions.h"
#import "DiscPublishing.h"
#import "DicomTag.h"
#import "NSFileManager+DiscPublisher.h"


@implementation DiscPublishingUserDefaultsController

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

@synthesize mode;
@synthesize mediaType;
@synthesize patientModeDelay;
@synthesize patientModeOptions;
@synthesize archivingModeOptions;

+(DiscPublishingUserDefaultsController*)sharedUserDefaultsController {
	static DiscPublishingUserDefaultsController* sharedUserDefaultsController = [[self alloc] init];
	return sharedUserDefaultsController;
}

-(NSDictionary*)initialValuesDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
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
//			[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
			[NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingPatientModeCompressionDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeZipFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeZipEncryptFlagDefaultsKey,
			// archiving mode
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey,
//			[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey, // TODO: check and fix
			[NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingArchivingModeCompressionDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipEncryptFlagDefaultsKey,
			NULL];
}

NSString* valuesKeyPath(NSString* key) {
	return [NSString stringWithFormat:@"values.%@", key];
}

-(id)valueForValuesKey:(NSString*)keyPath {
	return [self valueForKeyPath:valuesKeyPath(keyPath)];
}

-(void)setValue:(id)value forValuesKey:(NSString*)keyPath {
	[self setValue:value forKeyPath:valuesKeyPath(keyPath)];
}

-(id)init {
	self = [super initWithDefaults:[[[NSUserDefaults alloc] init] autorelease] initialValues:[self initialValuesDictionary]];
	
	[self bind:@"mode" toObject:self withValuesKeyPath:DiscPublishingBurnModeDefaultsKey options:NULL];
	[self bind:@"mediaType" toObject:self withValuesKeyPath:DiscPublishingBurnMediaTypeDefaultsKey options:NULL];
	[self bind:@"patientModeDelay" toObject:self withValuesKeyPath:DiscPublishingPatientModeBurnDelayDefaultsKey options:NULL];
	
	patientModeOptions = [[DiscPublishingOptions alloc] init];
	[patientModeOptions bind:@"anonymize" toObject:self withValuesKeyPath:DiscPublishingPatientModeAnonymizeFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"anonymizationTags" toObject:self withValuesKeyPath:DiscPublishingPatientModeAnonymizationTagsDefaultsKey options:NULL];
	[patientModeOptions bind:@"includeOsirixLite" toObject:self withValuesKeyPath:DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"includeHTMLQT" toObject:self withValuesKeyPath:DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"includeReports" toObject:self withValuesKeyPath:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"includeAuxiliaryDir" toObject:self withValuesKeyPath:DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"auxiliaryDirPath" toObject:self withValuesKeyPath:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey options:NULL];
	[patientModeOptions bind:@"compression" toObject:self withValuesKeyPath:DiscPublishingPatientModeCompressionDefaultsKey options:NULL];
	[patientModeOptions bind:@"compressJPEGNotJPEG2000" toObject:self withValuesKeyPath:DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey options:NULL];
	[patientModeOptions bind:@"zip" toObject:self withValuesKeyPath:DiscPublishingPatientModeZipFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"zipEncrypt" toObject:self withValuesKeyPath:DiscPublishingPatientModeZipEncryptFlagDefaultsKey options:NULL];
	[patientModeOptions bind:@"zipEncryptPassword" toObject:self withValuesKeyPath:DiscPublishingPatientModeZipEncryptPasswordDefaultsKey options:NULL];
	[patientModeOptions bind:@"discCoverTemplatePath" toObject:self withValuesKeyPath:DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey options:NULL];
	
	archivingModeOptions = [[DiscPublishingOptions alloc] init];
	archivingModeOptions.anonymize = NO;
	archivingModeOptions.includeOsirixLite = NO;
	archivingModeOptions.includeHTMLQT = NO;
	[archivingModeOptions bind:@"includeReports" toObject:self withValuesKeyPath:DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey options:NULL];
	[archivingModeOptions bind:@"includeAuxiliaryDir" toObject:self withValuesKeyPath:DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey options:NULL];
	[archivingModeOptions bind:@"auxiliaryDirPath" toObject:self withValuesKeyPath:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey options:NULL];
	[archivingModeOptions bind:@"compression" toObject:self withValuesKeyPath:DiscPublishingArchivingModeCompressionDefaultsKey options:NULL];
	[archivingModeOptions bind:@"compressJPEGNotJPEG2000" toObject:self withValuesKeyPath:DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey options:NULL];
	[archivingModeOptions bind:@"zip" toObject:self withValuesKeyPath:DiscPublishingArchivingModeZipFlagDefaultsKey options:NULL];
	[archivingModeOptions bind:@"zipEncrypt" toObject:self withValuesKeyPath:DiscPublishingArchivingModeZipEncryptFlagDefaultsKey options:NULL];
	[archivingModeOptions bind:@"zipEncryptPassword" toObject:self withValuesKeyPath:DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey options:NULL];
	[archivingModeOptions bind:@"discCoverTemplatePath" toObject:self withValuesKeyPath:DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey options:NULL];
	
	[self addObserver:self forKeyPath:valuesKeyPath(DiscPublishingBurnMediaTypeDefaultsKey) options:NULL context:NULL];
	[self addObserver:self forKeyPath:valuesKeyPath(DiscPublishingPatientModeAnonymizeFlagDefaultsKey) options:NSKeyValueObservingOptionInitial context:NULL];
	
	return self;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self) {
		if ([keyPath isEqual:valuesKeyPath(DiscPublishingBurnMediaTypeDefaultsKey)]) {
			CGFloat bytes = [DiscPublishing mediaCapacityBytesForMediaType:self.mediaType];
			NSUInteger measure = bytes<1000000000? 1000000 : 1000000000;
			[self setValue:[NSNumber numberWithFloat:bytes/measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityDefaultsKey)];
			[self setValue:[NSNumber numberWithUnsignedInt:measure] forKeyPath:valuesKeyPath(DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey)];
		} else if ([keyPath isEqual:valuesKeyPath(DiscPublishingPatientModeAnonymizeFlagDefaultsKey)]) {
			if ([[self valueForKeyPath:keyPath] boolValue])
				[self setValue:[NSNumber numberWithBool:NO] forValuesKey:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey];	
		}
	}
}

-(void)dealloc {
	[patientModeOptions release];
	[archivingModeOptions release];
	[super dealloc];
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

@end


@implementation NSObject (DiscPublishing)

-(void)bind:(NSString*)binding toObject:(id)observable withValuesKeyPath:(NSString*)keyPath options:(NSDictionary*)options {
	[self bind:binding toObject:observable withKeyPath:valuesKeyPath(keyPath) options:options];
}

@end


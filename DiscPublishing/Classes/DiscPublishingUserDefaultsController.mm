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
#import "DiscBurningOptions.h"
#import "DicomTag.h"
#import "NSFileManager+DiscPublisher.h"


@implementation DiscPublishingUserDefaultsController

const NSString* const DiscPublishingBurnModeDefaultsKey = @"DiscPublishingBurnMode";
const NSString* const DiscPublishingBurnMediaDefaultsKey = @"DiscPublishingBurnMedia";
const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey = @"DiscPublishingPatientModeBurnDelay";

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

const NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeReportsFlag";
const NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey = @"DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlag";
const NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey = @"DiscPublishingArchivingModeAuxiliaryDirectoryPathData";
const NSString* const DiscPublishingArchivingModeCompressionDefaultsKey = @"DiscPublishingArchivingModeCompression";
const NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey = @"DiscPublishingArchivingModeCompressJPEGNotJPEG2000";
const NSString* const DiscPublishingArchivingModeZipFlagDefaultsKey = @"DiscPublishingArchivingModeZipFlag";
const NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey = @"DiscPublishingArchivingModeZipEncryptFlag";
const NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey = @"DiscPublishingArchivingModeZipEncryptPassword";

@synthesize mode;
@synthesize media;
@synthesize patientModeDelay;
@synthesize patientModeBurnOptions;
@synthesize archivingModeBurnOptions;

+(DiscPublishingUserDefaultsController*)sharedUserDefaultsController {
	static DiscPublishingUserDefaultsController* sharedUserDefaultsController = [[self alloc] init];
	return sharedUserDefaultsController;
}

-(NSDictionary*)initialValuesDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedInt:BurnModePatient], DiscPublishingBurnModeDefaultsKey,
			[NSNumber numberWithUnsignedInt:DISCTYPE_CD], DiscPublishingBurnMediaDefaultsKey,
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
			[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey,
			[NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingPatientModeCompressionDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeZipFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingPatientModeZipEncryptFlagDefaultsKey,
			// archiving mode
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey,
			[[NSFileManager defaultManager] findSystemFolderOfType:kMusicDocumentsFolderType forDomain:kUserDomain], DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey,
			[NSNumber numberWithUnsignedInt:CompressionCompress], DiscPublishingArchivingModeCompressionDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipFlagDefaultsKey,
			[NSNumber numberWithBool:NO], DiscPublishingArchivingModeZipEncryptFlagDefaultsKey,
			NULL];
}

-(NSString*)valuesKeyPath:(NSString*)key {
	return [NSString stringWithFormat:@"values.%@", key];
}

-(id)init {
	self = [super initWithDefaults:[[[NSUserDefaults alloc] init] autorelease] initialValues:[self initialValuesDictionary]];
	
	[self bind:@"mode" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingBurnModeDefaultsKey] options:NULL];
	[self bind:@"media" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingBurnMediaDefaultsKey] options:NULL];
	[self bind:@"patientModeDelay" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeBurnDelayDefaultsKey] options:NULL];
	
	patientModeBurnOptions = [[DiscBurningOptions alloc] init];
	[patientModeBurnOptions bind:@"anonymize" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeAnonymizeFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"anonymizationTags" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeAnonymizationTagsDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"includeOsirixLite" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"includeHTMLQT" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"includeReports" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeIncludeReportsFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"includeAuxiliaryDir" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"auxiliaryDirPath" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"compression" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeCompressionDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"compressJPEGNotJPEG2000" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"zip" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeZipFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"zipEncrypt" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeZipEncryptFlagDefaultsKey] options:NULL];
	[patientModeBurnOptions bind:@"zipEncryptPassword" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingPatientModeZipEncryptPasswordDefaultsKey] options:NULL];
	
	archivingModeBurnOptions = [[DiscBurningOptions alloc] init];
	archivingModeBurnOptions.anonymize = NO;
	archivingModeBurnOptions.includeOsirixLite = NO;
	archivingModeBurnOptions.includeHTMLQT = NO;
	[archivingModeBurnOptions bind:@"includeReports" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"includeAuxiliaryDir" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"auxiliaryDirPath" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"compression" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeCompressionDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"compressJPEGNotJPEG2000" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"zip" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeZipFlagDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"zipEncrypt" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeZipEncryptFlagDefaultsKey] options:NULL];
	[archivingModeBurnOptions bind:@"zipEncryptPassword" toObject:self withKeyPath:[self valuesKeyPath:DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey] options:NULL];
	
	return self;
}

-(void)dealloc {
	[patientModeBurnOptions release];
	[archivingModeBurnOptions release];
	[super dealloc];
}

@end



//
//  DiscBurningOptions.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscBurningOptions.h"


@implementation DiscBurningOptions

@synthesize anonymize;
@synthesize anonymizationTags;
@synthesize includeOsirixLite;
@synthesize includeHTMLQT;
@synthesize includeReports;
@synthesize includeAuxiliaryDir;
@synthesize auxiliaryDirPath;
@synthesize compression;
@synthesize compressJPEGNotJPEG2000;
@synthesize zip;
@synthesize zipEncrypt;
@synthesize zipEncryptPassword;

-(id)copyWithZone:(NSZone*)zone {
	DiscBurningOptions* copy = [[DiscBurningOptions allocWithZone:zone] init];
	
	copy.anonymize = self.anonymize;
	copy.anonymizationTags = [self.anonymizationTags copyWithZone:zone];
	copy.includeOsirixLite = self.includeOsirixLite;
	copy.includeHTMLQT = self.includeHTMLQT;
	copy.includeReports = self.includeReports;
	copy.includeAuxiliaryDir = self.includeAuxiliaryDir;
	copy.auxiliaryDirPath = [self.auxiliaryDirPath copyWithZone:zone];
	copy.compression = self.compression;
	copy.compressJPEGNotJPEG2000 = self.compressJPEGNotJPEG2000;
	copy.zip = self.zip;
	copy.zipEncrypt = self.zipEncrypt;
	copy.zipEncryptPassword = [self.zipEncryptPassword copyWithZone:zone];
	
	return copy;
}

-(void)dealloc {
	self.anonymizationTags = NULL;
	self.auxiliaryDirPath = NULL;
	self.zipEncryptPassword = NULL;
	[super dealloc];
}


@end

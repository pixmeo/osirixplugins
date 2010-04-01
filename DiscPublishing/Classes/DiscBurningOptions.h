//
//  DiscBurningOptions.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DicomCompressor.h"


@interface DiscBurningOptions : NSObject <NSCopying> {
	BOOL anonymize;
	NSArray* anonymizationTags;
	BOOL includeOsirixLite;
	BOOL includeHTMLQT;
	BOOL includeReports;
	BOOL includeAuxiliaryDir;
	NSString* auxiliaryDirPath;
	Compression compression;
	BOOL compressJPEGNotJPEG2000;
	BOOL zip, zipEncrypt;
	NSString* zipEncryptPassword;
}

@property BOOL anonymize;
@property(retain) NSArray* anonymizationTags;
@property BOOL includeOsirixLite;
@property BOOL includeHTMLQT;
@property BOOL includeReports;
@property BOOL includeAuxiliaryDir;
@property(retain) NSString* auxiliaryDirPath;
@property Compression compression;
@property BOOL compressJPEGNotJPEG2000;
@property BOOL zip;
@property BOOL zipEncrypt;
@property(retain) NSString* zipEncryptPassword;

-(BOOL)zip;

@end

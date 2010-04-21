//
//  NSUserDefaultsController+DiscPublishing.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions;

enum BurnMode {
	BurnModeArchiving = 0,
	BurnModePatient = 1
};

@interface NSUserDefaultsController (DiscPublishing)

extern const NSString* const DiscPublishingBurnModeDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaTypeDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaCapacityDefaultsKey;
extern const NSString* const DiscPublishingBurnMediaCapacityMeasureTagDefaultsKey;

extern const NSString* const DiscPublishingPatientModeBurnDelayDefaultsKey;
extern const NSString* const DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAnonymizeFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAnonymizationTagsDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeOsirixLiteFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeHTMLQTFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeReportsFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey;
extern const NSString* const DiscPublishingPatientModeCompressionDefaultsKey;
extern const NSString* const DiscPublishingPatientModeCompressJPEGNotJPEG2000DefaultsKey;
extern const NSString* const DiscPublishingPatientModeZipEncryptFlagDefaultsKey;
extern const NSString* const DiscPublishingPatientModeZipEncryptPasswordDefaultsKey;

extern const NSString* const DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeIncludeReportsFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeIncludeAuxiliaryDirectoryFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressionDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeCompressJPEGNotJPEG2000DefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptFlagDefaultsKey;
extern const NSString* const DiscPublishingArchivingModeZipEncryptPasswordDefaultsKey;

-(BurnMode)mode;
-(UInt32)mediaType;
-(NSUInteger)patientModeDelay;
-(DiscPublishingOptions*)patientModeOptions;
-(DiscPublishingOptions*)archivingModeOptions;

-(CGFloat)mediaCapacityBytes;

@end


@interface NSObject (DiscPublishing)

// we often need to compose the string constants declared earlier in this file with a values key path - these functions/methods make that easier
extern NSString* valuesKeyPath(NSString* key);
-(id)valueForValuesKey:(NSString*)keyPath;
-(void)setValue:(id)value forValuesKey:(NSString*)keyPath;
-(void)bind:(NSString*)binding toObject:(id)observable withValuesKey:(NSString*)key options:(NSDictionary*)options;
-(void)addObserver:(NSObject*)observer forValuesKey:(NSString*)key options:(NSKeyValueObservingOptions)options context:(void*)context;
-(void)removeObserver:(NSObject*)observer forValuesKey:(NSString*)key;

@end;


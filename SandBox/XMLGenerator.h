//
//  SandBoxTestFilter.h
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <DicomImage.h>

#import <OsiriX/DCM.h>


@interface XMLGenerator : NSObject
{

}

+ (void) createDicomStructureWithFiles:(NSMutableArray*)files atPath:(NSString*)dicomFolderPath withObjects:(NSMutableArray*)dbObjectsID;
+ (void) generateXMLFile:(NSString*)fileName atPath:(NSString*)path withContent:(NSXMLElement*)content;

+ (NSArray*) patientAttributes:(DCMObject*)object;
+ (NSArray*) studyAttributes:(DCMObject*)object;
+ (NSArray*) seriesAttributes:(DCMObject*)object;


@end









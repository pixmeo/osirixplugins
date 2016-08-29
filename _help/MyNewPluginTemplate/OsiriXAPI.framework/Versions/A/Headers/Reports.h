/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

@class DicomStudy;

/** \brief reports */
@interface Reports : NSObject
{
	NSMutableString *templateName;
    NSString *templateFilename;
}

@property (retain) NSString *templateFilename;

+ (NSString*) getUniqueFilename:(DicomStudy*) study;
+ (NSString*) getOldUniqueFilename:(NSManagedObject*) study;

- (BOOL)createNewReport:(DicomStudy*) study destination:(NSString*)path type:(int)type;

+(NSString*)databaseWordTemplatesDirPath;
+(NSString*)resolvedDatabaseWordTemplatesDirPath;

- (BOOL) createNewPagesReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
- (BOOL) createNewOpenDocumentReportForStudy:(NSManagedObject*)aStudy toDestinationPath:(NSString*)aPath;
+ (NSArray*)pagesTemplatesList;
+ (NSArray*)wordTemplatesList;
- (NSMutableString *)templateName;
- (void)setTemplateName:(NSString *)aName;
+ (int) Pages5orHigher;
+ (void)checkForPagesTemplate;
+ (void)checkForWordTemplates;
+ (NSDictionary*) searchAndReplaceFieldsFromStudy:(DicomStudy*)aStudy inString:(NSMutableString*)aString;
+ (NSDictionary*) searchAndReplaceFieldsFromStudy:(DicomStudy*)aStudy inString:(NSMutableString*)aString testValidFields: (BOOL) testValidFields htmlEncoding: (BOOL) htmlEncoding;
+ (NSString*) getDICOMStringValueForField: (NSString*) rawField inDICOMFile: (NSString*) path;
@end

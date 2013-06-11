//
//  SandBoxTestFilter.h
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <DicomImage.h>
#import <DicomSeries.h>

#import <OsiriX/DCM.h>


@interface S_DicomNode : NSObject
{
	DCMObject* dcmObject;
	S_DicomNode* parent;
	NSMutableArray* children;
}

@property (retain) DCMObject* dcmObject;
@property (retain) S_DicomNode* parent;
@property (retain) NSMutableArray* children;

- (id) initWithDCMObject:(DCMObject*)object;

- (void) setParent:(S_DicomNode*)newParent;
- (void) addChild:(S_DicomNode*)newChild;

@end



@interface XMLGenerator : NSObject
{

}

+ (void) createDicomStructureAtPath:(NSString*)path withFiles:(NSMutableArray*)files withCorrespondingImages:(NSMutableArray*)images;
+ (void) generateXMLFile:(NSString*)fileName atPath:(NSString*)path withContent:(NSXMLElement*)content;

+ (NSArray*) patientAttributes:(DCMObject*)object;
+ (NSArray*) studyAttributes:(DCMObject*)object;
+ (NSArray*) seriesAttributes:(DCMObject*)object;
+ (NSArray*) instanceAttributes:(DCMObject*)object;

@end











//
//  CoreDataToMIRCXMLConverter.h
//  TeachingFile
//
//  Created by Lance Pysher on 3/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CoreDataToMIRCXMLConverter : NSObject {
	id _teachingFile;
	NSXMLDocument *_xmlDocument;
}

- (id)initWithTeachingFile:(id)teachingFile;
- (NSXMLDocument *)xmlDocument;
- (void)createXMLDocument;
- (NSXMLNode *)nodeFromXML:(NSString *)xml withName:(NSString *)name;
- (NSXMLElement *)historySection;
- (NSXMLElement *)imageSection;
- (NSXMLElement *)discussionSection;
- (NSXMLElement *)quizSection;
- (NSXMLElement *)sectionWithHeading:(NSString *)heading;
- (void)insertNode:(NSXMLElement *)node  intoNode:(NSXMLElement *)destination atIndex:(int)index;

@end

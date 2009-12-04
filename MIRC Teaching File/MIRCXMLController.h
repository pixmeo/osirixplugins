//
//  MIRCXMLController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/10/05.
//  Copyright 2005 Macrad,LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIRCAuthorController;
@class MIRCQuestionWindowController;
@class MIRCImageWindowController;
@class WhackedTVController;
@class QTMovie;
@class QTMovieView;
@class MIRCAuthor;


@interface MIRCXMLController : NSWindowController {
	NSString *_path;
	NSXMLDocument *_xmlDocument;	
	NSString *_refDoc;
	NSArray *_authors;
	MIRCAuthorController *authorController;
	IBOutlet NSArrayController *questionArrayController;
	IBOutlet NSArrayController *imageArrayController;
	MIRCQuestionWindowController *questionController;
	MIRCImageWindowController *imageController;
	WhackedTVController *whackedController;
	NSArray *_images;
	QTMovie *_historyMovie;
	QTMovie *_discussionMovie;
	IBOutlet QTMovieView *historyMovieView;
	IBOutlet QTMovieView *discussionMovieView;
	
	id _teachingFile;
	NSManagedObjectContext *_managedObjectContext;


}

- (NSXMLDocument *)xmlDocument;
- (NSXMLElement *)rootElement;
- (NSArray *)sections;
- (NSXMLElement *)sectionWithHeading:(NSString *)heading;
- (NSXMLElement *)historySection;
- (NSXMLElement *)imageSection;
- (NSXMLElement *)discussionSection;
- (NSXMLElement *)quizSection;

- (IBAction)quizAction:(id)sender;
- (IBAction)addQuestion:(id)sender;
- (IBAction)modifyQuestion:(id)sender;
- (IBAction)deleteQuestion:(id)sender;
- (IBAction)chooseRefDoc:(id)sender;

- (id)initWithTeachingFile:(id)teachingFile  managedObjectContext:(NSManagedObjectContext *)context;
- (id)createAuthor;
- (id)initWithPath: (NSString *)folder;
- (NSManagedObjectContext *)managedObjectContext;

//- (void)save: (id)sender;
//general info


- (NSString *)title;
- (NSString *)altTitle;

- (NSAttributedString *)abstractText;
- (void)setAbstractText:(NSAttributedString *)abstractText;
- (NSAttributedString *)altAbstractText;
- (void)setAltAbstractText:(NSAttributedString *)abstractText;

- (NSString *)keywords;
- (void)setKeywords:(NSString *)keywords;

//History
- (NSAttributedString *)history;
- (void)setHistory:(NSAttributedString *)history;

- (NSXMLElement *)patient;

 

//images

//Discussion
- (NSAttributedString *)discussion;
- (void)setDiscussion:(NSAttributedString *)discussion;

- (NSString *)diagnosis;
- (void)setDiagnosis:(NSString *)diagnosis;

- (NSAttributedString *)findings;
- (void)setFindings:(NSAttributedString *)findings;

- (NSString *)ddx;
- (void)setDdx:(NSString *)ddx;

//Quiz

- (NSXMLElement *)quiz;


-(NSXMLNode *)nodeFromXML:(NSString *)xml withName:(NSString *)name;
- (void)insertNode:(NSXMLElement *)node  intoNode:(NSXMLElement *)destination atIndex:(int)index;
- (NSString *)stringValueForNodeNamed:(NSString *)name  parentNode:(NSXMLElement *)parent;

- (NSArray *)thumbnails;
- (NSArray *)images;
- (void)setImages:(NSArray *)images;
- (IBAction)imageAction:(id)sender;
- (IBAction)addImage:(id)sender;
- (IBAction)modifyImage:(id)sender;
- (IBAction)deleteImage:(id)sender;
- (IBAction)captureHistory:(id)sender;
- (IBAction)captureDiscussion:(id)sender;
- (QTMovie *)historyMovie;
- (void)setHistoryMovie:(QTMovie *)movie;
- (void)newMovie:(NSNotification *)note;
- (void)setMovie:(QTMovie *)movie withName:(NSString *)name;
-  (void)saveWithAlert:(BOOL)useAlert;
- (id)teachingFile;
- (void)setTeachingFile:(id)teachingFile;

@end

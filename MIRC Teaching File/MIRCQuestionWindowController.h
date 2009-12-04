//
//  MIRCQuestionWindowController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/20/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIRCAnswerArrayController;
@interface MIRCQuestionWindowController : NSWindowController {
	id _question;
	IBOutlet MIRCAnswerArrayController *answerController;
	NSManagedObjectContext *_managedObjectContext;
}

- (id) initWithQuestion:(id)question managedObjectContext:(NSManagedObjectContext *)context;
- (id)question;
- (IBAction)closeWindow:(id)sender;


- (NSManagedObjectContext *) managedObjectContext;



@end

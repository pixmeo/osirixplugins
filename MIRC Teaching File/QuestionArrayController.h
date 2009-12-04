//
//  QuestionArrayController.h
//  TeachingFile
//
//  Created by Lance Pysher on 2/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIRCQuestionWindowController;

@interface QuestionArrayController : NSArrayController {
	MIRCQuestionWindowController *_questionWindowController;
	IBOutlet NSWindow *_window;
	IBOutlet id _controller;
}

- (IBAction)quizAction:(id)sender;
- (IBAction)modifyQuestion:(id)sender;
- (IBAction)addQuestion:(id)sender;


@end

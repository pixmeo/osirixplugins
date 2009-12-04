//
//  QuestionArrayController.m
//  TeachingFile
//
//  Created by Lance Pysher on 2/22/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "QuestionArrayController.h"
#import "MIRCQuestionWindowController.h"

@implementation QuestionArrayController


- (void)dealloc{
	[_questionWindowController release];
	[super dealloc];
}

- (IBAction)quizAction:(id)sender{
	
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		switch ([sender selectedSegment]) {
			case 0: [self addQuestion:sender];
					break;
			case 1: [self modifyQuestion:sender];
					break;
			case 2: [self remove:sender];
					break;
		}
	}
}

#pragma mark Questions
- (IBAction)addQuestion:(id)sender{
	id question = [self newObject];
	[self addObject:question];
	if (_questionWindowController)
		[_questionWindowController release];
	_questionWindowController = [[MIRCQuestionWindowController alloc] initWithQuestion:question managedObjectContext:[self managedObjectContext]];
	[NSApp beginSheet:[_questionWindowController window] modalForWindow:_window modalDelegate:self  didEndSelector:nil contextInfo:nil];
	
}

- (IBAction)modifyQuestion:(id)sender{	
	if (_questionWindowController)
		[_questionWindowController release];
	_questionWindowController = [[MIRCQuestionWindowController alloc] initWithQuestion:[[self selectedObjects] objectAtIndex:0] managedObjectContext:[self managedObjectContext]];
	[NSApp beginSheet:[_questionWindowController window] modalForWindow:_window modalDelegate:self  didEndSelector:nil contextInfo:nil];
}


@end

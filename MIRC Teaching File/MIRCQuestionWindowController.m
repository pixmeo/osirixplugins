//
//  MIRCQuestionWindowController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/20/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCQuestionWindowController.h"
#import "MIRCAnswerArrayController.h"
#import "MIRCQuestion.h"
#import "MIRCAnswer.h"


@implementation MIRCQuestionWindowController

- (id) initWithQuestion:(id)question managedObjectContext:(NSManagedObjectContext *)context{
	if (self = [super initWithWindowNibName:@"MIRCQuestion"]) {
		_question = question;
		_managedObjectContext = context;
	}
	return self;
}



- (id)question{
	return _question;
}

- (NSAttributedString *)questionString{
	return [[[NSAttributedString alloc] initWithString:[_question valueForKey:@"question"]] autorelease];
}

- (void)setQuestionString:(NSAttributedString *)questionString{
	[_question setValue:[questionString string] forKey:@"question"];
}



- (IBAction)closeWindow:(id)sender{
	
	[NSApp endSheet:[self window]];
	[[self window]  orderOut:self];
}



- (NSManagedObjectContext *) managedObjectContext{
	return _managedObjectContext;
}


@end

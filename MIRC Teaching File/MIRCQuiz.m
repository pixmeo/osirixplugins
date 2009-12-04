//
//  MIRCQuiz.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCQuiz.h"


@implementation NSXMLElement (MIRCQuiz) 

+ (id)quiz{
	return [[[NSXMLElement alloc] initWithName:@"quiz"] autorelease];
}

- (NSArray *)questions{
	return [self elementsForName:@"question"];
}

- (void)addQuestion:(NSXMLElement *)question{
	[self addChild:question];
}

- (void)setQuestions:(NSArray *)questions{
	NSArray *children = [self children];
	NSEnumerator *enumerator = [[self questions] objectEnumerator];
	NSXMLElement *question;
	while (question = [enumerator nextObject]) {
		int index = [children indexOfObject:question];
		[self removeChildAtIndex:index];
	}
	enumerator = [questions objectEnumerator];
	while (question = [enumerator nextObject]) 
		[self addChild:question];
}

@end

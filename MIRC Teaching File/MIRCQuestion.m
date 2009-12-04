//
//  MIRCQuestion.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCQuestion.h"


@implementation NSXMLElement (MIRCQuestion) 

+ (id)questionWithString:(NSString *)question{
	NSXMLElement * node = [[[NSXMLElement  alloc] initWithName:@"question"] autorelease];
	[node addChild:[NSXMLNode elementWithName:@"question-body" stringValue:question]];
	return node;
}

- (NSArray *)answers{
	return [self elementsForName:@"answer"];
}

- (void)addAnswer:(NSXMLElement *)answer{
	[self addChild:answer];
}

- (void)setAnswers:(NSArray *)answers{
	
	[[self answers] makeObjectsPerformSelector:@selector(detach)];
	NSEnumerator *enumerator;
	NSXMLElement *answer;	
	enumerator = [answers objectEnumerator];
	while (answer = [enumerator nextObject]) 
		[self addChild:answer];
	
	
	
}

- (void)setQuestionString:(NSString *)question{
	NSArray *array = [self elementsForName:@"question-body"];
	NSXMLElement *node = nil;
	if ([array count] > 0) {
		node = [array objectAtIndex:0];
		[node setStringValue:question];
	}
	else {
		node = [NSXMLNode elementWithName:@"question-body" stringValue:question];
		[self addChild:node];
	}
}

- (NSString *)questionString{
	NSArray *array = [self elementsForName:@"question-body"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];

	return [node stringValue];
}

@end

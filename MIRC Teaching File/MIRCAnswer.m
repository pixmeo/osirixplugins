//
//  MIRCAnswer.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/18/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCAnswer.h"


@implementation NSXMLElement (MIRCAnswer) 

+ (id)answerWithString:(NSString *)answer{
	NSXMLElement *node = [[[NSXMLElement alloc] initWithName:@"answer"] autorelease];
	[node addChild:[NSXMLNode elementWithName:@"answer-body" stringValue:answer]];
	return node;
}

- (void)setAnswerIsCorrect: (BOOL)isCorrect{
	NSXMLNode *attr = [self attributeForName:@"correct"];
	if (!attr) {
		attr = [NSXMLNode attributeWithName:@"correct" stringValue:(isCorrect) ? @"yes":@"no"];
		[self addAttribute:attr];
	}
	[attr setStringValue:(isCorrect) ? @"yes":@"no"];
	
	NSString *response = (isCorrect) ? @"Correct Answer": @"Incorrect: Try again";
	
	NSArray *array = [self elementsForName:@"response"];
	NSXMLElement *node = nil;
	if ([array count] > 0) {
			node = [array objectAtIndex:0];
			[node setStringValue:response];
	}
	else {
		node = [NSXMLNode elementWithName:@"response" stringValue:response];
		[self addChild:node];
	}

}

- (void)setAnswerString:(NSString *)answer{
	NSArray *array = [self elementsForName:@"answer-body"];
	NSXMLElement *node = nil;
	if ([array count] > 0) {
		node = [array objectAtIndex:0];
		[node setStringValue:answer];
	}
	else {
		node = [NSXMLNode elementWithName:@"answer-body" stringValue:answer];
		[self addChild:node];
	}
	
}

- (NSString *)answerString{
	NSArray *array = [self elementsForName:@"answer-body"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];

	return [node stringValue];
}

- (NSString *)answerResponse{
	NSArray *array = [self elementsForName:@"response"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];

	return [node stringValue];
}

- (BOOL)answerIsCorrect{
	NSXMLNode *attr = [self attributeForName:@"correct"];
	if (!attr)
		return NO;
	else if ([[attr stringValue] isEqualToString:@"no"])
		return NO;
	return YES;
}
	
	

@end

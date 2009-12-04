//
//  CoreDataToMIRCXMLConverter.m
//  TeachingFile
//
//  Created by Lance Pysher on 3/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CoreDataToMIRCXMLConverter.h"
#import "MIRCAuthor.h"
#import "MIRCImage.h"
#import "MIRCQuiz.h"
#import "MIRCQuestion.h"
#import "MIRCAnswer.h"


@implementation CoreDataToMIRCXMLConverter

- (id)initWithTeachingFile:(id)teachingFile{
	if (self = [super init])
		_teachingFile = teachingFile;
	return self;
}


- (NSXMLDocument *)xmlDocument{
	if (!_xmlDocument)
		[self createXMLDocument];
	return _xmlDocument;
}

- (void)createXMLDocument{
	NSXMLElement *root = [[[NSXMLElement alloc] initWithName:@"MIRCdocument"] autorelease];
	_xmlDocument = [[NSXMLDocument alloc] initWithRootElement:root];
	// Display type
	//[root addAttribute:[NSXMLNode attributeWithName:@"display" stringValue:@"mstf"]];
	[root addAttribute:[NSXMLNode attributeWithName:@"display" stringValue:@"tab"]];
	// Title
	if ([_teachingFile valueForKey:@"title"])
		[root addChild:[NSXMLNode elementWithName:@"title" stringValue:[_teachingFile valueForKey:@"title"]]];
	// Alternative Title
	if ([_teachingFile valueForKey:@"altTitle"])
		[root addChild:[NSXMLNode elementWithName:@"alternative-title" stringValue:[_teachingFile valueForKey:@"altTitle"]]];
	// Authors
	NSEnumerator *enumerator = [[_teachingFile valueForKey:@"authors"] objectEnumerator];
	id author;
	while (author = [enumerator nextObject]){

		MIRCAuthor *mircAuthor = [MIRCAuthor author];
		if ([author valueForKey:@"name"])
			[mircAuthor setAuthorName:[author valueForKey:@"name"]];
		if ([author valueForKey:@"phone"])
			[mircAuthor setPhone:[author valueForKey:@"phone"]];
		if ([author valueForKey:@"email"])
			[mircAuthor setEmail:[author valueForKey:@"email"]];
		if ([author valueForKey:@"affilitation"])
			[mircAuthor setAffiliation:[author valueForKey:@"affilitation"]];
		[root addChild:mircAuthor];
	}
	// History

	//Abstract
	if ([_teachingFile  valueForKey:@"abstractText"]) {
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[_teachingFile  valueForKey:@"abstractText"] withName:@"abstract"];
		[root addChild:node];
	}

	//Alt Abstract
	
	if ([_teachingFile  valueForKey:@"altAbstractText"]) {
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[_teachingFile  valueForKey:@"altAbstractText"] withName:@"alternative-abstract"];
		[root addChild:node];
	}

	//keywords
	if ([_teachingFile valueForKey:@"keywords"])
		[root addChild:[NSXMLNode elementWithName:@"keywords" stringValue:[_teachingFile valueForKey:@"keywords"]]];
	
	/********** Sections ************/
	
	[root addChild:[self historySection]];
	//[root addChild: [self sectionWithHeading:@"Method"]];
	[root addChild:[self imageSection]];
	//[root addChild: [self sectionWithHeading:@"Results"]];
	[root addChild:[self discussionSection]];
	[root addChild:[self quizSection]];
	
}

- (NSXMLNode *)nodeFromXML:(NSString*)xml withName:(NSString *)name{
	NSError *error;

	NSString *xmlString = [NSString stringWithFormat:@"<%@>%@</%@>",name, xml, name];
	NSXMLElement *node = [[[NSXMLElement alloc] initWithXMLString:xmlString error:&error] autorelease];
	if (!error)
		return node;
	NSLog(@"Error reading XML: %@", [error description]);
	return nil;
}

- (NSXMLElement *)historySection{

	NSXMLElement *historySection =  [self sectionWithHeading:@"History"];
	NS_DURING
	
	NSString *history = [_teachingFile valueForKey:@"history"];

	// Add history text.  Need to take into account possible embedded html
	if ([history hasPrefix:@"<"]) {
		//should be xml or html"

		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:history withName:@"history"];
		[self insertNode:(NSXMLElement *)node  intoNode:historySection atIndex:0];
	}
	// probably no HTML. treat it as plain text.
	else  if (history){
		NSLog(@"history, no html");
		NSXMLElement *node = nil;
		NSXMLNode *textNode = [NSXMLNode textWithStringValue:history];
		node = [NSXMLNode elementWithName:@"history"];
		[historySection addChild:node];
		//[self insertNode:(NSXMLElement *)node  intoNode:historySection atIndex:0];
		[node setChildren:[NSArray arrayWithObject:textNode]];
		
	}
	[history release];
	
	// add history movie
	if ([_teachingFile valueForKey:@"historyMovie"]) {
		// Add link text
		NSXMLElement *node = [NSXMLNode elementWithName:@"a" stringValue:@"watch video"];
		// add link to history.mov
		[node addAttribute:[NSXMLNode attributeWithName:@"href" stringValue:@"history.mov"]];
		[historySection  addChild:node];
	}
	
	NS_HANDLER
		NSLog (@"error saving history: %@", [localException name]);
	NS_ENDHANDLER
	
	return historySection;
}


- (NSXMLElement *)discussionSection{
	NSXMLElement *discussionSection =  [self sectionWithHeading:@"Discussion"];
	
	NS_DURING
	//diagnosis
	NSXMLNode *node = [NSXMLNode elementWithName:@"diagnosis" stringValue:[_teachingFile valueForKey:@"diagnosis"]];
	[discussionSection addChild:node];
	//[self insertNode:(NSXMLElement *)node  intoNode:discussionSection atIndex:0];
	
	//findings
	NSString *findings = [_teachingFile valueForKey:@"findings"];
	// Add findings text.  Need to take into account possible embedded html
	if (findings){
	//if ([findings hasPrefix:@"<"]) {
		//should be xml or html"
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:findings withName:@"findings"];
		[discussionSection addChild:node];
	}
	// probably no HTML. treat it as plain text.
	else  {
	//if (findings){
		NSLog(@"findings not html");
		NSXMLElement *node = nil;
		//NSXMLNode *textNode = [NSXMLNode textWithStringValue:findings];
		//node = [NSXMLNode elementWithName:@"findings"];
		//[self insertNode:(NSXMLElement *)node  intoNode:discussionSection atIndex:1];
		node = [NSXMLNode elementWithName:@"findings" stringValue:findings];
		[discussionSection addChild:node];	
	//	[node setChildren:[NSArray arrayWithObject:textNode]];
	}
	[findings release];
		
	//ddx
	node = [NSXMLNode elementWithName:@"differential-diagnosis" stringValue:[_teachingFile valueForKey:@"ddx"]];
	[discussionSection addChild:node];	
	
	NSString *discussion = [_teachingFile valueForKey:@"discussion"];

	// Add discussion text.  Need to take into account possible embedded html
	if (discussion){
	//if ([discussion hasPrefix:@"<"]) {
		//should be xml or html"
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:discussion withName:@"discussion"];
		[self insertNode:(NSXMLElement *)node  intoNode:discussionSection atIndex:3];
	}
	// probably no HTML. treat it as plain text.
	else { // if (discussion){
	
		NSXMLElement *node = nil;
		NSXMLNode *textNode = [NSXMLNode textWithStringValue:discussion];
		node = [NSXMLNode elementWithName:@"discussion"];
		[discussionSection addChild:node];
		[node setChildren:[NSArray arrayWithObject:textNode]];
		
	}
	[discussion release];
	

	// add discussion movie
	if ([_teachingFile valueForKey:@"discussionMovie"]) {
		// Add link text
		NSXMLElement *node = [NSXMLNode elementWithName:@"a" stringValue:@"watch video"];
		// add link to history.mov
		[node addAttribute:[NSXMLNode attributeWithName:@"href" stringValue:@"discussion.mov"]];
		[discussionSection  addChild:node];
	}
	
	NS_HANDLER
		NSLog (@"error saving discussion: %@", [localException name]);
	NS_ENDHANDLER
	return discussionSection;
}


- (NSXMLElement *)imageSection{
	NSXMLElement *	imageSection = [NSXMLNode elementWithName:@"image-section"];
	[imageSection addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"Images"]];	
	NSEnumerator *enumerator = [[_teachingFile valueForKey:@"images"] objectEnumerator];
	id image;
	while (image = [enumerator nextObject]) {
		NSXMLElement *mircImage = [NSXMLElement image];
		NSString *index = [[image valueForKey:@"index"] stringValue];
		[mircImage addAttribute:[NSXMLNode attributeWithName:@"src" stringValue:[index stringByAppendingPathExtension:@"jpg"]]];
		// original Dimension  Could  be movie or jpeg.  Only jpeg now.
		[mircImage setOriginalDimensionImagePath:[[NSString stringWithFormat:@"%@-OD", index] stringByAppendingPathExtension:[image valueForKey:@"originalDimensionExtension"]]];
		// Annotated Image
		[mircImage setAnnotationImagePath:[[NSString stringWithFormat:@"%@-ANN", index] stringByAppendingPathExtension:@"jpg"]];
		//orignal format
		[mircImage setOriginalFormatImagePath:[[NSString stringWithFormat:@"%@-OF", index] stringByAppendingPathExtension:[image valueForKey:@"originalFormatExtension"]]];
		[imageSection addChild:mircImage];
	}	
				
	return imageSection;
}

- (NSXMLElement *)quizSection{
	NSXMLElement *quizSection =  [self sectionWithHeading:@"Quiz"];
	NSXMLElement *quiz = [NSXMLElement quiz];
	[quizSection addChild:quiz];
	NSEnumerator *enumerator = [[_teachingFile valueForKey:@"questions"] objectEnumerator];
	id question;
	while (question = [enumerator nextObject]) {
		NSXMLElement *node = [NSXMLElement questionWithString:[question valueForKey:@"question"]];
		//add answers
		NSEnumerator *answerEnumerator = [[question valueForKey:@"answers"] objectEnumerator];
		id answer;
		while (answer = [answerEnumerator nextObject]) {
			NSXMLElement *answerNode = [NSXMLElement answerWithString:[answer valueForKey:@"answer"]];
			[answerNode setAnswerIsCorrect:[[answer valueForKey:@"isCorrect"] boolValue]];
			[node addAnswer:answerNode];
		}
		[quiz addQuestion:node];
	}
	return quizSection;
}

- (NSXMLElement *)sectionWithHeading:(NSString *)heading{
	
	NSXMLElement *node = [NSXMLNode elementWithName:@"section"];
	[node addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:heading]];
	return node;
}

- (void)insertNode:(NSXMLElement *)node  intoNode:(NSXMLElement *)destination atIndex:(int)index{
	int childCount = [destination childCount];
	if (childCount > index)
		[destination insertChild:node atIndex:index]; 
	else {

		[destination addChild:node];
	}
}

@end

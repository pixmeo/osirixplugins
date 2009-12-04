//
//  MIRCPatient.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/12/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCPatient.h"


@implementation NSXMLElement  (MIRCPatient)

 + (id)patient{
	NSXMLElement *node = [[[NSXMLElement alloc] initWithName:@"patient"] autorelease];
	[node addAttribute:[NSXMLNode attributeWithName:@"visible" stringValue:@"no"]];
	return node;
}

 - (NSString *)patientAge{
	NSArray *array = [self elementsForName:@"pt-age"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	NSArray *children = [node children];
	NSXMLElement *element = nil;
	if ([children count] > 0) {
		element = [children objectAtIndex: 0];
		return [NSString stringWithFormat:@"%@ %@",  [element stringValue], [element name]];		
	}
	return nil;
}

 - (void)setPatientAge:(NSString *)age{
	NSString *type= @"years";
	NSArray *substrings = [age componentsSeparatedByString:@" "];
	NSString *theAge = [substrings objectAtIndex:0];
	if ([substrings count] > 1)
		type = [substrings objectAtIndex:1];
	NSXMLElement *element = [NSXMLNode elementWithName:type stringValue:theAge];
 	NSArray *array = [self elementsForName:@"pt-age"];
	NSXMLElement *node = nil;
	if ([array count] > 0) {
		node = [array objectAtIndex:0];
	}
	else {
		node = [NSXMLNode elementWithName:@"pt-age"];
		[self addChild:node];
	}
	[node setChildren:[NSArray arrayWithObject:element]];
	//node 
	
 }
 /*
 - (NSString *ageType{
 }
 - (void)setAgeType:(NSString *) type{
 }
 */
 - (NSString *)sex{
 	NSArray *array = [self elementsForName:@"pt-sex"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];

	return [node stringValue];
}
 - (void)setSex:(NSString *)sex{
  	NSArray *array = [self elementsForName:@"pt-sex"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	else {
		node = [NSXMLNode elementWithName:@"pt-sex"];
		[self addChild:node];
	}
	[node setStringValue:sex];
 }
 
 - (NSString *)race{
 	NSArray *array = [self elementsForName:@"pt-race"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];

	return [node stringValue];
}


 - (void)setRace:(NSString *)race{
   	NSArray *array = [self elementsForName:@"pt-race"];
	NSXMLElement *node = nil;
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	else {
		node = [NSXMLNode elementWithName:@"pt-race"];
		[self addChild:node];
	}
	[node setStringValue:race];
 }

@end

//
//  MIRCAuthor.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/10/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCAuthor.h"


@implementation MIRCAuthor

+ (id)author{
	return [[[MIRCAuthor alloc] init] autorelease];
}

- (id)init{
	if (self = [super initWithName:@"author"]){
		[self addChild:[NSXMLNode elementWithName:@"name"]];
		[self addChild:[NSXMLNode elementWithName:@"affiliation"]];
		[self addChild:[NSXMLNode elementWithName:@"contact"]];		//email
		[self addChild:[NSXMLNode elementWithName:@"contact"]];		//phone
		[self addChild:[NSXMLNode elementWithName:@"contact"]];		//address 1
		[self addChild:[NSXMLNode elementWithName:@"contact"]];		//address 2
	}	
	return self;
}



@end

@implementation NSXMLElement (AuthorCategory) 

- (NSString *)authorName{
	NSArray *array = [self elementsForName:@"name"];
	if (array)
		return [[array objectAtIndex:0] stringValue];
	return nil;
}

- (void)setAuthorName:(NSString *)authorName{
	NSArray *array = [self elementsForName:@"name"];
	if (array)
		[[array objectAtIndex:0] setStringValue:authorName];
	else if ([self childCount] > 0)
		[self insertChild:[NSXMLNode elementWithName:@"name" stringValue:authorName]  atIndex:0]; //name is first child
	else
		[self addChild:[NSXMLNode elementWithName:@"name" stringValue:authorName]]; 
}

- (NSString *)affiliation{
	NSArray *array = [self elementsForName:@"affiliation"];
	if (array)
		return [[array objectAtIndex:0] stringValue];
	return nil;
}

- (void)setAffiliation:(NSString *)affiliation{
	NSArray *array = [self elementsForName:@"affiliation"];
	if (array)
		[[array objectAtIndex:0] setStringValue:affiliation];
	else if ([self childCount] > 1)
		[self insertChild:[NSXMLNode elementWithName:@"affiliation" stringValue:affiliation]  atIndex:1]; //affiliation is second child
	else
		[self addChild:[NSXMLNode elementWithName:@"affiliation" stringValue:affiliation]]; 
}

- (NSArray *)contacts{
	return [self elementsForName:@"contact"];
}

- (void)setContacts:(NSArray *)contacts{
	
	int i;
	for (i = 0; i < [contacts count]; i++){
		//contacts should be 3rd through the end of the children
		if ( i + 2 < [self childCount])
			[self replaceChildAtIndex:i+2 withNode:[contacts objectAtIndex:i]];
		else
			[self addChild:[contacts objectAtIndex:i]];
	}
}



- (NSString *)email{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 0)
		return [[array objectAtIndex:0] stringValue];
	return nil;
}

- (void)setEmail:(NSString *)email{
	NSArray *array = [self elementsForName:@"contact"];
	if (array)
		[[array objectAtIndex:0] setStringValue:email];
	else if ([self childCount] > 2)
		[self insertChild:[NSXMLNode elementWithName:@"name" stringValue:email]  atIndex:2]; //email is 3rd child
	else
		[self addChild:[NSXMLNode elementWithName:@"name" stringValue:email]]; 
}


- (NSString *)phone{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 1)
		return [[array objectAtIndex:1] stringValue];
	return nil;
}

- (void)setPhone:(NSString *)phone{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 1)
		[[array objectAtIndex:1] setStringValue:phone];
	else if ([self childCount] > 3)
		[self insertChild:[NSXMLNode elementWithName:@"name" stringValue:phone]  atIndex:3]; //phone is 4rd child
	else
		[self addChild:[NSXMLNode elementWithName:@"name" stringValue:phone]]; 
}


- (NSString *)address1{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 2)
		return [[array objectAtIndex:2] stringValue];
	return nil;
}

- (void)setAddress1:(NSString *)address{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 2)
		[[array objectAtIndex:2] setStringValue:address];
	else if ([self childCount] > 4)
		[self insertChild:[NSXMLNode elementWithName:@"name" stringValue:address]  atIndex:4]; //address is 5th child
	else
		[self addChild:[NSXMLNode elementWithName:@"name" stringValue:address]]; 
}

- (NSString *)address2{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 3)
		return [[array objectAtIndex:3] stringValue];
	return nil;
}

- (void)setAddress2:(NSString *)address{
	NSArray *array = [self elementsForName:@"contact"];
	if (array && [array count] > 3)
		[[array objectAtIndex:3] setStringValue:address];
	else if ([self childCount] > 5)
		[self insertChild:[NSXMLNode elementWithName:@"name" stringValue:address]  atIndex:5]; //address is 6th child
	else
		[self addChild:[NSXMLNode elementWithName:@"name" stringValue:address]]; 
}




@end

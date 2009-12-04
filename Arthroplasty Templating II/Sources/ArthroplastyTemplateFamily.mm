//
//  ArthroplastyTemplateFamily.m
//  Arthroplasty Templating II
//  Created by Alessandro Volz on 6/4/09.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplate.h"


@implementation ArthroplastyTemplateFamily
@synthesize templates = _templates;

-(id)initWithTemplate:(ArthroplastyTemplate*)templat {
	self = [super init];
	
	_templates = [[NSMutableArray arrayWithCapacity:8] retain];
	[self add:templat];
	
	return self;
}

-(void)dealloc {
	[_templates release]; _templates = NULL;
	[super dealloc];
}

-(BOOL)matches:(ArthroplastyTemplate*)templat {
	if (![[templat manufacturer] isEqualToString:[self manufacturer]]) return NO;
	if (![[templat name] isEqualToString:[self name]]) return NO;
	return YES;
}

-(void)add:(ArthroplastyTemplate*)templat {
	[_templates addObject:templat];
	[templat setFamily:self];
}

-(ArthroplastyTemplate*)template:(NSInteger)index {
	return [_templates objectAtIndex:index];
}

-(ArthroplastyTemplate*)templateAfter:(ArthroplastyTemplate*)t {
	return [self template:([_templates indexOfObject:t]+1)%[_templates count]];
}

-(ArthroplastyTemplate*)templateBefore:(ArthroplastyTemplate*)t {
	int index = [_templates indexOfObject:t]-1;
	if (index < 0) index = [_templates count]-1;
	return [self template:index];
}

-(NSString*)fixation {
	return [[self template:0] fixation];
}

-(NSString*)group {
	return [[self template:0] group];
}

-(NSString*)manufacturer {
	return [[self template:0] manufacturer];
}

-(NSString*)modularity {
	return [[self template:0] modularity];
}

-(NSString*)name {
	return [[self template:0] name];
}

-(NSString*)placement {
	return [[self template:0] placement];
}

-(NSString*)surgery {
	return [[self template:0] surgery];
}

-(NSString*)type {
	return [[self template:0] type];
}

@end

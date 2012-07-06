//
//  ArthroplastyTemplateFamily.m
//  Arthroplasty Templating II
//  Created by Alessandro Volz on 6/4/09.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplate.h"
#import <cmath>


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

+(CGFloat)numberForSize:(NSString*)size {
    NSRange r = [size rangeOfCharacterFromSet:[NSCharacterSet.decimalDigitCharacterSet invertedSet]];
    if (r.location == 0)
        return 0;
    if (r.location != NSNotFound)
        size = [size substringToIndex:r.location];
    return [size floatValue];
}

-(ArthroplastyTemplate*)templateMatchingSize:(NSString*)size {
    // 1) by compairing strings
    for (ArthroplastyTemplate* at in _templates)
        if ([at.size isEqualToString:size])
            return at;
    
    // 2) by compairing numbers...
    NSInteger closestIndex = -1;
    CGFloat closestDelta;
    CGFloat nin = [[self class] numberForSize:size];
    for (NSInteger i = 0; i < _templates.count; ++i) {
        ArthroplastyTemplate* at = [_templates objectAtIndex:i];
        
        CGFloat nat = [[self class] numberForSize:at.size];
        if (nin == nat)
            return at;
        
        CGFloat delta = std::pow(nat-nin, 2); // actially this is delta pow 2, but we don't need the actual value so avoid sqrt to save time
        
        if (closestIndex == -1 || closestDelta > delta) {
            closestIndex = i;
            closestDelta = delta;
        }
    }
    
    return [_templates objectAtIndex:closestIndex];
}

-(ArthroplastyTemplate*)templateForIndex:(NSInteger)index {
	return [_templates objectAtIndex:index];
}

-(ArthroplastyTemplate*)templateAfter:(ArthroplastyTemplate*)t {
	return [self templateForIndex:([_templates indexOfObject:t]+1)%[_templates count]];
}

-(ArthroplastyTemplate*)templateBefore:(ArthroplastyTemplate*)t {
	int index = [_templates indexOfObject:t]-1;
	if (index < 0) index = [_templates count]-1;
	return [self templateForIndex:index];
}

-(NSString*)fixation {
	return [self templatesValueForKey:@"fixation"];
}

-(NSString*)group {
	return [self templatesValueForKey:@"group"];
}

-(NSString*)manufacturer {
	return [self templatesValueForKey:@"manufacturer"];
}

-(NSString*)modularity {
	return [self templatesValueForKey:@"modularity"];
}

-(NSString*)name {
	return [self templatesValueForKey:@"name"];
}

-(NSString*)placement {
	return [self templatesValueForKey:@"placement"];
}

-(NSString*)surgery {
	return [self templatesValueForKey:@"surgery"];
}

-(NSString*)type {
	return [self templatesValueForKey:@"type"];
}

-(NSString*)templatesValueForKey:(NSString*)key {
    NSArray* values = [_templates valueForKey:key];
    
    NSMutableArray* usedValues = [NSMutableArray array];
    NSMutableString* str = [NSMutableString string];
    
    for (NSString* value in values)
        if ([value isKindOfClass:[NSString class]] && ![usedValues containsObject:value]) {
            [usedValues addObject:value];
            if (!str.length)
                [str appendString:value];
            else [str appendFormat:@"| %@", value];
        }
    
    return str;
}

@end

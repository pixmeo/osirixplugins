//
//  InfoTxtTemplate.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 19/03/07.
//  Modified by Alessandro Volz since 07/2009
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "InfoTxtTemplate.h"
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/N2Operators.h>

@implementation InfoTxtTemplate

static id First(id a, id b) {
	return a? a : b;
}

+(NSArray*)templatesFromFileAtPath:(NSString*)path {
    return [NSArray arrayWithObject:[[[[self class] alloc] initFromFileAtPath:path] autorelease]];
}

+(NSDictionary*)propertiesFromInfoFileAtPath:(NSString*)path {
	NSError* error;
	NSString* fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!fileContent) {
		fileContent = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:&error];
		if(!fileContent) {
			NSLog(@"[ZimmerTemplate propertiesFromFileInfoAtPath]: %@", error);
			return NULL;
		}
	}
	
	NSScanner* infoFileScanner = [NSScanner scannerWithString:fileContent];
	[infoFileScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
	
	NSMutableDictionary* properties = [[NSMutableDictionary alloc] initWithCapacity:128];
	NSCharacterSet* newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
	while (![infoFileScanner isAtEnd]) {
		NSString *key = @"", *value = @"";
		[infoFileScanner scanUpToString:@":=:" intoString:&key];
		key = [key stringByTrimmingStartAndEnd];
		[infoFileScanner scanString:@":=:" intoString:NULL];
		[infoFileScanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&value];
		value = [value stringByTrimmingStartAndEnd];
		[properties setObject:value forKey:key];
		[infoFileScanner scanCharactersFromSet:newlineCharacterSet intoString:NULL];
	}
	
	return [properties autorelease];
}

-(id)initFromFileAtPath:(NSString*)path {
	self = [super initWithPath:path];
	
	// properties
	_properties = [[[self class] propertiesFromInfoFileAtPath:path] retain];
	if (!_properties)
		return NULL; // TODO: is self released?

	return self;
}

-(void)dealloc {
	[_properties release]; _properties = NULL;
	[super dealloc];
}

-(NSString*)pdfPathForDirection:(ArthroplastyTemplateViewDirection)direction {
	NSString* key = direction==ArthroplastyTemplateAnteriorPosteriorDirection? @"PDF_FILE_AP" : @"PDF_FILE_ML";
	NSString* filename = [_properties objectForKey:key];
	return [[_path stringByDeletingLastPathComponent] stringByAppendingPathComponent:filename];
}

-(NSString*)prefixForDirection:(ArthroplastyTemplateViewDirection)direction {
	return direction == ArthroplastyTemplateAnteriorPosteriorDirection? @"AP" : @"ML";
}

-(BOOL)point:(NSPoint*)point forEntry:(NSString*)entry direction:(ArthroplastyTemplateViewDirection)dir {
	NSString* prefix = [NSString stringWithFormat:@"%@_%@_", [self prefixForDirection:dir], entry];
	
	NSString* key = [NSString stringWithFormat:@"%@X", prefix];
	NSString *xs = [_properties objectForKey:key];
	key = [NSString stringWithFormat:@"%@Y", prefix];
	NSString *ys = [_properties objectForKey:key];
	
	if (!xs || !ys || ![xs length] || ![ys length])
		return NO;
	
	*point = NSMakePoint([xs floatValue], [ys floatValue])/25.4; // 1in = 25.4mm, ORIGIN data in mm
	return YES;
}

-(BOOL)origin:(NSPoint*)point forDirection:(ArthroplastyTemplateViewDirection)dir {
	return [self point:point forEntry:@"ORIGIN" direction:dir];
}

-(BOOL)csys:(NSPoint*)point forDirection:(ArthroplastyTemplateViewDirection)dir {
	return [self point:point forEntry:@"PRODUCT_FAMILY_CSYS" direction:dir];
}

-(NSArray*)headRotationPointsForDirection:(ArthroplastyTemplateViewDirection)dir {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:5];
	
	NSPoint origin; [self origin:&origin forDirection:dir];
//	NSPoint csys; BOOL hasCsys = [self csys:&csys forDirection:dir];
    
	for (unsigned i = 1; i <= 5; ++i) {
		NSPoint point = {0,0};
        
        BOOL hasPoint = [self point:&point forEntry:[NSString stringWithFormat:@"HEAD_ROTATION_POINT_%d", i] direction:dir];
        if (hasPoint)
/*            if (hasCsys)
                point = (point+csys);
            else*/ point += origin;
        
		[points addObject:[NSValue valueWithPoint:point]];
	}
	
	return points;
}

-(NSArray*)matingPointsForDirection:(ArthroplastyTemplateViewDirection)dir {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:5];
	
	NSPoint origin; [self origin:&origin forDirection:dir];
	
	for (unsigned i = 0; i < 4; ++i) {
		NSString* ki = NULL;
		switch (i) {
			case 0: ki = @"A"; break;
			case 1: ki = @"A2"; break;
			case 2: ki = @"B"; break;
			case 3: ki = @"B2"; break;
		}
        
		NSPoint point = {0,0};
        
        BOOL hasPoint = [self point:&point forEntry:[NSString stringWithFormat:@"MATING_POINT_%@", ki] direction:dir];
        if (hasPoint)
            point += origin;
        
		[points addObject:[NSValue valueWithPoint:point+origin]];
	}
	
	return points;
}

-(NSImage*)imageForDirection:(ArthroplastyTemplateViewDirection)direction {
	return [[[NSImage alloc] initWithContentsOfFile:[self pdfPathForDirection:direction]] autorelease];
}

-(NSArray*)textualData {
	return [NSArray arrayWithObjects:[self name], [NSString stringWithFormat:@"Size: %@", [self size]], [self manufacturer], @"", @"", NULL];
}

// props

-(NSString*)fixation {
	return [_properties objectForKey:@"FIXATION_TYPE"];
}

-(NSString*)group {
	return [_properties objectForKey:@"PRODUCT_GROUP"];
}

-(NSString*)manufacturer {
	return First([_properties objectForKey:@"IMPLANT_MANUFACTURER"], [_properties objectForKey:@"DESIGN_OWNERSHIP"]);
}

-(NSString*)modularity {
	return [_properties objectForKey:@"MODULARITY_INFO"];
}

-(NSString*)name {
	return First([_properties objectForKey:@"COMPONENT_FAMILY_NAME"], [_properties objectForKey:@"PRODUCT_FAMILY_NAME"]);
}

-(NSString*)placement {
	return First([_properties objectForKey:@"PATIENT_SIDE"], [_properties objectForKey:@"LEFT_RIGHT"]);
}

-(NSString*)surgery {
	return [_properties objectForKey:@"TYPE_OF_SURGERY"];
}

-(NSString*)type {
	return [_properties objectForKey:@"COMPONENT_TYPE"];
}

-(NSString*)size {
	return [_properties objectForKey:@"SIZE"];
}

-(NSString*)referenceNumber {
	return First([_properties objectForKey:@"PRODUCT_ID"], [_properties objectForKey:@"REF_NO"]);
}

-(CGFloat)scale {
	return 1;
}

-(CGFloat)rotation {
	NSString* rotationString = [_properties objectForKey:@"AP_HEAD_ROTATION_RADS"];
	return rotationString? [rotationString floatValue] : 0;
}

-(ATSide)side {
	NSString* orientation = [_properties objectForKey:@"ORIENTATION"];
	if (!orientation || ([orientation compare:@"RIGHT" options:NSCaseInsensitiveSearch+NSLiteralSearch] == NSOrderedSame))
		return ATRightSide;
	if ([orientation compare:@"LEFT" options:NSCaseInsensitiveSearch+NSLiteralSearch] == NSOrderedSame)
		return ATLeftSide;
	return ATRightSide;
}

-(BOOL)isProximal {
    return [[self.type lowercaseString] contains:@"proximal"];
}

-(BOOL)isDistal {
    return [[self.type lowercaseString] contains:@"distal"];
}


@end

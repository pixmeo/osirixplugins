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

+(NSArray*)templatesAtPath:(NSString*)dirpath {
	return [[self class] templatesAtPath:dirpath usingClass:[self class]];
}

+(NSArray*)templatesAtPath:(NSString*)dirpath usingClass:(Class)classs {
	NSMutableArray* templates = [NSMutableArray array];
	
	BOOL isDirectory, exists = [[NSFileManager defaultManager] fileExistsAtPath:dirpath isDirectory:&isDirectory];
	if (exists && isDirectory) {
		NSDirectoryEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:dirpath];
		NSString* sub; while (sub = [e nextObject]) {
			NSString* subpath = [dirpath stringByAppendingPathComponent:sub];
			[[NSFileManager defaultManager] fileExistsAtPath:subpath isDirectory:&isDirectory];
			if (!isDirectory && [subpath rangeOfString:@".disabled/"].location == NSNotFound && [[subpath pathExtension] isEqualToString:@"txt"])
				[templates addObject:[[[classs alloc] initFromFileAtPath:subpath] autorelease]];
		}
	}
	
	return templates;
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

-(BOOL)origin:(NSPoint*)point forDirection:(ArthroplastyTemplateViewDirection)direction {
	NSString* prefix = [NSString stringWithFormat:@"%@_ORIGIN_", [self prefixForDirection:direction]];
	
	NSString* key = [NSString stringWithFormat:@"%@X", prefix];
	NSString *xs = [_properties objectForKey:key];
	key = [NSString stringWithFormat:@"%@Y", prefix];
	NSString *ys = [_properties objectForKey:key];
	
	if (!xs || !ys || ![xs length] || ![ys length])
		return NO;
	
	*point = NSMakePoint([xs floatValue], [ys floatValue])/25.4; // 1in = 25.4mm, ORIGIN data in mm
	return YES;
}

-(NSArray*)headRotationPointsForDirection:(ArthroplastyTemplateViewDirection)direction {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:5];
	NSString* prefix = [NSString stringWithFormat:@"%@_HEAD_ROTATION_POINT_", [self prefixForDirection:direction]];
	
	NSPoint origin; [self origin:&origin forDirection:direction];
	
	for (unsigned i = 1; i <= 5; ++i) {
		NSString* sx = [_properties objectForKey:[NSString stringWithFormat:@"%@%d_X", prefix, i]];
		NSString* sy = [_properties objectForKey:[NSString stringWithFormat:@"%@%d_Y", prefix, i]];
		NSPoint point = {0,0};
		if ([sx length] && [sy length])
			point = NSMakePoint([sx floatValue], [sy floatValue])/25.4;
		[points addObject:[NSValue valueWithPoint:point+origin]];
	}
	
	return points;
}

-(NSArray*)matingPointsForDirection:(ArthroplastyTemplateViewDirection)direction {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:5];
	NSString* prefix = [NSString stringWithFormat:@"%@_MATING_POINT_", [self prefixForDirection:direction]];
	
	NSPoint origin; [self origin:&origin forDirection:direction];
	
	for (unsigned i = 0; i < 4; ++i) {
		NSString* ki = NULL;
		switch (i) {
			case 0: ki = @"A"; break;
			case 1: ki = @"A2"; break;
			case 2: ki = @"B"; break;
			case 3: ki = @"B2"; break;
		}
		NSPoint point = {0,0};
		NSString* sx = [_properties objectForKey:[NSString stringWithFormat:@"%@%@_X", prefix, ki]];
		NSString* sy = [_properties objectForKey:[NSString stringWithFormat:@"%@%@_Y", prefix, ki]];
		if ([sx length] && [sy length])
			point = NSMakePoint([sx floatValue], [sy floatValue])/25.4;
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
	return [_properties objectForKey:@"LEFT_RIGHT"];
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
	return [_properties objectForKey:@"REF_NO"];
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

@end

//
//  MIRCImage.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/24/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCImage.h"


@implementation NSXMLElement  (MIRCImage) 

+ (id)image{
	return [[[NSXMLElement  alloc] initWithName:@"image"] autorelease];
}
+ (id)altImage{
	return [[[NSXMLElement  alloc] initWithName:@"alternative-image"] autorelease];
}

- (NSString *)path{
	
	return [[self attributeForName:@"src"] stringValue];
}
	
- (void)setPath:(NSString *)path{
	NSXMLNode *attr = [self attributeForName:@"src"];
	if (attr)
		[attr setStringValue:path];
	else
		[self addAttribute:[NSXMLNode attributeWithName:@"src" stringValue:path]];
}

- (NSArray *)alternativeImages{
	return [self elementsForName:@"alternative-image"];
}

- (NSXMLElement *)alternativeImageWithRole:(NSString *)role{
	NSEnumerator *enumerator = [[self alternativeImages] objectEnumerator];
	NSXMLElement *node;
	while (node = [enumerator nextObject]) {
		if ([[[node attributeForName:@"role"] stringValue] isEqualToString:role])
			return node;
	}
	return nil;
}

- (NSXMLElement *)newAltImageWithRole:(NSString *)role  src:(NSString *)src{
	NSXMLElement *node = [NSXMLElement altImage];
	[node addAttribute:[NSXMLNode attributeWithName:@"src" stringValue:src]];
	[node addAttribute:[NSXMLNode attributeWithName:@"role" stringValue:role]];
	return node;
}
		

- (void)setOriginalFormatImage:(NSXMLElement *)altImage{
	[[self originalFormatImage] detach];
	[self addChild:altImage];
}

- (void)setOriginalDimensionImage:(NSXMLElement *)altImage{
	[[self originalDimensionImage] detach];
	[self addChild:altImage];
}

- (void)setAnnotationImage:(NSXMLElement *)altImage{
	[[self annotationImage] detach];
	[self addChild:altImage];
}



- (void)setOriginalFormatImagePath:(NSString *)path{
	NSXMLElement *node = [self newAltImageWithRole:@"original-format"  src:path];
	[self setOriginalFormatImage:node];
}

- (void)setOriginalDimensionImagePath:(NSString *)path{
		NSXMLElement *node = [self newAltImageWithRole:@"original-dimensions"  src:path];
	[self setOriginalDimensionImage:node];
}

- (void)setAnnotationImagePath:(NSString *)path{
	NSXMLElement *node = [self newAltImageWithRole:@"annotation"  src:path];
	[self setAnnotationImage:node];
}


- (NSXMLElement *)originalFormatImage{
	return [self alternativeImageWithRole:@"original-format"];
}

- (NSXMLElement *)originalDimensionImage{
	return [self alternativeImageWithRole:@"original-dimensions"];
}

- (NSXMLElement *)annotationImage{
	return [self alternativeImageWithRole:@"annotation"];
}

- (NSString *)originalFormatImagePath{
	return [[[self originalFormatImage] attributeForName:@"src"] stringValue];
}

- (NSString *)originalDimensionImagePath{
	return [[[self originalDimensionImage] attributeForName:@"src"] stringValue];
}

- (NSString *)annotationImagePath{
	return [[[self annotationImage] attributeForName:@"src"] stringValue];
}


@end

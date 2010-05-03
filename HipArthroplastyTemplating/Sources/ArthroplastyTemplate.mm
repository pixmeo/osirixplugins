//
//  ArthroplastyTemplate.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplate.h"


@implementation ArthroplastyTemplate
@synthesize family = _family;
@synthesize path = _path;

-(id)initWithPath:(NSString*)path {
	self = [super init];
	_path = [path retain];
	return self;
}

-(void)dealloc {
	[_path release];
	[super dealloc];
}

-(NSString*)fixation {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate fixation] must be implemented"];
	return NULL;
}

-(NSString*)group {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate group] must be implemented"];
	return NULL;
}

-(NSString*)manufacturer {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate manufacturer] must be implemented"];
	return NULL;
}

-(NSString*)modularity {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate modularity] must be implemented"];
	return NULL;
}

-(NSString*)name {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate name] must be implemented"];
	return NULL;
}

-(NSString*)placement {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate placement] must be implemented"];
	return NULL;
}

-(NSString*)surgery {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate surgery] must be implemented"];
	return NULL;
}

-(NSString*)type {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate type] must be implemented"];
	return NULL;
}

-(NSString*)size {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate size] must be implemented"];
	return NULL;
}

-(NSString*)referenceNumber {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate referenceNumber] must be implemented"];
	return NULL;
}

-(CGFloat)scale {
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate scale] must be implemented"];
	return 0;
}

-(CGFloat)rotation { // in RADS
	[NSException raise:NSInternalInconsistencyException format:@"[ArthroplastyTemplate scale] must be implemented"];
	return 0;
}

-(ATSide)side {
	return ATRightSide;
}

@end

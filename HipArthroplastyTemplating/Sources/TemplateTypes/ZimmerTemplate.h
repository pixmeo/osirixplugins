//
//  ZimmerTemplate.h
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 19/03/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplate.h"

@interface ZimmerTemplate : ArthroplastyTemplate {
	NSMutableDictionary* _properties;
}

+(NSArray*)templatesAtPath:(NSString*)path usingClass:(Class)classs;
-(id)initFromFileAtPath:(NSString*)path;

@end

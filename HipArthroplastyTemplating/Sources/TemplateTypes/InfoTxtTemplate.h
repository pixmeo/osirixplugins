//
//  ZimmerTemplate.h
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 19/03/07.
//  Modified by Alessandro Volz since 07/2009
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ArthroplastyTemplate.h"

@interface InfoTxtTemplate : ArthroplastyTemplate {
	NSDictionary* _properties;
}

+(NSArray*)templatesAtPath:(NSString*)path;
+(NSArray*)templatesAtPath:(NSString*)path usingClass:(Class)classs;
-(id)initFromFileAtPath:(NSString*)path;

@end

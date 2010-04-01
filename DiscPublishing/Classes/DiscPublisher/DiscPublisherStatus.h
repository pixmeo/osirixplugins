//
//  DiscPublisherStatus.h
//  Primiera
//
//  Created by Alessandro Volz on 2/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscPublisherStatus : NSObject {
	NSString* _path;
	NSXMLDocument* _doc;
}

@property(readonly) NSString* path;
@property(retain) NSXMLDocument* doc;

@property(readonly) NSArray* robotIds;

-(id)initWithFileAtPath:(NSString*)path;
-(void)refresh;

-(BOOL)allRobotsAreIdle;

@end

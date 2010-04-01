//
//  NSXMLNode+DiscPublisher.h
//  Primiera
//
//  Created by Alessandro Volz on 2/23/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLNode (DiscPublisher)

+(id)elementWithName:(NSString*)name text:(NSString*)text;
+(id)elementWithName:(NSString*)name unsignedInt:(NSUInteger)value;
+(id)elementWithName:(NSString*)name bool:(BOOL)value;
-(NSXMLNode*)childNamed:(NSString*)childName;

@end

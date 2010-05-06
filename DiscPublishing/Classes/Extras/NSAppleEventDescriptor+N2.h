//
//  NSObject+Scripting.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/5/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (Scripting)

-(NSAppleEventDescriptor*)appleEventDescriptor;

@end


@interface NSAppleEventDescriptor (Scripting)

-(id)object;
+(NSDictionary*)dictionaryWithArray:(NSArray*)array;

@end
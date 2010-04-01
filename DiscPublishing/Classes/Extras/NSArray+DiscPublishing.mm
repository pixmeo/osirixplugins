//
//  NSArray.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/1/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSArray+DiscPublishing.h"


@implementation NSArray (DiscPublishing)

-(NSString*)componentsJoinedByCommasAndAnd {
	NSMutableString* string = [[NSMutableString alloc] init];
	
	for (NSString* str in self)
		if (str == [self objectAtIndex:0])
			[string appendString:str];
		else if (str == [self lastObject])
			[string appendFormat:@" and %@", str];
		else [string appendFormat:@", %@", str];
	
	return [string autorelease];
}

@end

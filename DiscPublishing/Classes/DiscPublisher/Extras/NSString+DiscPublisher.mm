//
//  NSString+DiscPublisher.mm
//  Primiera
//
//  Created by Alessandro Volz on 2/22/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSString+DiscPublisher.h"


@implementation NSString (DiscPublisher)

-(NSString*)stringByPrefixingLinesWithString:(NSString*)prefix {
	NSMutableArray* lines = [[[self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy] autorelease];
	if ([[lines lastObject] isEqual:@""]) [lines removeLastObject];	
	return [NSString stringWithFormat:@"%@%@\n", prefix, [lines componentsJoinedByString:[NSString stringWithFormat:@"\n%@", prefix]]];
}

+(NSString*)stringByRepeatingString:(NSString*)string times:(NSUInteger)times {
	NSMutableString* ret = [[NSMutableString alloc] initWithCapacity:[string length]*times];
	for (NSUInteger i = 0; i < times; ++i)
		[ret appendString:string];
	return [ret autorelease];
}

-(NSString*)suspendedString {
	NSUInteger dotsCount = 0;
	for (NSInteger i = [self length]-1; i >= 0; --i)
		if ([self characterAtIndex:i] == '.')
			++dotsCount;
		else break;
	if (dotsCount >= 3) return self;
	return [self stringByAppendingString:[NSString stringByRepeatingString:@"." times:3-dotsCount]];
}

@end

//
//  CSV.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "CSV.h"
#import <OsiriX Headers/NSString+N2.h>


@implementation CSV

+(NSString*)quote:(NSString*)str {
	BOOL doubleQuote = [str contains:@","] || [str contains:@"\n"] || [str contains:@"\""] || [str hasPrefix:@" "] || [str hasSuffix:@" "];
	if (!doubleQuote)
		return str;
	return [NSString stringWithFormat:@"\"%@\"", [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
}

+(NSString*)stringFromArray:(NSArray*)array {
	NSMutableString* str = [NSMutableString string];
	
	for (NSString* istr in array) {
		if (str.length)
			[str appendString:@","];
		[str appendString:[self quote:istr]];
	}
	
	return [[str copy] autorelease];
}

@end

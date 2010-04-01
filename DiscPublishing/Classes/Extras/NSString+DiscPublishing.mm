//
//  NSString+DiscPublishing.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSString+DiscPublishing.h"
#include <cmath>

@implementation NSString (DiscPublishing)

+(NSString*)stringForTimeInterval:(NSTimeInterval)timeInterval {
	NSMutableString* str = [[NSMutableString alloc] init];
	
	if (timeInterval > 3600) {
		[str appendFormat:@"%d %@ and ", int(timeInterval/3600), int(timeInterval/3600) != 1 ? @"hours" : @"hour"];
		timeInterval = fmod(timeInterval, 3600.0);
	}
	
	if (timeInterval > 60) {
		[str appendFormat:@"%d %@ and ", int(timeInterval/60), int(timeInterval/60) != 1 ? @"minutes" : @"minute"];
		timeInterval = fmod(timeInterval, 60.0);
	}
	
	[str appendFormat:@"%d %@", int(timeInterval), int(timeInterval) != 1 ? @"seconds" : @"second"];
	
	return [str autorelease];
}

@end

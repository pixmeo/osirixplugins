//
//  NSThread+DiscPublishingTool.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSThread+DiscPublishingTool.h"


@implementation NSThread (DiscPublishingTool)

NSString* const NSThreadStatusKey = @"NSThreadStatus";
NSString* const NSThreadAdvancementKey = @"NSThreadAdvancement";

-(void)setStatus:(NSString*)status {
	[self.threadDictionary setObject:status forKey:NSThreadStatusKey];
}

-(NSString*)status {
	return [self.threadDictionary objectForKey:NSThreadStatusKey];
}

-(void)setAdvancement:(CGFloat)advancement {
	[self.threadDictionary setObject:[NSNumber numberWithFloat:advancement] forKey:NSThreadAdvancementKey];
}

-(CGFloat)advancement {
	NSNumber* advancement = [self.threadDictionary objectForKey:NSThreadAdvancementKey];
	return advancement? [advancement floatValue] : -1;
}

@end

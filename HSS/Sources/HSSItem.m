//
//  HSSItem.h
//  HSS
//
//  Created by Alessandro Volz on 11.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSItem.h"

@implementation HSSItem

@synthesize oid = _oid;
@synthesize name = _name;
@synthesize assignable = _assignable;

NSString* const HSSTab = @"    ";

-( NSMutableString*)descriptionWithTab:(NSInteger)t {
    NSMutableString* desc = [NSMutableString string];
    for (int i = 0; i < t; ++i) [desc appendString:HSSTab];
    [desc appendFormat:@"[%@ %@: %@]", self.className, self.oid, self.name];
    return desc;
}

- (NSString*)description {
    return [self descriptionWithTab:0];
}

@end

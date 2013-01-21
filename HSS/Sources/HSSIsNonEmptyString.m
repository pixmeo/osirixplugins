//
//  HSSIsNonEmptyString.m
//  HSS
//
//  Created by Alessandro Volz on 10.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSIsNonEmptyString.h"

@implementation HSSIsNonEmptyString

+ (void)load {
    [NSValueTransformer setValueTransformer:[[[self class] alloc] init] forName:@"HSSIsNonEmptyString"];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

- (NSNumber*)transformedValue:(NSString*)value {
    return [NSNumber numberWithBool:(value.length > 0)];
}

@end

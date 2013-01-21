//
//  HSSMedcase.m
//  HSS
//
//  Created by Alessandro Volz on 11.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSMedcase.h"

@implementation HSSMedcase

- (BOOL)isLeaf {
    return YES;
}

- (BOOL)assignable {
    return YES;
    // McKesson said "adding images to an existing case is outside the scope of this project" (Rex Jakobovits, 2012/1/27 00:47:26 HNEC)
    // then Christian insisted...
}

- (NSString*)desc {
    return @""; // zero-length description -> medcase name spans over the description cell
}

@end

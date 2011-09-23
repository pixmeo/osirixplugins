//
//  DiscPublishingUtils.m
//  DiscPublishing
//
//  Created by Alessandro Volz on 23.09.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import "DiscPublishingUtils.h"


CF_EXTERN_C_BEGIN

// we redeclare this here because OsiriX's valuesKeyPath in NSUserDefaultsController+N2 changes between C and C++ depending on the version of OsiriX, leading to dynamic link errors
NSString* DP_valuesKeyPath(NSString* key) {
	return [@"values." stringByAppendingString:key];
}

CF_EXTERN_C_END
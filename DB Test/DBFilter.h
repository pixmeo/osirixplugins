//
//  DuplicateFilter.h
//  Duplicate
//
//  Created by Lance Pysher on Monday August 1, 2005.
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.


#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface DBFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

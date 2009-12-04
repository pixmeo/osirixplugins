//
//  DuplicateFilter.h
//  Duplicate
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface DuplicateFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

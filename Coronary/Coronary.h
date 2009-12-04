//
//  Coronary.h
//  Coronary
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsiriX Headers/PluginFilter.h"

@interface Coronary : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

//
//  JPEG.h
//  JPEG
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface JPEG : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

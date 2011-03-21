//
//  BullsEye.h
//  BullsEye
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@interface BullsEye : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

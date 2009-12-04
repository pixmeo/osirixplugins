//
//  FloatDICOMExport.h
//  FloatDICOMExport
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface FloatDICOMExport : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

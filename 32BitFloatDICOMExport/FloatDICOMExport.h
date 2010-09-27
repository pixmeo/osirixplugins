//
//  FloatDICOMExport.h
//  FloatDICOMExport
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX Headers/PluginFilter.h>

@interface FloatDICOMExport : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

//
//  ITKPluginFilter.h
//  ITKPlugin
//
//  Copyright (c) 2012 SNI. All rights reserved.
//


#import <Foundation/Foundation.h>

#import <OsiriXAPI/PluginFilter.h>


@interface ITKPluginFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

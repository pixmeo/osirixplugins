//
//  MonitorsAutoConfigureFilter.h
//  MonitorsAutoConfigure
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface DisplaysAutoConfigurationFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

@end

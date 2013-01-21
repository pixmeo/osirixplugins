//
//  HSS.h
//  HSS
//
//  Created by Alessandro Volz on 29.11.11.
//  Copyright 2011 HUG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface HSS : PluginFilter {
}

extern NSString* const HSSErrorDomain;

- (long)filterImage:(NSString*)menuName;

+ (NSURL*)baseURL;

+ (Class)enterpriseClass;

@end

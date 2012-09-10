//
//  KiOPFilter.h
//  KiOP
//
//  Copyright (c) 2012 KiOP. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface KiOPFilter : PluginFilter {
    NSPoint origin;
}

- (long) filterImage:(NSString*) menuName;

@end

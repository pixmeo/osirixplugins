//
//  PrintingLayoutFilter.h
//  PrintingLayout
//
//  Copyright (c) 2012 HUG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>
#import "PLWindowController.h"

@interface PLFilter : PluginFilter
{
}

- (long)filterImage:(NSString*) menuName;

@end

//
//  DMGSFilter.h
//  DMGS
//
//  Copyright (c) 2009 jacques.fauquex@opendicom.com. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <Foundation/Foundation.h>
#import "PluginFilter.h"


@interface DMGSFilter : PluginFilter
{
}

- (long) filterImage:(NSString*) menuName;
@end

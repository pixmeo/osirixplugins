//
//  VolumeGeneratorFilter.m
//  VolumeGenerator
//
//  Created by Philippe Thevenaz on Tue May 6 2008.
//  Copyright (c) 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface VolumeGeneratorFilter
	: PluginFilter
{
}

- (long int)filterImage
	: (NSString*)menuName;

@end

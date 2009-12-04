//
//  90degFilter.h
//  90deg
//
//  Copyright (c) 2009 OsiriX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriX Headers/PluginFilter.h>

@interface NinetyDegreesFilter : PluginFilter {
	NSMutableArray* _ndrois;
	NSMutableArray* _distrois;
}

-(long)filterImage:(NSString*)menuName;

@end

//
//   SSHFilter
//  
//

//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@class SSHWindowController;

@interface SSHFilter : PluginFilter {
	SSHWindowController *_windowController;
}

- (long) filterImage:(NSString*) menuName;


@end

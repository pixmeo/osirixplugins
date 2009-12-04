//
//  WindowAnchoredAnnotationsFilter.h
//  WindowAnchoredAnnotations
//
//  Copyright (c) 2007 jacques.fauquex@opendicom.com. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface WindowAnchoredAnnotationsFilter : PluginFilter {}

- (void) initPlugin;

- (long) filterImage:(NSString*) menuName;

- (void) PLUGINdrawTextInfoFilter:(NSNotification*)note;

@end

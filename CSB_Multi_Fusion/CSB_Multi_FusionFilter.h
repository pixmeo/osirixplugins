//
//  CSB_Multi_FusionFilter.h
//  CSB_Multi_Fusion
//
//  Copyright (c) 2009 CSB_MGH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface CSB_Multi_FusionFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;
- (ViewerController*)   viewerController;

@end

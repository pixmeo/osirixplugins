//
//  CMIR_T2_Fit_MapFilter.h
//  CMIR_T2_Fit_Map
//
//  Copyright (c) 2009 CMIR. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PluginFilter.h"

//#import "CMIRViewerController.h"

@interface CMIR_T2_Fit_MapFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;
- (ViewerController*)   viewerController;

@end

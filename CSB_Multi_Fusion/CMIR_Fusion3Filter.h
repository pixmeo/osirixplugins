//
//  CMIR_Fusion3Filter.h
//  CMIR_Fusion3
//
//  Copyright (c) 2009 CMIR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
//#import "CMIRViewerController.h"
//#import "dicomFile.h"


@interface CMIR_Fusion3Filter : PluginFilter {
	
}

- (long) filterImage:(NSString*) menuName;
//- (CMIR_ViewerController*)   viewerController;
- (ViewerController*)   viewerController;
@end

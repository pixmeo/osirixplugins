//
//  MIRCFilter.h
//  Invert
//
//  Created by Lance Pysher July 22, 2005
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@class MIRCController;

@interface MIRCFilter : PluginFilter {
	MIRCController* controller;

}

- (long) filterImage:(NSString*) menuName;
- (ViewerController *)   viewerController; 
- (NSString *)teachingFileFolder;

@end

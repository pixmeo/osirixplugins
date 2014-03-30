//
//  Mapping.h
//  Mapping
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface MappingT2FitFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;
- (ViewerController*)   viewerController;

@end

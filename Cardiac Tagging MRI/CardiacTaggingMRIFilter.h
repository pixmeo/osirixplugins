//
//  CardiacTaggingMRIFilter.h
//  CardiacTaggingMRI
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2005 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@interface CardiacTaggingMRIFilter : PluginFilter
{

}

- (long) filterImage:(NSString*) menuName;
@end


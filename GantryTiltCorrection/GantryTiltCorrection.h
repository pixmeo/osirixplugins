//
//  GantryTiltCorrection.h
//  GantryTiltCorrection
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2005 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface GantryTiltCorrection : PluginFilter
{

}

- (long) filterImage:(NSString*) menuName;
@end


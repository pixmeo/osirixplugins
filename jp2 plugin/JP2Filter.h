//
//  JP2Filter.h

//
//  Created by Lance Pysher on Monday August 1, 2005.
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.


#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFileFormatDecoder.h"


@interface JP2Filter : PluginFileFormatDecoder {

}


- (float *)checkLoadAtPath:(NSString *)path;





@end

//
//  MATLABPlugin.mm
//  MATLAB Plugin
//
//  Created by Alessandro Volz on 12/21/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "MATLABPlugin.h"

@implementation MATLABPlugin

-(void)initPlugin {
	[NSException raise:NSGenericException format:@"The MATLAB plugin can only function with the 32 bits i386 (intel) version of OsiriX."];
}

@end

//
//   SSHFilter
//  
//

//  Copyright (c) 2005 Macrad, LL. All rights reserved.
//

#import "SSHFilter.h"
#import <OsiriX/DCM.h>

#import "SSHWindowController.h"



@implementation SSHFilter

+ (PluginFilter *)filter{
	return [[[SSHFilter alloc] init] autorelease]; 
}


- (long) filterImage:(NSString*) menuName
{
	if (!_windowController)
		_windowController = [[SSHWindowController alloc] init];
	[_windowController showWindow:self];	
		return -1;
}


- (void)dealloc{
	[_windowController release];
	[super dealloc];
}

@end

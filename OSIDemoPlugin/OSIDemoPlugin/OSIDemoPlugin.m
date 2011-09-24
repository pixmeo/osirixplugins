//
//  OSIDemoPlugin.m
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSIDemoPlugin.h"
#import "OSIDemoWindowController.h"

@implementation OSIDemoPlugin

- (void)initPlugin
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OSIEnvironmentActivated"];
}

- (long)filterImage:(NSString*)menuName
{
	OSIDemoWindowController *windowController;
	
	windowController = [[OSIDemoWindowController alloc] init];
	[windowController showWindow:self];
	[windowController release];
	
	return 0;
}

@end

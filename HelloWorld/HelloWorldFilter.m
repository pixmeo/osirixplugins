//
//  HelloWorldFilter.m
//  HelloWorld
//
//  Copyright (c) 2008 Joris. All rights reserved.
//

#import "HelloWorldFilter.h"

@implementation HelloWorldFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	NSAlert *myAlert = [NSAlert alertWithMessageText:@"Hello World!"
									   defaultButton:@"Hello"
									 alternateButton:nil
										 otherButton:nil
						   informativeTextWithFormat:@":-)"];
	
	[myAlert runModal];
	
	return 0; // No Errors
}

@end

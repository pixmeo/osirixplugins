//
//  OpenGLFilter.m
//  OpenGLFilter
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "OpenGLFilter.h"

@implementation OpenGLFilter

- (long) filterImage:(NSString*) menuName
{
	//Now create a window with an opengl view
	OpenGLController* openglWin = [[OpenGLController alloc] init];
	[openglWin showWindow:self];
	return 0;
}

@end

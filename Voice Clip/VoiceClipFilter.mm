/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "VoiceClipFilter.h"
#import "browserController.h"
#import "VoiceClipController.h"
#include "DCAudioFileRecorder.h"
#include <sys/param.h>



@implementation VoiceClipFilter

- (void) initPlugin
{
	
}

- (long) filterImage:(NSString*) menuName
{
	NSLog(@"Voice Clip filter");
	if (!voiceClipController)
		voiceClipController = [[VoiceClipController alloc] init];
		
	[voiceClipController reset];
	[voiceClipController showWindow:nil];
	return -1;
}

- (void)dealloc{
	NSLog(@"VoiceClipController dealloc");
	[super dealloc];
}



@end

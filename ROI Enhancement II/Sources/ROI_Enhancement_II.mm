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

#import "ROI_Enhancement_II.h"
#import "Interface.h"

@implementation ROI_Enhancement_II

+(void)initialize {
	//	static BOOL initialized = NO;
	//	if (initialized) return;
	//	initialized = YES;
	
	//	NSString* frameworkPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Frameworks/GraphX.framework"];
	//	NSBundle* framework = [NSBundle bundleWithPath:frameworkPath];
	//	NSLog(@"Loading framework: %@", framework);
	//	
	//	NSError* error = NULL;
	//	if(![framework loadAndReturnError:&error]) {
	//		NSLog(@"GraphX load error: %@", error);
	//		NSLog(@"\tExecutable: %@", [framework executablePath]);
	//		NSLog(@"\tInfo: %@", [framework infoDictionary]);
	//		NSLog(@"\tArchitectures: %@", [framework executableArchitectures]);
	//	} else
	//		NSLog(@"GraphX successfully loaded for ROI Enhancement II");
}

-(long)filterImage:(NSString*)menuName {
	[[[[Interface alloc] initForViewer:viewerController] window] makeKeyAndOrderFront:NULL];
	return 0;
}

@end

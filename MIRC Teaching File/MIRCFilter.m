//
//  MIRCFilter.m
//  Invert
//
//  Created by Lance Pysher July 22, 2005
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCFilter.h"
#import "DCMPix.h"
#import "MIRCController.h"
#import "browserController.h"



@implementation MIRCFilter

- (void) initPlugin{
	//create main teaching file folder in OsiriX Data
	controller = nil;
	[self teachingFileFolder];
}

- (void)dealloc{
	[controller release];
	[super dealloc];
}

- (long) filterImage:(NSString*) menuName
{
	if (!controller)
		controller = [[MIRCController alloc] initWithFilter:self];
	[controller showWindow:self];
	return 0;   // No Errors
}

- (NSString *)teachingFileFolder{
	BOOL isDir;
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSString *directory = [NSString stringWithFormat:@"%@/TeachingFile", [[BrowserController currentBrowser] documentsDirectory]];
	if (!([defaultManager fileExistsAtPath:directory isDirectory:&isDir] && isDir)){
		[defaultManager createDirectoryAtPath:directory attributes:nil];
	}

	return directory;
}
	

- (ViewerController *)   viewerController{
	return viewerController;
}



@end

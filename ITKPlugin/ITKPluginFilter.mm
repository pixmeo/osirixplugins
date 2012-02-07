//
//  ITKPluginFilter.m
//  ITKPlugin
//
//  Copyright (c) 2012 SNI. All rights reserved.
//

#import "ITKPluginFilter.h"

#import "ITKCode.h"

// Make sure to unzip ITK40 and ITK40Headers!

@implementation ITKPluginFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
    itk_code([[[NSBundle bundleForClass:[self class]] pathForResource:@"inputFile" ofType:@"txt"] fileSystemRepresentation]);
	
	return 0;
}

@end

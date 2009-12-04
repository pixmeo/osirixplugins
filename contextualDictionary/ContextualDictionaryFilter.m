//
//  ContextualDictionaryFilter.m
//  ContextualDictionary
//
//  Copyright (c) 2007 jacques.fauquex@opendicom.com. All rights reserved.
//

#import "ContextualDictionaryFilter.h"

@implementation ContextualDictionaryFilter

- (void) initPlugin{}

- (long) filterImage:(NSString*) menuName
{
	if( [menuName isEqualToString: @"default"]) [viewerController contextualDictionaryPath:menuName];
	else {[viewerController contextualDictionaryPath:[[NSBundle bundleForClass:[self class]] pathForResource:menuName ofType:@"plist"]];}

	[viewerController createDCMViewMenu];
	return 0;
}

@end

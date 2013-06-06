//
//  SandBoxTestFilter.m
//  SandBoxTest
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import "SandBoxFilter.h"


@implementation SandBoxFilter

- (void) initPlugin
{
	

	
}

- (long) filterImage:(NSString*) menuName
{	
	BrowserController *currentBrowser = [BrowserController currentBrowser];
	
	NSMutableArray *managedObjects = [NSMutableArray array];
	NSMutableArray *filesToBurn;
	
	if (1)
		filesToBurn = [currentBrowser filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];
	else
		filesToBurn = [currentBrowser filesForDatabaseOutlineSelection:managedObjects onlyImages:NO];
	
	m_window = [[S_BurnerWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects];
	[m_window showWindow:self];
	
	return 0;
}

@end






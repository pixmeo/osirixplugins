//
//  SandBoxFilter.m
//  SandBox
//
//  Copyright (c) 2013 Thomas. All rights reserved.
//

#import <SandBoxFilter.h>
#import <SandboxWindowController.h>

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomImage.h>



@implementation SandBoxFilter

- (void) initPlugin
{
	
}

- (long) filterImage:(NSString*) menuName
{	
	BrowserController *currentBrowser = [BrowserController currentBrowser];

	NSMutableArray *managedObjects = [NSMutableArray array];
	NSMutableArray *filesToBurn;
	
	if( ([[[currentBrowser oMatrix] menu] isKindOfClass:[NSMenuItem class]] && [[currentBrowser oMatrix] menu] == [[currentBrowser oMatrix] menu]) || [[currentBrowser window] firstResponder] == [currentBrowser oMatrix])
		filesToBurn = [currentBrowser filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];
	else
		filesToBurn = [currentBrowser filesForDatabaseOutlineSelection:managedObjects onlyImages:NO];
	
	m_window = [[SandboxWindowController alloc] initWithFiles:filesToBurn managedObjects:managedObjects];
	
	[m_window showWindow:self];
	
	return 0;
}

@end






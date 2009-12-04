//
//  ArthroplastyTemplatingPlugin.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingPlugin.h"
#import "ArthroplastyTemplatingStepsController.h"
#import "ArthroplastyTemplatingWindowController.h"
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/Notifications.h>


@implementation ArthroplastyTemplatingPlugin
@synthesize templatesWindowController = _templatesWindowController;

-(void)initialize {
	if (_initialized) return;
	_initialized = YES;
	
	_templatesWindowController = [[ArthroplastyTemplatingWindowController alloc] initWithPlugin:self];
	[_templatesWindowController window]; // force nib loading
}

- (void)initPlugin {
	_windows = [[NSMutableArray alloc] initWithCapacity:4];
	
	//[self initialize];
	//[[_templatesWindowController window] makeKeyAndOrderFront:self];
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:@"CloseViewerNotification" object:viewerController];
}

- (long)filterImage:(NSString*)menuName {
	if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] intValue] < 5939) {
		NSAlert* alert = [NSAlert alertWithMessageText:@"The OsiriX application you are running is out of date." defaultButton:@"Close" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"OsiriX 3.6 is necessary for this plugin to execute."];
		[alert beginSheetModalForWindow:[viewerController window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
		return 0;
	}
	
	[self initialize];
	ArthroplastyTemplatingStepsController* window = [self windowControllerForViewer:viewerController];
	if (window) {
		[window showWindow:self];
		return 0;
	}
	
	if ([[[viewerController roiList:0] objectAtIndex:0] count])
		if (!NSRunAlertPanel(@"Arthroplasty Templating II", @"All the ROIs on this image will be removed.", @"OK", @"Cancel", NULL))
			return 0;
	
	window = [[ArthroplastyTemplatingStepsController alloc] initWithPlugin:self viewerController:viewerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:OsirixCloseViewerNotification object:viewerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[window window]];
	[_windows addObject:[window window]];
	[window showWindow:self];
	
	return 0;
}

-(void)windowWillClose:(NSNotification*)notification {
	[_windows removeObject:[notification object]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[notification object]];
}

-(ArthroplastyTemplatingStepsController*)windowControllerForViewer:(ViewerController*)viewer {
	for (NSWindow* window in _windows)
		if ([[window delegate] viewerController] == viewer)
			return [window delegate];
	return NULL;
}

-(void)viewerWillClose:(NSNotification*)notification {
	[[[self windowControllerForViewer:[notification object]] window] close];
}

-(BOOL)handleEvent:(NSEvent*)event forViewer:(ViewerController*)controller {
	ArthroplastyTemplatingStepsController* window = [self windowControllerForViewer:controller];
	if (window)
		return [window handleViewerEvent:event];
	return NO;
}

//- (void)viewerWillClose:(NSNotification*)notification;
//{
//	if(stepByStepController) [stepByStepController close];
//}

//- (void)windowWillClose:(NSNotification *)aNotification
//{
//	NSLog(@"windowWillClose ArthroplastyTemplatingsPluginFilter");
//	if(stepByStepController)
//	{
//		if([[aNotification object] isEqualTo:[stepByStepController window]])
//		{
//			[stepByStepController release];
//			stepByStepController = nil;
//		}
//	}
//}

@end

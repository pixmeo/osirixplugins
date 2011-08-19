//
//  ArthroplastyTemplatingPlugin.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Modified by Alessandro Volz since 07/2009
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingPlugin.h"
#import "ArthroplastyTemplatingStepsController.h"
#import "ArthroplastyTemplatingWindowController.h"
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/NSPanel+N2.h>


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
	if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] intValue] < 6894) {
		NSAlert* alert = [NSAlert alertWithMessageText:@"The OsiriX application you are running is out of date." defaultButton:@"Close" alternateButton:NULL otherButton:NULL informativeTextWithFormat:@"OsiriX 3.7.1 is necessary for this plugin to execute."];
		[alert beginSheetModalForWindow:[viewerController window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
		return 0;
	}
	
	[self initialize];
	ArthroplastyTemplatingStepsController* window = [self windowControllerForViewer:viewerController];
	if (window) {
		[window showWindow:self];
		return 0;
	}
	
	NSString* disclaimer = [NSString stringWithFormat:@"Hip Arthroplasty Templating %@\n\nTHE SOFTWARE IS PROVIDED AS IS. USE THE SOFTWARE AT YOUR OWN RISK. THE AUTHORS MAKE NO WARRANTIES AS TO PERFORMANCE OR FITNESS FOR A PARTICULAR PURPOSE, OR ANY OTHER WARRANTIES WHETHER EXPRESSED OR IMPLIED. NO ORAL OR WRITTEN COMMUNICATION FROM OR INFORMATION PROVIDED BY THE AUTHORS SHALL CREATE A WARRANTY. UNDER NO CIRCUMSTANCES SHALL THE AUTHORS BE LIABLE FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES RESULTING FROM THE USE, MISUSE, OR INABILITY TO USE THE SOFTWARE, EVEN IF THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. THESE EXCLUSIONS AND LIMITATIONS MAY NOT APPLY IN ALL JURISDICTIONS. YOU MAY HAVE ADDITIONAL RIGHTS AND SOME OF THESE LIMITATIONS MAY NOT APPLY TO YOU.\n\nTHIS SOFTWARE IS NOT INTENDED FOR PRIMARY DIAGNOSTIC, ONLY FOR SCIENTIFIC USAGE.\n\nTHE VERSION OF OSIRIX USED MAY NOT BE CERTIFIED AS A MEDICAL DEVICE FOR PRIMARY DIAGNOSIS. IF YOUR VERSION IS NOT CERTIFIED, YOU CAN ONLY USE OSIRIX AS A REVIEWING AND SCIENTIFIC SOFTWARE, NOT FOR PRIMARY DIAGNOSTIC.\n\nAll calculations, measurements and images provided by this software are intended only for scientific research. Any other use is entirely at the discretion and risk of the user. If you do use this software for scientific research please give appropriate credit in publications. This software may not be redistributed, sold or commercially used in any other way without prior approval of the author.", [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
	NSPanel* alert = [NSPanel alertWithTitle:@"Disclaimer" message:disclaimer defaultButton:@"Stop" alternateButton:@"Continue" icon:[NSImage imageNamed:@"ArthroplastyTemplating"]];
	[NSApp beginSheet:alert modalForWindow:[viewerController window] modalDelegate:self didEndSelector:@selector(disclaimerDidEnd:returnCode:contextInfo:) contextInfo:NULL];
	
	return 0;
}

-(void)disclaimerDidEnd:(NSPanel*)panel returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[panel orderOut:self];
	
	if (returnCode == NSAlertDefaultReturn) // Stop
		return;
	
	if ([[[viewerController roiList:0] objectAtIndex:0] count])
		if (!NSRunAlertPanel(@"Arthroplasty Templating II", @"All the ROIs on this image will be removed.", @"OK", @"Cancel", NULL))
			return;
	
	ArthroplastyTemplatingStepsController* controller = [[ArthroplastyTemplatingStepsController alloc] initWithPlugin:self viewerController:viewerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:OsirixCloseViewerNotification object:viewerController];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[controller window]];
	[_windows addObject:[controller window]];
	[controller showWindow:self];
}


-(void)windowWillClose:(NSNotification*)notification {
	[_windows removeObject:[notification object]];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[notification object]];
}

-(ArthroplastyTemplatingStepsController*)windowControllerForViewer:(ViewerController*)viewer {
	for (NSWindow* window in _windows)
		if ([(ArthroplastyTemplatingStepsController*)[window delegate] viewerController] == viewer)
			return (ArthroplastyTemplatingStepsController*)[window delegate];
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

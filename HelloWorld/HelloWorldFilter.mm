//
//  HelloWorldFilter.m
//  HelloWorld
//
//  Copyright (c) 2008 Joris Heuberger. All rights reserved.
//

#import "HelloWorldFilter.h"
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/N2Operators.h>
#import <OsiriXAPI/SRController.h>

@implementation HelloWorldFilter

- (void) initPlugin
{
	// The following line creates a preference pane for the plugin in the preferences of OsiriX
	// it adds the HelloWorldPreferences.prefPane as the pref pane. This bundle is created by a dedicated
	// target in this project, named HelloWorldPreferences: as its info.plist file describes, the main
	// class of the prefPane bunndle is HelloWorldPreferencesController, while the main nib is HelloWorldPreferences.xib
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"HelloWorldPreferences" inBundle:[NSBundle bundleForClass:[self class]] withTitle:@"Hello World" image:[NSImage imageNamed:@"NSUser"]];
    
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector( windowDidBecomeMain:) name: NSWindowDidBecomeMainNotification object: nil];
}

- (long) filterImage:(NSString*) menuName
{
	NSString* message = [[NSUserDefaults standardUserDefaults] stringForKey:@"HelloWorld_Message"];
	if (!message) message = @"Define this message in the Hello World plugin's preferences";
	
	NSAlert *myAlert = [NSAlert alertWithMessageText:@"Hello World!"
									   defaultButton:@"Hello"
									 alternateButton:nil
										 otherButton:nil
						   informativeTextWithFormat:@"%@", message];
	
	[myAlert runModal];

	[self loopTroughImages];
	
	return 0; // No Errors
}

// Add a custom icon
- (NSArray*) toolbarAllowedIdentifiersForViewer: (id) v
{
    if( [v isKindOfClass: [ViewerController class]])
    {
        return [NSArray arrayWithObject: @"MyImageIdentifier"];
    }
    
    if( [v isKindOfClass: [SRController class]])
    {
        return [NSArray arrayWithObject: @"MyImageIdentifier2"];
    }
    
    return [NSArray array];
}

//
- (NSToolbarItem *) toolbarItemForItemIdentifier: (NSString *) itemIdent forViewer: (id) v
{
	if([itemIdent isEqualToString: @"MyImageIdentifier"] && [v isKindOfClass: [ViewerController class]])
	{
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
		[toolbarItem setLabel: NSLocalizedString( @"Plugin",nil)];
		[toolbarItem setImage: [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:HelloWorldFilter.class] pathForResource:@"fatigue" ofType:@"png"]] autorelease]];
        
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(filterImage:)];
        
        return toolbarItem;
    }
    
    if([itemIdent isEqualToString: @"MyImageIdentifier2"] && [v isKindOfClass: [SRController class]])
	{
        NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
        
		[toolbarItem setLabel: NSLocalizedString( @"Plugin 2",nil)];
		[toolbarItem setImage: [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:HelloWorldFilter.class] pathForResource:@"fatigue" ofType:@"png"]] autorelease]];
        
        return toolbarItem;
    }
    
    return nil;
}

- (void) windowDidBecomeMain:(NSNotification *)aNotification
{
    NSWindow *w = [aNotification object];
    
    //We will automatically add our toolbar icon, if it's not here
    
    if( [w.windowController isKindOfClass: [ViewerController class]])
    {
        ViewerController *vc = w.windowController;
        
        NSToolbar *t = [vc toolbar]; // ViewerController toolbar is a SPECIAL case : you CANNOT use window.toolbar, but you HAVE TO use [window.windowcontroller toolbar]
        
        for( NSToolbarItem *i in t.items)
        {
            if( [i.itemIdentifier isEqualToString: @"MyImageIdentifier"])
                return;
        }
        
        [t insertItemWithItemIdentifier: @"MyImageIdentifier" atIndex: 0];
    }
    
    if( [w.windowController isKindOfClass: [SRController class]])
    {
        NSToolbar *t = [w toolbar];
        
        for( NSToolbarItem *i in t.items)
        {
            if( [i.itemIdentifier isEqualToString: @"MyImageIdentifier2"])
                return;
        }
        
        [t insertItemWithItemIdentifier: @"MyImageIdentifier2" atIndex: 0];
    }
}

// This method demonstrate how to loop through all the images of the current viewer
- (void) loopTroughImages;
{
	// the 'viewerController' variable is defined in PluginFilter.h
	// it is the selected viewer (if more than one is open)
	ViewerController *currentViewer = viewerController;
	
	// loop through time (for dynamic studies)
	for (long frame=0; frame<[currentViewer maxMovieIndex]; frame++)
	{
		NSLog(@"Frame : %d/%d", frame+1, [currentViewer maxMovieIndex]);

		// the pixList contains all DCMPix for the current frame
		NSArray *pixList = [currentViewer pixList:frame];
		for (NSUInteger i=0; i<[pixList count]; i++)
		{
			DCMPix *pix = [pixList objectAtIndex:i];
			// do something with the DCMPix...
			NSLog(@"Image : %d/%d || Location : %f", i+1, [pixList count], pix.sliceLocation);
		}
	}
}

// this method demonstrates how te catch a viewer's mousedown event
-(BOOL)handleEvent:(NSEvent*)event forViewer:(ViewerController*)c {
	if (![c isKindOfClass:[ViewerController class]])
		return NO;
	
	if ([event type] == NSLeftMouseDown) {
		NSPoint p = [[c imageView] ConvertFromNSView2GL:[[c imageView] convertPoint:[event locationInWindow] fromView:nil]];
		
		NSImage* image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:HelloWorldFilter.class] pathForResource:@"fatigue" ofType:@"png"]] autorelease];
		
		float pixSpacing = (1.0 / 72 * 25.4); // image is in 72 dpi, we work in millimeters
		ROI* newLayer = [c addLayerRoiToCurrentSliceWithImage:image referenceFilePath:nil layerPixelSpacingX:pixSpacing layerPixelSpacingY:pixSpacing];
		
		[c bringToFrontROI:newLayer];
		[newLayer generateEncodedLayerImage];
		
		// find the center of the template
		NSPoint o = NSMakePoint([image size]/2);
		
		NSArray *layerPoints = [newLayer points];
		NSPoint layerSize = [[layerPoints objectAtIndex:2] point] - [[layerPoints objectAtIndex:0] point];
		
		NSPoint layerCenter = layerSize*0.5;
		[[newLayer points] addObject:[MyPoint point:layerCenter]]; // center, index 4
		
		[newLayer setROIMode:ROI_selected]; // in order to make the roiMove method possible
		[newLayer roiMove:p-layerCenter :YES];
		
		return YES;
	}
	
	return NO;
}


@end

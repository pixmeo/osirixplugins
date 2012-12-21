//
//  DCMView+PrintingLayoutOverride.m
//  PrintingLayout
//
//  Created by Benoit Deville on 09.11.12.
//
//

#import "DCMView+PrintingLayoutOverride.h"
#import "PLWindowController.h"

@implementation DCMView (PrintingLayoutOverride)

// Used to change the DCMView timer for drag & drop when the plugin is on without limiting it to the plugin window.
- (NSTimeInterval)printingLayoutTimeIntervalForDrag
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        if ([[[[windowList objectAtIndex:i] windowController] className] isEqualToString:@"PLWindowController"])
        {
            return .15;
        }
    }
    
    return 1.;
}

// Used to let the '<' key send DCMView to the PLDocumentView
- (void)printingLayoutActionForHotKey:(NSEvent*)event
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        if ([[[[windowList objectAtIndex:i] windowController] className] isEqualToString:@"PLWindowController"])
        {
            [[(PLWindowController*)[[windowList objectAtIndex:i] windowController] fullDocumentView] keyDown:event];
        }
    }
}

@end

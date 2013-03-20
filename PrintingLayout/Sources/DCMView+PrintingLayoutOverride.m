//
//  DCMView+PrintingLayoutOverride.m
//  PrintingLayout
//
//  Created by Benoit Deville on 09.11.12.
//
//

#import "DCMView+PrintingLayoutOverride.h"
#import "PLWindowController.h"
#import <OsiriXAPI/ViewerController.h>

@implementation DCMView (PrintingLayoutOverride)

// Used to change the DCMView timer for drag & drop when the plugin is on, without limiting it to the plugin window.
- (NSTimeInterval)printingLayoutTimeIntervalForDrag
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    // If there is at least one PLWindowController in the window list, then the drag & drop timer is changed
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        if ([[[windowList objectAtIndex:i] windowController] class] == [PLWindowController class])
        {
            return .1;
        }
    }
    
    return 1.;
}

- (void)printingLayoutOpenOnPrint:(id)sender
{
    for (NSWindow *window in [NSApp windows])
    {
        if ([window.windowController class] == [ViewerController class])
        {
            [(ViewerController*)window.windowController executeFilterFromString:@"PrintingLayout"];
        }
    }
}

@end

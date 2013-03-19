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

// Used to change the DCMView timer for drag & drop when the plugin is on, without limiting it to the plugin window.
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

@end

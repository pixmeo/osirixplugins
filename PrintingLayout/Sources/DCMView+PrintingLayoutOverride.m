//
//  DCMView+PrintingLayoutOverride.m
//  PrintingLayout
//
//  Created by Benoit Deville on 09.11.12.
//
//

#import "DCMView+PrintingLayoutOverride.h"

@implementation DCMView (PrintingLayoutOverride)

- (NSTimeInterval)printingLayoutTimeIntervalForDrag
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        if ([[[[windowList objectAtIndex:i] windowController] className] isEqualToString:@"PLWindowController"])
        {
            return .2;
        }
    }
    
    return 1.;
}

@end

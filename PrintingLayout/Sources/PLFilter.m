//
//  PrintingLayoutFilter.m
//  PrintingLayout
//
//  Copyright (c) 2012 HUG. All rights reserved.
//

#import "PLFilter.h"

@implementation PLFilter

- (void) initPlugin
{
    [self filterImage:nil];
}

- (long) filterImage:(NSString*) menuName
{
    PLWindowController * layoutController = [[PLWindowController alloc] init];
    [NSTimer scheduledTimerWithTimeInterval:1. target:[layoutController window] selector:@selector(makeKeyAndOrderFront:) userInfo:nil repeats:NO];
//    [[layoutController window] makeKeyAndOrderFront:self];
    
    return 0;
}

@end

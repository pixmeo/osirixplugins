//
//  PrintingLayoutFilter.m
//  PrintingLayout
//
//  Copyright (c) 2012 HUG. All rights reserved.
//

#import "PLFilter.h"
#import "PLWindowController.h"
#import <objc/runtime.h>
#import <OsiriXAPI/DCMView.h>

@interface PLFilter ()

- (void)setupSwizzles;

@end

@implementation PLFilter

- (void) initPlugin
{
    [self filterImage:nil];
    [self setupSwizzles];
}

- (long) filterImage:(NSString*) menuName
{
    PLWindowController *layoutController = [[PLWindowController alloc] init];
// Window opening depends on debug mode
#ifndef NDEBUG
    [NSTimer scheduledTimerWithTimeInterval:1. target:[layoutController window] selector:@selector(makeKeyAndOrderFront:) userInfo:nil repeats:NO];
#else
    [[layoutController window] makeKeyAndOrderFront:self];
#endif
    
    return 0;
}

- (void)setupSwizzles
{
    // Change the value of the DCMView drag & drop timer
    Method newMethod = class_getInstanceMethod([DCMView class], @selector(printingLayoutTimeIntervalForDrag));
    Method replacedMethod = class_getInstanceMethod([DCMView class], @selector(timeIntervalForDrag));
    method_exchangeImplementations(newMethod, replacedMethod);
    
    newMethod = class_getInstanceMethod([DCMView class], @selector(printingLayoutOpenOnPrint:));
    replacedMethod = class_getInstanceMethod([DCMView class], @selector(print:));
    method_exchangeImplementations(newMethod, replacedMethod);
}

- (BOOL) handleEvent:(NSEvent *)event forViewer:(ViewerController*)controller
{
    if (event.type == NSKeyDown)
    {
        unichar key = [event.characters characterAtIndex:0];

        switch (key)
        {
            case NSF1FunctionKey:
            case NSF2FunctionKey:
            case NSF3FunctionKey:
            case NSF5FunctionKey:
                for (NSWindow *window in [NSApp windows])
                {
                    if ([window.windowController class] == [PLWindowController class])
                    {
                        PLWindowController *wc = window.windowController;
                        [wc.fullDocumentView keyDown:event];
                        return YES;
                    }
                }
                break;
                
            default:
                break;
        }
    }
    
    return NO;
}

@end

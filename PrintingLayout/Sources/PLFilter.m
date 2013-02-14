//
//  PrintingLayoutFilter.m
//  PrintingLayout
//
//  Copyright (c) 2012 HUG. All rights reserved.
//

#import "PLFilter.h"
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
    
    newMethod = class_getInstanceMethod([DCMView class], @selector(printingLayoutActionForHotKey:));
    replacedMethod = class_getInstanceMethod([DCMView class], @selector(actionPluginForHotKey:));
    method_exchangeImplementations(newMethod, replacedMethod);
}

@end

//
//  HSS.m
//  HSS
//
//  Created by Alessandro Volz on 29.11.11.
//  Copyright 2011 HUG. All rights reserved.
//

#import "HSS.h"
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/BrowserController.h>
//#import <OsiriXAPI/NSString+N2.h>
//#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/ThreadModalForWindowController.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <objc/runtime.h>
//#include <stdlib.h>
//#import "HSSAuthenticationWindowController.h"
#import "HSSExportWindowController.h"


@interface HSS ()

- (void)_initToolbarItems;
- (void)_processWithWindowController:(NSWindowController*)controller;

@end

@implementation HSS

extern NSString* const HSSErrorDomain = @"HSSErrorDomain";

- (void)initPlugin {
    [self _initToolbarItems];
}

- (long)filterImage:(NSString*)name { // jamais utilisé
    NSWindowController* wc = [[NSApp keyWindow] windowController];
    if ([wc isKindOfClass:[NSWindowController class]])
        [self _processWithWindowController:wc];
    return 0;
}

+ (NSURL*)baseURL {
    NSString* str = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"HSS base URL"];
    if (!str) return nil;
    return [NSURL URLWithString:[str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

+ (Class)enterpriseClass {
    static Class enterprise = nil;
    if (!enterprise) {
        enterprise = NSClassFromString(@"Enterprise");
        if (!enterprise)
            enterprise = [NSNull class];
    }
    
    if (enterprise != [NSNull class])
        return enterprise;
    
    return nil;
}

#pragma mark Toolbars

HSS* HssInstance = nil;

- (void)_initToolbarItems {
    HssInstance = self;
    
    Method method;
    IMP imp;
    
    // BrowserController
    
    Class BrowserControllerClass = NSClassFromString(@"BrowserController");
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_HssBrowserToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_HssBrowserToolbarAllowedItemIdentifiers:)));
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_HssBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_HssBrowserToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
    
    // ViewerController
    
    Class ViewerControllerClass = NSClassFromString(@"ViewerController");
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbarAllowedItemIdentifiers:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_HssViewerToolbarAllowedItemIdentifiers:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_HssViewerToolbarAllowedItemIdentifiers:)));
    
    method = class_getInstanceMethod(ViewerControllerClass, @selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:));
    imp = method_getImplementation(method);
    class_addMethod(ViewerControllerClass, @selector(_HssViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_HssViewerToolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)));
}

NSString* HssToolbarItemIdentifier = @"HssToolbarItem";

- (NSArray*)_HssBrowserToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [[self _HssBrowserToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObject:HssToolbarItemIdentifier];
}

- (NSArray*)_HssViewerToolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [[self _HssViewerToolbarAllowedItemIdentifiers:toolbar] arrayByAddingObject:HssToolbarItemIdentifier];
}

- (NSToolbarItem*)_HssToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    static NSString* HssIconFilePath = [[[NSBundle bundleForClass:[HSS class]] pathForImageResource:@"HSS"] retain];
    
    if ([itemIdentifier isEqualToString:HssToolbarItemIdentifier]) {
        NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:HssToolbarItemIdentifier] autorelease];
        item.image = [[NSImage alloc] initWithContentsOfFile:HssIconFilePath];
        item.minSize = item.image.size;
        item.label = item.paletteLabel = NSLocalizedString(@"HSS", @"Name of toolbar item");
        item.target = HssInstance;
        item.action = @selector(_toolbarItemAction:);
        return item;
    }
    
    return nil;
}

- (NSToolbarItem*)_HssViewerToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [HssInstance _HssToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _HssViewerToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

- (NSToolbarItem*)_HssBrowserToolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem* item = [HssInstance _HssToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
    if (item) return item;
    return [self _HssBrowserToolbar:toolbar itemForItemIdentifier:itemIdentifier willBeInsertedIntoToolbar:flag];
}

- (BOOL)validateToolbarItem:(NSToolbarItem*)item {
    if ([item.toolbar.delegate isKindOfClass:[BrowserController class]])
        return [[(BrowserController*)item.toolbar.delegate databaseOutline] numberOfSelectedRows] >= 1;
    return YES;
}

- (void)_toolbarItemAction:(NSToolbarItem*)sender {
    if ([sender.toolbar.delegate isKindOfClass:[NSWindowController class]])
        [self _processWithWindowController:(NSWindowController*)sender.toolbar.delegate];
    else NSLog(@"Warning: the toolbar delegate is not of type NSWindowController as expected, so the HSS plugin cannot proceed.");
}

#pragma mark Processing

+ (NSArray*)_uniqueObjectsInArray:(NSArray*)objects {
    NSMutableArray* r = [NSMutableArray array];
    
    for (id o in objects)
        if (![r containsObject:o])
            [r addObject:o];
    
    return r;
}

- (void)_seriesIn:(id)obj into:(NSMutableArray*)collection {
    if ([obj isKindOfClass:[DicomSeries class]])
        if (![collection containsObject:obj])
            [collection addObject:obj];

    if ([obj isKindOfClass:[NSArray class]])
        for (id i in obj)
            [self _seriesIn:i into:collection];
    
    if ([obj isKindOfClass:[DicomStudy class]])
        [self _seriesIn:[[(DicomStudy*)obj series] allObjects] into:collection];
    
    if ([obj isKindOfClass:[DicomImage class]])
        [self _seriesIn:[(DicomImage*)obj series] into:collection];
}

- (void)_processWithWindowController:(NSWindowController*)controller {
    if (!controller)
        controller = [BrowserController currentBrowser];
    
    NSMutableArray* images = [NSMutableArray array];
    NSMutableArray* series = [NSMutableArray array];
    
    if ([controller isKindOfClass:[ViewerController class]]) {
        ViewerController* vc = (ViewerController*)controller;
        [images addObject:vc.currentImage];
        [series addObject:vc.currentSeries];
    }
    
    if ([controller isKindOfClass:[BrowserController class]]) {
        BrowserController* bc = (BrowserController*)controller;
        
        NSArray* selection = nil;
        id responder = bc.window.firstResponder;
        if (responder == bc.databaseOutline)
            selection = [(BrowserController*)controller databaseSelection];
        if (responder == bc.oMatrix) {
            NSMutableArray* s = [NSMutableArray array];
            for (NSCell* cell in [responder selectedCells])
                [s addObject:[bc.matrixViewArray objectAtIndex:[cell tag]]];
            selection = s;
        }
        
        for (id obj in selection)
            if ([obj isKindOfClass:[DicomImage class]])
                [images addObject:obj];
            else if ([obj isKindOfClass:[DicomSeries class]])
                [series addObject:obj];
        
        [self _seriesIn:selection into:series];
    }
    
    // remove OsiriX private series
    
    for (NSUInteger i = 0; i < series.count; ++i) {
        DicomSeries* s = [series objectAtIndex:i];
        if (![DicomStudy displaySeriesWithSOPClassUID:s.seriesSOPClassUID andSeriesDescription:s.name])
            [series removeObjectAtIndex:i--];
    }
    
    // is selection valid?
    
    if (series.count < 1 && images.count < 1) {
        NSBeginAlertSheet(nil, nil, nil, nil, controller.window, nil, nil, nil, nil, NSLocalizedString(@"The current selection is invalid.", nil));
        return;
    }
    
    // oook....
    
//    Class enterprise = [HSS enterpriseClass];
//    NSString* enterpriseName = nil;
//    if ([enterprise respondsToSelector:@selector(Name)])
//        enterpriseName = [enterprise performSelector:@selector(Name)];
    
    HSSExportWindowController* hex = [[HSSExportWindowController alloc] initWithSeries:series images:images];
    [hex beginSheetOnWindow:controller.window];
    
//    // TODO: set up window etc etc
//    NSSavePanel* panel = nil;
//    
//    [panel beginSheetModalForWindow:controller.window completionHandler:^(NSInteger result) {
//        [panel orderOut:self];
//        
//        if (!result)
//            return;
//        
//        NSThread* thread = [[[NSThread alloc] initWithTarget:self selector:@selector(_processInBackground:) object:[NSArray arrayWithObjects: nil]] autorelease];
//        thread.name = [NSString stringWithFormat:NSLocalizedString(@"Posting %d %@...", nil), 123, (series.count == 1 ? NSLocalizedString(@"image", @"singular") : NSLocalizedString(@"images", @"plural"))];
//        [thread startModalForWindow:controller.window];
//        [thread start];
//    }];
}

//- (void)_processInBackground:(NSArray*)params {
//    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
//    @try {
//        NSThread* thread = [NSThread currentThread];
//
//        
//
//        thread.status = @"Done.";
//        thread.progress = -1;
//    } @catch (NSException* e) {
//        NSLog(@"HSS exception: %@", e.reason);
//    } @finally {
//        [pool release];
//    }
//}

@end


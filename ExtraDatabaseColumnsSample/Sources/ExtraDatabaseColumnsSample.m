//
//  ExtraDatabaseColumnsSample.m
//  ExtraDatabaseColumnsSample
//
//  Copyright (c) 2013 Alessandro Volz. All rights reserved.
//

#import "ExtraDatabaseColumnsSample.h"
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <objc/runtime.h>

@implementation ExtraDatabaseColumnsSample

@synthesize tc = _tc;

static ExtraDatabaseColumnsSample* ExtraDatabaseColumnsSampleInstance = nil;

- (void)initPlugin {
    ExtraDatabaseColumnsSampleInstance = self;
    
    Method method;
    Class BrowserControllerClass = [BrowserController class];
    
    // we must supply the outline view with the values to display in the added column
    if (!(method = class_getInstanceMethod(BrowserControllerClass, @selector(outlineView:objectValueForTableColumn:byItem:))))
        [NSException raise:NSGenericException format:@"can't find -[BrowserController outlineView:objectValueForTableColumn:byItem:]"];
    class_addMethod(BrowserControllerClass, @selector(_ExtraDatabaseColumnsSample_BrowserController_outlineView:objectValueForTableColumn:byItem:), method_getImplementation(method), method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ExtraDatabaseColumnsSample_BrowserController_outlineView:objectValueForTableColumn:byItem:)));

    // same with tooltips
    if (!(method = class_getInstanceMethod(BrowserControllerClass, @selector(outlineView:toolTipForCell:rect:tableColumn:item:mouseLocation:))))
        [NSException raise:NSGenericException format:@"can't find -[BrowserController outlineView:toolTipForCell:rect:tableColumn:item:mouseLocation:]"];
    class_addMethod(BrowserControllerClass, @selector(_ExtraDatabaseColumnsSample_BrowserController_outlineView:toolTipForCell:rect:tableColumn:item:mouseLocation:), method_getImplementation(method), method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ExtraDatabaseColumnsSample_BrowserController_outlineView:toolTipForCell:rect:tableColumn:item:mouseLocation:)));
    
    // make sure the column is displayed, always (the user can hide it, but it'll show up again...)
    if (!(method = class_getInstanceMethod(BrowserControllerClass, @selector(loadSortDescriptors:))))
        [NSException raise:NSGenericException format:@"can't find -[BrowserController loadSortDescriptors:]"];
    class_addMethod(BrowserControllerClass, @selector(_ExtraDatabaseColumnsSample_BrowserController_loadSortDescriptors:), method_getImplementation(method), method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_ExtraDatabaseColumnsSample_BrowserController_loadSortDescriptors:)));
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(observeApplicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
}

- (void)observeApplicationDidFinishLaunching:(NSNotification*)notification {
    MyOutlineView* dbov = [BrowserController.currentBrowser databaseOutline];
    
    self.tc = [[[NSTableColumn alloc] initWithIdentifier:@"edcs"] autorelease];
    [self.tc.headerCell setStringValue:@"EDCS"];
    
    [dbov addTableColumn:self.tc];
    
    [BrowserController.currentBrowser performSelector:@selector(buildColumnsMenu)];
}

- (void)dealloc {
    self.tc = nil;
    [super dealloc];
}

- (long)filterImage:(NSString*)menuName {
	return 0;
}

- (id)BrowserController:(BrowserController*)bc outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tc byItem:(id)item {
    if (tc == self.tc) {
        return [NSString stringWithFormat:@"EDCS %@ %@", bc.selectedAlbumName, [item className]]; // fill the column text to show we can display contextual data
    }
    
    return nil;
}

- (id)_ExtraDatabaseColumnsSample_BrowserController_outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn*)tc byItem:(id)item {
    id r = [ExtraDatabaseColumnsSampleInstance BrowserController:(id)self outlineView:outlineView objectValueForTableColumn:tc byItem:item];
    if (!r) r = [self _ExtraDatabaseColumnsSample_BrowserController_outlineView:outlineView objectValueForTableColumn:tc byItem:item];
    return r;
}

- (NSString*)BrowserController:(BrowserController*)bc outlineView:(NSOutlineView*)outlineView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if (tc == self.tc) {
        return [NSString stringWithFormat:@"ExtraDatabaseColumnsSample %@ %@", bc.selectedAlbumName, [item className]]; // we can return contextual data
    }
    
    return nil;
}

- (NSString*)_ExtraDatabaseColumnsSample_BrowserController_outlineView:(NSOutlineView*)outlineView toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    id r = [ExtraDatabaseColumnsSampleInstance BrowserController:(id)self outlineView:outlineView toolTipForCell:cell rect:rect tableColumn:tc item:item mouseLocation:mouseLocation];
    if (!r) r = [self _ExtraDatabaseColumnsSample_BrowserController_outlineView:outlineView toolTipForCell:cell rect:rect tableColumn:tc item:item mouseLocation:mouseLocation];
    return r;
}

- (void)BrowserController:(BrowserController*)bc loadSortDescriptors:(DicomAlbum*)album {
    // we should only do this in specific situations (for example, when a specific album is selected, or if this is the first time the column can be shown for this album...)
    [self.tc setHidden:NO];
}

- (void)_ExtraDatabaseColumnsSample_BrowserController_loadSortDescriptors:(DicomAlbum*)album {
    [self _ExtraDatabaseColumnsSample_BrowserController_loadSortDescriptors:album];
    [ExtraDatabaseColumnsSampleInstance BrowserController:(id)self loadSortDescriptors:album];
}


@end

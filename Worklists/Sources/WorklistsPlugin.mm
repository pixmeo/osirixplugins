//
//  WorklistsPlugin.mm
//  Worklists
//
//  Created by Alessandro Volz on 09/11/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "WorklistsPlugin.h"
#import "Worklist.h"
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/PrettyCell.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <objc/runtime.h>


@interface WorklistsArrayController : NSArrayController

@end


@implementation WorklistsPlugin

@synthesize worklists = _worklists;

static WorklistsPlugin* WorklistsPluginInstance = nil;
static NSString* const Worklists = @"Worklists";
NSString* const WorklistsDefaultsKey = Worklists;

+ (WorklistsPlugin*)instance {
    return WorklistsPluginInstance;
}

- (id)init {
    if ((self = [super init])) {
        if (WorklistsPluginInstance == nil)
            WorklistsPluginInstance = [self retain];
        
        _errors = [[NSMutableDictionary alloc] init];
        
        _worklistObjs = [[NSMutableDictionary alloc] init];
        
        _worklists = [[WorklistsArrayController alloc] init];
        //[_worklists setObjectClass:[WorklistsMutableDictionary class]];
        [_worklists bind:@"contentArray" toObject:[NSUserDefaultsController.sharedUserDefaultsController values] withKeyPath:WorklistsDefaultsKey options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSHandlesContentAsCompoundValueBindingOption]];
        [_worklists setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        
        [_worklists addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionInitial context:[self class]];
    }
    
    return self;
}

- (void)dealloc {
    [_worklistObjs release];
    [_worklists release];
    [_errors release];
    [super dealloc];
}

- (void)initPlugin {
    NSImage* image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:Worklists]] autorelease];
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"WorklistsPreferences" inBundle:[NSBundle bundleForClass:[self class]] withTitle:Worklists image:image];
    
    Method method;
    IMP imp;
    
    Class BrowserControllerClass = [BrowserController class];
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(tableView:willDisplayCell:forTableColumn:row:));
    if (!method) [NSException raise:NSGenericException format:@"bad OsiriX version"];
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_Worklists_BrowserController_tableView:willDisplayCell:forTableColumn:row:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_Worklists_BrowserController_tableView:willDisplayCell:forTableColumn:row:)));
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:));
    if (!method) [NSException raise:NSGenericException format:@"bad OsiriX version"];
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_Worklists_BrowserController_tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_Worklists_BrowserController_tableView:toolTipForCell:rect:tableColumn:row:mouseLocation:)));

    method = class_getInstanceMethod(BrowserControllerClass, @selector(menuWillOpen:));
    if (!method) [NSException raise:NSGenericException format:@"bad OsiriX version"];
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_Worklists_BrowserController_menuWillOpen:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_Worklists_BrowserController_menuWillOpen:)));
}

- (long)filterImage:(NSString*)menuName {
	return 0;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        
    //NSLog(@"observe %@, %@", keyPath, change);
    
    NSMutableDictionary* existingWorklistObjs = [[_worklistObjs mutableCopy] autorelease];
    
    for (NSDictionary* wp in _worklists.content) {
        NSString* wid = [wp objectForKey:WorklistIDKey];
        if (!wid) continue;
        
        Worklist* w = [existingWorklistObjs objectForKey:wid];
        
        if (w) { // it already exists, update it
            [w setProperties:wp];
            [existingWorklistObjs removeObjectForKey:wid];
        } else {
            [_worklistObjs setObject:(w = [Worklist worklistWithProperties:wp]) forKey:wid];
        }
    }
    
    for (NSString* wid in existingWorklistObjs) { // these worklists don't exist anymore, delete them
        [[_worklistObjs objectForKey:wid] delete];
        [_worklistObjs removeObjectForKey:wid];
    }
}

- (Worklist*)worklistForAlbum:(DicomAlbum*)album {
    NSString* albumId = [album.objectID.URIRepresentation absoluteString];
    NSArray* worklists = [_worklistObjs allValues];
    NSInteger i = [[worklists valueForKeyPath:@"albumId"] indexOfObject:albumId];
    return i != NSNotFound ? [worklists objectAtIndex:i] : nil;
}

- (void)deselectAlbumOfWorklist:(Worklist*)worklist {
    NSString* albumId = [worklist valueForKeyPath:@"albumId"];
    
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    if ([[BrowserController currentBrowser] database] != db) // the database is not selected, no need to delect the album
        return;
    
    DicomAlbum* album = [db objectWithID:albumId];
    if (!album) // album not found...
        return;
    
    if (![[[BrowserController currentBrowser] albumTable] isRowSelected:[db.albums indexOfObject:album]+1]) // album is not selected
        return;
    
    [[[BrowserController currentBrowser] albumTable] selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)setError:(id)error onWorklist:(Worklist*)worklist {
    [_errors setObject:error forKey:[worklist.properties objectForKey:WorklistIDKey]];
}

- (void)clearErrorOnWorklist:(Worklist*)worklist {
    [_errors removeObjectForKey:[worklist.properties objectForKey:WorklistIDKey]];
}

#pragma mark BrowserController

- (void)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)column row:(NSInteger)row {
    if (table == bc.albumTable) {
        NSArray* albums = [bc albums];
        if (row-1 > albums.count-1)
            return;
        
        Worklist* worklist = [self worklistForAlbum:[[bc albums] objectAtIndex:row-1]];
        if (worklist) {
            static NSImage* image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[WorklistsPlugin class]] pathForImageResource:@"album"]];
            static NSImage* eimage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[WorklistsPlugin class]] pathForImageResource:@"album_err"]];
            if ([_errors objectForKey:[worklist.properties objectForKey:WorklistIDKey]])
                [cell setImage:eimage];
            else [cell setImage:image];
        }
    }
}

- (void)_Worklists_BrowserController_tableView:(NSTableView*)table willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)column row:(NSInteger)row {
    [self _Worklists_BrowserController_tableView:table willDisplayCell:cell forTableColumn:column row:row];
    [WorklistsPluginInstance _BrowserController:(id)self tableView:table willDisplayCell:cell forTableColumn:column row:row];
}

- (NSString*)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    if (table == bc.albumTable) {
        NSArray* albums = [bc albums];
        if (row-1 > albums.count-1)
            return nil;
        
        Worklist* worklist = [self worklistForAlbum:[[bc albums] objectAtIndex:row-1]];
        if (worklist) {
            id e = [_errors objectForKey:[worklist.properties objectForKey:WorklistIDKey]];
            if ([e isKindOfClass:[NSException class]])
                return [e reason];
        }
    }
    
    return nil;
}

- (NSString*)_Worklists_BrowserController_tableView:(NSTableView*)table toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    NSString* r = [WorklistsPluginInstance _BrowserController:(id)self tableView:table toolTipForCell:cell rect:rect tableColumn:tableColumn row:row mouseLocation:mouseLocation];
    if (r) return r;
    return [self _Worklists_BrowserController_tableView:table toolTipForCell:cell rect:rect tableColumn:tableColumn row:row mouseLocation:mouseLocation];
}

- (void)_BrowserController:(BrowserController*)bc menuWillOpen:(NSMenu*)menu {
    if (menu == [[bc albumTable] menu]) {
        NSInteger i = [bc.albumTable clickedRow];
        if (i == -1)
            return;
        
        DicomAlbum* album = [bc.albums objectAtIndex:i-1];

        Worklist* worklist = [self worklistForAlbum:album];
        if (!worklist)
            return;
        
        i = 0;
        NSMenuItem* mi;
        
        mi = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Refresh Worklist", nil) action:@selector(_refreshWorklist:) keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = worklist;
        [menu insertItem:mi atIndex:i++];
        
        [menu insertItem:[NSMenuItem separatorItem] atIndex:i++];
    }
}

- (void)_refreshWorklist:(NSMenuItem*)mi {
    [mi.representedObject initiateRefresh];
}

- (void)_Worklists_BrowserController_menuWillOpen:(NSMenu*)menu {
    [self _Worklists_BrowserController_menuWillOpen:menu];
    [WorklistsPluginInstance _BrowserController:(id)self menuWillOpen:menu];
}

@end


@implementation WorklistsArrayController

// send KVO notifications for content value changes done through views bound to this object

-(void)setValue:(id)value forKey:(NSString *)key {
    [self willChangeValueForKey:@"content"];
    [super setValue:value forKey:key];
    [self didChangeValueForKey:@"content"];
}

-(void)setValue:(id)value forKeyPath:(NSString *)keyPath {
    [self willChangeValueForKey:@"content"];
    [super setValue:value forKeyPath:keyPath];
    [self didChangeValueForKey:@"content"];
}

@end


//
//  WorklistsPlugin.mm
//  Worklists
//
//  Created by Alessandro Volz on 09/11/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "WorklistsPlugin.h"
#import "Worklist.h"
#import "WorklistsNonretainingTimerInvoker.h"
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/PrettyCell.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/Notifications.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <objc/runtime.h>


@interface WorklistsArrayController : NSArrayController

@end

@interface WorklistsPlugin ()

@property(readwrite,retain) NSTimer* urlSyncTimer;

@end

@implementation WorklistsPlugin

@synthesize worklists = _worklists;
@synthesize urlSyncTimer = _urlSyncTimer;

static WorklistsPlugin* WorklistsPluginInstance = nil;
static NSString* const Worklists = @"Worklists";
NSString* const WorklistsDefaultsKey = Worklists;
NSString* const WorklistAlbumIDsDefaultsKey = @"Worklist Album IDs";


+ (WorklistsPlugin*)instance {
    return WorklistsPluginInstance;
}

- (id)init {
    if ((self = [super init])) {
        if (WorklistsPluginInstance == nil)
            WorklistsPluginInstance = [self retain];
        
        _errors = [[NSMutableDictionary alloc] init];
        
        _worklistObjs = [[NSMutableDictionary alloc] init];
        
        _studiesLastSeenDates = [[NSMutableDictionary alloc] init];
        _cachePath = [[DicomDatabase.defaultDatabase.baseDirPath stringByAppendingPathComponent:@"WorklistsCache.plist"] retain];
        NSDictionary* slsd = [NSDictionary dictionaryWithContentsOfFile:_cachePath];
        if ([slsd isKindOfClass:[NSDictionary class]])
            [_studiesLastSeenDates setValuesForKeysWithDictionary:slsd];
        
        _worklists = [[WorklistsArrayController alloc] init];
        [_worklists bind:@"contentArray" toObject:[NSUserDefaultsController.sharedUserDefaultsController values] withKeyPath:WorklistsDefaultsKey options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSHandlesContentAsCompoundValueBindingOption]];
        [_worklists setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(id)n {
    [_worklists addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionInitial context:[self class]];
    [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forKeyPath:@"values.WorklistsPlistURL" options:0 context:[self class]];
    [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forKeyPath:@"values.WorklistsPlistURLSyncFlag" options:NSKeyValueObservingOptionInitial context:[self class]];
}

- (void)dealloc {
    [self saveSLSDs];
    
    [NSUserDefaultsController.sharedUserDefaultsController removeObserver:self];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    self.urlSyncTimer = nil;
    
    [_cachePath release];
    [_worklistObjs release];
    [_worklists release];
    [_studiesLastSeenDates release];
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
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(tableView:validateDrop:proposedRow:proposedDropOperation:));
    if (!method) [NSException raise:NSGenericException format:@"bad OsiriX version"];
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_Worklists_BrowserController_tableView:validateDrop:proposedRow:proposedDropOperation:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_Worklists_BrowserController_tableView:validateDrop:proposedRow:proposedDropOperation:)));
    
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
    
    method = class_getInstanceMethod(BrowserControllerClass, @selector(outlineView:willDisplayCell:forTableColumn:item:));
    if (!method) [NSException raise:NSGenericException format:@"bad OsiriX version"];
    imp = method_getImplementation(method);
    class_addMethod(BrowserControllerClass, @selector(_Worklists_BrowserController_outlineView:willDisplayCell:forTableColumn:item:), imp, method_getTypeEncoding(method));
    method_setImplementation(method, class_getMethodImplementation([self class], @selector(_Worklists_BrowserController_outlineView:willDisplayCell:forTableColumn:item:)));
}

- (long)filterImage:(NSString*)menuName {
	return 0;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    //NSLog(@"observe %@, %@", keyPath, change);
    
    if (object == _worklists) {
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
        
        // clean up leftover albums...
        @synchronized (self) {
            NSArray* albumIDs = [_worklistObjs.allValues valueForKey:@"albumId"];
            
            NSArray* savedAlbumIDs = [NSUserDefaults.standardUserDefaults objectForKey:WorklistAlbumIDsDefaultsKey];
            NSMutableArray* mAlbumIDs = [savedAlbumIDs isKindOfClass:[NSArray class]]? [[savedAlbumIDs mutableCopy] autorelease] : [NSMutableArray array];
            
            for (NSString* albumId in savedAlbumIDs)
                if (![albumIDs containsObject:albumId]) {
                    // TODO: delete 0-image studies // but what if the list is being synced ?
                    ;
                    // delete the album
                    [Worklist deleteAlbumWithId:albumId];
                    // remove from list
                    [mAlbumIDs removeObject:albumId];
                }
            
            [NSUserDefaults.standardUserDefaults setObject:mAlbumIDs forKey:WorklistAlbumIDsDefaultsKey];
        }
    }
    else {
        if ([keyPath isEqualToString:@"values.WorklistsPlistURLSyncFlag"] || [keyPath isEqualToString:@"values.WorklistsPlistURL"]) {
            if ([[NSUserDefaults.standardUserDefaults objectForKey:@"WorklistsPlistURLSyncFlag"] boolValue])
                self.urlSyncTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:[WorklistsNonretainingTimerInvoker invokerWithTarget:self selector:@selector(_urlSync)] selector:@selector(fire:) userInfo:nil repeats:YES];
            else self.urlSyncTimer = nil;
            [self.urlSyncTimer fire];
        }
    }
}

- (void)_urlSync {
    [NSThread performBlockInBackground:^{
        NSURL* url = [NSURL URLWithString:[NSUserDefaults.standardUserDefaults objectForKey:@"WorklistsPlistURL"]];
        /*NSURLRequest* request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60];
        
        NSURLResponse* response = nil;
        NSError* error = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];*/
        
        NSArray* entries = [NSArray arrayWithContentsOfURL:url];
        
        if (entries)
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![_worklists.content isEqual:entries]) {
                    [_worklists setContent:entries];
                    [self observeValueForKeyPath:@"content" ofObject:_worklists change:nil context:[self class]];
                }
            });
    }];
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
    [[self class] refreshAlbumsForDatabase:[DicomDatabase defaultDatabase]];
}

- (void)clearErrorOnWorklist:(Worklist*)worklist {
    [_errors removeObjectForKey:[worklist.properties objectForKey:WorklistIDKey]];
    [[self class] refreshAlbumsForDatabase:[DicomDatabase defaultDatabase]];
}

+ (NSString*)SLSDKeyForStudy:(DicomStudy*)study worklist:(Worklist*)worklist {
    return [NSString stringWithFormat:@"%@/%@", [worklist.properties objectForKey:WorklistIDKey], study.studyInstanceUID];
}

- (void)setLastSeenDate:(NSDate*)date forStudy:(DicomStudy*)study worklist:(Worklist*)worklist {
    @synchronized (_studiesLastSeenDates) {
        if (date)
            [_studiesLastSeenDates setObject:date forKey:[[self class] SLSDKeyForStudy:study worklist:worklist]];
        else [_studiesLastSeenDates removeObjectForKey:[[self class] SLSDKeyForStudy:study worklist:worklist]];
    }
}

- (NSDate*)lastSeenDateForStudy:(DicomStudy*)study worklist:(Worklist*)worklist {
    @synchronized (_studiesLastSeenDates) {
        return [_studiesLastSeenDates objectForKey:[[self class] SLSDKeyForStudy:study worklist:worklist]];
    }
}

- (void)saveSLSDs {
    @synchronized (_studiesLastSeenDates) {
        // clean up dead items
        for (NSString* key in _studiesLastSeenDates.allKeys)
            if (-[[_studiesLastSeenDates objectForKey:key] timeIntervalSinceNow] > 172800) // 2 days
                [_studiesLastSeenDates removeObjectForKey:key];
        // save
        [_studiesLastSeenDates writeToFile:_cachePath atomically:YES];
    }
}

+ (void)refreshAlbumsForDatabase:(DicomDatabase*)db {
    [NSNotificationCenter.defaultCenter postNotificationName:O2DatabaseInvalidateAlbumsCacheNotification object:db];
    [BrowserController.currentBrowser refreshAlbums];
}

#pragma mark BrowserController

- (void)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)column row:(NSInteger)row {
    if (bc.database != [DicomDatabase defaultDatabase])
        return;
    
    if (table == bc.albumTable) {
        if (row <= 0) // low check
            return;
        --row; // index in albums array instead of index in album table (index 1 = entire database)
        
        NSArray* albums = [bc albums];
        if (row >= albums.count) // high check
            return;
        
        Worklist* worklist = [self worklistForAlbum:[albums objectAtIndex:row]];
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

- (BOOL)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation returnDropOperation:(NSTableViewDropOperation&)returnDropOperation {
    if (bc.database != [DicomDatabase defaultDatabase])
        return NO;

    if (table == bc.albumTable) {
        if (row <= 0) // low check
            return NO;
        --row; // index in albums array instead of index in album table (index 1 = entire database)

        NSArray* albums = [bc albums];
        if (row >= albums.count) // high check
            return NO;
        
        Worklist* worklist = [self worklistForAlbum:[albums objectAtIndex:row]];
        if (worklist) {
            returnDropOperation = NSDragOperationNone;
            return YES;
        }
    }
    
    return NO;
}

- (NSDragOperation)_Worklists_BrowserController_tableView:(NSTableView*)table validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    NSDragOperation returnDropOperation;
    if ([WorklistsPluginInstance _BrowserController:(id)self tableView:table validateDrop:info proposedRow:row proposedDropOperation:operation returnDropOperation:returnDropOperation])
        return returnDropOperation;
    return [self _Worklists_BrowserController_tableView:table validateDrop:info proposedRow:row proposedDropOperation:operation];
}


- (NSString*)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table toolTipForCell:(NSCell*)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn*)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
    if (bc.database != [DicomDatabase defaultDatabase])
        return nil;

    if (table == bc.albumTable) {
        if (row <= 0) // low check
            return nil;
        --row; // index in albums array instead of index in album table (index 1 = entire database)
        
        NSArray* albums = [bc albums];
        if (row >= albums.count) // high check
            return nil;
        
        Worklist* worklist = [self worklistForAlbum:[albums objectAtIndex:row]];
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
    if (bc.database != [DicomDatabase defaultDatabase])
        return;

    if (menu == [[bc albumTable] menu]) {
        NSInteger row = [bc.albumTable clickedRow];
        if (row <= 0) // low check
            return;
        --row; // index in albums array instead of index in album table (index 1 = entire database)
        
        NSArray* albums = [bc albums];
        if (row >= albums.count) // high check
            return;

        Worklist* worklist = [self worklistForAlbum:[albums objectAtIndex:row]];
        if (!worklist)
            return;
        
        int i = 0;
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

- (void)_BrowserController:(BrowserController*)bc outlineView:(NSOutlineView*)outlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn*)column item:(id)item {
    if (bc.database != [DicomDatabase defaultDatabase])
        return;
    
    @try {
        NSInteger row = [bc.albumTable selectedRow];
        if (row <= 0) // low check
            return;
        --row; // index in albums array instead of index in album table (index 1 = entire database)
        
        NSArray* albums = [bc albums];
        if (row >= albums.count) // high check
            return;

        Worklist* worklist = [self worklistForAlbum:[albums objectAtIndex:row]];
        if (!worklist)
            return;

        DicomStudy* study = nil;
        if ([item isKindOfClass:[DicomStudy class]])
            study = item;
        if ([item isKindOfClass:[DicomSeries class]])
            study = [item study];
        
        if (!study)
            return;
        
        if (![worklist.lastRefreshStudyInstanceUIDs containsObject:study.studyInstanceUID])
            [cell setFont:[NSFont systemFontOfSize:12]];

    } @catch (NSException* e) {
        N2LogExceptionWithStackTrace(e);
    }
}

- (void)_Worklists_BrowserController_outlineView:(NSOutlineView*)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn*)column item:(id)item {
    [self _Worklists_BrowserController_outlineView:outlineView willDisplayCell:cell forTableColumn:column item:item];
    [WorklistsPluginInstance _BrowserController:(id)self outlineView:outlineView willDisplayCell:cell forTableColumn:column item:item];
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


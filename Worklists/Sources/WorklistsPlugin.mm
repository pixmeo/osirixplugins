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

}

- (long)filterImage:(NSString*)menuName {
	return 0;
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        
    NSLog(@"observe %@, %@", keyPath, change);
    
    NSMutableDictionary* existingWorklistObjs = [[_worklistObjs mutableCopy] autorelease];
    
    for (NSMutableDictionary* wp in _worklists.content) {
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

#pragma mark BrowserController

- (void)_BrowserController:(BrowserController*)bc tableView:(NSTableView*)table willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)column row:(NSInteger)row {
    NSArray* albums = [bc albums];
    if (row-1 > albums.count-1)
        return;
    
    DicomAlbum* album = [[bc albums] objectAtIndex:row-1];
    NSString* albumId = [album.objectID.URIRepresentation absoluteString];
    
    if ([[[_worklistObjs allValues] valueForKeyPath:@"properties.album_id"] containsObject:albumId]) {
        static NSImage* image = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[WorklistsPlugin class]] pathForImageResource:@"album"]];
        [cell setImage:image];
    }
}

- (void)_Worklists_BrowserController_tableView:(NSTableView*)table willDisplayCell:(PrettyCell*)cell forTableColumn:(NSTableColumn*)column row:(NSInteger)row {
    [self _Worklists_BrowserController_tableView:table willDisplayCell:cell forTableColumn:column row:row];
    [WorklistsPluginInstance _BrowserController:(id)self tableView:table willDisplayCell:cell forTableColumn:column row:row];
}

@end


@implementation WorklistsArrayController

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


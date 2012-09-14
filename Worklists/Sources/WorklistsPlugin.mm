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


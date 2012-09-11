//
//  WorklistsPlugin.mm
//  Worklists
//
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "WorklistsPlugin.h"
#import <OsiriXAPI/PreferencesWindowController.h>

@implementation WorklistsPlugin

@synthesize worklists = _worklists;

static WorklistsPlugin* WorklistsPluginInstance = nil;

+ (WorklistsPlugin*)instance {
    return WorklistsPluginInstance;
}

- (id)init {
    if ((self = [super init])) {
        if (WorklistsPluginInstance == nil)
            WorklistsPluginInstance = [self retain];
        
        _worklists = [[NSArrayController alloc] init];
        [_worklists bind:@"contentArray" toObject:[[NSUserDefaultsController sharedUserDefaultsController] values] withKeyPath:@"Worklists" options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:NSHandlesContentAsCompoundValueBindingOption]];
        [_worklists setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
       // [_worklists setAutomaticallyRearrangesObjects:YES];
        
    }
    
    return self;
}

- (void)initPlugin {
    NSImage* image = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForImageResource:@"Worklists"]] autorelease];
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"WorklistsPreferences" inBundle:[NSBundle bundleForClass:[self class]] withTitle:@"Worklists" image:image];
}

- (long)filterImage:(NSString*)menuName {
	return 0;
}

@end

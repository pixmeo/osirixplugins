//
//  KeyObjectSelectionPrefs.m
//  KeyObjectSelectionPrefs
//
//  Created by Alessandro Volz on 29.05.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "KeyObjectSelectionPrefsPane.h"
#import "NSUserDefaults+KOS.h"

@implementation KeyObjectSelectionPrefsPane

@synthesize locationsMenu = _locationsMenu;

- (void)menuWillOpen:(NSMenu*)menu {
    [menu removeAllItems];
    [menu addItemWithTitle:NSLocalizedString(@"Locations...", nil) action:@selector(dummy:) keyEquivalent:@""];
    
    NSArray* nodes = [NSUserDefaults.standardUserDefaults objectForKey:@"SERVERS"];
    nodes = [nodes sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"Description" ascending:YES]]];
    
    for (NSDictionary* node in nodes) {
        NSMenuItem* mi = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@: %@@%@:%@", [node objectForKey:@"Description"], [node objectForKey:@"AETitle"], [node objectForKey:@"Address"], [node objectForKey:@"Port"]] action:@selector(chooseLocation:) keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = node;
        [menu addItem:mi];
    }
}

-(void)awakeFromNib {
    [self menuWillOpen:_locationsMenu];
}

-(void)chooseLocation:(NSMenuItem*)mi {
    NSDictionary* node = mi.representedObject;
    [NSUserDefaults.standardUserDefaults setObject:[node objectForKey:@"Address"] forKey:KOSNodeHostKey];
    [NSUserDefaults.standardUserDefaults setObject:[node objectForKey:@"Port"] forKey:KOSNodePortKey];
    [NSUserDefaults.standardUserDefaults setObject:[node objectForKey:@"AETitle"] forKey:KOSAETKey];
}

@end

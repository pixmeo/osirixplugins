//
//  WorklistsPreferencesController.m
//  Worklists
//
//  Created by Alessandro Volz on 09/11/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "WorklistsPreferencesController.h"
#import "WorklistsPlugin.h"
#import "Worklist.h"
#import <OsiriXAPI/DCMTKQueryNode.h>


@interface WorklistsPreferencesController ()

- (void)adjustSetupAndGUI;

@end


@implementation WorklistsPreferencesController

@synthesize worklistsTable = _worklistsTable;
@synthesize refreshButton = _refreshButton;
@synthesize autoretrieveButton = _autoretrieveButton;
@synthesize filterEditor = _filterEditor;

- (void)awakeFromNib {
    [self.worklists addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionInitial context:[self class]];
    
    NSDictionary* binding = [[[self.filterEditor infoForBinding:@"value"] retain] autorelease];
    NSMutableDictionary* options = [[[binding objectForKey:NSOptionsKey] mutableCopy] autorelease];
    
    [options setObject:[NSCompoundPredicate andPredicateWithSubpredicates:nil] forKey:NSNullPlaceholderBindingOption];
    
    [self.filterEditor unbind:@"value"];
    [self.filterEditor bind:@"value" toObject:[binding objectForKey:NSObservedObjectKey] withKeyPath:[binding objectForKey:NSObservedKeyPathKey] options:options];
    
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (context != [self class])
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
    [self adjustSetupAndGUI];
}

- (void)dealloc {
    [self.worklists removeObserver:self forKeyPath:@"content"];
    [super dealloc];
}

- (NSArrayController*)worklists {
    return [[WorklistsPlugin instance] worklists];
}

+ (NSString*)stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [uuidString autorelease];
}

- (IBAction)add:(id)caller {
    NSString* uid = [[self class] stringWithUUID];
    
    NSMutableDictionary* dic = [[[[self.worklists objectClass] alloc] init] autorelease];
    [dic setObject:uid forKey:WorklistIDKey];
    
    [self.worklists addObject:dic];
    
    [self.worklists setSelectedObjects:[NSArray arrayWithObject:dic]];
    [self.worklistsTable editColumn:0 row:[self.worklists.arrangedObjects indexOfObject:dic] withEvent:nil select:YES];
}

- (void)tableViewTextDidEndEditing:(NSNotification*)n {
    [self.worklists rearrangeObjects];
    [self.worklists didChangeValueForKey:@"content"];
}

- (void)tableViewSelectionDidChange:(NSNotification*)notification {
    [self adjustSetupAndGUI];
}

- (void)adjustSetupAndGUI {
    // adjust refresh interval selection and 
    
    NSInteger refresh = _refreshButton.selectedTag;

    if (_autoretrieveButton.selectedTag >= refresh)
        [_autoretrieveButton selectItemWithTag:0];
    
    for (NSMenuItem* mi in _autoretrieveButton.itemArray)
        if (mi.tag > 0)
            [mi setHidden:(mi.tag >= refresh)];
}

- (BOOL)canCountSuboperations {
    return [DCMTKQueryNode instancesRespondToSelector:@selector(countOfSuccessfulSuboperations)];
}

@end


@interface WorklistsTableView : NSTableView

@end


@implementation WorklistsTableView

- (void)textDidEndEditing:(NSNotification*)n {
    [super textDidEndEditing:n];
    if ([self.delegate respondsToSelector:@selector(tableViewTextDidEndEditing:)])
        [self.delegate performSelector:@selector(tableViewTextDidEndEditing:) withObject:n];
}

@end


@interface WorklistPredicateEditorRowTemplate : NSPredicateEditorRowTemplate

@end























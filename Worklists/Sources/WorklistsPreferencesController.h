//
//  WorklistsPreferencesController.h
//  Worklists
//
//  Created by Alessandro Volz on 09/11/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface WorklistsPreferencesController : NSPreferencePane {
    NSTableView* _worklistsTable;
    NSPopUpButton* _refreshButton;
    NSPopUpButton* _autoretrieveButton;
    NSPredicateEditor* _filterEditor;
}

@property(readonly) IBOutlet NSArrayController* worklists;

@property(assign) IBOutlet NSTableView* worklistsTable;
@property(assign) IBOutlet NSPopUpButton* refreshButton;
@property(assign) IBOutlet NSPopUpButton* autoretrieveButton;
@property(assign) IBOutlet NSPredicateEditor* filterEditor;

- (IBAction)add:(id)caller;

@end

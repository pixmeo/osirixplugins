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
}

@property(assign) IBOutlet NSTableView* worklistsTable;

- (IBAction)add:(id)caller;

@end

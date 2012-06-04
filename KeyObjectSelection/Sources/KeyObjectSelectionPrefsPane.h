//
//  KeyObjectSelectionPrefs.h
//  KeyObjectSelectionPrefs
//
//  Created by Alessandro Volz on 29.05.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface KeyObjectSelectionPrefsPane : NSPreferencePane {
    NSMenu* _locationsMenu;
}

@property(assign) IBOutlet NSMenu* locationsMenu;

@end

//
//  AutoCleanPrefsController.h
//  AutoClean
//
//  Created by Alessandro Volz on 12/1/2011
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>


@interface AutoCleanPrefsController : NSPreferencePane {
    IBOutlet NSTextField* _lastCleanTimeField;
    IBOutlet NSTextField* _nextCleanTimeField;
    IBOutlet NSPopUpButton* _thresholdPullDown;
    NSString* _lastCleanFormat;
    NSString* _nextCleanFormat;
}



@end

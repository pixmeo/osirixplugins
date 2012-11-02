//
//  AutoCleanPrefsController.mm
//  AutoClean
//
//  Created by Alessandro Volz on 12/1/2011
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "AutoCleanPrefsController.h"
#import "AutoCleanCommons.h"
#import <OsiriXAPI/NSUserDefaultsController+N2.h>


@implementation AutoCleanPrefsController

-(void)awakeFromNib {
    NSLog(@"AutoCleanPrefsController awakeFromNib");

    _lastCleanFormat = [_lastCleanTimeField.stringValue retain];
    _nextCleanFormat = [_nextCleanTimeField.stringValue retain];
    
    [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:AutoCleanPluginLastExecutionDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
    [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:AutoCleanPluginNextExecutionDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
}

-(void)dealloc {
    NSLog(@"AutoCleanPrefsController dealloc");
    [NSUserDefaults.standardUserDefaults removeObserver:self forValuesKey:AutoCleanPluginThresholdDefaultsKey];
    [NSUserDefaults.standardUserDefaults removeObserver:self forValuesKey:AutoCleanPluginLastExecutionDefaultsKey];
    [NSUserDefaults.standardUserDefaults removeObserver:self forValuesKey:AutoCleanPluginNextExecutionDefaultsKey];
    [_lastCleanFormat release]; _lastCleanFormat = nil;
    [_nextCleanFormat release]; _nextCleanFormat = nil;
    [super dealloc];
}

+(void)_formatDate:(NSDate*)date intoDateString:(NSString**)ds timeString:(NSString**)ts {
    if (ds) *ds = date? [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle] : nil;
    if (ts) *ts = date? [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle] : nil;
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    NSLog(@"AutoCleanPrefsController observeValueForKeyPath: %@", keyPath);
    
    if ([keyPath isEqualToString:valuesKeyPath(AutoCleanPluginLastExecutionDefaultsKey)]) {
        NSDate* date = [NSUserDefaults.standardUserDefaults objectForKey:AutoCleanPluginLastExecutionDefaultsKey];
        NSString *dateString, *timeString; [[self class] _formatDate:date intoDateString:&dateString timeString:&timeString];
        [_lastCleanTimeField setStringValue:[NSString stringWithFormat:NSLocalizedString(_lastCleanFormat, nil), date? [NSString stringWithFormat:NSLocalizedString(@"on %@ at %@", nil), dateString, timeString] : NSLocalizedString(@"never", nil)]];
    }
    
    if ([keyPath isEqualToString:valuesKeyPath(AutoCleanPluginNextExecutionDefaultsKey)]) {
        NSDate* date = [NSUserDefaults.standardUserDefaults objectForKey:AutoCleanPluginNextExecutionDefaultsKey];
        NSString *dateString, *timeString; [[self class] _formatDate:date intoDateString:&dateString timeString:&timeString];
        [_nextCleanTimeField setStringValue:[NSString stringWithFormat:NSLocalizedString(_nextCleanFormat, nil), date? [NSString stringWithFormat:NSLocalizedString(@"on %@ at %@", nil), dateString, timeString] : NSLocalizedString(@"undefined", nil)]];
    }
}


@end

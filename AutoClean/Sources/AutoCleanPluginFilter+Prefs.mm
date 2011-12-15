//
//  AutoCleanPluginFilter+Prefs.m
//  AutoClean
//
//  Created by Alessandro Volz on 01.12.11.
//  Copyright (c) 2011 OsiriX Team. All rights reserved.
//

#import "AutoCleanPluginFilter+Prefs.h"
#import "AutoCleanCommons.h"
#import <OsiriXAPI/PreferencesWindowController.h>
#import <OsiriXAPI/NSUserDefaultsController+N2.h>

@interface _AutoCleanPluginDefaultsHelper : NSObject {
    AutoCleanPluginFilter* _plugin;
}

-(id)initWithPlugin:(AutoCleanPluginFilter*)plugin;

@end

@implementation AutoCleanPluginFilter (Prefs)

-(void)initPrefs {
    [PreferencesWindowController addPluginPaneWithResourceNamed:@"AutoCleanPrefs" inBundle:[NSBundle bundleForClass:[self class]] withTitle:@"AutoClean" image:[NSImage imageNamed:@"NSUser"]];
    [[_AutoCleanPluginDefaultsHelper alloc] initWithPlugin:self];
}

@end

@implementation _AutoCleanPluginDefaultsHelper

-(id)initWithPlugin:(AutoCleanPluginFilter*)plugin {
    if (([super init])) {
        _plugin = [plugin retain];
        
        [NSUserDefaults.standardUserDefaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO], AutoCleanPluginEnabledDefaultsKey,
                                    [NSDate dateWithTimeIntervalSinceReferenceDate:0], AutoCleanPluginTimeDefaultsKey, // midnight
                                    [NSNumber numberWithInteger:-40], AutoCleanPluginThresholdDefaultsKey,
                                    nil]];
        
        [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:AutoCleanPluginEnabledDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
        [NSUserDefaultsController.sharedUserDefaultsController addObserver:self forValuesKey:AutoCleanPluginNextExecutionDefaultsKey options:NSKeyValueObservingOptionInitial context:nil];
    }
    
    return self;
}

-(void)dealloc {
//    NSLog(@"_AutoCleanPluginDefaultsHelper dealloc");
    [_plugin release]; _plugin = nil;
    [super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
//    NSLog(@"_AutoCleanPluginDefaultsHelper observeValueForKeyPath: %@", keyPath);
    
    if ([keyPath isEqualToString:valuesKeyPath(AutoCleanPluginEnabledDefaultsKey)]) {
        BOOL enabled = [NSUserDefaults.standardUserDefaults boolForKey:AutoCleanPluginEnabledDefaultsKey];
        if (enabled) {
            const NSTimeInterval secondsPerDay = 60*60*24;
            NSDate* time = [NSUserDefaults.standardUserDefaults objectForKey:AutoCleanPluginTimeDefaultsKey];
//            NSLog(@"Time: %@", time);
            NSTimeInterval magic = [time isKindOfClass:[NSDate class]]? ([time timeIntervalSinceReferenceDate]/secondsPerDay) : 0;
//            NSLog(@"magic: %F", magic);
            NSTimeInterval whenInDay = magic-floor(magic);
//            NSLog(@"whenInDay: %F", whenInDay);
            NSDate* now = [NSDate date];
            magic = (floor([now timeIntervalSinceReferenceDate]/secondsPerDay)+whenInDay)*secondsPerDay;
//            NSLog(@"magic: %F", magic);
            NSDate* when = [NSDate dateWithTimeIntervalSinceReferenceDate:magic];
            if ([when compare:now] <= 0)
                when = [NSDate dateWithTimeIntervalSinceReferenceDate:magic+secondsPerDay];
            [NSUserDefaults.standardUserDefaults setObject:when forKey:AutoCleanPluginNextExecutionDefaultsKey];
        } else [NSUserDefaults.standardUserDefaults removeObjectForKey:AutoCleanPluginNextExecutionDefaultsKey];
    }
    
    if ([keyPath isEqualToString:valuesKeyPath(AutoCleanPluginEnabledDefaultsKey)]) {
        NSDate* date = [NSUserDefaults.standardUserDefaults objectForKey:AutoCleanPluginNextExecutionDefaultsKey];
//        NSLog(@"Next AutoClean: %@", date);
        if (date)
            [_plugin scheduleAutoCleanAt:date];
        else [_plugin unscheduleAutoClean];
    }
    
    //    BOOL anySpecialIsOn = [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingEventsDefaultsKey]
    //                       || [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingIDDefaultsKey]
    //                       || [defaults boolForKey:DicomUnEnhancerNIfTIOutputNamingProtocolDefaultsKey];
    //    if (!anySpecialIsOn) [defaults setBool:YES forKey:DicomUnEnhancerNIfTIOutputNamingDateDefaultsKey];
}

@end


//
//  AutoCleanPluginFilter.mm
//  AutoClean
//
//  Created by Alessandro Volz on 12/1/2011
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "AutoCleanPluginFilter.h"
#import "AutoCleanPluginFilter+Prefs.h"
#import "AutoCleanCommons.h"
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/ThreadsManager.h>

@implementation AutoCleanPluginFilter

-(void)initPlugin {
	[self initPrefs];
}

-(void)dealloc {
    [self unscheduleAutoClean];
}

-(void)scheduleAutoCleanAt:(NSDate*)date {
    [self unscheduleAutoClean];
//  _timer = [[NSTimer alloc] initWithFireDate:date interval:0 target:self selector:@selector(_performScheduledAutoClean:) userInfo:nil repeats:NO];
    _timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3] interval:0 target:self selector:@selector(_performScheduledAutoClean:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

-(void)unscheduleAutoClean {
    if (_timer) {
        [_timer invalidate];
        [_timer release];
        _timer = nil;
    }
}

-(void)_performScheduledAutoClean:(NSTimer*)timer {
    [self performSelectorInBackground:@selector(_autoCleanThread:) withObject:[timer fireDate]];
}

-(void)_autoCleanThread:(NSDate*)date {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    @try {
        id oldAUTOCLEANINGSPACESIZE = [[NSUserDefaults.standardUserDefaults objectForKey:@"AUTOCLEANINGSPACESIZE"] retain];
        id oldAUTOCLEANINGSPACE = [[NSUserDefaults.standardUserDefaults objectForKey:@"AUTOCLEANINGSPACE"] retain];
        
        @try {
            NSThread* thread = [NSThread currentThread];
            thread.name = NSLocalizedString(@"AutoClean Plugin", nil);
            [ThreadsManager.defaultManager addThreadAndStart:thread];
            
            Class DD = NSClassFromString(@"DicomDatabase");
            if (DD)
            {
                id dd = [DD valueForKey:@"defaultDatabase"];
                [dd performSelector:@selector(cleanForFreeSpaceMB:) withObject:[NSNumber numberWithInteger:124000]]; // TODO: 124000 -> -AutoCleanPluginThreshold/100*disksize
            }
            else // old OsiriX has @selector(autoCleanDatabaseFreeSpaceThread:)... but this will return without doing anything if autoclean is already running! and we cannot know
            {
                [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"AUTOCLEANINGSPACE"];
                NSInteger threshold = [[NSUserDefaults.standardUserDefaults objectForKey:AutoCleanPluginThresholdDefaultsKey] integerValue];
                [NSUserDefaults.standardUserDefaults setInteger:threshold forKey:@"AUTOCLEANINGSPACE"];
                
                [[BrowserController currentBrowser] performSelector:@selector(autoCleanDatabaseFreeSpaceThread:) withObject:self];
                
                [NSUserDefaults.standardUserDefaults setObject:date forKey:AutoCleanPluginLastExecutionDefaultsKey];
            }
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            [NSUserDefaults.standardUserDefaults setObject:[oldAUTOCLEANINGSPACE autorelease] forKey:@"AUTOCLEANINGSPACE"];
            [NSUserDefaults.standardUserDefaults setObject:[oldAUTOCLEANINGSPACESIZE autorelease] forKey:@"AUTOCLEANINGSPACESIZE"];
            
        }
        
        const NSTimeInterval secondsPerDay = 60*60*24;
        [NSUserDefaults.standardUserDefaults setObject:[date dateByAddingTimeInterval:secondsPerDay] forKey:AutoCleanPluginNextExecutionDefaultsKey];
    } @catch (NSException* e) {
        [pool release];
    }
}

@end

#import <Foundation/Foundation.h>
#import <OsiriXAPI/PluginFilter.h>

@interface AutoCleanPluginFilter : PluginFilter {
    NSTimer* _timer;
}

-(void)scheduleAutoCleanAt:(NSDate*)date;
-(void)unscheduleAutoClean;

@end

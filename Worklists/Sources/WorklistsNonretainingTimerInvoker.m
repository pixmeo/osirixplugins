//
//  WorklistsNonretainingTimerInvoker.m
//  Worklists
//
//  Created by Alessandro Volz on 30.11.12.
//
//

#import "WorklistsNonretainingTimerInvoker.h"


@implementation WorklistsNonretainingTimerInvoker

- (id)initWithTarget:(id)target selector:(SEL)sel {
    if ((self = [super init])) {
        _target = target; // no retain!
        _sel = sel;
    }
    
    return self;
}

+ (id)invokerWithTarget:(id)target selector:(SEL)sel {
    return [[[[self class] alloc] initWithTarget:target selector:sel] autorelease];
}

- (void)fire:(NSTimer*)timer {
    [_target performSelector:_sel withObject:timer];
}

@end
//
//  WorklistsNonretainingTimerInvoker.h
//  Worklists
//
//  Created by Alessandro Volz on 30.11.12.
//
//

#import <Foundation/Foundation.h>

@interface WorklistsNonretainingTimerInvoker : NSObject {
    id _target;
    SEL _sel;
}

+ (id)invokerWithTarget:(id)target selector:(SEL)sel;

@end

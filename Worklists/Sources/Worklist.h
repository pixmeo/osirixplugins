//
//  Worklist.h
//  Worklists
//
//  Created by Alessandro Volz on 09/14/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString* const WorklistIDKey;
extern NSString* const WorklistNameKey;
extern NSString* const WorklistHostKey;
extern NSString* const WorklistPortKey;
extern NSString* const WorklistCalledAETKey;
extern NSString* const WorklistCallingAETKey;
extern NSString* const WorklistRefreshSecondsKey;
extern NSString* const WorklistAutoRetrieveKey;


@interface Worklist : NSObject {
    NSDate* _lastRefreshDate;
    NSMutableDictionary* _properties;
}

@property(retain,nonatomic) NSMutableDictionary* properties;
@property(retain,readonly) NSDate* lastRefreshDate;

+ (id)worklistWithProperties:(NSMutableDictionary*)properties;
- (id)initWithProperties:(NSMutableDictionary*)properties;

- (void)delete;

-(void)refresh;

@end

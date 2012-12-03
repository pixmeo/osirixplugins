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
extern NSString* const WorklistFilterFlagKey;
extern NSString* const WorklistFilterRuleKey;
extern NSString* const WorklistNoLongerThenKey;
extern NSString* const WorklistNoLongerThenIntervalKey;


@class DicomAlbum;
@class DicomDatabase;
@class DicomStudy;


@interface Worklist : NSObject {
    NSDictionary* _properties;
    NSTimer* _refreshTimer;
    NSTimer* _autoretrieveTimer;
    NSRecursiveLock* _refreshLock;
    NSRecursiveLock* _autoretrieveLock;
    NSMutableDictionary* _currentAutoretrieves;
    NSMutableArray* _lastRefreshStudyInstanceUIDs;
}

@property(retain,nonatomic) NSDictionary* properties;

+ (id)worklistWithProperties:(NSDictionary*)properties;
- (id)initWithProperties:(NSDictionary*)properties;

+ (void)deleteAlbumWithId:(NSString*)albumId;
- (void)delete;

- (DicomAlbum*)albumInDatabase:(DicomDatabase*)db;

- (void)initiateRefresh;
- (NSArray*)lastRefreshStudyInstanceUIDs;

- (DicomStudy*)database:(DicomDatabase*)db createEmptyStudy:(NSDictionary*)entry;

@end

//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 17.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DiscPublishingJobInfoDiscNameKey;
extern NSString* const DiscPublishingJobInfoTemplatePathKey;
extern NSString* const DiscPublishingJobInfoMergeValuesKey;
extern NSString* const DiscPublishingJobInfoMediaTypeKey;
extern NSString* const DiscPublishingJobInfoBurnSpeedKey;

extern NSString* const DiscPublishingToolWillFinishLaunchingNotification;
extern NSString* const DiscPublishingToolWillTerminateNotification;
extern NSString* const DiscPublishingToolThreadInfoChangeNotification;
extern NSString* const DiscPublishingToolThreadChangedInfoKey;

extern NSString* const DiscPublishingToolProxyName;

@protocol DiscPublishingTool <NSObject>

-(BOOL)ping;

-(void)setBinSelectionEnabled:(BOOL)enabled leftBinType:(NSUInteger)leftBinType rightBinType:(NSUInteger)rightBinType defaultBin:(NSUInteger)defaultBin;
-(NSString*)publishDiscWithRoot:(NSString*)root info:(NSDictionary*)info;

-(NSArray*)listTasks;
-(NSDictionary*)getTaskInfoForId:(NSString*)taskId;

-(NSString*)getStatusXML;

-(void)setQuitWhenDone:(BOOL)flag;

@end

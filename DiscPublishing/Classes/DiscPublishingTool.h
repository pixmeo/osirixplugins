//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 17.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const DPJobInfoDiscNameKey;
extern NSString* const DPJobInfoTemplatePathKey;
extern NSString* const DPJobInfoMergeValuesKey;
extern NSString* const DPJobInfoMediaTypeKey;
extern NSString* const DPJobInfoBurnSpeedKey;
extern NSString* const DPJobInfoObjectIDsKey;
extern NSString* const DPJobInfoDeleteWhenCompletedKey;

extern NSString* const DPTWillFinishLaunchingNotification;
extern NSString* const DPTWillTerminateNotification;
extern NSString* const DPTThreadInfoChangeNotification;
extern NSString* const DPTThreadChangedInfoKey;
extern NSString* const DPTJobCompletedNotification;

extern NSString* const DiscPublishingToolProxyName;

@protocol DiscPublishingTool <NSObject>

-(BOOL)ping;

-(void)growlWithTitle:(NSString*)title message:(NSString*)message;

-(void)setBinSelectionEnabled:(BOOL)enabled leftBinType:(NSUInteger)leftBinType rightBinType:(NSUInteger)rightBinType defaultBin:(NSUInteger)defaultBin;
-(NSString*)publishDiscWithRoot:(NSString*)root info:(NSDictionary*)info;

-(NSArray*)listTasks;
-(NSDictionary*)getTaskInfoForId:(NSString*)taskId;

-(NSString*)getStatusXML;

-(void)setQuitWhenDone:(BOOL)flag;

@end

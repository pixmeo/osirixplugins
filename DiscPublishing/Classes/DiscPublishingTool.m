//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 17.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "DiscPublishingTool.h"

NSString* const DPJobInfoDiscNameKey = @"DiscName";
NSString* const DPJobInfoTemplatePathKey = @"TemplatePath";
NSString* const DPJobInfoMergeValuesKey = @"MergeValues";
NSString* const DPJobInfoMediaTypeKey = @"MediaType";
NSString* const DPJobInfoBurnSpeedKey = @"BurnSpeed";
NSString* const DPJobInfoObjectIDsKey = @"ObjectIDs";
NSString* const DPJobInfoDeleteWhenCompletedKey = @"DeleteCompleted";

NSString* const DPTWillFinishLaunchingNotification = @"DPTWillFinishLaunchingNotification";
NSString* const DPTWillTerminateNotification = @"DPTWillTerminateNotification";
NSString* const DPTThreadInfoChangeNotification = @"DPTThreadInfoChangeNotification";
NSString* const DPTThreadChangedInfoKey = @"DPTThreadChangedInfoKey";
NSString* const DPTJobCompletedNotification = @"DPTJobCompletedNotification";

NSString* const DiscPublishingToolProxyName = @"DiscPublishingTool";
//
//  DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 17.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "DiscPublishingTool.h"

NSString* const DiscPublishingJobInfoDiscNameKey = @"DiscName";
NSString* const DiscPublishingJobInfoTemplatePathKey = @"TemplatePath";
NSString* const DiscPublishingJobInfoMergeValuesKey = @"MergeValues";
NSString* const DiscPublishingJobInfoMediaTypeKey = @"MediaType";
NSString* const DiscPublishingJobInfoBurnSpeedKey = @"BurnSpeed";

NSString* const DiscPublishingToolWillFinishLaunchingNotification = @"DiscPublishingToolWillFinishLaunchingNotification";
NSString* const DiscPublishingToolWillTerminateNotification = @"DiscPublishingToolWillTerminateNotification";
NSString* const DiscPublishingToolThreadInfoChangeNotification = @"DiscPublishingToolThreadInfoChangeNotification";
NSString* const DiscPublishingToolThreadChangedInfoKey = @"DiscPublishingToolThreadChangedInfoKey";

NSString* const DiscPublishingToolProxyName = @"DiscPublishingTool";
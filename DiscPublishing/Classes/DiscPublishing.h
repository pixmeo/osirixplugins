//
//  DiscPublishing.h
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import <OsiriX Headers/PluginFilter.h>


@class DiscPublishingFilesManager;

@interface DiscPublishing : PluginFilter {
	DiscPublishingFilesManager* _filesManager;
	NSTimer* robotReadyTimer;
	BOOL robotIsReady;
	NSTimer* toolAliveKeeperTimer;
}

+(DiscPublishing*)instance;

+(NSString*)baseDirPath;
+(NSString*)discCoverTemplatesDirPath;

@end

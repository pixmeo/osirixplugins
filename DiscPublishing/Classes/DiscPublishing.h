//
//  DiscPublishing.h
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import <OsiriXAPI/PluginFilter.h>


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

-(void)updateBinSelection;

@end

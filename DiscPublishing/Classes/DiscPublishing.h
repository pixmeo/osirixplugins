//
//  DiscPublishing.h
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import <OsiriX Headers/PluginFilter.h>


@class DiscPublisher, DiscPublishingFilesManager;

@interface DiscPublishing : PluginFilter {
	DiscPublisher* _discPublisher;
	DiscPublishingFilesManager* _filesManager;
}

+(DiscPublishing*)instance;

@property(readonly) DiscPublisher* discPublisher;

+(NSString*)baseDirPath;
+(NSString*)discCoverTemplatesDirPath;

@end

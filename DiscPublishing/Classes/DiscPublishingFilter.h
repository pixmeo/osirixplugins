//
//  DiscPublishingFilter.h
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import <OsiriX Headers/PluginFilter.h>


@class DiscPublisher, DiscPublishingFilesManager;

@interface DiscPublishingFilter : PluginFilter {
	DiscPublisher* _discPublisher;
	DiscPublishingFilesManager* _filesManager;
}

@property(readonly) DiscPublisher* discPublisher;

-(NSView*)prefsView;

@end

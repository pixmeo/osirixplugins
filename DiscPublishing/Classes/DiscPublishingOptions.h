//
//  DiscPublishingOptions.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/12/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <OsiriX Headers/DiscBurningOptions.h>


@interface DiscPublishingOptions : DiscBurningOptions {
	NSString* discCoverTemplatePath;
}

//extern NSString* const DiscPublishingOptionsDiscCoverTemplatePathArchivingKey;

@property(retain) NSString* discCoverTemplatePath;

@end

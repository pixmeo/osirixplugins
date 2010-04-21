//
//  DiscPublishingJob.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublisherJob.h"

extern const NSString* const DiscPublishingJobInfoDiscNameKey;
extern const NSString* const DiscPublishingJobInfoOptionsKey;
extern const NSString* const DiscPublishingJobInfoMergeValuesKey;

@interface DiscPublishingJob : DiscPublisherJob {
	NSString* _root;
	NSDictionary* _info;
}

@property(retain) NSString* root;
@property(retain) NSDictionary* info;

+(void)renderDiscCover:(NSString*)dcoverPath merge:(NSString*)mergePath into:(NSString*)outputJpgPath;

@end

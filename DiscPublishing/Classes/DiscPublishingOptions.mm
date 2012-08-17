//
//  DiscPublishingOptions.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/12/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingOptions.h"


@implementation DiscPublishingOptions

static NSString* const DiscPublishingOptionsBurnModeArchivingKey = @"burnMode";
static NSString* const DiscPublishingOptionsDiscCoverTemplatePathArchivingKey = @"discCoverTemplatePath";

@synthesize mode;
@synthesize discCoverTemplatePath;

-(id)copyWithZone:(NSZone*)zone {
	DiscPublishingOptions* copy = [super copyWithZone:zone];
	
    copy.mode = self.mode;
	copy.discCoverTemplatePath = [self.discCoverTemplatePath copyWithZone:zone];
	
	return copy;
}

-(void)dealloc {
	self.discCoverTemplatePath = NULL;
	[super dealloc];
}

-(void)encodeWithCoder:(NSCoder*)encoder {
	[super encodeWithCoder:encoder];
	[encoder encodeObject:[NSNumber numberWithInteger:self.mode] forKey:DiscPublishingOptionsBurnModeArchivingKey];
	[encoder encodeObject:self.discCoverTemplatePath forKey:DiscPublishingOptionsDiscCoverTemplatePathArchivingKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
	self = [super initWithCoder:decoder];
	self.mode = [[decoder decodeObjectForKey:DiscPublishingOptionsBurnModeArchivingKey] integerValue];
	self.discCoverTemplatePath = [decoder decodeObjectForKey:DiscPublishingOptionsDiscCoverTemplatePathArchivingKey];
	return self;
}

@end

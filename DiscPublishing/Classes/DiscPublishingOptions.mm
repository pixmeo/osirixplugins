//
//  DiscPublishingOptions.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/12/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingOptions.h"


@implementation DiscPublishingOptions

static NSString* const DPOptionsBurnModeArchivingKey = @"burnMode";
static NSString* const DPOptionsDiscCoverTemplatePathArchivingKey = @"discCoverTemplatePath";
static NSString* const DPOptionsDeleteOnCompletitionArchivingKey = @"deleteOnCompletition";
static NSString* const DPOptionsFSMatchFlagArchivingKey = @"fsMatchFlag";
static NSString* const DPOptionsFSMatchMountPathArchivingKey = @"fsMatchMountPath";
static NSString* const DPOptionsFSMatchTokensArchivingKey = @"fsMatchTokens";
static NSString* const DPOptionsFSMatchConditionArchivingKey = @"fsMatchCondition";
static NSString* const DPOptionsFSMatchDeleteArchivingKey = @"fsMatchDelete";
static NSString* const DPOptionsFSMatchDelayArchivingKey = @"fsMatchDelay";


@synthesize mode;
@synthesize discCoverTemplatePath;
@synthesize deleteOnCompletition;

@synthesize fsMatchFlag;
@synthesize fsMatchShareUrl;
@synthesize fsMatchTokens;
@synthesize fsMatchCondition;
@synthesize fsMatchDelete;
@synthesize fsMatchDelay;


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
    
	[encoder encodeObject:[NSNumber numberWithInteger:self.mode] forKey:DPOptionsBurnModeArchivingKey];
	[encoder encodeObject:self.discCoverTemplatePath forKey:DPOptionsDiscCoverTemplatePathArchivingKey];
	[encoder encodeObject:[NSNumber numberWithBool:self.deleteOnCompletition] forKey:DPOptionsDeleteOnCompletitionArchivingKey];
    
	[encoder encodeObject:[NSNumber numberWithBool:self.fsMatchFlag] forKey:DPOptionsFSMatchFlagArchivingKey];
	[encoder encodeObject:self.fsMatchShareUrl forKey:DPOptionsFSMatchMountPathArchivingKey];
	[encoder encodeObject:self.fsMatchTokens forKey:DPOptionsFSMatchTokensArchivingKey];
	[encoder encodeObject:[NSNumber numberWithBool:self.fsMatchCondition] forKey:DPOptionsFSMatchConditionArchivingKey];
	[encoder encodeObject:[NSNumber numberWithBool:self.fsMatchDelete] forKey:DPOptionsFSMatchDeleteArchivingKey];
	[encoder encodeObject:[NSNumber numberWithInteger:self.fsMatchDelay] forKey:DPOptionsFSMatchDelayArchivingKey];
}

-(id)initWithCoder:(NSCoder*)decoder {
	self = [super initWithCoder:decoder];
    
	self.mode = [[decoder decodeObjectForKey:DPOptionsBurnModeArchivingKey] integerValue];
	self.discCoverTemplatePath = [decoder decodeObjectForKey:DPOptionsDiscCoverTemplatePathArchivingKey];
	self.deleteOnCompletition = [[decoder decodeObjectForKey:DPOptionsDeleteOnCompletitionArchivingKey] boolValue];
    
    self.fsMatchFlag = [[decoder decodeObjectForKey:DPOptionsFSMatchFlagArchivingKey] boolValue];
    self.fsMatchShareUrl = [decoder decodeObjectForKey:DPOptionsFSMatchMountPathArchivingKey];
    self.fsMatchTokens = [decoder decodeObjectForKey:DPOptionsFSMatchTokensArchivingKey];
    self.fsMatchCondition = [[decoder decodeObjectForKey:DPOptionsFSMatchConditionArchivingKey] boolValue];
    self.fsMatchDelete = [[decoder decodeObjectForKey:DPOptionsFSMatchDeleteArchivingKey] boolValue];
    self.fsMatchDelay = [[decoder decodeObjectForKey:DPOptionsFSMatchDelayArchivingKey] integerValue];
    
	return self;
}

@end

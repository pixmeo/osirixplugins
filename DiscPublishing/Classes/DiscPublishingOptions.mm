//
//  DiscPublishingOptions.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/12/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingOptions.h"


@implementation DiscPublishingOptions

@synthesize discCoverTemplatePath;

-(id)copyWithZone:(NSZone*)zone {
	DiscPublishingOptions* copy = [super copyWithZone:zone];
	
	copy.discCoverTemplatePath = [self.discCoverTemplatePath copyWithZone:zone];
	
	return copy;
}

-(void)dealloc {
	self.discCoverTemplatePath = NULL;
	[super dealloc];
}

@end

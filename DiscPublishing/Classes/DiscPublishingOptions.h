//
//  DiscPublishingOptions.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/12/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <OsiriXAPI/DiscBurningOptions.h>

//#define BurnModeArchiving 0
#define BurnModePatient 1

@interface DiscPublishingOptions : DiscBurningOptions {
    NSInteger mode;
	NSString* discCoverTemplatePath;
}

@property(assign) NSInteger mode;
@property(retain) NSString* discCoverTemplatePath;

@end

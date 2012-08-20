//
//  NSUserDefaultsController+DiscPublishing.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSUserDefaults+DiscPublishing.h"


@interface NSUserDefaultsController (DiscPublishing)

+ (void)discPublishingInitialize;

//- (BOOL)discPublishingIsActive;

- (NSString*)DPServiceNameForId:(NSString*)sid;
- (NSUInteger)DPDelayForServiceId:(NSString*)sid;
- (DiscPublishingOptions*)DPOptionsForServiceId:(NSString*)sid;
//-(DiscPublishingOptions*)discPublishingArchivingModeOptions;

-(NSUInteger)discPublishingMediaTypeTagForBin:(NSUInteger)bin;
-(NSDictionary*)discPublishingMediaCapacities;

+ (BOOL)discPublishingIsValidPassword:(NSString*)password;

@end



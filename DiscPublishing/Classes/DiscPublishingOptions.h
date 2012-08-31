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
    BOOL deleteOnCompletition;
    
    BOOL fsMatchFlag;
    NSString* fsMatchShareUrl;
    NSArray* fsMatchTokens;
    BOOL fsMatchCondition;
    BOOL fsMatchDelete;
    NSInteger fsMatchDelay;
}

@property(assign) NSInteger mode;
@property(retain) NSString* discCoverTemplatePath;
@property(assign) BOOL deleteOnCompletition;

@property(assign) BOOL fsMatchFlag;
@property(retain) NSString* fsMatchShareUrl;
@property(retain) NSArray* fsMatchTokens;
@property(assign) BOOL fsMatchCondition;
@property(assign) BOOL fsMatchDelete;
@property(assign) NSInteger fsMatchDelay;

@end

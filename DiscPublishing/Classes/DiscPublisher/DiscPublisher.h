//
//  DiscPublisher.h
//  Primiera
//
//  Created by Alessandro Volz on 2/9/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <JobManager/PTJobManager.h>

@class DiscPublisherJob, DiscPublisherStatus;

@interface DiscPublisher : NSObject {
	@private
	NSMutableArray* _jobs;
	DiscPublisherStatus* _status;
}

@property(readonly) DiscPublisherStatus* status;

+(NSString*)baseDirPath;
+(NSString*)jobsDirPath;

+(void)initializeJobManager;
+(void)terminateJobManager;

-(DiscPublisherJob*)createJob;
-(DiscPublisherJob*)createPrintOnlyJob;

-(void)robot:(UInt32)robot systemAction:(UInt32)action;

@end

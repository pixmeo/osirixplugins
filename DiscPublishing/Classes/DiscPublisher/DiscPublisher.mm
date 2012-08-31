//
//  DiscPublisher.mm
//  Primiera
//
//  Created by Alessandro Volz on 2/9/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublisher.h"
#import "DiscPublisherJob.h"
#import "DiscPublisherStatus.h"
#import "DiscPublisher+Constants.h"
#import <PTRobot/PTRobot.h>
#import <JobManager/PTJobManager.h>
#import <OsiriXAPI/NSFileManager+N2.h>


@implementation DiscPublisher

@synthesize status = _status;

-(JM_BinSelection&)binSelection {
    return _binSelection;
}

+(NSString*)baseDirPath {
	NSString* path = [[[NSFileManager defaultManager] userApplicationSupportFolderForApp] stringByAppendingPathComponent:[self className]];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

+(NSString*)jobsDirPath {
	NSString* path = [[self baseDirPath] stringByAppendingPathComponent:@"Jobs"];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

+(NSString*)statusDirPath {
	NSString* path = [[self baseDirPath] stringByAppendingPathComponent:@"Status"];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

-(id)init {
	self = [super init];
	
	@try {
		[DiscPublisher initializeJobManager];
	} @catch (...) {
		[DiscPublisher terminateJobManager];
		@throw;
	}
    
	_jobs = [[NSMutableArray alloc] initWithCapacity:8];

	char filePath[512];
	UInt32 err = JM_GetStatusFile(filePath);
	ConditionalDiscPublisherJMErrorException(err);
	_status = [[DiscPublisherStatus alloc] initWithFileAtPath:[NSString stringWithUTF8String:filePath]];
    
	return self;
}

-(void)dealloc {
	[DiscPublisher terminateJobManager];
	[_status release];
	[_jobs release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Wrapper methods for c functions

+(void)initializeJobManager {
    [NSFileManager.defaultManager removeItemAtPath:[DiscPublisher baseDirPath] error:NULL];
    
	UInt32 err = JM_Initialize((char*)[DiscPublisher baseDirPath].UTF8String,
							   (char*)[[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey] UTF8String],
							   (char*)[[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey] UTF8String],
							   YES);
	ConditionalDiscPublisherJMErrorException(err);
}

+(void)terminateJobManager {
	UInt32 err = JM_Terminate();
	ConditionalDiscPublisherJMErrorException(err);
}

-(id)createJobOfClass:(Class)c {
	id job = [[c alloc] initWithDiscPublisher:self];
	//	[_jobs addObject:job]; // TODO: remove completed jobs
	return [job autorelease];
}

-(DiscPublisherJob*)createJob {
	return [self createJobOfClass:[DiscPublisherJob class]];
}

-(DiscPublisherJob*)createPrintOnlyJob {
	DiscPublisherJob* job = [self createJob];
	job.type = JP_JOB_PRINT_ONLY;
	return job;
}

-(void)robot:(UInt32)robot systemAction:(UInt32)action {
	UInt32 err = JM_RobotSystemAction(robot, action);
	ConditionalDiscPublisherJMErrorException(err);
}

-(void)applyBinSelection:(JM_BinSelection*)bs {
    NSLog(@"Applying bin selection: %d,%d,%d,%d", bs->fEnabled, bs->nLeftBinType, bs->nRightBinType, bs->nDefaultBin);
    memcpy(&_binSelection, bs, sizeof(JM_BinSelection));
    UInt32 err = JM_SetBinSelection(bs);
    if (err != JM_OK)
        [NSException raise:NSGenericException format:@"JM_SetBinSelection returned %d", (int)err];
}

@end

//
//  DiscPublisherJob.mm
//  Primiera
//
//  Created by Alessandro Volz on 2/19/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublisherJob.h"
#import "DiscPublisherStatus.h"
#import "DiscPublisher+Constants.h"
#import "NSFileManager+DiscPublisher.h"
#import "NSXMLNode+DiscPublisher.h"
#import "NSString+DiscPublisher.h"


@implementation DiscPublisherJob

@synthesize discPublisher = _discPublisher;
@synthesize uid = _uid;
@synthesize xmlFilePath = _xmlFilePath;

@synthesize status = _status;

@synthesize author = _author;
@synthesize numCopies = _numCopies;
@synthesize type = _type;
@synthesize discType = _discType;
@synthesize robotId = _robotId;

@synthesize writeSpeed = _writeSpeed;
@synthesize volumeName = _volumeName;
@synthesize verify = _verify;
@synthesize closeDisc = _closeDisc;
@synthesize fileSys = _fileSys;
@synthesize printFirst = _printFirst;
@synthesize printReject = _printReject;
@synthesize files = _files;

@synthesize innerDiameter = _innerDiameter;
@synthesize outerMargin = _outerMargin;
@synthesize printQuality = _printQuality;
@synthesize printFile = _printFile;
@synthesize printMergeFile = _printMergeFile;

-(id)initWithDiscPublisher:(DiscPublisher*)discPublisher {
	self = [super init];
	_discPublisher = discPublisher;
	
	self.author = NSFullUserName();
	self.numCopies = 1;
	self.type = JP_JOB_UNKNOWN;
	self.discType = DISCTYPE_UNKNOWN;
	
	self.writeSpeed = 1000;
	self.volumeName = @"Untitled";
	self.verify = NO;
	self.closeDisc = YES;
	self.fileSys = FileSys_ISO_Level_2_Long;
	self.printFirst = NO;
	self.printReject = NO;
	_files = [[NSMutableArray alloc] initWithCapacity:512];
	
	self.innerDiameter = 230;
	self.outerMargin = 10;
	self.printQuality = PQ_BETTER;
	
	return self;
}

-(void)dealloc {
	self.volumeName = NULL;
	[_files release];
	
	self.author = NULL;
	self.printFile = NULL;
	self.printMergeFile = NULL;
	_discPublisher = NULL;
	
	if (self.status.dwJobState == JOB_COMPLETED)
		[[NSFileManager defaultManager] removeItemAtPath:self.xmlFilePath error:NULL];
	self.xmlFilePath = NULL;
	
	NSLog(@"[DiscPublisherJob dealloc]");
	
	[super dealloc];
}


-(NSXMLElement*)ptJob {
	NSMutableArray* job = [NSMutableArray arrayWithCapacity:3];
	
	NSXMLElement* properties = [NSXMLNode elementWithName:@"JOB_PROPERTIES"];
	[job addObject:properties];
	[properties addChild:[NSXMLNode elementWithName:@"JOB_NAME" text:[[self.xmlFilePath lastPathComponent] stringByDeletingPathExtension]]];
	[properties addChild:[NSXMLNode elementWithName:@"JOB_NAME_FROM" text:[[self.xmlFilePath lastPathComponent] stringByDeletingPathExtension]]];
	[properties addChild:[NSXMLNode elementWithName:@"ROBOT_ID" unsignedInt:self.robotId]];
	[properties addChild:[NSXMLNode elementWithName:@"AUTHOR" text:self.author]];
	[properties addChild:[NSXMLNode elementWithName:@"COPIES" unsignedInt:self.numCopies]];
	[properties addChild:[NSXMLNode elementWithName:@"JOB_TYPE" unsignedInt:self.type]];
	[properties addChild:[NSXMLNode elementWithName:@"INT_JOB_TYPE" unsignedInt:7]]; // TODO: ???
	[properties addChild:[NSXMLNode elementWithName:@"DELETE_TEMP_IMAGE_FILES" bool:NO]];
	[properties addChild:[NSXMLNode elementWithName:@"DELETE_TEMP_MERGE_FILES" bool:NO]];
	[properties addChild:[NSXMLNode elementWithName:@"DISC_TYPE" text:[DiscPublisherJob DiscType:self.discType]]];
	
	if (self.printFile) {
		NSXMLElement* printing = [NSXMLNode elementWithName:@"PRINTING"];
		[job addObject:printing];
		if (self.printFile) [printing addChild:[NSXMLNode elementWithName:@"FILE" text:self.printFile]];
		if (self.printFile) [printing addChild:[NSXMLNode elementWithName:@"FILE_FROM" text:self.printFile]];
		if (self.printMergeFile) [printing addChild:[NSXMLNode elementWithName:@"MERGE_FILE" text:self.printMergeFile]];
		if (self.printMergeFile) [printing addChild:[NSXMLNode elementWithName:@"MERGE_FILE_FROM" text:self.printMergeFile]];
		[printing addChild:[NSXMLNode elementWithName:@"INNER_DIAMETER" unsignedInt:self.innerDiameter]];
		[printing addChild:[NSXMLNode elementWithName:@"MEDIA" text:@"TuffCoat Plus CD"]]; // TODO: TuffCoat Plus CD, TuffCoat with Aquaguard, ...
		[printing addChild:[NSXMLNode elementWithName:@"OUTER_MARGIN" unsignedInt:self.outerMargin]];
		[printing addChild:[NSXMLNode elementWithName:@"PRINT_QUALITY" unsignedInt:self.printQuality]];
	}
	
	if (self.files.count) {
		NSXMLElement* recording = [NSXMLNode elementWithName:@"RECORDING"];
		[job addObject:recording];
		NSXMLElement* settings = [NSXMLNode elementWithName:@"SETTINGS"];
		[recording addChild:settings];
		[settings addChild:[NSXMLNode elementWithName:@"WRITE_SPEED" unsignedInt:self.writeSpeed]];
		[settings addChild:[NSXMLNode elementWithName:@"DEST_DRIVE" unsignedInt:0]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"FILESYS" unsignedInt:self.fileSys]];
		[settings addChild:[NSXMLNode elementWithName:@"MULTISESSION" unsignedInt:0]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"FILESYS_BRIDGE" unsignedInt:1]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"VERIFY" bool:self.verify]];
		[settings addChild:[NSXMLNode elementWithName:@"CLOSE_DISC" bool:self.closeDisc]];
		[settings addChild:[NSXMLNode elementWithName:@"SAO" bool:NO]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"TEST_RECORD" bool:NO]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"MODE2" bool:NO]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"SETNOW" bool:NO]]; // TODO: var
		[settings addChild:[NSXMLNode elementWithName:@"PRINT_REJECT" bool:self.printReject]];
		[settings addChild:[NSXMLNode elementWithName:@"VOLUME" text:self.volumeName]];
		NSXMLElement* source = [NSXMLNode elementWithName:@"SOURCE"];
		[recording addChild:source];
		NSXMLElement* filesFrom = [NSXMLNode elementWithName:@"FILES_FROM"];
		[source addChild:filesFrom];
		NSXMLElement* files = [NSXMLNode elementWithName:@"FILES"];
		[source addChild:files];
		for (NSString* path in self.files) {
			[filesFrom addChild:[NSXMLNode elementWithName:@"FILE" text:path]];
			[files addChild:[NSXMLNode elementWithName:@"FILE" text:path]];
		}
	}
	
	return [NSXMLNode elementWithName:@"PTJOB" children:job attributes:NULL];
}

-(NSData*)xmlData {
	return [[[[NSXMLDocument alloc] initWithRootElement:[self ptJob]] autorelease] XMLDataWithOptions:NSXMLDocumentTidyXML];
}

-(void)start {
	NSString* jobsDirPath = [DiscPublisher jobsDirPath];
	self.xmlFilePath = [[NSFileManager defaultManager] tmpFilePathInDir:jobsDirPath];
	
	NSError* error = NULL;
	[[NSFileManager defaultManager] createDirectoryAtPath:jobsDirPath withIntermediateDirectories:YES attributes:NULL error:&error];
	[[self xmlData] writeToFile:self.xmlFilePath options:NULL error:&error];
	if (error) [NSException raise:DiscPublisherException format:@"%@", [error localizedDescription]];
	
	NSLog(@"Job:\n\n%@\n\n", [[[NSString alloc] initWithData:[self xmlData] encoding:NSUTF8StringEncoding] autorelease]);
	
	UInt32 err = JM_NewJob((char*)self.xmlFilePath.UTF8String, &_uid);
	ConditionalDiscPublisherJMErrorException(err);
}

-(void)abort {
	UInt32 err = JM_CancelJob(self.robotId, self.uid);
	ConditionalDiscPublisherJMErrorException(err);
}

-(NSXMLNode*)xmlStatus {
	[self.discPublisher.status refresh];
	
	NSError* error = NULL;
	NSArray* nodes = [self.discPublisher.status.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/JOBS/JOB" constants:NULL error:&error];
	if (error) [NSException raise:DiscPublisherException format:@"%@", [error localizedDescription]];
	
	if (!nodes || !nodes.count) [NSException raise:DiscPublisherException format:@"Status information not available yet"];
	
	for (NSXMLNode* node in nodes)
		if ([[[node childNamed:@"JOB_ID"] stringValue] floatValue] == self.uid)
			return node;
	
	[NSException raise:DiscPublisherException format:@"Status information not available"];
	return NULL;
}

-(const JobStatus&)refreshStatus {
	UInt32 err = JP_GetJobStatus(self.uid, &_status);
	ConditionalDiscPublisherJMErrorException(err);
	return _status;
}

-(NSString*)statusString {
	@try {
		[self refreshStatus];
	} @catch (NSException* e) {
		return @"Starting job...";
	}
	
	if (self.status.dwJobState == JOB_COMPLETED)
		return @"Completed.";
	
	return [[NSString stringWithUTF8String:self.status.tszStatusString] suspendedString];
}

+(NSString*)DiscType:(UInt32)type {
	switch (type) {
		case DISCTYPE_CD: return @"CD";
		case DISCTYPE_DVD: return @"DVD";
		case DISCTYPE_DVDDL: return @"DVDDL";
		case DISCTYPE_BR: return @"BR";
		case DISCTYPE_BR_DL: return @"BR_DL";
		default: return @"UNKNOWN";
	}
}

@end

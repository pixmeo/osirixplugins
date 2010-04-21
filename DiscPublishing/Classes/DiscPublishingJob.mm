//
//  DiscPublishingJob.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingJob.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublishingOptions.h"
#import "CSV.h"
#import "NSFileManager+DiscPublisher.h"


@implementation DiscPublishingJob

const NSString* const DiscPublishingJobInfoDiscNameKey = @"DiscName";
const NSString* const DiscPublishingJobInfoOptionsKey = @"Options";
const NSString* const DiscPublishingJobInfoMergeValuesKey = @"MergeValues";

@synthesize root = _root;
@synthesize info = _info;

+(void)renderDiscCover:(NSString*)dcoverPath merge:(NSString*)mergePath into:(NSString*)outputJpgPath {
	NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"PTRobot.framework/Resources/ScriptsPTR.scpt"];
	NSLog(@"%@", scptPath);
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:[errors description]];
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"CreateDCFPreviewForPrintingMergePTR" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[NSAppleEventDescriptor descriptorWithString:dcoverPath] atIndex:1];
	[params insertDescriptor:[NSAppleEventDescriptor descriptorWithString:outputJpgPath] atIndex:2];
	[params insertDescriptor:[NSAppleEventDescriptor descriptorWithString:mergePath] atIndex:3];
	[params insertDescriptor:[NSAppleEventDescriptor descriptorWithString:@"1"] atIndex:4];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	if (![appleScript executeAppleEvent:event error:&errors])
		[NSException raise:NSGenericException format:[errors description]];
	
	[appleScript release];
}

-(void)start {
	[self.info writeToFile:[self.root stringByAppendingPathExtension:@"plist"] atomically:YES];
	
	DiscPublishingOptions* options = [self.info objectForKey:DiscPublishingJobInfoOptionsKey];

	self.discType = [[NSUserDefaultsController sharedUserDefaultsController] mediaType];
	self.volumeName = [self.info objectForKey:DiscPublishingJobInfoDiscNameKey];

//	self.type = JP_JOB_PRINT_ONLY;
	self.type = JP_JOB_DATA;
	for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.root error:NULL])
		[self.files addObject:[self.root stringByAppendingPathComponent:subpath]];
	
	// the merging of the template and csv is buggy in the framework, we do this ourselves
	NSString* csvFile = [self.root stringByAppendingPathExtension:@"csv"];
	[[CSV stringFromArray:[self.info objectForKey:DiscPublishingJobInfoMergeValuesKey]] writeToFile:csvFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	self.printFile = [self.root stringByAppendingPathExtension:@"jpg"];
	[DiscPublishingJob renderDiscCover:options.discCoverTemplatePath merge:csvFile into:self.printFile];
	[[NSFileManager defaultManager] removeItemAtPath:csvFile error:NULL];
	
	[super start];
}

-(void)dealloc {
	[[NSFileManager defaultManager] removeItemAtPath:self.printFile error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:self.root error:NULL];
	self.root = NULL;
	self.info = NULL;
	[super dealloc];
}



@end

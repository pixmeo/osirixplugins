//
//  DiscPublishingJob.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 4/14/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingJob.h"
//#import "DiscPublishingOptions.h"
#import <OsiriXAPI/N2CSV.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import "DiscPublishingJob+Info.h"


@implementation DiscPublishingJob

@synthesize root = _root;
@synthesize info = _info;

+(void)renderDiscCover:(NSString*)dcoverPath merge:(NSString*)mergePath into:(NSString*)outputJpgPath {
	// make sure the system knows where to find Disc Cover 3 PE.app, (com.belightsoft.DiscCover3.pe)
	
    NSString* myPath = [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"PTRobot.framework/Resources/Disc Cover 3 PE.app"];
    
    NSString* knownBundlePath = nil;
    @try {
        knownBundlePath = [NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.belightsoft.DiscCover3.pe"];
    } @catch (...) {
    }
    
    NSString* knownNamePath = nil;
    @try {
        knownNamePath = [NSWorkspace.sharedWorkspace fullPathForApplication:@"Disc Cover 3 PE"];
    } @catch (...) {
    }
    
    if (![knownBundlePath isEqualToString:myPath] || ![knownNamePath isEqualToString:myPath]) {
        [NSWorkspace.sharedWorkspace launchApplication:myPath];
    }
    
    // execute applescript
    
    NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] privateFrameworksPath] stringByAppendingPathComponent:@"PTRobot.framework/Resources/ScriptsPTR.scpt"];
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:@"%@", [errors description]];
	
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
		[NSException raise:NSGenericException format:@"%@", [errors description]];
	
	[appleScript release];
}

-(void)start {
	[self.info writeToFile:[self.root stringByAppendingPathExtension:@"plist"] atomically:YES];
	
//	DiscPublishingOptions* options = [self.info objectForKey:DiscPublishingJobInfoOptionsKey];
	NSString* templatePath = [self.info objectForKey:DiscPublishingJobInfoTemplatePathKey];

	self.discType = [[self.info objectForKey:DiscPublishingJobInfoMediaTypeKey] unsignedIntValue];
	self.volumeName = [self.info objectForKey:DiscPublishingJobInfoDiscNameKey];
	self.writeSpeed = [[self.info objectForKey:DiscPublishingJobInfoBurnSpeedKey] intValue]*10;
	
//	NSLog(@"starting %@ (%@)", [NSString stringWithContentsOfFile:[[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DiscPublishingMode.switch"] encoding:NSUTF8StringEncoding error:NULL], [[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DiscPublishingMode.switch"]);
	if ([@"TEST" isEqual:[NSString stringWithContentsOfFile:[[[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]] stringByAppendingPathComponent:@"DiscPublishingMode.switch"] encoding:NSUTF8StringEncoding error:NULL]])
		 self.type = JP_JOB_PRINT_ONLY;
	else {
		 self.type = JP_JOB_DATA;
		for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.root error:NULL])
			[self.files addObject:[self.root stringByAppendingPathComponent:subpath]];
	}
	
//	NSLog(@"self.info.descriptionself.info.descriptionself.info.description\n%@", self.info.description);
	
	// the merging of the template and csv is buggy in the framework, we do this ourselves
	NSString* csvFile = [self.root stringByAppendingPathExtension:@"csv"];
	[[N2CSV stringFromArray:[self.info objectForKey:DiscPublishingJobInfoMergeValuesKey]] writeToFile:csvFile atomically:YES encoding:NSMacOSRomanStringEncoding error:NULL];
	self.printFile = [self.root stringByAppendingPathExtension:@"jpg"];
	
    [DiscPublishingJob renderDiscCover:templatePath merge:csvFile into:self.printFile];
    
    [[NSFileManager defaultManager] removeItemAtPath:csvFile error:NULL];
	
	[super start];
}

-(void)dealloc {
	[[NSFileManager defaultManager] removeItemAtPath:self.printFile error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:self.root error:NULL];
	[[NSFileManager defaultManager] removeItemAtPath:[self.root stringByAppendingPathExtension:@"plist"] error:NULL];
	self.root = NULL;
	self.info = NULL;
	[super dealloc];
}



@end

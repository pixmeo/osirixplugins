//
//  DiscPublishing.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishing.h"
#import "ThreadsWindowController.h"
#import "DiscPublishingFilesManager.h"
#import "ThreadsManager.h"
#import "DiscPublisher.h"
#import <OsiriX Headers/NSFileManager+N2.h>
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublisherStatus.h"
#import <QTKit/QTKit.h>
#import <OsiriX Headers/PreferencesWindowController.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/DicomAlbum.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX Headers/DicomSeries.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingTasksManager.h"
#import "DiscPublishingOptions.h"
#import "NSAppleEventDescriptor+N2.h"

//#include "NSThread+N2.h"

@implementation DiscPublishing

static DiscPublishing* discPublishingInstance = NULL;
+(DiscPublishing*)instance {
	return discPublishingInstance;
}

-(void)toolSetQuitWhenDone:(BOOL)flag {
	NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"DiscPublishingTool.scpt"];
	NSLog(@"scpt %@", scptPath);
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:[errors description]];
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"SetQuitWhenDone" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[[NSNumber numberWithInt:flag] appleEventDescriptor] atIndex:1];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	NSAppleEventDescriptor* result = [appleScript executeAppleEvent:event error:&errors];
	if (!result)
		[NSException raise:NSGenericException format:errors.description];	
}

-(void)initPlugin {
	discPublishingInstance = self;
	
	[QTMovie movie]; // this initializes the QT kit on the main thread
	[NSUserDefaultsController discPublishingInitialize];
	
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"DiscPublishingPreferences" inBundle:bundle withTitle:NSLocalizedString(@"Disc Publishing", NULL) image:[[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Icon" ofType:@"png"]] autorelease]]; // TODO: icon
	
	[[ThreadsWindowController defaultController] window];
	
//	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"ch.osirix.discpublishing.tool" options:NSWorkspaceLaunchWithoutAddingToRecents|NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:NULL launchIdentifier:NULL];
	[self toolSetQuitWhenDone:NO];
	[DiscPublishingTasksManager defaultManager];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeOsirixWillTerminate:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
	
/*	NSThread* bidon = [[NSThread alloc] initWithTarget:self selector:@selector(bidonThread:) object:NULL];
//	bidon.supportsCancel = YES;
	[[ThreadsManager defaultManager] addThread:bidon];
	[bidon start];*/
}

-(void)observeOsirixWillTerminate:(NSNotification*)notification {
	NSLog(@"observeOsirixWillTerminate");
	[self toolSetQuitWhenDone:YES];
}

/*-(void)bidonThread:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSThread* thread = [NSThread currentThread];
	thread.name = @"Bidon...";
	
	while (!thread.isCancelled) {
		[NSThread sleepForTimeInterval:0.001];
		thread.status = [NSString stringWithFormat:@"Time: %.2f", [NSDate timeIntervalSinceReferenceDate]];
	}
	
	[pool release];
}*/

-(void)dealloc {
	NSLog(@"DiscPublishing dealloc");
	[[_filesManager invalidate] release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
	[super dealloc];
}

-(void)filesIn:(id)obj into:(NSMutableArray*)files {
	if ([obj isKindOfClass:[NSArray class]])
		for (id sobj in obj)
			[self filesIn:sobj into:files];
	else
	if ([obj isKindOfClass:[DicomAlbum class]])
		for (id study in ((DicomAlbum*)obj).studies)
			[self filesIn:study into:files];
	else
	if ([obj isKindOfClass:[DicomStudy class]])
		for (id series in ((DicomStudy*)obj).series)
			[self filesIn:series into:files];
	else
	if ([obj isKindOfClass:[DicomSeries class]])
		[files addObjectsFromArray:[((DicomSeries*)obj).images allObjects]];
}

-(NSArray*)filesIn:(NSArray*)arr {
	NSMutableArray* files = [NSMutableArray array];
	[self filesIn:arr into:files];
	return files;
}

-(long)filterImage:(NSString*)menuName {
	BrowserController* bc = [BrowserController currentBrowser];
	NSArray* sel = [bc databaseSelection];
	
	[[[DiscPublishingPatientDisc alloc] initWithFiles:[self filesIn:sel] options:[[NSUserDefaultsController sharedUserDefaultsController] discPublishingPatientModeOptions]] autorelease];
	
	return 0;
}

+(NSString*)baseDirPath {
	NSString* path = [[[NSFileManager defaultManager] userApplicationSupportFolderForApp] stringByAppendingPathComponent:[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey]];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

+(NSString*)discCoverTemplatesDirPath {
	NSString* path = [[self baseDirPath] stringByAppendingPathComponent:@"Disc Cover Templates"];
	return [[NSFileManager defaultManager] confirmDirectoryAtPath:path];
}

@end

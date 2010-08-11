//
//  DiscPublishing.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishing.h"
#import "DiscPublishing+Tool.h"
#import <OsiriX Headers/ActivityWindowController.h>
#import "DiscPublishingFilesManager.h"
#import <OsiriX Headers/ThreadsManager.h>
#import <OsiriX Headers/NSFileManager+N2.h>
#import "NSUserDefaultsController+DiscPublishing.h"
#import <OsiriX Headers/NSUserDefaultsController+N2.h>
#import <QTKit/QTKit.h>
#import <OsiriX Headers/PreferencesWindowController.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/DicomAlbum.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX Headers/DicomSeries.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingTasksManager.h"
#import "DiscPublishingOptions.h"
#import <OsiriX Headers/NSAppleEventDescriptor+N2.h>
#import <PTRobot/PTRobot.h>

//#include "NSThread+N2.h"

@implementation DiscPublishing

static DiscPublishing* discPublishingInstance = NULL;
+(DiscPublishing*)instance {
	return discPublishingInstance;
}

-(void)initPlugin {
	discPublishingInstance = self;
	
	[QTMovie movie]; // this initializes the QT kit on the main thread
	[NSUserDefaultsController discPublishingInitialize];
	
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"DiscPublishingPreferences" inBundle:bundle withTitle:NSLocalizedString(@"Disc Publishing", NULL) image:[[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Icon" ofType:@"png"]] autorelease]]; // TODO: icon
	
//	[[ActivityWindowController defaultController] window];
	
//	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"ch.osirix.discpublishing.tool" options:NSWorkspaceLaunchWithoutAddingToRecents|NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:NULL launchIdentifier:NULL];
	[DiscPublishing SetQuitWhenDone:NO];
	[DiscPublishingTasksManager defaultManager];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
	robotReadyTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(robotReadyTimerCallback:) userInfo:NULL repeats:YES];
	[robotReadyTimer fire];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeOsirixWillTerminate:) name:NSApplicationWillTerminateNotification object:[NSApplication sharedApplication]];
	
/*	NSThread* bidon = [[NSThread alloc] initWithTarget:self selector:@selector(bidonThread:) object:NULL];
//	bidon.supportsCancel = YES;
	[[ThreadsManager defaultManager] addThreadAndStart:bidon];
*/
}

-(void)observeOsirixWillTerminate:(NSNotification*)notification {
	[DiscPublishing SetQuitWhenDone:YES];
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
	[robotReadyTimer invalidate]; robotReadyTimer = NULL;
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
	
	[[[[DiscPublishingPatientDisc alloc] initWithFiles:[self filesIn:sel] options:[[NSUserDefaultsController sharedUserDefaultsController] discPublishingPatientModeOptions]] autorelease] start];
	
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

-(void)updateBinSelection {
	if (!robotIsReady)
		return;
	
	NSString* xml = [DiscPublishing GetStatusXML];
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
	NSArray* bins = [doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL];
	
//#warning: this MUST be enabled when releasing
	if (bins.count == 1) {
		[DiscPublishing SetBinSelection:NO leftBinMediaType:0 rightBinMediaType:0 defaultBin:LOCATION_REJECT];
	} else
	if (bins.count == 2) {
		NSUserDefaultsController* defaultsC = [NSUserDefaultsController sharedUserDefaultsController];
		[DiscPublishing SetBinSelection:YES leftBinMediaType:[defaultsC discPublishingMediaTypeTagForBin:1] rightBinMediaType:[defaultsC discPublishingMediaTypeTagForBin:0] defaultBin:LOCATION_REJECT];
	} else {
		NSLog(@"Warning: we didn't expect having to handle more than 2 bins...");
	}
	
	[doc release];
}

-(void)robotReadyTimerCallback:(NSTimer*)timer {
	@try {
		NSString* xml = [DiscPublishing GetStatusXML];
		[robotReadyTimer invalidate]; robotReadyTimer = NULL;
		// this will only happen ONCE
		robotIsReady = YES;
		[self updateBinSelection];
		NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:0] options:NULL context:NULL];
//#warning: this MUST be enabled when releasing
		if ([[doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL] count] > 1)
			[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:1] options:NULL context:NULL];
	} @catch (NSException* e) {
		NSLog(@"%@", e);
	} 
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"plugin observeValueForKeyPath:%@", keyPath);
	
	if ([keyPath hasSuffix:DiscPublishingMediaTypeTagSuffix]) {
		[self updateBinSelection];
	}
}

@end

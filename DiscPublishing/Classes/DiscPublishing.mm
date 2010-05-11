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
#import "NSFileManager+DiscPublisher.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublisherStatus.h"
#import <QTKit/QTKit.h>
#import <OsiriX Headers/PreferencesWindowController.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/DicomAlbum.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX Headers/DicomSeries.h>
#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingOptions.h"

//#include "NSThread+N2.h"

@implementation DiscPublishing

static DiscPublishing* discPublishingInstance = NULL;
+(DiscPublishing*)instance {
	return discPublishingInstance;
}

-(void)initPlugin {
	discPublishingInstance = self;
	
	[QTMovie movie]; // this initializes the QT kit on the main thread
	[NSUserDefaultsController initializeDiscPublishing];
	
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	
	[PreferencesWindowController addPluginPaneWithResourceNamed:@"DiscPublishingPreferences" inBundle:bundle withTitle:NSLocalizedString(@"Disc Publishing", NULL) image:[[[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Icon" ofType:@"png"]] autorelease]]; // TODO: icon
	
	[[ThreadsWindowController defaultController] window];
	
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"ch.osirix.discpublishing.tool" options:NSWorkspaceLaunchWithoutAddingToRecents|NSWorkspaceLaunchAsync|NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:NULL launchIdentifier:NULL];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
/*	NSThread* bidon = [[NSThread alloc] initWithTarget:self selector:@selector(bidonThread:) object:NULL];
//	bidon.supportsCancel = YES;
	[[ThreadsManager defaultManager] addThread:bidon];
	[bidon start];*/
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
	[[_filesManager invalidate] release];
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
	
	[[[DiscPublishingPatientDisc alloc] initWithFiles:[self filesIn:sel] options:[[NSUserDefaultsController sharedUserDefaultsController] patientModeOptions]] autorelease];
	
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

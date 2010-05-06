//
//  DiscPublishing.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishing.h"
#import "ThreadsWindowController.h"
#import "DiscPublishingFilesManager.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadsManager.h"
#import "DiscPublisher.h"
#import "NSFileManager+DiscPublisher.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublisherStatus.h"
#import <QTKit/QTKit.h>
#import <OsiriX Headers/PreferencesWindowController.h>


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
}

-(void)dealloc {
	[[_filesManager invalidate] release];
	[super dealloc];
}

-(long)filterImage:(NSString*)menuName {
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

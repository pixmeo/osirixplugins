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

@synthesize discPublisher = _discPublisher;

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
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
	[[[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisher:) object:NULL] autorelease] start];
}

-(void)dealloc {
	[[_filesManager invalidate] release];
	[super dealloc];
}

-(long)filterImage:(NSString*)menuName {
	return 0;
}

-(void)initDiscPublisher:(id)obj {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	NSThread* thread = [NSThread currentThread];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:thread name:@"Initializing Disk Publisher..."];
	[[ThreadsManager defaultManager] setSupportsCancel:YES forThread:thread];
	
	while (![thread isCancelled] && !_discPublisher)
		@try {
			_discPublisher = [[DiscPublisher alloc] init];
			
			for (NSNumber* robotId in self.discPublisher.status.robotIds)
				[self.discPublisher robot:robotId.unsignedIntValue systemAction:PTACT_IGNOREINKLOW];
			
			while (![thread isCancelled]) @try {
				if ([self.discPublisher.status allRobotsAreIdle])
					break;
			} @catch (NSException* e) {
				NSLog(@"[DiscPublishingFilter initDiscPublisher:] exception: %@", e);
			} @finally {
				[NSThread sleepForTimeInterval:0.5];
			}
		} @catch (NSException* e) {
			[threadInfo setStatus:[NSString stringWithFormat:@"Initialization error %@, is any robot connected to the computer?", e]];
			[NSThread sleepForTimeInterval:5];
		}
	
	[pool release];
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

//
//  DiscPublishing.m
//  DiscPublishing
//
//  Copyright (c) 2010 OsiriX. All rights reserved.
//

#import "DiscPublishing.h"
#import "DiscPublishingPrefsViewController.h"
#import "ThreadsWindowController.h"
#import "DiscPublishingFilesManager.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadsManager.h"
#import "DiscPublisher.h"
#import "NSFileManager+DiscPublisher.h"
#import "DiscPublisherStatus.h"
#import <QTKit/QTKit.h>


@implementation DiscPublishing

@synthesize discPublisher = _discPublisher;

-(void)initPlugin {
	[QTMovie movie]; // this initializes the QT kit on the main thread
	
	NSWindow* window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 300) styleMask:NSTitledWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setContentView:[self prefsView]];
	[window orderFront:self];
	
	[[ThreadsWindowController defaultController] window];
	
	_filesManager = [[DiscPublishingFilesManager alloc] init];
	
	[[[[NSThread alloc] initWithTarget:self selector:@selector(initDiscPublisher:) object:NULL] autorelease] start];

}

-(void)dealloc {
	[[_filesManager invalidate] release];
	[super dealloc];
}

-(NSView*)prefsView {
	return [[[DiscPublishingPrefsViewController alloc] init] view];
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

+(CGFloat)mediaCapacityBytesForMediaType:(UInt32)mediaType {
	switch (mediaType) {
		case DISCTYPE_CD: return 700*1000000; // 700 MB
		case DISCTYPE_DVD: return 4.7*1000000000; // 4.7 GB
		case DISCTYPE_DVDDL: return 8.5*1000000000; // 8.5 GB
		case DISCTYPE_BR: return 25.0*1000000000; // 25 GB
		case DISCTYPE_BR_DL: return 50.0*1000000000; // 50 GB
		default: return 0;
	}	
}

@end

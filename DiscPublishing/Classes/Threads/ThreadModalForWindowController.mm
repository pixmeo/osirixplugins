//
//  ThreadModalForWindowm.m
//  ManualBindings
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "ThreadModalForWindowController.h"
#import "ThreadsManager.h"
#import "ThreadsManagerThreadInfo.h"


@implementation ThreadModalForWindowController

@synthesize threadInfo = _threadInfo;
@synthesize docWindow = _docWindow;
@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize titleField = _titleField;
@synthesize statusField = _statusField;

-(id)initWithThread:(ThreadsManagerThreadInfo*)threadInfo window:(NSWindow*)docWindow {
	self = [super initWithWindowNibName:@"ThreadModalForWindow"];
	
	_docWindow = [docWindow retain];
	_threadInfo = [threadInfo retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadCompletedNotification:) name:ThreadsManagerThreadCompletedNotification object:_threadInfo];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadCancelledNotification:) name:ThreadsManagerThreadCancelledNotification object:_threadInfo];

	[NSApp beginSheet:self.window modalForWindow:self.docWindow modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];

	return self;	
}

-(void)awakeFromNib {
	[self.progressIndicator setUsesThreadedAnimation:YES];
	[self.progressIndicator startAnimation:self];
	
    [self.titleField bind:@"value" toObject:self.threadInfo withKeyPath:@"thread.name" options:NULL];
    [self.statusField bind:@"value" toObject:self.threadInfo withKeyPath:@"status" options:NULL];
    [self.cancelButton bind:@"enabled" toObject:self.threadInfo withKeyPath:@"supportsCancel" options:NULL];
	[_threadInfo addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)dealloc {
	[self.threadInfo removeObserver:self forKeyPath:@"progress"];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:ThreadsManagerThreadCompletedNotification object:_threadInfo];
	
	[_threadInfo release];
	[_docWindow release];
	
	[super dealloc]; 
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.threadInfo)
		if ([keyPath isEqual:@"progress"]) {
			[self.progressIndicator setMinValue:0];
			[self.progressIndicator setMaxValue:self.threadInfo.progressTotal];
			[self.progressIndicator setDoubleValue:self.threadInfo.progress];
			[self.progressIndicator setIndeterminate:!self.threadInfo.progressTotal];	
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)threadCancelledNotification:(NSNotification*)notification {
	[self.cancelButton setEnabled:NO];
}

-(void)threadCompletedNotification:(NSNotification*)notification {
	[NSApp endSheet:self.window];
	[self close];
	[self autorelease];
}

-(void)cancelAction:(id)source {
	[self.threadInfo.manager cancelThread:self.threadInfo];
}

@end

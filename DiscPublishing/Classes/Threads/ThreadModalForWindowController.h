//
//  ThreadModalForWindow.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//


@class ThreadsManagerThreadInfo;

@interface ThreadModalForWindowController : NSWindowController {
	ThreadsManagerThreadInfo* _threadInfo;
	NSWindow* _docWindow;
	NSProgressIndicator* _progressIndicator;
	NSButton* _cancelButton;
	NSTextField* _titleField;
	NSTextField* _statusField;
}

@property(retain, readonly) ThreadsManagerThreadInfo* threadInfo;
@property(retain, readonly) NSWindow* docWindow;
@property(retain) IBOutlet NSProgressIndicator* progressIndicator;
@property(retain) IBOutlet NSButton* cancelButton;
@property(retain) IBOutlet NSTextField* titleField;
@property(retain) IBOutlet NSTextField* statusField;

-(id)initWithThread:(ThreadsManagerThreadInfo*)threadInfo window:(NSWindow*)window;

-(IBAction)cancelAction:(id)source;

@end

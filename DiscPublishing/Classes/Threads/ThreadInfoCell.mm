//
//  ThreadInfoCell.m
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import "ThreadInfoCell.h"
#import "ThreadsManagerThreadInfo.h"
#import "ThreadsManager.h"
#import "ThreadsWindowController.h"
#import "ThreadInfoCancelButton.h"
#import "NSString+DiscPublisher.h"


@implementation ThreadInfoCell

@synthesize progressIndicator = _progressIndicator;
@synthesize cancelButton = _cancelButton;
@synthesize threadInfo = _threadInfo;
@synthesize view = _view;

-(id)initWithInfo:(ThreadsManagerThreadInfo*)threadInfo view:(NSTableView*)view {
	self = [super init];
	
	_view = [view retain];
	
	ThreadsWindowController* threadsController = (id)view.delegate;
	[self setTextColor:threadsController.statusLabel.textColor];
	
	self.progressIndicator = [[[NSProgressIndicator alloc] initWithFrame:NSZeroRect] autorelease];
	[self.progressIndicator setUsesThreadedAnimation:YES];
	
	self.cancelButton = [[[ThreadInfoCancelButton alloc] initWithFrame:NSZeroRect] autorelease]; // TODO: the button sucks, make it look better
	self.cancelButton.target = self;
	self.cancelButton.action = @selector(cancelThreadAction:);
	
	self.threadInfo = threadInfo;

	return self;
}

-(void)dealloc {
	[self.progressIndicator removeFromSuperview];
	self.progressIndicator = NULL;
	[self.cancelButton removeFromSuperview];
	self.cancelButton = NULL;
	self.threadInfo = NULL;
	[_view release];
	[super dealloc];
}

-(void)setThreadInfo:(ThreadsManagerThreadInfo*)threadInfo {
	@try {
		[self.threadInfo removeObserver:self forKeyPath:@"supportsCancel"];
		[self.threadInfo removeObserver:self forKeyPath:@"progress"];
		[self.threadInfo removeObserver:self forKeyPath:@"status"];
	} @catch (...) {
	}
	
	[_threadInfo release];
	_threadInfo = [threadInfo retain];
	
	[self.threadInfo addObserver:self forKeyPath:@"status" options:NULL context:NULL];
	[self.threadInfo addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.threadInfo addObserver:self forKeyPath:@"supportsCancel" options:NSKeyValueObservingOptionInitial context:NULL];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == self.threadInfo)
		if ([keyPath isEqual:@"status"]) {
			[self.view setNeedsDisplayInRect:[self statusFrame]];
			return;
		} else if ([keyPath isEqual:@"progress"]) {
			[self.progressIndicator setMinValue:0];
			[self.progressIndicator setMaxValue:self.threadInfo.progressTotal];
			[self.progressIndicator setDoubleValue:self.threadInfo.progress];
			[self.progressIndicator setIndeterminate:!self.threadInfo.progressTotal];	
			return;
		} else if ([keyPath isEqual:@"supportsCancel"]) {
			[self.cancelButton setHidden:!self.threadInfo.supportsCancel];
			[self.cancelButton setEnabled:self.threadInfo.supportsCancel];
			return;
		}
	
	[super observeValueForKeyPath:keyPath ofObject:obj change:change context:context];
}

-(void)cancelThreadAction:(id)source {
	[self.threadInfo.manager cancelThread:self.threadInfo];
}

-(void)drawInteriorWithFrame:(NSRect)frame inView:(NSView*)view {
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	NSMutableDictionary* textAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: [self textColor], NSForegroundColorAttributeName, [NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]], NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, NULL];

	[NSGraphicsContext saveGraphicsState];
	
	NSRect nameFrame = NSMakeRect(frame.origin.x+3, frame.origin.y, frame.size.width-23, frame.size.height);
	NSString* name = self.threadInfo.thread.name;
	if (!name) name = @"Untitled Thread";
	[name drawWithRect:nameFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	NSRect statusFrame = [self statusFrame];
	[textAttributes setObject:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]] forKey:NSFontAttributeName];
	[(self.threadInfo.status? self.threadInfo.status : @"No activity information was provided for this thread.") drawWithRect:statusFrame options:NSStringDrawingUsesLineFragmentOrigin attributes:textAttributes];
	
	NSRect cancelFrame = NSMakeRect(frame.origin.x+frame.size.width-15-5, frame.origin.y+6, 15, 15);
	if (![self.cancelButton superview])
		[view addSubview:self.cancelButton];
	if (!NSEqualRects(self.cancelButton.frame, cancelFrame)) [self.cancelButton setFrame:cancelFrame];
	
	NSRect progressFrame = NSMakeRect(frame.origin.x+1, frame.origin.y+28, frame.size.width-2, frame.size.height-29);
	if (![self.progressIndicator superview]) {
		[view addSubview:self.progressIndicator];
		[self.progressIndicator startAnimation:self];
	} if (!NSEqualRects(self.progressIndicator.frame, progressFrame)) [self.progressIndicator setFrame:progressFrame];
	
	[NSGraphicsContext restoreGraphicsState];
}

static NSPoint operator+(const NSPoint& p, const NSSize& s)
{ return NSMakePoint(p.x+s.width, p.y+s.height); }

-(void)drawWithFrame:(NSRect)frame inView:(NSView*)view {
	[self drawInteriorWithFrame:frame inView:view];
	
	[NSGraphicsContext saveGraphicsState];
	
	[[[NSColor grayColor] colorWithAlphaComponent:0.5] set];
	[NSBezierPath strokeLineFromPoint:frame.origin+NSMakeSize(-2, frame.size.height) toPoint:frame.origin+frame.size+NSMakeSize(2,0)];
	
	[NSGraphicsContext restoreGraphicsState];
}

-(NSRect)statusFrame {
	NSRect frame = [self.view rectOfRow:[self.threadInfo.manager.threads indexOfObject:self.threadInfo]];
	return NSMakeRect(frame.origin.x+3, frame.origin.y+14, frame.size.width-23, frame.size.height-13);
}

@end

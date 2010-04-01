//
//  ThreadInfoCancelButton.mm
//  Threads
//
//  Created by Alessandro Volz on 2/18/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "ThreadInfoCancelButton.h"


@implementation ThreadInfoCancelButton

-(NSImage*)image {
	return [NSImage imageNamed: [[self cell] isHighlighted]? @"InvertedNSStopProgressFreestandingTemplate" :@"InvertedNSStopProgressFreestandingTemplatePressed"];
}

-(BOOL)isOpaque {
	return NO;
}

-(void)drawRect:(NSRect)dirtyRect {
	NSImage* image = [self image];
	NSRect frame = NSZeroRect; frame.size = [image size];
	[image drawInRect:[self bounds] fromRect:frame operation:NSCompositeSourceOver fraction:1];
}

@end

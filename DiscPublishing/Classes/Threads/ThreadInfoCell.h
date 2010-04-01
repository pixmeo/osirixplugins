//
//  ThreadInfoCell.h
//  ManualBindings
//
//  Created by Alessandro Volz on 2/16/10.
//  Copyright 2010 Ingroppalgrillo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ThreadsManagerThreadInfo;

@interface ThreadInfoCell : NSTextFieldCell {
	NSProgressIndicator* _progressIndicator;
	NSButton* _cancelButton;
	ThreadsManagerThreadInfo* _threadInfo;
	NSTableView* _view;
}

@property(retain) NSProgressIndicator* progressIndicator;
@property(retain) NSButton* cancelButton;
@property(retain) ThreadsManagerThreadInfo* threadInfo;
@property(retain, readonly) NSTableView* view;

-(id)initWithInfo:(ThreadsManagerThreadInfo*)threadInfo view:(NSTableView*)view;

-(NSRect)statusFrame;

@end

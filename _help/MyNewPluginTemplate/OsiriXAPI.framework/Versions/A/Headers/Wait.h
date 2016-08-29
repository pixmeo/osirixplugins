/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>
#import <IOKit/pwr_mgt/IOPMLib.h>


@class SendController;

/** \brief Window Controller for the Wait Panel */
@interface Wait : NSWindowController <NSWindowDelegate>
{
    IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField		 *text, *elapsed;
	IBOutlet NSButton			 *abort;
	
	SendController * _target;
	NSDate  *startTime;
	BOOL	cancel, aborted;
	NSModalSession session;
	NSTimeInterval lastTimeFrame, lastTimeFrameUpdate, firstTime, displayedTime;
    IOPMAssertionID assertionID;
}

- (void)incrementBy:(double)delta;
- (NSProgressIndicator*) progress;
- (id) initWithString:(NSString*) str;
- (BOOL) aborted;
- (IBAction) abortButton: (id) sender;
- (void) setCancel :(BOOL) val;
- (void) setElapsedString :(NSString*) str;
@end

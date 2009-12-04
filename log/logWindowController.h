//
//  logWindowController.h
//  logExtractor
//
//  Created by Antoine Rosset on 19.07.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface logWindowController : NSWindowController {

	IBOutlet	NSTextView		*resultField;
	IBOutlet	NSTextField		*urlString, *state;
	
	NSLock *lock;
	volatile int threadsFinished;
}

- (IBAction) openLog:(id) sender;
- (IBAction) openLogURL:(id) sender;

@end

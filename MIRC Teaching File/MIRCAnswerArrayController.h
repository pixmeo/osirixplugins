//
//  MIRCAnswerArrayController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/20/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MIRCAnswerArrayController : NSArrayController {
	IBOutlet id _controller;
}

- (IBAction)answerAction:(id)sender;
- (IBAction)modifyAnswer:(id)sender;

@end

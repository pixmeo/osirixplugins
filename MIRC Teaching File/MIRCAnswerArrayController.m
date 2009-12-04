//
//  MIRCAnswerArrayController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/20/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCAnswerArrayController.h"
#import "MIRCAnswer.h"


@implementation MIRCAnswerArrayController



- (IBAction)answerAction:(id)sender{
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		switch ([sender selectedSegment]) {
			case 0: [self add:sender];
					break;
			case 1: [self remove:sender];
					break;
		}
	}
}


@end

//
//  Graph.h
//  Mapping
//
//  Created by Antoine Rosset on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface Graph : NSView {

	float   *minValues, *maxValues, *meanValues;
	long	arraySize;

}

-(void) setArrays: (long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr;

@end

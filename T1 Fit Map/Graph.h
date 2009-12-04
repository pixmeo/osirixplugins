//
//  Graph.h
//  Mapping
//
//  Created by Antoine Rosset on Tue Aug 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface GraphT1Fit : NSView {

	float   *minValues, *maxValues, *meanValues, *teValues;
	float	slope;
	float	intercept;
	long	arraySize;
	BOOL	logMode;
}

-(void) setArrays: (long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log;
-(void) setLinearRegression:(float)b :(float) m;

@end

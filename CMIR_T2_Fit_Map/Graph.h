//
//  Graph.h
//  Mapping
//
//  Created by Antoine Rosset on Tue Aug 03 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface GraphCMIRT2Fit : NSView {

	float   *minValues, *maxValues, *meanValues, *teValues;
	float	slope;
	float	intercept;
	//++++++++++
	float	threshold;
	long	offset;
	//++++++++++
	long	arraySize;
	BOOL	logMode;
	
}

//--    -(void) setArrays: (long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log;
-(void) setArrays: (long)off :(long) nb :(float*) meanPtr :(float*)minPtr :(float*)maxPtr :(float*) teV :(BOOL) log;
-(void) setLinearRegression:(float)b :(float) m;
//++++++++++
-(void) setThreshold:(float)th;
//++++++++++

@end

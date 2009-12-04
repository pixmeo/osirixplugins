//
//  RegUpdate.m
//  PetSpectFusion_Plugin
//
//  Created by Brian Jensen on 17.04.09.
//  Copyright 2009. All rights reserved.
//

#import "RegUpdate.h"


@implementation RegUpdate

@synthesize metricVal;
@synthesize iteration;
@synthesize level;

-(id) initWithParams:(ParametersType &) params metricVal:(float) metric iteration:(int) iter
{
	if( self = [super init])
	{
		curParams = params;
		metricVal = metric;
		iteration = iter;
	}
	return self;
}

-(id) initWithLevel:(int) curLevel
{
	if(self = [super init])
	{
		level = curLevel;
	}
	return self;
	
}

- (ParametersType &) curParams
{
	return curParams;
}

@end

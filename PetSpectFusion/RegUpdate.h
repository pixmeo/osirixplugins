/*=========================================================================
 Program:  PetSpectFusion, an osirix plugin
 
 RegUpdate.h: This class is used to pass update information between the 
 registration thread and the main GUI thread.
 
 
 Copyright (c) Brian Jensen
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://home.in.tum.de/~jensen/projects/projects_en.shtml for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>

#import "Project_defs.h"

#define id Id
#include "Typedefs.h"
#undef id

@interface RegUpdate : NSObject {
	ParametersType curParams;
	float	metricVal;
	int iteration;
	int level;
}

@property(readonly) float	metricVal;
@property(readonly) int iteration;
@property(readonly) int level;

-(id) initWithParams:(ParametersType &) params metricVal:(float) metricVal iteration:(int) iteration;

-(id) initWithLevel:(int) curLevel;

- (ParametersType &) curParams;

@end

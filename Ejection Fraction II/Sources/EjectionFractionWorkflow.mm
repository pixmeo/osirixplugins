//
//  EjectionFractionWorkflow.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionWorkflow.h"
#import "EjectionFractionWorkflow+OsiriX.h"
#import "EjectionFractionStepsController.h"

NSString* Dias = @"Diastole";
NSString* Syst = @"Systole";

@implementation EjectionFractionWorkflow
@synthesize plugin = _plugin, /*viewer = _viewer,*/ steps = _steps, algorithm = _algorithm, expectedRoiId = _expectedRoiId;

-(id)initWithPlugin:(EjectionFractionPlugin*)plugin viewer:(ViewerController*)viewer {
	self = [super init];
	
	_plugin = plugin;
//	[self setViewer:viewer];
	[self setSteps:[[[EjectionFractionStepsController alloc] initWithWorkflow:self] autorelease]];
	
//	[_steps setSelectedAlgorithm:_algorithm];
	
	[self initOsiriX];
	
	return self;
}

-(void)dealloc {
	NSLog(@"%X [EjectionFractionWorkflow dealloc]", self);
	[self deallocOsiriX];
//	[self setViewer:NULL];
	if (_steps) [_steps close];
	[self setSteps:NULL];
	[super dealloc];
}

-(void)setAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	if (_algorithm) [algorithm release];
	_algorithm = [algorithm retain];
	[_steps setSelectedAlgorithm:algorithm];
}

@end

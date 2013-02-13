//
//  EjectionFractionWorkflow.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionWorkflow.h"
#import "EjectionFractionWorkflow+OsiriX.h"
#import "EjectionFractionAlgorithm.h"
#import "EjectionFractionStepsController.h"
#import <OsiriXAPI/N2Debug.h>
#import <OsiriXAPI/N2UserDefaults.h>

NSString* Dias = @"Diastole";
NSString* Syst = @"Systole";

@implementation EjectionFractionWorkflow
@synthesize plugin = _plugin, /*viewer = _viewer,*/ steps = _steps, algorithm = _algorithm;

-(id)initWithPlugin:(EjectionFractionPlugin*)plugin viewer:(ViewerController*)viewer {
	self = [super init];
	
	_plugin = plugin;
//	[self setViewer:viewer];
	[self setSteps:[[[EjectionFractionStepsController alloc] initWithWorkflow:self] autorelease]];
	
//	[_steps setSelectedAlgorithm:_algorithm];
	
	[self initOsiriX];
	
	return self;
}

-(id)retain {
	return [super retain];
}

-(void)dealloc {
	DLog(@"%@ [EjectionFractionWorkflow dealloc]", self);
	[self deallocOsiriX];
	[self setAlgorithm:NULL];
//	[self setViewer:NULL];
	if (_steps) [_steps close];
	[self setSteps:NULL];
	[super dealloc];
}

-(void)setAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	[_algorithm setWorkflow:NULL];
	[_algorithm release];
	
	_algorithm = [algorithm retain];
	
	[_algorithm setWorkflow:self];
	[_steps setSelectedAlgorithm:_algorithm];
	
	[_steps setResult:[_algorithm compute:_rois]];
}

-(NSDictionary*)rois {
	return _rois;
}

static NSColor* DiasColor = NULL;
static NSColor* SystColor = NULL;
static NSString* const DiasColorUserDefaultsKey = @"EjectionFractionDiastoleColor";
static NSString* const SystColorUserDefaultsKey = @"EjectionFractionSystoleColor";

-(NSColor*)diasColor {
	if (!DiasColor)
		DiasColor = [[[N2UserDefaults defaultsForObject:self] colorForKey:DiasColorUserDefaultsKey default:[NSColor redColor]] retain];
	return DiasColor;
}

-(void)setDiasColor:(NSColor*)color {
	[DiasColor release];
	DiasColor = [color retain];
	[[N2UserDefaults defaultsForObject:self] setColor:DiasColor forKey:DiasColorUserDefaultsKey];
}

-(NSColor*)systColor {
	if (!SystColor)
		SystColor = [[[N2UserDefaults defaultsForObject:self] colorForKey:SystColorUserDefaultsKey default:[NSColor blueColor]] retain];
	return SystColor;
}

-(void)setSystColor:(NSColor*)color {
	[SystColor release];
	SystColor = [color retain];
	[[N2UserDefaults defaultsForObject:self] setColor:SystColor forKey:SystColorUserDefaultsKey];
}

@end

//
//  EjectionFractionWorkflow.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OsiriX Headers/ViewerController.h>

@class EjectionFractionStepsController, EjectionFractionPlugin, EjectionFractionAlgorithm;

extern NSString* Dias;
extern NSString* Syst;

@interface EjectionFractionWorkflow : NSObject {
	EjectionFractionPlugin* _plugin;
//	ViewerController* _viewer;
	EjectionFractionStepsController* _steps;
	EjectionFractionAlgorithm* _algorithm;
	@private // +OsiriX
		NSMutableDictionary* _rois;
		NSString* _expectedRoiId;
}

@property(readonly) EjectionFractionPlugin* plugin;
//@property(assign) ViewerController* viewer;
@property(retain) EjectionFractionStepsController* steps;
@property(retain) EjectionFractionAlgorithm* algorithm;
@property(retain) NSString* expectedRoiId;

-(id)initWithPlugin:(EjectionFractionPlugin*)plugin viewer:(ViewerController*)viewer;

@end

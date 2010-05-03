//
//  ArthroplastyTemplatingStepsController.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingStepsController.h"
#import "ArthroplastyTemplatingWindowController+Templates.h"
#import "ArthroplastyTemplatingPlugin.h"
#import "ArthroplastyTemplatingUserDefaults.h"
#import <OsiriX Headers/SendController.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/N2Step.h>
#import <OsiriX Headers/N2Steps.h>
#import <OsiriX Headers/N2StepsView.h>
#import <OsiriX Headers/N2Panel.h>
#import <OsiriX Headers/NSBitmapImageRep+N2.h>
#import <OsiriX Headers/N2Operators.h>
#import <OsiriX Headers/Notifications.h>
#import "ArthroplastyTemplateFamily.h"
// #include "vImage/Convolution.h"
#include <vector>

#define kInvalidAngle 666
#define kInvalidMagnification 0
const NSString* const PlannersNameUserDefaultKey = @"Planner's Name";

@interface ArthroplastyTemplatingStepsController (Private)
-(void)adjustStemToCup:(unsigned)index;
@end
@implementation ArthroplastyTemplatingStepsController
@synthesize viewerController = _viewerController;


#pragma mark Initialization

-(id)initWithPlugin:(ArthroplastyTemplatingPlugin*)plugin viewerController:(ViewerController*)viewerController {
	self = [self initWithWindowNibName:@"ArthroplastyTemplatingSteps"];
	_plugin = [plugin retain];
	_viewerController = [viewerController retain];
	_appliedMagnification = 1;
	
	_knownRois = [[NSMutableSet alloc] initWithCapacity:16];
	
	// place at viewer window upper right corner
	NSRect frame = [[self window] frame];
	NSRect screen = [[[_viewerController window] screen] frame];
	frame.origin.x = screen.origin.x+screen.size.width-frame.size.width;
	frame.origin.y = screen.origin.y+screen.size.height-frame.size.height;
	[[self window] setFrame:frame display:YES];
	
	[_viewerController roiDeleteAll:self];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiChanged:) name:OsirixROIChangeNotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiRemoved:) name:OsirixRemoveROINotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerDidChangeKeyStatus:) name:NSWindowDidBecomeKeyNotification object:[_viewerController window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerDidChangeKeyStatus:) name:NSWindowDidResignKeyNotification object:[_viewerController window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKeyStatus:) name:NSWindowDidBecomeKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeKeyStatus:) name:NSWindowDidResignKeyNotification object:[self window]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendToPACS:) name:OsirixAddToDBNotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:OsirixCloseViewerNotification object:NULL];
	
	return self;
}

-(void)awakeFromNib {
	[_stepsView setForeColor:[NSColor whiteColor]];
	[_stepsView setControlSize:NSSmallControlSize];

	[_steps addObject: _stepCalibration = [[N2Step alloc] initWithTitle:@"Calibration" enclosedView:_viewCalibration]];
	[_steps addObject: _stepAxes = [[N2Step alloc] initWithTitle:@"Axes" enclosedView:_viewAxes]];
	[_steps addObject: _stepLandmarks = [[N2Step alloc] initWithTitle:@"Femoral landmarks" enclosedView:_viewLandmarks]];
	[_steps addObject: _stepCutting = [[N2Step alloc] initWithTitle:@"Femur identification" enclosedView:_viewCutting]];
	[_steps addObject: _stepCup = [[N2Step alloc] initWithTitle:@"Cup" enclosedView:_viewCup]];
	[_steps addObject: _stepStem = [[N2Step alloc] initWithTitle:@"Stem" enclosedView:_viewStem]];
	[_steps addObject: _stepPlacement = [[N2Step alloc] initWithTitle:@"Reduction" enclosedView:_viewPlacement]];
	[_steps addObject: _stepSave = [[N2Step alloc] initWithTitle:@"Save" enclosedView:_viewSave]];
	[_steps enableDisableSteps];
	
	[_magnificationRadioCustom setAttributedTitle:[[[NSAttributedString alloc] initWithString:[_magnificationRadioCustom title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [_magnificationRadioCustom font], NSFontAttributeName, NULL]] autorelease]];
	[_magnificationRadioCalibrate setAttributedTitle:[[[NSAttributedString alloc] initWithString:[_magnificationRadioCalibrate title] attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName, [_magnificationRadioCalibrate font], NSFontAttributeName, NULL]] autorelease]];
	[_magnificationCustomFactor setBackgroundColor:[[self window] backgroundColor]];
	[_magnificationCalibrateLength setBackgroundColor:[[self window] backgroundColor]];
	[_plannersNameTextField setBackgroundColor:[[self window] backgroundColor]];
	[_magnificationCustomFactor setFloatValue:1.15];
//	[self updateInfo];
	
	[_plannersNameTextField setStringValue:[[[_plugin templatesWindowController] userDefaults] object:PlannersNameUserDefaultKey otherwise:NSFullUserName()]];
}

- (void)dealloc {
	[self hideTemplatesPanel];
	
	[self resetSBSUpdatingView:NO];
	
	[_stepCalibration release];
	[_stepAxes release];
	[_stepLandmarks release];
	[_stepCutting release];
	[_stepCup release];
	[_stepStem release];
	[_stepPlacement release];
	[_stepSave release];
	[_knownRois release];
	if (_isMyMouse) [_isMyMouse release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[super dealloc];
}

-(NSString*)windowFrameAutosaveName {
	return @"Arthroplasty Templating";
}

#pragma mark Windows

- (void)windowWillClose:(NSNotification *)aNotification { // this window is closing
	[self release];
}

- (void)viewerWillClose:(NSNotification*)notification {
//	[self close];
}

-(void)viewerDidChangeKeyStatus:(NSNotification*)notif {
	if ([[_viewerController window] isKeyWindow])
		;//[[self window] orderFront:self];
	else { 
		if ([[self window] isKeyWindow]) return; // TODO: somehow this is not yet valid (both windows are not the key window)
		if ([[[_plugin templatesWindowController] window] isKeyWindow]) return;
//		[[self window] orderOut:self];
	}
}

-(void)windowDidChangeKeyStatus:(NSNotification*)notif {
	NSLog(@"windowDidChangeKeyStatus");
}

#pragma mark Link to OsiriX

-(void)removeRoiFromViewer:(ROI*)roi {
	if (!roi) return;
	[[[_viewerController roiList] objectAtIndex:0] removeObject:roi];
	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixRemoveROINotification object:roi userInfo:NULL];
}

// landmark OR horizontal axis has changed
-(BOOL)landmarkChanged:(ROI*)landmark axis:(ROI**)axis other:(ROI*)otherLandmark {
	if (!landmark || [[landmark points] count] != 1 || !_horizontalAxis) {
		if (*axis) {
			[self removeRoiFromViewer:*axis];
			*axis = NULL;
		} return NO;	
	}
	
	BOOL newAxis = !*axis;
	if (newAxis) {
		*axis = [[ROI alloc] initWithType:tMesure :[[_horizontalAxis valueForKey:@"pixelSpacingX"] floatValue] :[[_horizontalAxis valueForKey:@"pixelSpacingY"] floatValue] :[[_horizontalAxis valueForKey:@"imageOrigin"] pointValue]];
		[*axis setDisplayTextualData:NO];
		[*axis setThickness:1]; [*axis setOpacity:.5];
		[*axis setSelectable:NO];
		NSTimeInterval group = [NSDate timeIntervalSinceReferenceDate];
		[landmark setGroupID:group];
		[*axis setGroupID:group];
		[[_viewerController imageView] roiSet:*axis];
		[[[_viewerController roiList] objectAtIndex:[[_viewerController imageView] curImage]] addObject:*axis];
		[*axis release];
	}
	
	NSPoint horizontalAxisD = [[[_horizontalAxis points] objectAtIndex:0] point] - [[[_horizontalAxis points] objectAtIndex:1] point];
	NSPoint axisPM = [[[landmark points] objectAtIndex:0] point];
	NSPoint axisP0 = axisPM+horizontalAxisD/2;
	NSPoint axisP1 = axisPM-horizontalAxisD/2;
	
	if (otherLandmark) {
		NSPoint otherPM = [[[otherLandmark points] objectAtIndex:0] point];
		axisP1 = NSMakeLine(axisP0, axisP1) * NSMakeLine(otherPM, !NSMakeVector(axisP0, axisP1));
		axisP0 = axisPM;
	}
	
	if (!newAxis)
		if (axisP0 != [[[*axis points] objectAtIndex:0] point] || axisP1 != [[[*axis points] objectAtIndex:1] point]) {
			[[*axis points] removeAllObjects];
			newAxis = YES;
		}
	
	if (newAxis) {
		[*axis setPoints:[NSArray arrayWithObjects:[MyPoint point:axisP0], [MyPoint point:axisP1], NULL]];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:*axis userInfo:NULL];
//		[_viewerController bringToFrontROI:landmark]; // TODO: this makes the landmark disappear!
	}
	
	return newAxis; // returns YES if the axis was changed
}

-(void)updateInequality:(ROI**)axis from:(ROI*)roiFrom to:(ROI*)roiTo name:(NSString*)name positioning:(CGFloat)positioning value:(CGFloat*)value {
	if (!_horizontalAxis || [[_horizontalAxis points] count] < 2) {
		if (*axis)
			[self removeRoiFromViewer:*axis];
		return;
	}
	
	NSVector horizontalVector = NSMakeVector([[[_horizontalAxis points] objectAtIndex:0] point], [[[_horizontalAxis points] objectAtIndex:1] point]);
	NSLine lineFrom; if (roiFrom) lineFrom = NSMakeLine([[[roiFrom points] objectAtIndex:0] point], horizontalVector);
	NSLine lineTo; if (roiTo) lineTo = NSMakeLine([[[roiTo points] objectAtIndex:0] point], horizontalVector);
	
	if (roiFrom && roiTo) {
		if (!*axis) {
			*axis = [[ROI alloc] initWithType:tMesure :[[_horizontalAxis valueForKey:@"pixelSpacingX"] floatValue] :[[_horizontalAxis valueForKey:@"pixelSpacingY"] floatValue] :[[_horizontalAxis valueForKey:@"imageOrigin"] pointValue]];
			[*axis setThickness:1]; [*axis setOpacity:.5];
			[*axis setSelectable:NO];
			[[_viewerController imageView] roiSet:*axis];
			[[[_viewerController roiList] objectAtIndex:[[_viewerController imageView] curImage]] addObject:*axis];
			[*axis release];
		}
	} else {
		if (*axis)
			[self removeRoiFromViewer:*axis];
		return;
	}
	
	NSLine inequalityLine = NSMakeLine([[[roiFrom points] objectAtIndex:0] point]*(1.0-positioning)+[[[roiTo points] objectAtIndex:0] point]*positioning, !horizontalVector);
	NSPoint pointFrom = lineFrom*inequalityLine, pointTo = lineTo*inequalityLine;
	
	if ([[*axis points] count]) [[*axis points] removeAllObjects];
	[*axis setPoints:[NSArray arrayWithObjects:[MyPoint point:pointFrom], [MyPoint point:pointTo], NULL]];
	*value = [*axis MesureLength:NULL]*NSSign((pointTo-pointFrom).y)*(-1);
	
	[*axis setName:name];
//	[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_legInequality userInfo:NULL];
}

-(void)updateLegInequality {
	ROI *lm1 = _femurLandmarkOther? (_femurLandmarkOther==_landmark1?_landmark2:_landmark1) : _landmark1, *lm2 = _femurLandmarkOther? _femurLandmarkOther : _landmark2;
	[self updateInequality:&_originalLegInequality from:lm1 to:lm2 name:@"Original leg inequality" positioning:.5 value:&_originalLegInequalityValue];
	[self updateInequality:&_legInequality from:_femurLandmark to:_femurLandmarkOther name:@"Leg inequality" positioning:1 value:&_legInequalityValue];
	if (_horizontalAxis && _femurLandmarkOriginal && _femurLandmarkAxis) {
		NSVector horizontalDir = NSMakeVector([[[_horizontalAxis points] objectAtIndex:0] point], [[[_horizontalAxis points] objectAtIndex:1] point]);
		NSLine horizontalAxis = NSMakeLine([[[_horizontalAxis points] objectAtIndex:0] point], horizontalDir);
		_lateralOffsetValue = std::abs([_horizontalAxis Length:horizontalAxis*NSMakeLine([[[_femurLandmarkOriginal points] objectAtIndex:0] point], !horizontalDir) :horizontalAxis*NSMakeLine([[[_femurLandmarkAxis points] objectAtIndex:0] point], !horizontalDir)]);
	}
	
//	NSVector horizontalVector = NSMakeVector([[[_horizontalAxis points] objectAtIndex:0] point], [[[_horizontalAxis points] objectAtIndex:1] point]);
	
//	[_verticalOffsetTextField setStringValue:[NSString stringWithFormat:@"Vertical offset: ", ]];
}

-(void)roiChanged:(NSNotification*)notification {
	ROI* roi = [notification object];
	if (!roi) return;
	
	// verify that the ROI is on our viewer
	if (![_viewerController containsROI:roi]) return;
	
	// add to known list
	BOOL wasKnown = [_knownRois containsObject:roi];
	if (!wasKnown) [_knownRois addObject:roi];
	
	// if is _infoBoxRoi then return (we already know about it)
	if (roi == _infoBox) return;	
	
	// step dependant
	if (!wasKnown) {
		if ([_steps currentStep] == _stepCalibration)
			if (!_magnificationLine && [roi type] == tMesure) {
				_magnificationLine = roi;
				[roi setName:@"Calibration Line"];
			}
		
		if ([_steps currentStep] == _stepAxes)
			if (!_horizontalAxis && [roi type] == tMesure) {
				_horizontalAxis = roi;
				[roi setName:@"Horizontal Axis"];
			} else if (!_femurAxis && [roi type] == tMesure) {
				_femurAxis = roi;
				[roi setName:@"Femur Axis"];
			}
		
		if ([_steps currentStep] == _stepLandmarks)
			if (!_landmark1 && [roi type] == t2DPoint) {
				_landmark1 = roi;
				[roi setDisplayTextualData:NO];
			} else if (!_landmark2 && [roi type] == t2DPoint) {
				_landmark2 = roi;
				[roi setDisplayTextualData:NO];
			}
		
		if ([_steps currentStep] == _stepCutting)
			if (!_femurRoi && [roi type] == tPencil) {
				_femurRoi = roi;
				[roi setThickness:1]; [roi setOpacity:.5];
				[roi setIsSpline:NO];
				[roi setDisplayTextualData:NO];
			}
		
		if ([_steps currentStep] == _stepCup)
			if (!_cupLayer && [roi type] == tLayerROI) {
				_cupLayer = roi;
				_cupTemplate = [[_plugin templatesWindowController] templateAtPath:[roi layerReferenceFilePath]];
			}
		
		if ([_steps currentStep] == _stepStem)
			if (!_stemLayer && [roi type] == tLayerROI) {
				_stemLayer = roi;
				_stemTemplate = [[_plugin templatesWindowController] templateAtPath:[roi layerReferenceFilePath]];
				NSArray* points = [_stemTemplate headRotationPointsForDirection:ArthroplastyTemplateAnteriorPosteriorDirection];
				for (int i = 0; i < [_neckSizePopUpButton numberOfItems]; ++i)
					[[_neckSizePopUpButton itemAtIndex:i] setEnabled:(i+1 <= (int)[points count])];
			}
	}
	
	if (roi == _landmark1 || roi == _landmark2 || roi == _horizontalAxis || roi == _femurLandmark) {
		[self landmarkChanged:_landmark1 axis:&_landmark1Axis other:_landmark2];
		[self landmarkChanged:_landmark2 axis:&_landmark2Axis other:_landmark1];
		[self landmarkChanged:_femurLandmark axis:&_femurLandmarkAxis other:_femurLandmarkOther];
		[self updateLegInequality];
	}

	if (roi == _cupLayer && [[[_cupLayer points] objectAtIndex:0] point] != NSZeroPoint)
		if (!_cupRotated && [[_cupLayer points] count] >= 6) {
			_cupRotated = YES;
			if ([_cupLayer pointAtIndex:4].x < [[[_viewerController imageView] curDCM] pwidth]/2)
				[_cupLayer rotate:45 :[[[_cupLayer points] objectAtIndex:4] point]];
			else [_cupLayer rotate:-45 :[_cupLayer pointAtIndex:4]];
			[_cupLayer rotate:_horizontalAngle/pi*180 :[_cupLayer pointAtIndex:4]];
		}
	
	if (roi == _stemLayer)
		if (!_stemRotated && [[_stemLayer points] count] >= 6) {
			_stemRotated = YES;
			[_stemLayer rotate:(fabs(_femurAngle)-pi/2)/pi*180 :[[[_stemLayer points] objectAtIndex:4] point]];
		}
	
	[self computeValues];
}

-(void)roiRemoved:(NSNotification*)notification {
	ROI *roi = [notification object];
	
	[_knownRois removeObject:roi];

	if (roi == _magnificationLine) {
		_magnificationLine = NULL;
		[_stepCalibration setDone:NO];
		[_steps setCurrentStep:_stepCalibration];
	}
	
	if (roi == _horizontalAxis) {
		_horizontalAxis = NULL;
		[_stepAxes setDone:NO];
		[_steps setCurrentStep:_stepAxes];
		[self updateLegInequality];
	}
	
	if (roi == _femurAxis) {
		_femurAxis = NULL;
		[_steps setCurrentStep:_stepAxes];
	}
	
	if (roi == _landmark1) {
		_landmark1 = NULL;
		[self landmarkChanged:_landmark1 axis:&_landmark1Axis other:_landmark2]; // removes _landmark1Axis
		if (_landmark2) {
			_landmark1 = _landmark2; _landmark2 = NULL;
			_landmark1Axis = _landmark2Axis; _landmark2Axis = NULL;
			[_landmark1 setName:@"Landmark 1"];
			if (![self landmarkChanged:_landmark1 axis:&_landmark1Axis other:_landmark2])
				[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_landmark1 userInfo:NULL];
		} else
			[_stepLandmarks setDone:NO];
		[_steps setCurrentStep:_stepLandmarks];
		[self updateLegInequality];
	}
	
	if (roi == _landmark1Axis)
		_landmark1Axis = NULL;
	
	if (roi == _landmark2) {
		_landmark2 = NULL;
		[self landmarkChanged:_landmark1 axis:&_landmark1Axis other:_landmark2];
		[self landmarkChanged:_landmark2 axis:&_landmark2Axis other:_landmark1];
		[self updateLegInequality];
	}
	
	if (roi == _landmark2Axis)
		_landmark2Axis = NULL;

	if (roi == _femurRoi)
		_femurRoi = NULL;
	
	if (roi == _femurLayer) {
		_femurLayer = NULL; _femurLandmark = NULL;
		[self removeRoiFromViewer:_originalFemurOpacityLayer];
		[_stepCutting setDone:NO];
		[_steps setCurrentStep:_stepCutting];
	}
	
	if (roi == _cupLayer) {
		_cupLayer = NULL;
		_cupTemplate = NULL;
		[_stepCup setDone:NO];
		[_steps setCurrentStep:_stepCup];
		_cupRotated = NO;
	}
	
	if (roi == _stemLayer) {
		_stemLayer = nil;
		_stemTemplate = NULL;
		[_stepStem setDone:NO];
		[_steps setCurrentStep:_stepStem];
		_stemRotated = NO;
		[_neckSizePopUpButton setEnabled:NO];
	}
	
	if (roi == _infoBox)
		_infoBox = NULL;
	
	if (roi == _femurLandmark) {
		_femurLandmark = NULL;
		[self removeRoiFromViewer:_femurLandmarkAxis];
		[self updateLegInequality];
	}
	
	if (roi == _femurLandmarkAxis)
		_femurLandmarkAxis = NULL;
	
	if (roi == _femurLandmarkOther)
		_femurLandmarkOther = NULL;
	
	if (roi == _legInequality)
		_legInequality = NULL;
	
	if (roi == _originalLegInequality)
		_originalLegInequality = NULL;
	
	if (roi == _originalFemurOpacityLayer)
		 _originalFemurOpacityLayer = NULL;
		
	if (roi == _femurLandmarkOriginal)
		_femurLandmarkOriginal = NULL;
		
	[self advanceAfterInput:NULL];
	[self computeValues];
}


#pragma mark General Methods

-(IBAction)resetSBS:(id)sender {
	[self resetSBSUpdatingView:YES];
}

- (void)resetSBSUpdatingView:(BOOL)updateView {
	[self removeRoiFromViewer:_stemLayer];
	[self removeRoiFromViewer:_cupLayer];
	[self removeRoiFromViewer:_femurLayer];
	[self removeRoiFromViewer:_femurRoi];
	[self removeRoiFromViewer:_landmark2];
	[self removeRoiFromViewer:_landmark1];
	[self removeRoiFromViewer:_femurAxis];
	[self removeRoiFromViewer:_horizontalAxis];
	[self removeRoiFromViewer:_magnificationLine];
	[self removeRoiFromViewer:_infoBox];
	[_viewerController roiDeleteAll:self];
	
	if (_planningDate) [_planningDate release]; _planningDate = NULL;
	
	if (updateView) {
		[_steps reset:self];
		[[_viewerController imageView] display];
	}
}

#pragma mark Templates

-(IBAction)showTemplatesPanel:(id)sender {
	if ([[[_plugin templatesWindowController] window] isVisible]) return;
	[[[_plugin templatesWindowController] window] makeKeyAndOrderFront:sender];
	_userOpenedTemplates = [sender class] == [NSButton class];
}

-(void)hideTemplatesPanel {
	[[[_plugin templatesWindowController] window] orderOut:self];
}

#pragma mark Step by Step

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step {
	if (steps != _steps)
		return; // this should never happen
	
	if ([_steps currentStep] != step)
		[steps setCurrentStep:step];

	BOOL showTemplates = NO, selfKey = NO;
	int tool = tROISelector;

	if (step == _stepCalibration) {
		tool = [_magnificationRadioCalibrate state]? tMesure : tROISelector;
		selfKey = YES;
	} else if (step == _stepAxes)
		tool = tMesure;
	else if (step == _stepLandmarks)
		tool = t2DPoint;
	else if (step == _stepCutting) {
		tool = tPencil;
		if (_femurRoi) {
			[_femurRoi setOpacity:1];
			[_femurRoi setSelectable:YES];
			[_femurRoi setROIMode:ROI_selected];
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurRoi userInfo:NULL];
		}
	} else if (step == _stepCup) {
		showTemplates = [[_plugin templatesWindowController] setFilter:@"Cup"];
		NSPoint pt = NSZeroPoint;
		for (MyPoint* p in [_femurRoi points])
			pt += [p point];
		pt /= [[_femurRoi points] count];
		[[_plugin templatesWindowController] setSide: (pt.x > [[[_viewerController imageView] curDCM] pwidth]/2)? ATLeftSide : ATRightSide ];
	} else if (step == _stepStem) {
		if (_stemLayer)
			[_stemLayer setGroupID:0];
		showTemplates = [[_plugin templatesWindowController] setFilter:@"Stem"];
		[[_plugin templatesWindowController] setSide: ([_cupLayer pointAtIndex:4].x > [[[_viewerController imageView] curDCM] pwidth]/2)? ATLeftSide : ATRightSide ];
	} else if (step == _stepPlacement)
		[self adjustStemToCup];
	else if (step == _stepSave)
		selfKey = YES;
	
	[_viewerController setROIToolTag:tool];
	if (showTemplates)
		[self showTemplatesPanel:self];
	else if (!_userOpenedTemplates) [self hideTemplatesPanel];
	
	[(N2Panel*)[self window] setCanBecomeKeyWindow:selfKey];
	if (selfKey) {
		if ([[self window] isVisible]) 
			[[self window] makeKeyAndOrderFront:self];
	} else if (!showTemplates) [[_viewerController window] makeKeyAndOrderFront:self];
}

-(void)steps:(N2Steps*)steps valueChanged:(id)sender {
	// calibration
	if (sender == _magnificationRadioCustom)
		[_magnificationRadioCalibrate setState:![_magnificationRadioCustom state]];
	if (sender == _magnificationRadioCalibrate)
		[_magnificationRadioCustom setState:![_magnificationRadioCalibrate state]];
	if (sender == _magnificationRadioCustom || sender == _magnificationRadioCalibrate) {
		BOOL calibrate = [_magnificationRadioCalibrate state];
		[_magnificationCustomFactor setEnabled:!calibrate];
		[_magnificationCalibrateLength setEnabled:calibrate];
	}
	// placement
	if (sender == _neckSizePopUpButton)
		[self adjustStemToCup:[_neckSizePopUpButton indexOfSelectedItem]];
	
	[self advanceAfterInput:sender];
}

-(void)advanceAfterInput:(id)sender {
	if (sender == _magnificationRadioCustom || sender == _magnificationRadioCalibrate) {
		BOOL calibrate = [_magnificationRadioCalibrate state];
		[_viewerController setROIToolTag: calibrate? tMesure : tROISelector];
		[[self window] makeKeyWindow];
		if (calibrate)
			[_magnificationCalibrateLength performClick:self];
		else [_magnificationCustomFactor performClick:self];
	}
	
	[_neckSizePopUpButton setEnabled: _stemLayer != NULL];

	
}

-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step {
	NSString* errorMessage = NULL;
	
	if (step == _stepCalibration) {
		if ([_magnificationRadioCustom state]) {
			if ([_magnificationCustomFactor floatValue] <= 0)
				errorMessage = @"Please specify a custom magnification factor value.";
		} else
			if (!_magnificationLine)
				errorMessage = @"Please draw a line the size of the calibration object.";
			else if ([_magnificationCalibrateLength floatValue] <= 0)
				errorMessage = @"Please specify the real size of the calibration object.";
	}
	else if (step == _stepAxes) {
		if (!_horizontalAxis)
			errorMessage = @"Please draw a line parallel to the horizontal axis of the pelvis.";
	}
	else if (step == _stepLandmarks) {
		if (!_landmark1)
			errorMessage = @"Please locate one or two landmarks on the proximal femur (e.g. the tips of the greater trochanters).";
	}
	else if (step == _stepCutting) {
		if (!_femurRoi)
			errorMessage = @"Please encircle the proximal femur destined to receive the femoral implant. Femoral head and neck should not be included if you plan to remove them.";
	}
	else if (step == _stepCup) {
		if (!_cupLayer)
			errorMessage = @"Please select an acetabular template, rotate and locate the component into the pelvic bone.";
	}
	else if (step == _stepStem) {
		if (!_stemLayer)
			errorMessage = @"Please select a femoral template, drag it and drop it into the proximal femur, then rotate it.";
	}
	else if (step == _stepSave) {
		if ([[_plannersNameTextField stringValue] length] == 0)
			errorMessage = @"The planner's name must be specified.";
	}

	if (errorMessage)
		[[NSAlert alertWithMessageText:[step title] defaultButton:@"OK" alternateButton:NULL otherButton:NULL informativeTextWithFormat:errorMessage] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
	return errorMessage == NULL;
}

-(ROI*)closestROIFromSet:(NSSet*)rois toPoints:(NSArray*)points {
	NSArray* roisArray = [rois allObjects];
	CGFloat distances[[rois count]];
	// fill distances
	for (unsigned i = 0; i < [rois count]; ++i) {
		distances[i] = MAXFLOAT;
		if (![roisArray objectAtIndex:i]) continue;
		NSPoint roiPoint = [[[[roisArray objectAtIndex:i] points] objectAtIndex:0] point];
		for (unsigned j = 0; j < [points count]; ++j)
			distances[i] = std::min(distances[i], NSDistance(roiPoint, [[points objectAtIndex:j] point]));
	}
	
	unsigned minIndex = 0;
	for (unsigned i = 1; i < [rois count]; ++i)
		if (distances[i] < distances[minIndex])
			minIndex = i;
	
	return [roisArray objectAtIndex:minIndex];
}

-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step {
	if (step == _stepCalibration) {
		if ([_magnificationRadioCalibrate state]) {
			if (!_magnificationLine || [[_magnificationLine points] count] != 2) return;
			NSLog(@"_magnificationCalibrateLength %f", [_magnificationCalibrateLength floatValue]);
			[_magnificationCustomFactor setFloatValue:[_magnificationLine MesureLength:NULL]/[_magnificationCalibrateLength floatValue]];
		}
		CGFloat magnificationValue = [_magnificationCustomFactor floatValue];
		CGFloat factor = 1.*_appliedMagnification/magnificationValue;
		
//		[view setPixelSpacingX:[view pixelSpacingX]*factor]
		for (DCMPix* p in [_viewerController pixList]) {
			[p setPixelSpacingX:[p pixelSpacingX]*factor];
			[p setPixelSpacingY:[p pixelSpacingY]*factor];
		}
		for (ROI* r in [_viewerController roiList]) {
		//	[r setPixelSpacingX:[r pixelSpacingX]*factor];
		//	[r setPixelSpacingY:[r pixelSpacingY]*factor];
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:r];
		}
		
		_appliedMagnification = magnificationValue;
	}
	else if(step == _stepAxes) {
	}
	else if(step == _stepLandmarks) {
	}
	else if(step == _stepCutting) {
		if (_femurLayer)
			[self removeRoiFromViewer:_femurLayer];
			
		_femurLayer = [_viewerController createLayerROIFromROI:_femurRoi];
		[_femurLayer roiMove:NSMakePoint(-10,10)]; // when the layer is created it is shifted, but we don't want this so we move it back
		[_femurLayer setOpacity:1];
		[_femurLayer setDisplayTextualData:NO];
		
		
		_femurLandmarkOriginal = [self closestROIFromSet:[NSSet setWithObjects:_landmark1, _landmark2, NULL] toPoints:[_femurRoi points]];
		_femurLandmark = [[ROI alloc] initWithType:t2DPoint :[[_femurLandmarkOriginal valueForKey:@"pixelSpacingX"] floatValue] :[[_femurLandmarkOriginal valueForKey:@"pixelSpacingY"] floatValue] :[[_femurLandmarkOriginal valueForKey:@"imageOrigin"] pointValue]];
		[_femurLandmark setROIRect:[_femurLandmarkOriginal rect]];
		[_femurLandmark setName:[NSString stringWithFormat:@"%@'",[_femurLandmarkOriginal name]]]; // same name + prime
		[_femurLandmark setDisplayTextualData:NO];
		
		_femurLandmarkOther = _femurLandmarkOriginal == _landmark1? _landmark2 : _landmark1;
		
		[[_viewerController imageView] roiSet:_femurLandmark];
		[[[_viewerController roiList] objectAtIndex:[[_viewerController imageView] curImage]] addObject:_femurLandmark];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurLandmark userInfo:NULL];
		
		// bring the point to front (we don't want it behind the layer)
		[_viewerController bringToFrontROI:_femurLandmark];

		// group the layer and the points
		NSTimeInterval group = [NSDate timeIntervalSinceReferenceDate];
		[_femurLayer setGroupID:group];
		[_femurLandmark setGroupID:group];
		
		// opacity

		NSBitmapImageRep* femur = [NSBitmapImageRep imageRepWithData:[[_femurLayer layerImage] TIFFRepresentation]];
		NSSize size = [[_femurLayer layerImage] size];
		NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:size.width*4 bitsPerPixel:32];
		unsigned char* bitmapData = [bitmap bitmapData];
		int bytesPerRow = [bitmap bytesPerRow], bitsPerPixel = [bitmap bitsPerPixel];
		for (int y = 0; y < size.height; ++y)
			for (int x = 0; x < size.width; ++x) {
				int base = bytesPerRow*y+bitsPerPixel/8*x;
				bitmapData[base+0] = 0;
				bitmapData[base+1] = 0;
				bitmapData[base+2] = 0;
				bitmapData[base+3] = [[femur colorAtX:x y:y] alphaComponent]>0? 128 : 0;
			}
		
		NSImage* image = [[NSImage alloc] init];
		unsigned kernelSize = 5; 
		NSBitmapImageRep* temp = [bitmap smoothen:kernelSize];
		[image addRepresentation:temp];
		
		_originalFemurOpacityLayer = [_viewerController addLayerRoiToCurrentSliceWithImage:[image autorelease] referenceFilePath:@"none" layerPixelSpacingX:[[[_viewerController imageView] curDCM] pixelSpacingX] layerPixelSpacingY:[[[_viewerController imageView] curDCM] pixelSpacingY]];
		[_originalFemurOpacityLayer setSelectable:NO];
		[_originalFemurOpacityLayer setDisplayTextualData:NO];
		[_originalFemurOpacityLayer roiMove:[[[_femurLayer points] objectAtIndex:0] point]-[[[_originalFemurOpacityLayer points] objectAtIndex:0] point]-([temp size]-[bitmap size])/2];
		[_originalFemurOpacityLayer setNSColor:[[NSColor redColor] colorWithAlphaComponent:.5]];
		[[_viewerController imageView] roiSet:_originalFemurOpacityLayer];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_originalFemurOpacityLayer userInfo:NULL];

		[_femurRoi setROIMode:ROI_sleep];
		[_femurRoi setSelectable:NO];
		[_femurRoi setOpacity:0.2];
		[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_femurRoi userInfo:NULL];
		
		[_viewerController selectROI:_femurLayer deselectingOther:YES];
		[_viewerController bringToFrontROI:_femurLayer];
	}
	else if (step == _stepCup) {
	}
	else if (step == _stepStem) {
		[_stemLayer setGroupID:[_femurLayer groupID]];
		[_viewerController setMode:ROI_selected toROIGroupWithID:[_femurLayer groupID]];
		[_viewerController bringToFrontROI:_stemLayer];
	}
	else if (step == _stepSave) {
		[[[_plugin templatesWindowController] userDefaults] setObject:[_plannersNameTextField stringValue] forKey:PlannersNameUserDefaultKey];
		
		if (_planningDate) [_planningDate release];
		_planningDate = [[NSDate date] retain];
		[self updateInfo];

		NSManagedObject* study = [[[_viewerController fileList:0] objectAtIndex:[[_viewerController imageView] curImage]] valueForKeyPath:@"series.study"];
		NSArray* seriesArray = [[study valueForKey:@"series"] allObjects];

		NSString* namePrefix = @"Planning";

		int n = 1, m;
		for (unsigned i = 0; i < [seriesArray count]; i++) {
			NSString *currentSeriesName = [[seriesArray objectAtIndex:i] valueForKey:@"name"];
			if ([currentSeriesName hasPrefix:namePrefix]) {
				m = [[currentSeriesName substringFromIndex:[namePrefix length]+1] intValue];
				if (n <= m) n = m+1;
			}
		}
		
		NSString* name = [NSString stringWithFormat:@"%@ %d", namePrefix, n];
		[_viewerController deselectAllROIs];
		[_viewerController exportDICOMFileInt:YES withName:name];
		[[BrowserController currentBrowser] checkIncoming:self];
		
		// send to PACS
		if ([_sendToPACSButton state]==NSOnState)
			_imageToSendName = [name retain];
		else {
			[_imageToSendName release];
			_imageToSendName = NULL;
		}
	}
}

-(CGFloat)estimateRotationOfROI:(ROI*)roi {
	return NSAngle(NSMakeVector([[[roi points] objectAtIndex:4] point], [[[roi points] objectAtIndex:5] point]));
}

-(void)replaceLayer:(ROI*)roi with:(ArthroplastyTemplate*)t {
	NSPoint center = [[[roi points] objectAtIndex:4] point];
	CGFloat angle = [self estimateRotationOfROI:roi];
	NSTimeInterval group = [roi groupID];
	[self removeRoiFromViewer:roi];
	roi = [[_plugin templatesWindowController] createROIFromTemplate:t inViewer:_viewerController centeredAt:center];
	[roi rotate:(angle-[self estimateRotationOfROI:roi])/pi*180 :center];
	[roi setGroupID:group];
}

-(void)rotateLayer:(ROI*)roi by:(float)degs {
	NSPoint center = [[[roi points] objectAtIndex:4] point];
	if (roi == _stemLayer && [_stemLayer groupID] == [_femurLayer groupID])
		center = [[[roi points] objectAtIndex:4+_stemNeckSizeIndex] point];
	[roi rotate:degs :center];
}

-(void)rotateLayer:(ROI*)roi byTrackingMouseFrom:(NSPoint)wp1 to:(NSPoint)wp2 {
	wp1 = [[_viewerController imageView] ConvertFromNSView2GL:[[_viewerController imageView] convertPoint:wp1 fromView:NULL]];
	wp2 = [[_viewerController imageView] ConvertFromNSView2GL:[[_viewerController imageView] convertPoint:wp2 fromView:NULL]];
	NSPoint center = [[[roi points] objectAtIndex:4] point];
	if (roi == _stemLayer && [_stemLayer groupID] == [_femurLayer groupID])
		center = [[[roi points] objectAtIndex:4+_stemNeckSizeIndex] point];
	CGFloat angle = NSAngle(center, wp2)-NSAngle(center, wp1);
	[self rotateLayer:roi by:angle/pi*180];
}

-(BOOL)handleViewerEvent:(NSEvent*)event {
	if ([event type] == NSKeyDown)
		switch ([event keyCode]) {
			case 76: // enter
			case 36: // return
				[_steps nextStep:self];
				return YES;
			default:
				unichar uc = [[event charactersIgnoringModifiers] characterAtIndex:0];
				BOOL handled = NO;
				switch (uc) {
					case '+':
					case '-':
					case NSUpArrowFunctionKey:
					case NSDownArrowFunctionKey: {
						BOOL next = uc == '+' || uc == NSUpArrowFunctionKey;
						
						if (_cupLayer && [_cupLayer ROImode] == ROI_selected && _cupTemplate) {
							ArthroplastyTemplate* t = next? [[_cupTemplate family] templateAfter:_cupTemplate] : [[_cupTemplate family] templateBefore:_cupTemplate];
							[self replaceLayer:_cupLayer with:t];
							handled = YES;
						}
						if (_stemLayer && [_stemLayer ROImode] == ROI_selected && _stemTemplate) {
							ArthroplastyTemplate* t = next? [[_stemTemplate family] templateAfter:_stemTemplate] : [[_stemTemplate family] templateBefore:_stemTemplate];
							[self replaceLayer:_stemLayer with:t];
							handled = YES;
						}
						
						return handled;
					}
					case '*':
					case '/':
					case NSLeftArrowFunctionKey:
					case NSRightArrowFunctionKey:
						BOOL cw = uc == '*' || uc == NSRightArrowFunctionKey;
						
						if (_cupLayer && [_cupLayer ROImode] == ROI_selected) {
							[self rotateLayer:_cupLayer by:cw? 1 : -1];
							handled = YES;
						}
						if (_stemLayer && [_stemLayer ROImode] == ROI_selected) {
							[self rotateLayer:_stemLayer by:cw? 1 : -1];
							handled = YES;
						}
						
						return handled;
				}
		}
	
	if ([event type] == NSLeftMouseDown || [event type] == NSRightMouseDown || [event type] == NSOtherMouseDown) {
		if ((_cupLayer && [_cupLayer ROImode] == ROI_selected) || (_stemLayer && [_stemLayer ROImode] == ROI_selected)) {
			NSUInteger modifiers = [event modifierFlags]&0xffff0000;
			_isMyMouse = (modifiers == NSCommandKeyMask+NSAlternateKeyMask)? [event retain] : NULL;
			return _isMyMouse != NULL;
		}
	} else if (_isMyMouse && [event type] == NSLeftMouseDragged || [event type] == NSRightMouseDragged || [event type] == NSOtherMouseDragged) {
		if (_cupLayer && [_cupLayer ROImode] == ROI_selected)
			[self rotateLayer:_cupLayer byTrackingMouseFrom:[_isMyMouse locationInWindow] to:[event locationInWindow]];
		if (_stemLayer && [_stemLayer ROImode] == ROI_selected)
			[self rotateLayer:_stemLayer byTrackingMouseFrom:[_isMyMouse locationInWindow] to:[event locationInWindow]];
		[_isMyMouse release];
		_isMyMouse = [event retain];
		return YES;
	} else if ([event type] == NSLeftMouseUp || [event type] == NSRightMouseUp || [event type] == NSOtherMouseUp) {
		if ([_femurLayer groupID] == [_stemLayer groupID])
			[self adjustStemToCup];
		if (_isMyMouse) [_isMyMouse release]; _isMyMouse = NULL;
	}
	
	return NO;
}


#pragma mark Steps specific methods

-(void)adjustStemToCup {
	if (!_cupLayer || !_stemLayer)
		return;
	
	NSPoint cupCenter = [[[_cupLayer points] objectAtIndex:4] point];
	
	unsigned magnetsCount = [[_stemLayer points] count]-6;
	NSPoint magnets[magnetsCount];
	CGFloat distances[magnetsCount];
	for (unsigned i = 0; i < magnetsCount; ++i) {
		magnets[i] = [[[_stemLayer points] objectAtIndex:i+6] point];
		distances[i] = NSDistance(cupCenter, magnets[i]);
	}
	
	unsigned indexOfClosestMagnet = 0;
	for (unsigned i = 1; i < magnetsCount; ++i)
		if (distances[i] < distances[indexOfClosestMagnet])
			indexOfClosestMagnet = i;
	
	[self adjustStemToCup:indexOfClosestMagnet];
}

-(void)adjustStemToCup:(unsigned)index {
	if (!_cupLayer || !_stemLayer)
		return;
	
	_stemNeckSizeIndex = index;
	
	NSPoint cupCenter = [[[_cupLayer points] objectAtIndex:4] point];
	
	unsigned magnetsCount = [[_stemLayer points] count]-6;
	NSPoint magnets[magnetsCount];
	for (unsigned i = 0; i < magnetsCount; ++i)
		magnets[i] = [[[_stemLayer points] objectAtIndex:i+6] point];
	
	for (id loopItem in [[_viewerController roiList:[_viewerController curMovieIndex]] objectAtIndex:[[_viewerController imageView] curImage]])
		if ([loopItem groupID] == [_stemLayer groupID])
			[loopItem roiMove:cupCenter-magnets[index]];
	
	[_neckSizePopUpButton setEnabled:YES];
	[_neckSizePopUpButton selectItemAtIndex:index];
}

// dicom was added to database, send it to PACS
-(void)sendToPACS:(NSNotification*)notification {
	if ([_sendToPACSButton state] && _imageToSendName) {
		[_sendToPACSButton setState:NSOffState];
		
//		NSLog(@"send to PACS");
		NSManagedObject *study = [[[_viewerController fileList:0] objectAtIndex:[[_viewerController imageView] curImage]] valueForKeyPath:@"series.study"];
		NSArray	*seriesArray = [[study valueForKey:@"series"] allObjects];
//		NSLog(@"[seriesArray count] : %d", [seriesArray count]);
		NSString *pathOfImageToSend;
		
		
		NSManagedObject* imageToSend = NULL;
		
		for (unsigned i = 0; i < [seriesArray count]; i++)
		{
			NSString *currentSeriesName = [[seriesArray objectAtIndex:i] valueForKey:@"name"];
//			NSLog(@"currentSeriesName : %@", currentSeriesName);
			if([currentSeriesName isEqualToString:_imageToSendName])
			{
				NSArray *images = [[[seriesArray objectAtIndex:i] valueForKey:@"images"] allObjects];
//				NSLog(@"[images count] : %d", [images count]);
//				NSLog(@"images : %@", images);
				imageToSend = [images objectAtIndex:0];
				pathOfImageToSend = [[images objectAtIndex:0] valueForKey:@"path"];
				//pathOfImageToSend = [images valueForKey:@"path"];
//				NSLog(@"pathOfImageToSend : %@", pathOfImageToSend);
			}
		}
		
		NSMutableArray *file2Send = [NSMutableArray arrayWithCapacity:1];
		//[file2Send addObject:pathOfImageToSend];
		[file2Send addObject:imageToSend];
		[SendController sendFiles:file2Send];
	}
}


#pragma mark Result

-(void)computeValues {
	// horizontal angle
	_horizontalAngle = kInvalidAngle;
	if (_horizontalAxis && [[_horizontalAxis points] count] == 2)
		_horizontalAngle = [_horizontalAxis pointAtIndex:0].x < [_horizontalAxis pointAtIndex:1].x?
			NSAngle([_horizontalAxis pointAtIndex:0], [_horizontalAxis pointAtIndex:1]) :
			NSAngle([_horizontalAxis pointAtIndex:1], [_horizontalAxis pointAtIndex:0]) ;
	
	// femur angle
	_femurAngle = kInvalidAngle;
	if (_femurAxis && [[_femurAxis points] count] == 2)
		_femurAngle = [_femurAxis pointAtIndex:0].y < [_femurAxis pointAtIndex:1].y?
			NSAngle([_femurAxis pointAtIndex:0], [_femurAxis pointAtIndex:1]) :
			NSAngle([_femurAxis pointAtIndex:1], [_femurAxis pointAtIndex:0]) ;
	else if (_horizontalAngle != kInvalidAngle)
		_femurAngle = _horizontalAngle+pi/2;
	
	NSLog(@"fa %f", _femurAngle);
	
	// leg inequalty
	
	// cup inclination
	if (_cupLayer && [[_cupLayer points] count] >= 6) {
		_cupAngle = -([self estimateRotationOfROI:_cupLayer]-_horizontalAngle)/pi*180;
		[_cupAngleTextField setStringValue:[NSString stringWithFormat:@"Rotation angle: %.2f°", _cupAngle]];
	}
	
	// stem inclination
	if (_stemLayer && [[_stemLayer points] count] >= 6) {
		_stemAngle = -([self estimateRotationOfROI:_stemLayer]+pi/2-_femurAngle)/pi*180;
		[_stemAngleTextField setStringValue:[NSString stringWithFormat:@"Rotation angle: %.2f°", _stemAngle]];
 	}
	
	[self updateInfo];
}

- (void)createInfoBox {
	if (_femurRoi && [[_femurRoi points] count] > 0 && [_femurRoi pointAtIndex:0] != NSZeroPoint)
		if (_infoBox)
			return;
		else {
			NSPoint pt = NSZeroPoint;
			for (MyPoint* p in [_femurRoi points])
				pt += [p point];
			pt /= [[_femurRoi points] count];
			BOOL left = pt.x < [[[_viewerController imageView] curDCM] pwidth]/2;
			_infoBox = [[ROI alloc] initWithType:tText :[[_viewerController imageView] pixelSpacingX] :[[_viewerController imageView] pixelSpacingY] :[[_viewerController imageView] origin]];
			[_infoBox setROIRect:NSMakeRect([[[_viewerController imageView] curDCM] pwidth]/4*(left?3:1), [[[_viewerController imageView] curDCM] pheight]/3*2, 0.0, 0.0)];
			[[_viewerController imageView] roiSet:_infoBox];
			[[[_viewerController roiList] objectAtIndex:[[_viewerController imageView] curImage]] addObject:_infoBox];
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:_infoBox userInfo:NULL];
			[_infoBox release];
		}
	else
		if (_infoBox)
			[self removeRoiFromViewer:_infoBox];
}

-(void)updateInfo {
	[self createInfoBox];
	if (!_infoBox) return;
	
	NSMutableString* str = [[NSMutableString alloc] initWithCapacity:512];
	
	[str appendString:@"OsiriX Arthroplasty Templating"];
	
	if (_originalLegInequality || _legInequality) {
		[str appendFormat:@"\nLeg length discrepancy:\n"];
		if (_originalLegInequality)
			[str appendFormat:@"\tOriginal: %.2f cm\n", _originalLegInequalityValue];
		if (_legInequality)
			[str appendFormat:@"\tFinal: %.2f cm\n", _legInequalityValue];
		if (_originalLegInequality && _legInequality) {
			CGFloat change = std::abs(_originalLegInequalityValue - _legInequalityValue);
			[str appendFormat:@"\tVariation: %.2f cm\n", change];
			[_verticalOffsetTextField setStringValue:[NSString stringWithFormat:@"Vertical offset variation: %.2f cm", change]];
		}
		
		if (_horizontalAxis && _femurLandmarkOriginal && _femurLandmarkAxis) {
			[str appendFormat:@"Lateral offset variation: %.2f cm\n", _lateralOffsetValue];
			[_horizontalOffsetTextField setStringValue:[NSString stringWithFormat:@"Lateral offset variation: %.2f cm", _lateralOffsetValue]];
		}
	}
	
	if (_cupLayer) {
		[str appendFormat:@"\nCup: %@\n", [_cupTemplate name]];
		[str appendFormat:@"\tManufacturer: %@\n", [_cupTemplate manufacturer]];
		[str appendFormat:@"\tSize: %@\n", [_cupTemplate size]];
		[str appendFormat:@"\tRotation: %.2f°\n", _cupAngle];
		[str appendFormat:@"\tReference: %@\n", [_cupTemplate referenceNumber]];
	}
	
	if (_stemTemplate) {
		[str appendFormat:@"\nStem: %@\n", [_stemTemplate name]];
		[str appendFormat:@"\tManufacturer: %@\n", [_stemTemplate manufacturer]];
		[str appendFormat:@"\tSize: %@\n", [_stemTemplate size]];
		[str appendFormat:@"\tReference: %@\n", [_stemTemplate referenceNumber]];
	}

	if ([_neckSizePopUpButton isEnabled])
		[str appendFormat:@"\nNeck size: %@\n", [[_neckSizePopUpButton selectedItem] title]];

	if ([[_plannersNameTextField stringValue] length])
		[str appendFormat:@"\nPlanified by: %@\n", [_plannersNameTextField stringValue]];
	if (_planningDate)
		[str appendFormat:@"Date: %@\n", _planningDate];

	[_infoBox setName:str];
}

@end

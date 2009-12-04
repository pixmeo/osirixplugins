//
//  CMIVVesselPlotView.h
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMIVVesselPlotView : NSView {
	IBOutlet NSPopUpButton *yAxisOptionsButton;
	NSColor *backgroundColor, *pointsColor, *curveColor, *textLabelColor, *axesColor, *selectBoxColor,*referenceLineColor;
	int leftSpace, bottomSpace;
	int pointDiameter;
	int lineWidth;
	float xScaleFactor,yScaleFactor;
	float xUnit,yUnit;
	float xStepLength;
	float xLeftLimit,xRightLimit;
	float yTopLimit, yBottomLimit;
	NSRect viewFrame;
	int handleSize;
	NSAffineTransform* globalTransform;
	NSAffineTransform* invertedTransfer;
	NSArray* currentCurve;
	id viewControllor;
	float curPtX;
	float startPtX,endPtX;
	
	NSRect curXHandleRect;
	NSPoint startDragPoint;
	
	float curPtY;
	float referenceY;
	
	float mousePtX;
	
	int mouseStartDraggingFlag;
	int curseLabelFlag;
	
}

@property(readonly) float curPtX;

- (NSAffineTransform *)transform:(NSRect) rect;
- (void)setACurve:(NSString*)name:(NSArray*)curve:(NSColor*)color:(float)xscale:(float)yscale;
- (void)removeCurCurve;
- (void)setViewControllor:(id)controllor;
- (void)drawAxesInRect:(NSRect)rect;
- (void)drawCurveInRect:(NSRect)rect; 
- (void)drawSelectedBoxInRect:(NSRect)rect;
- (void)drawStenosisBoxInRect:(NSRect)rect;
- (void)setCursorLabelWithText:(NSString*)text;
@end

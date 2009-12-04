//
//  CMIVDCMView.h
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCMPix.h"	
#import "DCMView.h"	

@interface CMIVDCMView : DCMView {
	NSSlider* tranlateSlider;
	NSSlider* horizontalSlider;
	NSPoint crossPoint;
	id dcmViewWindowController;
	int mouseOperation;
	float crossAngle;
	float mouseToCrossXAngle;
	int displayCrossLines;
	int ifLeftButtonDown;
	
}
-(void)showCrossHair;
-(void)hideCrossHair;
-(void)setTranlateSlider:(NSSlider*) aSlider;
-(void)setHorizontalSlider:(NSSlider*) aSlider;
-(void)setDcmViewWindowController:(id)vc;
- (void) setMPRAngle: (float) vectorMPR;

- (void) setCrossCoordinates:(float) x :(float) y :(BOOL) update;
- (void) getCrossCoordinates:(float*) x :(float*) y;

- (float) angle;
- (int) checkMouseOnCrossLines:(NSPoint)mouseLocation;
-(float) angleToCrossXFromPt:(NSPoint)pt;
@end

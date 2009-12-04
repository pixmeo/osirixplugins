//
//  SpineCounterFilter.h
//  SpineCounter
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "ROI.h"

@interface SpineCounterFilter : PluginFilter {

}

- (long) filterImage:(NSString*) menuName;

- (void) setMenus;

- (void) switchTypes: (BOOL) PSD;
- (void) incrementDefaultName;
- (void) exportSpines;
- (void) exportPSDs;
- (void) exportLengths;
- (void) exportDistances;
- (void) saveROIs;

- (NSString*) outputString:(NSString*) prevType: (NSString*) newType;


- (void) rotateSpineType:(ROI*) roi;
- (void) rotatePSDType:(ROI*) roi;


- (void) endSavePanelSpines: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo;
- (void) endSavePanelPSDs: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo;
- (void) endSavePanelLengths: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo;
- (void) endSavePanelDistances: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo;

- (ROI*) findMeasureROIWithShortnameInController: (NSString *) prefix: (ViewerController*) controller;
- (NSString *) shortname: (NSString *) name;
- (NSString *) spineType: (NSString *) name;
- (NSString *) PSDType: (NSString *) name;


- (float)	spineDistance: (ROI*) spine: (ROI*) axis;
- (NSPoint)	transformPoint: (NSPoint) point : (NSPoint) ori : (NSPoint) ext;


@end

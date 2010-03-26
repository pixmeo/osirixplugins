//
//  CardiacStatisticsFilter.h
//  CardiacStatistics
//
//  Copyright (c) 2010 StanislasRapacchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

#import "SectorManagerController.h"


@interface CardiacStatisticsFilter : PluginFilter {
	//need to create a new panel
	IBOutlet NSWindow       *mywindow;
	
	IBOutlet NSButton *DoneButton;
	
	IBOutlet NSButton *InitButton;
	IBOutlet NSButton *SegmentButton;
	IBOutlet NSButton *DeleteSectorsButton;
	
	IBOutlet NSTextField *TextDisplayField;
	
	IBOutlet NSTextField *SectorNumberField;
	IBOutlet NSTextField *LayersNumberField;
	
	//mouse handling
	NSPoint prevclickedPoint;
	int clickCount;
	
	//init sectors array
	NSMutableArray *SectorArray;	
}

- (long) filterImage:(NSString*) menuName;

// Actions

- (IBAction)endMyDialog:(id)sender;

- (IBAction)SegmentInter:(id)sender;

-(IBAction) DeleteSectors:(id)sender;

// Specific functions

-(NSPoint)GetPointfromRoiwithAngle:(ROI*)myRoi:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle;

-(ROI*)GetRoibtwRoiswithAngle:(ROI*)myRoi1:(ROI*)myRoi2:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle;

-(ROI*) CreateROIbwnROI1andROI2:(ROI*)ROI1:(ROI*)ROI2:(float)factor1:(float)factor2;

- (NSMutableArray*)RetrieveSectorsinRoiList:(NSMutableArray*)RoiList;

- (NSMutableArray*)DeleteSectorsinRoiList:(NSMutableArray*)RoiList;


// Generic functions

-(NSPoint)CreatePointfromPointandAngleandRadius:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle:(float)gRadius;

-(ROI*) FindRoiByName:(NSString*) RoiName;

-(float)myAngle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3;

-(ROI*) ResampleRoiSplinePoints:(ROI*)RoiIn;

-(ROI*) ResampleRoiSplinePoints:(ROI*)RoiIn:(long)PointsStep;

// Mouse handling
- (IBAction)startTrackingMouse:(id)sender;

- (void)stopTrackingMouse;

-(void)myMouseDown:(NSNotification*)note;

@end

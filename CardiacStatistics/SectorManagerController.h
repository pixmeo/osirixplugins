/*=========================================================================
Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - LGPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>

#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/ROI.h>
#import <OsiriX Headers/ViewerController.h>

#import "CardiacStatisticsFilter.h"

/** \brief  Window Controller for Sector management */

@interface SectorManagerController : NSWindowController
{
		ViewerController			*viewer;
		IBOutlet NSTableView		*tableView;
		float						pixelSpacingZ;
	
		DCMPix	*curPix;
		NSMutableArray *LocSectorArray;
		IBOutlet NSTextField		*inputThreshold;
}

/** Default initializer */
- (id) initWithViewer:(ViewerController*) v:(NSMutableArray*) InputArray;
/** Delete ROI */
- (IBAction)deleteROI:(id)sender;
	// Table view data source methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex;
- (void) roiListModification :(NSNotification*) note;
- (void) fireUpdate: (NSNotification*) note;

- (IBAction) menuExport: (id)sender;

- (IBAction) AvdancedMode:(id) sender;

-(float) GetMedianValueinRoi:(ROI*)myROI:(DCMPix*)myPix;

-(float) GetPercentAboveThreshinRoi:(ROI*)myROI:(DCMPix*)myPix:(float)thresh;

-(IBAction) keyDownInput:(id)sender;

int CmpFunc ( const void* _a , const void* _b);

@end

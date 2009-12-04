/*=========================================================================
CMIVSaveResult

Save 2D images in current 2D viewer into OsiriX database and open the new
series and copye the ROIs into the new series

Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

CMIV CTA image processing Plugin for OsiriX is free software;
you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option)
any later version.

CMIV CTA image processing Plugin for OsiriX is distributed in
the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "PluginFilter.h"
#import "CMIV_CTA_TOOLS.h"
@interface CMIVSaveResult : NSObject
{
	IBOutlet NSWindow	*window;
    IBOutlet NSTextField *seriesName;
    IBOutlet NSTextField *seriesNumber;
	IBOutlet NSButton *okButton;
	ViewerController     *originalViewController;
	CMIV_CTA_TOOLS* parent;
	NSMatrix * previewMatrix;
	int seriesBefore;
	NSString			*exportSeriesUID;
	NSTimer* databaseUpdateTimer;
	int checkTime;
	id waitWindow;
}
- (IBAction)onCancel:(id)sender;
- (IBAction)onSave:(id)sender;
- (id) showSaveResultPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner;
- (void) exportSeries:(ViewerController *) vc:(NSString*)sname:(int)snumber:(CMIV_CTA_TOOLS*) owner;
@end

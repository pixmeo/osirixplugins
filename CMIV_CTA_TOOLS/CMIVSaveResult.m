/*=========================================================================
Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linköping University, Sweden, http://www.cmiv.liu.se/

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

#import "CMIVSaveResult.h"
#import "CMIVExport.h"

//#define VERBOSEMODE


@implementation CMIVSaveResult

- (IBAction)onCancel:(id)sender
{
	if(databaseUpdateTimer)
	{
		[databaseUpdateTimer invalidate];
		[databaseUpdateTimer release];
		databaseUpdateTimer=nil;
	}
	if(waitWindow)
		[originalViewController endWaitWindow: waitWindow];
	if([window isVisible])
	{
		[window setReleasedWhenClosed:YES];
		[window close];
		[NSApp endSheet:window returnCode:[sender tag]];
		[parent cleanSharedData];
	}
}

- (IBAction)onSave:(id)sender
{
#ifdef VERBOSEMODE
	NSLog( @"**********Start Exporting Data************");
#endif
	[self exportSeries:originalViewController:[seriesName stringValue]:[seriesNumber intValue]:parent];
	[okButton setEnabled: NO];
	
}
-(void) exportSeries:(ViewerController *) vc:(NSString*)sname:(int)snumber:(CMIV_CTA_TOOLS*) owner
{	

	checkTime=0;
	originalViewController=vc;	
	parent = owner;
	CMIVExport *exporter=[[CMIVExport alloc] init];
	[exporter setSeriesDescription: sname];
	if(snumber<=0)
		[exporter setSeriesNumber:6600 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];
	else
		[exporter setSeriesNumber:snumber];
	[exporter exportCurrentSeries: vc];
	//exportSeriesUID=[[exporter exportSeriesUID] retain];
	[exporter release];	
	[self onCancel:nil];
	return;
	
}
- (id) showSaveResultPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner
{

	originalViewController=vc;	
	parent = owner;


	[NSBundle loadNibNamed:@"Save_Panel" owner:self];
	[seriesName setStringValue:[[originalViewController window] title]];
	[NSApp beginSheet: window modalForWindow:[originalViewController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	//[window makeKeyAndOrderFront:nil];
	return self;
}
@end

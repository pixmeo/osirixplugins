/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "RoiEnhancementROIList.h"
#import <OsiriXAPI/ROI.h>
#import "RoiEnhancementInterface.h"
#import "RoiEnhancementChart.h"
#import <OsiriXAPI/ViewerController.h>
#import <GRLineDataSet.h>
#import <GRAreaDataSet.h>
#import "RoiEnhancementOptions.h"
#import <OsiriXAPI/Notifications.h>

@implementation RoiEnhancementROIRec
@synthesize roi = _roi;
@synthesize menuItem = _menuItem;
@synthesize roiIndexPixList = _roiIndexPixList;
@synthesize minDataSet = _minDataSet, meanDataSet = _meanDataSet, maxDataSet = _maxDataSet, minmaxDataSet = _minmaxDataSet;

-(id)init:(ROI*)roi forList:(RoiEnhancementROIList*)roiList index:(NSUInteger)i{
	self = [super init];
	
	_roiList = roiList;
	_roi = [roi retain];
    _roiIndexPixList = i;
    
	_menuItem = [[NSMenuItem alloc] initWithTitle:[roi name] action:@selector(roiMenuItemSelected:) keyEquivalent:@""];
	[_menuItem setTarget:roiList];
	
	_minDataSet = [[[[_roiList interface] chart] createOwnedLineDataSet] retain];
	[[[_roiList interface] chart] addDataSet:_minDataSet loadData:NO];
	_meanDataSet = [[[[_roiList interface] chart] createOwnedLineDataSet] retain];
	[[[_roiList interface] chart] addDataSet:_meanDataSet loadData:NO];
	_maxDataSet = [[[[_roiList interface] chart] createOwnedLineDataSet] retain];
	[[[_roiList interface] chart] addDataSet:_maxDataSet loadData:NO];
	_minmaxDataSet = [[[[_roiList interface] chart] createOwnedAreaDataSetFrom:_minDataSet to:_maxDataSet] retain];
	[[[_roiList interface] chart] addAreaDataSet:_minmaxDataSet];
	
	[_minDataSet setProperty:[NSNumber numberWithFloat:1] forKey:GRDataSetPlotLineWidth];
	[_maxDataSet setProperty:[NSNumber numberWithFloat:1] forKey:GRDataSetPlotLineWidth];
	
	_displayed = NO; [self setDisplayed:NO];

	return self;
}

-(void)updateDisplayed {
	[_minmaxDataSet setDisplayed: (_displayed && [[[_roiList interface] options] fill])];
	[_minDataSet setProperty:[NSNumber numberWithBool:!(_displayed && [[[_roiList interface] options] min])] forKey:GRDataSetHidden];
	[_meanDataSet setProperty:[NSNumber numberWithBool:!(_displayed && [[[_roiList interface] options] mean])] forKey:GRDataSetHidden];
	[_maxDataSet setProperty:[NSNumber numberWithBool:!(_displayed && [[[_roiList interface] options] max])] forKey:GRDataSetHidden];
}

-(void)setDisplayed:(BOOL)displayed {
	_displayed = displayed;
	[self updateDisplayed];
	[_menuItem setState:displayed? NSOnState : NSOffState];
}

-(BOOL)displayed {
	return _displayed;
}

-(void)dealloc {
	[[[_roiList interface] chart] removeDataSet:_minDataSet];
	[[[_roiList interface] chart] removeDataSet:_meanDataSet];
	[[[_roiList interface] chart] removeDataSet:_maxDataSet];
	[[[_roiList interface] chart] removeAreaDataSet:_minmaxDataSet];

	[_menuItem release]; _menuItem = NULL;
	[_minDataSet release]; _minDataSet = NULL;
	[_meanDataSet release]; _meanDataSet = NULL;
	[_maxDataSet release]; _maxDataSet = NULL;
	[_minmaxDataSet release]; _minmaxDataSet = NULL;
//	[_roiList release]; _roiList = NULL;
	[_roi release]; _roi = NULL;
	
	[super dealloc];
}

@end


@implementation RoiEnhancementROIList
@synthesize interface = _interface;

-(void)awakeFromNib {
	_records = [[NSMutableArray alloc] init];
	
	[self displaySelectedROIs];
	
	[_menu retain];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiChange:) name:OsirixROIChangeNotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeROI:) name:OsirixRemoveROINotification object:NULL];
}

-(void)loadViewerROIs {
	NSArray* roiSeriesList = [[_interface viewer] roiList];
	for (unsigned i = 0; i < [roiSeriesList count]; i++) {
		NSArray* roiImageList = [roiSeriesList objectAtIndex:i];
		for (unsigned x = 0; x < [roiImageList count]; x++)
			[[NSNotificationCenter defaultCenter] postNotificationName:OsirixROIChangeNotification object:[roiImageList objectAtIndex:x]];
	}
	
	unsigned displayedCount = [self countOfDisplayedROIs];
	if (!displayedCount || displayedCount == [_records count])
		[self displayAllROIs];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_records release]; _records = NULL;
	[_menu release]; _menu = NULL;
	[super dealloc];
}

-(unsigned)countOfDisplayedROIs {
	unsigned count = 0;
	for (unsigned i = 0; i < [_records count]; ++i)
		if ([(RoiEnhancementROIRec*)[_records objectAtIndex:i] displayed])
			++count;
	return count;
}

-(RoiEnhancementROIRec*)displayedROIRec:(unsigned)index {
	unsigned count = 0;
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		if ([roiRec displayed])
			if (count++ == index)
				return roiRec;
	}
	
	return NULL;
}

-(RoiEnhancementROIRec*)findRecordByROI:(ROI*)roi {
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		if ([roiRec roi] == roi)
			return roiRec;
	}
	
	return NULL;
}

-(RoiEnhancementROIRec*)findRecordByMenuItem:(NSMenuItem*)menuItem {
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		if ([roiRec menuItem] == menuItem)
			return roiRec;
	}
	
	return NULL;
}

-(RoiEnhancementROIRec*)findRecordByDataSet:(GRDataSet*)dataSet sel:(ROISel*)sel {
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		if ([roiRec minDataSet] == dataSet)
			{ *sel = ROIMin; return roiRec; }
		if ([roiRec meanDataSet] == dataSet)
			{ *sel = ROIMean; return roiRec; }
		if ([roiRec maxDataSet] == dataSet)
			{ *sel = ROIMax; return roiRec; }
	}
	
	*sel = (ROISel)-1;
	return NULL;
}

-(RoiEnhancementROIRec*)findRecordByDataSet:(GRDataSet*)dataSet {
	ROISel sel;
	return [self findRecordByDataSet:dataSet sel:&sel];
}

// check whether the parameter ROI is in this graph's associated viewer
-(NSUInteger)indexInViewer:(ROI*)roi {
	NSArray* roiSeriesList = [[_interface viewer] roiList];
	for (unsigned i = 0; i < [roiSeriesList count]; ++i) {
		NSArray* roiImageList = [roiSeriesList objectAtIndex:i];
		if ([roiImageList containsObject:roi])
			return i;
	}
	
	return NSNotFound;
}

-(void)roiChange:(NSNotification*)notification
{
	ROI* roi = [notification object];
    
    
	// if not in our viewer, ignore
    NSUInteger index = [self indexInViewer:roi];
    if (index == NSNotFound)
		return;
	
	// if it doesn't have a surface, then we're not interested in it
	if ( [roi areaPix] <= 0)
		return;
	
	RoiEnhancementROIRec* roiRec = [self findRecordByROI:roi];
	if (!roiRec) { // not in list
		// create record, store it in the list, add its menu item to the menu
		roiRec = [[[RoiEnhancementROIRec alloc] init:roi forList:self index: index] autorelease];
		[_menu addItem:[roiRec menuItem]];
		[_records addObject:roiRec];
		[[roiRec meanDataSet] setProperty:[roi name] forKey:GRDataSetLegendLabel];
		// display if in mode "display all" - mode "display selected" is handled later
		[roiRec setDisplayed:_display_all];
//		[roiRec release];
		// the separator between menus must be shown, as there are ROIs in the list
		[_separator setHidden:NO];
	}
	
	// update name if necessary
	if (![[[roiRec menuItem] title] isEqualToString:[roi name]]) // if name has changed, update menu
		[[roiRec menuItem] setTitle:[roi name]];
		
	// handle selection changes
	if (_display_selected) {
		BOOL should_display = roi.ROImode == ROI_selected;
		if (should_display != [roiRec displayed])
			[roiRec setDisplayed:should_display];
	}
	
	[[_interface chart] refresh:roiRec];
}

-(void)removeROI:(NSNotification*)notification {
	ROI* roi = [notification object];

	RoiEnhancementROIRec* roiRec = [self findRecordByROI:roi];
	// if it's not in our list, ignore it
	if (!roiRec)
		return;

	// it is in our list, remove the menu item
	[_menu removeItem:[roiRec menuItem]];
	
	// if it is displayed, hide it
	if ([roiRec displayed])
		[roiRec setDisplayed:NO];

	// remove from list
	[_records removeObject:roiRec];
	
	// might need to hide the separator between menus
	[_separator setHidden:[_records count] == 0];

	[[_interface chart] setNeedsDisplay:YES];
}

-(void)setButtonTitle:(NSString*)title {
	[_button setTitle:[NSString stringWithFormat:@"Display: %@", title]];
}

-(void)displayAllROIs {
	[_all setState:_display_all = YES];
	[_selected setState:_display_selected = NO];
	[_checked setState:_display_checked = NO];
	[self setButtonTitle:[_all title]];
	
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		[roiRec setDisplayed:YES];
	}
}

-(void)displayAllROIs:(id)sender {
	[self displayAllROIs];
}

-(void)displaySelectedROIs {
	[_all setState:_display_all = NO];
	[_selected setState:_display_selected = YES];
	[_checked setState:_display_checked = NO];
	[self setButtonTitle:[_selected title]];
	
	for (unsigned i = 0; i < [_records count]; ++i) {
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		[roiRec setDisplayed:[roiRec roi].ROImode == ROI_selected];
	}
}

-(void)displaySelectedROIs:(id)sender {
	[self displaySelectedROIs];
}

-(void)displayCheckedROIs {
	[_all setState:_display_all = NO];
	[_selected setState:_display_selected = NO];
	[_checked setState:_display_checked = YES];
	
	unsigned displayedCount = 0;
	RoiEnhancementROIRec* firstDisplayed = NULL;
	for (unsigned i = 0; i < [_records count]; ++i){
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		
		BOOL displayed = [roiRec displayed];
		[roiRec setDisplayed:displayed];
		
		if (displayed) {
			++displayedCount;
			if (!firstDisplayed)
				firstDisplayed = roiRec;
		}
	}
	
	[self setButtonTitle:displayedCount == 1 ? [[firstDisplayed menuItem] title] : [_checked title]];
}

-(void)displayCheckedROIs:(id)sender {
	[self displayCheckedROIs];
}

-(void)roiMenuItemSelected:(id)sender {
	RoiEnhancementROIRec* roiRec = [self findRecordByMenuItem:sender];
	[roiRec setDisplayed:![roiRec displayed]];
	[self displayCheckedROIs];
}

-(void)changedMin:(BOOL)min mean:(BOOL)mean max:(BOOL)max fill:(BOOL)fill {
	for (unsigned i = 0; i < [_records count]; ++i){
		RoiEnhancementROIRec* roiRec = [_records objectAtIndex:i];
		[roiRec updateDisplayed];
	}
}

@end
	
	
	

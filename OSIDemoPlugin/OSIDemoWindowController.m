//
//  OSIDemoWindowController.m
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSIDemoWindowController.h"
#import "OSIEnvironment.h"
#import "OSIVolumeWindow.h"
#import "OSIROI.h"
#import "OSIDemoCoalescedWindowController.h"

@interface OSIDemoWindowController ()

- (void)_openVolumeWindowsDidUpdateNotification:(NSNotification *)notification;
- (void)_roisDidUpdateNotification:(NSNotification *)notification;
- (IBAction)_openCoalescedWindow:(id)sender;

@end

@implementation OSIDemoWindowController

@synthesize outlineView = _outlineView;

- (id)init
{
	if ( (self = [super initWithWindowNibName:@"OSIDemoWindowController"]) ) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_openVolumeWindowsDidUpdateNotification:) name:OSIEnvironmentOpenVolumeWindowsDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_roisDidUpdateNotification:) name:OSIROIManagerROIsDidUpdateNotification object:nil];
		[self retain]; // matched in - (void)windowWillClose:(NSNotification *)notification
	}
	return self;
}

- (void)awakeFromNib
{
    [_outlineView setTarget:self];
    [_outlineView setDoubleAction:@selector(_openCoalescedWindow:)];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_outlineView release];
	_outlineView = nil;
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[self autorelease]; // from the retain in init
}

#pragma mark -
#pragma mark NSOutlineViewDataSource Methods

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (item == nil) {
		return [[[OSIEnvironment sharedEnvironment] openVolumeWindows] objectAtIndex:index];
	} else if ([item isKindOfClass:[OSIVolumeWindow class]]) {
		return [[[(OSIVolumeWindow *)item ROIManager] ROIs] objectAtIndex:index];
	} else {
		return nil;
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isKindOfClass:[OSIVolumeWindow class]]) {
		return YES;
	} else {
		return NO;
	}
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if ([item isKindOfClass:[OSIVolumeWindow class]]) {
		if ([[tableColumn identifier] isEqualToString:@"name"]) {
			return [(OSIVolumeWindow *)item title];
		} else {
			return @"";
		}
	} else if ([item isKindOfClass:[OSIROI class]]) {
		if ([[tableColumn identifier] isEqualToString:@"name"]) {
			return [(OSIROI *)item name];
		} else if ([[tableColumn identifier] isEqualToString:@"value"]) {
			return [(OSIROI *)item label];
        } else {
			return @"";
		}
	} else {
		return @"";
	}
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil) {
		return [[[OSIEnvironment sharedEnvironment] openVolumeWindows] count];
	} else if ([item isKindOfClass:[OSIVolumeWindow class]]) {
		return [[[(OSIVolumeWindow *)item ROIManager] ROIs] count];
	} else {
		return 0;
	}

}

- (void)_openVolumeWindowsDidUpdateNotification:(NSNotification *)notification
{
	[_outlineView reloadItem:nil];
}

- (void)_roisDidUpdateNotification:(NSNotification *)notification
{
	[_outlineView reloadItem:nil];
}

- (IBAction)_openCoalescedWindow:(id)sender
{
    OSIDemoCoalescedWindowController *newWindow;
    OSIVolumeWindow *volumeWindow;
    id item;
    NSInteger clickedRow;
    
    clickedRow = [_outlineView clickedRow];
    if (clickedRow < 0) {
        return;
    }
    item = [_outlineView itemAtRow:clickedRow];
    if ([item isKindOfClass:[OSIVolumeWindow class]] == NO) {
        return;
    }
    
    volumeWindow = (OSIVolumeWindow*)item;
    newWindow = [[OSIDemoCoalescedWindowController alloc] initWithVolumeWindow:volumeWindow];
    [newWindow showWindow:self];
    [newWindow release];
}

@end

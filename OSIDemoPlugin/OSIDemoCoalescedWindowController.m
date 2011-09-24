//
//  OSIDemoCoalescedWindowController.m
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "OSIDemoCoalescedWindowController.h"
#import <OsiriXAPI/OSIVolumeWindow.h>
#import <OsiriXAPI/OSIROIManager.h>
#import <OsiriXAPI/OSIROI.h>

@interface OSIDemoCoalescedWindowController ()

- (void)_roisDidUpdateNotification:(NSNotification *)notification;

@end

@implementation OSIDemoCoalescedWindowController

@synthesize outlineView = _outlineView;
@synthesize volumeWindow = _volumeWindow;

- (id)initWithVolumeWindow:(OSIVolumeWindow *)volumeWindow;
{
	if ( (self = [super initWithWindowNibName:@"OSIDemoWindowController"]) ) {
        _volumeWindow = [volumeWindow retain];
        _coalescedROIManager = [[OSIROIManager alloc] initWithVolumeWindow:_volumeWindow coalesceROIs:YES];
        _coalescedROIManager.delegate = self;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_roisDidUpdateNotification:) name:OSIROIManagerROIsDidUpdateNotification object:nil];
		[self retain]; // matched in - (void)windowWillClose:(NSNotification *)notification
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_outlineView release];
	_outlineView = nil;
    [_volumeWindow release];
    _volumeWindow = nil;
    _coalescedROIManager.delegate = nil;
    [_coalescedROIManager release];
    _coalescedROIManager = nil;
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
        return [[_coalescedROIManager ROIs] objectAtIndex:index];
    } else {
        return nil;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
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
		return [[_coalescedROIManager ROIs] count];
	} else {
		return 0;
	}
    
}

- (void)_roisDidUpdateNotification:(NSNotification *)notification
{
	[_outlineView reloadItem:nil];
}



@end

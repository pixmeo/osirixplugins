//
//  OSIDemoCoalescedWindowController.h
//  OSIDemo
//
//  Created by Joël Spaltenstein on 2/21/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OSIROIManager.h"

@class OSIVolumeWindow;
@class OSIROIManager;

@interface OSIDemoCoalescedWindowController : NSWindowController <OSIROIManagerDelegate> {
	NSOutlineView *_outlineView;
    OSIVolumeWindow *_volumeWindow;
    OSIROIManager *_coalescedROIManager;
}

@property (nonatomic, readwrite, retain) IBOutlet NSOutlineView *outlineView;
@property (nonatomic, readonly, retain) OSIVolumeWindow *volumeWindow;

- (id)initWithVolumeWindow:(OSIVolumeWindow *)volumeWindow;

@end

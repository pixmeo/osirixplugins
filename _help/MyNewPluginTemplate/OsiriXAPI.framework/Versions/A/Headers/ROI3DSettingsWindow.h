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

#import <AppKit/AppKit.h>
#import "ROI.h"

/** \brief Window Controller for histogram display */

@interface ROI3DSettingsWindow : NSWindowController {
    IBOutlet NSPopover *popoverPeak, *popoverIso;
    NSColor *isoContourColor, *peakValueColor;
}

@property (retain, nonatomic) NSColor *isoContourColor, *peakValueColor;

- (IBAction)togglePopover:(NSButton*)sender;
- (id) init;
@end

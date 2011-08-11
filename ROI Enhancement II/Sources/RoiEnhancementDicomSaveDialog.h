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

#import <Cocoa/Cocoa.h>
@class RoiEnhancementInterface;

@interface RoiEnhancementDicomSaveDialog : NSWindow<NSWindowDelegate> {
	IBOutlet RoiEnhancementInterface* _interface;
	IBOutlet NSColorWell* _imageBackgroundColor;
	IBOutlet NSButton* _saveButton;
	IBOutlet NSButton* _cancelButton;
	IBOutlet NSTextField* _seriesName;
}

@property(assign) NSColor* imageBackgroundColor;
@property(assign) NSString* seriesName;

-(IBAction)buttonClicked:(id)sender;

@end

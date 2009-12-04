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
@class Interface;

@interface DicomSaveDialog : NSWindow {
	IBOutlet Interface* _interface;
	IBOutlet NSColorWell* _imageBackgroundColor;
	IBOutlet NSButton* _saveButton;
	IBOutlet NSButton* _cancelButton;
}

-(IBAction)buttonClicked:(id)sender;

-(NSColor*)imageBackgroundColor;
-(void)setImageBackgroundColor:(NSColor*)imageBackgroundColor;

@end

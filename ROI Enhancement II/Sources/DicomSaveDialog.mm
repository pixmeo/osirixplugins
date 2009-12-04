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

#import "DicomSaveDialog.h"


@implementation DicomSaveDialog

-(void)awakeFromNib {
	[self setDefaultButtonCell:[_saveButton cell]];
	[self setDelegate:self];
}

-(IBAction)buttonClicked:(id)sender {
	[NSApp endSheet:self returnCode:(sender==_saveButton?NSOKButton:NSCancelButton)];
	[self orderOut:self];
}

-(NSColor*)imageBackgroundColor {
	return [_imageBackgroundColor color];
}

-(void)setImageBackgroundColor:(NSColor*)imageBackgroundColor {
	[_imageBackgroundColor setColor:imageBackgroundColor];
}
@end

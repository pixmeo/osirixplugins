//
//  EjectionFractionDicomSaveDialog.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 18.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionDicomSaveDialog.h"


@implementation EjectionFractionDicomSaveDialog

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

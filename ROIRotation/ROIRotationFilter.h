/*=========================================================================
  Program:   OsiriX

  Copyright (c) Kanteron Systems, Spain
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.kanteron.com

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface ROIRotationFilter : PluginFilter
{
    IBOutlet NSSlider *angleCir;
    IBOutlet NSTextField *angleField;
	IBOutlet NSTextField *angleField2;
    IBOutlet NSWindow *window;
	float angleRoiOld,angleRoiNew,angleValue;
}

- (long) filterImage:(NSString*) menuName;
-(void)rotateRoi:(float)rotationAngle;
- (IBAction)endDialog:(id)sender;
- (IBAction)setAngleToRoi:(id)sender;
@end

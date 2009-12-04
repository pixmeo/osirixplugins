
/*=========================================================================
CMIVSpoonController

Binary mathematic morphology operation on 2d/3d images with vtk.

Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

CMIV CTA image processing Plugin for OsiriX is free software;
you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option)
any later version.

CMIV CTA image processing Plugin for OsiriX is distributed in
the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/

#import <Cocoa/Cocoa.h>
#import "DCMObject.h"
#import "DCMCalendarDate.h"
#import "CMIV_CTA_TOOLS.h"
#include <Accelerate/Accelerate.h>
#import "PluginFilter.h"
#define id Id
#include <vtkImageImport.h>
#include <vtkImageData.h>
#include <vtkImageContinuousErode3D.h>
#include <vtkImageContinuousDilate3D.h>
#include <vtkImageMathematics.h>
#include <vtkImageThreshold.h>
#include <vtkImageOpenClose3D.h>
#include <vtkImageDilateErode3D.h>

#undef id
enum DCM_CompressionQuality {DCMLosslessQuality, DCMHighQuality, DCMMediumQuality, DCMLowQuality};
@interface CMIVSpoonController : NSObject
{
	IBOutlet NSWindow	*window;
    IBOutlet NSMatrix *exportOption;
    IBOutlet NSSlider *imageSlider;
    IBOutlet NSMatrix *operationOption;
    IBOutlet DCMView *viewer;
    IBOutlet NSTextField *xRadius;
    IBOutlet NSTextField *yRadius;
    IBOutlet NSTextField *zRadius;
    IBOutlet NSSlider *thresholdSlider;
    IBOutlet NSMatrix *binaryOrROIOption;
	IBOutlet NSPopUpButton *existedROI;
	IBOutlet NSTextField *maskName;
	IBOutlet NSButton *deleteCurrentSeries;	
	
	IBOutlet NSTextField *thresholdText;
	
	ViewerController     *originalViewController;
	
	int              isFirstTime;
	NSMutableArray    *viewROIList;
	NSMutableArray    *resultROIList;
	NSMutableArray    *controllorROIList;
	NSMutableArray    *existedMaskList;
	NSArray				*pixList;
	DCMPix*				curPix;
	RGBColor		color;
	int                 imageWidth , imageHeight , imageAmount;
	int             isShowingResult;
	NSMutableArray      *toolbarList;
	CMIV_CTA_TOOLS* parent;

}
- (IBAction)applyOperation:(id)sender;
- (IBAction)cancelDialog:(id)sender;
- (IBAction)exportImages:(id)sender;
- (IBAction)goNextStep:(id)sender;
- (IBAction)setThreshold:(id)sender;
- (IBAction)setBinaryOrROI:(id)sender;
- (IBAction)selectANewROI:(id)sender;
- (IBAction)pageDownorUp:(id)sender;
- (IBAction)deleteCurrentMask:(id)sender;
- (int) showSpoonPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner;
- (void) initExistedMaskList;
- (void)updateROI:(int)imageIndex;

@end

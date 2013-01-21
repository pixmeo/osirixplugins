//
//  EjectionFractionResultsController.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class EjectionFractionWorkflow, EjectionFractionDicomSaveDialog;

@interface EjectionFractionResultsController : NSWindowController<NSWindowDelegate> {
	IBOutlet NSView* _dicomSaveOptions;
	IBOutlet NSColorWell* _dicomSaveOptionsBackgroundColor;
	IBOutlet EjectionFractionDicomSaveDialog* _dicomSaveDialog;
	EjectionFractionWorkflow* _workflow;
}

@property(retain) EjectionFractionWorkflow* workflow;

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow;
-(IBAction)print:(id)sender;
-(IBAction)saveDICOM:(id)sender;
-(IBAction)saveAsPDF:(id)sender;
-(IBAction)saveAsTIFF:(id)sender;
-(IBAction)saveAsDICOM:(id)sender;

@end

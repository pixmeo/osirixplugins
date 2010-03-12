//
//  EjectionFractionStepsController.h
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 7/20/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

@class N2Steps, N2Step, EjectionFractionWorkflow, ROI, N2View, N2Resizer, N2StepsView, N2ColorWell;

@interface EjectionFractionStepsController : NSWindowController {
	EjectionFractionWorkflow* _workflow;

	IBOutlet N2Steps* _steps;
	IBOutlet N2StepsView* _stepsView;

	N2Step* _stepAlgorithm;
	IBOutlet NSView* _viewAlgorithm;
	CGFloat _viewAlgorithmOriginalFrameHeight;
	IBOutlet NSPopUpButton* _viewAlgorithmChoice;
	IBOutlet NSImageView* _viewAlgorithmPreview;
	
	N2Step* _stepROIs;
	IBOutlet NSView* _viewROIs;
	IBOutlet NSTextField* _viewROIsText;
	NSString* _viewROIsTextFormat;
	IBOutlet N2View* _viewROIsList;
	N2Resizer* _stepROIsResizer;
	
	N2Step* _stepResult;
	IBOutlet NSView* _viewResult;
	IBOutlet NSTextField* _viewResultText;
	NSString* _viewResultTextFormat;
	IBOutlet NSButton* _viewResultShowResultWindow;
	
	NSImage* _checkmarkImage;
	NSImage* _arrowImage;
	
	N2ColorWell* _diastoleColorWell;
	N2ColorWell* _systoleColorWell;
	
//	NSMutableArray* _activeSteps;
}

@property(readonly) N2Step* stepResult;
@property(readonly) N2StepsView* stepsView;

-(IBAction)help:(id)source;

-(id)initWithWorkflow:(EjectionFractionWorkflow*)plugin;

-(void)setSelectedAlgorithm:(EjectionFractionAlgorithm*)algorithm;
-(void)setResult:(CGFloat)result;

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step;
-(void)steps:(N2Steps*)steps valueChanged:(id)sender;
-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step;
-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step;

-(IBAction)detailsButtonClicked:(id)sender;

@end

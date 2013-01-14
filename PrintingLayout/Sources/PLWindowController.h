//
//  PrintingLayoutController.h
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import <Cocoa/Cocoa.h>
#import "PLDocumentView.h"
#import "PLLayoutView.h"
#import "PLUtils.h"
#import <OsiriXAPI/ViewerController.h>

@interface PLWindowController : NSWindowController //ViewerController
{
    IBOutlet NSPopUpButton  *layoutChoiceButton;
    
    IBOutlet NSTextField    *widthTextField;
    IBOutlet NSTextField    *heightTextField;
    IBOutlet NSStepper      *widthValueAdjuster;
    IBOutlet NSStepper      *heightValueAdjuster;
    NSUInteger heightValue;
    NSUInteger widthValue;
    
    IBOutlet NSScrollView   *scrollView;  // Historic: could be really used if the scrolling was not causing trouble with NSOpenGLView
    IBOutlet PLDocumentView *fullDocumentView;
    paperSize scrollViewFormat;
    NSLayoutConstraint *ratioConstraint;
    int currentPage;
}

@property NSUInteger heightValue, widthValue;
@property paperSize scrollViewFormat;
@property int currentPage;
@property (readonly) PLDocumentView *fullDocumentView;

- (IBAction)addPage:(id)sender;
- (IBAction)insertPage:(id)sender;
- (IBAction)updateViewRatio:(id)sender;
- (IBAction)updateGridLayoutFromButton:(id)sender;
- (IBAction)displayModeChanged:(id)sender;
- (IBAction)clearViewsInLayout:(id)sender;
- (IBAction)exportViewToDicom:(id)sender;
- (IBAction)exportViewToPDF:(id)sender;
- (IBAction)changeTool:(id)sender;
- (IBAction)adjustLayoutWidth:(id)sender;
- (IBAction)adjustLayoutHeight:(id)sender;
- (IBAction)pageByPageNavigation:(id)sender;
- (void)updateHeight;
- (void)updateWidth;
- (void)layoutMatrixUpdated;
- (void)updateWindowTitle;
- (void)currentPageUpdated;

@end

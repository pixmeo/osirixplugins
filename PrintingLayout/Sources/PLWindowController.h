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

@interface PLWindowController : NSWindowController//ViewerController //
{
    IBOutlet NSButton       *exportButton;
    
    IBOutlet NSTextField    *widthTextField;
    IBOutlet NSTextField    *heightTextField;
    IBOutlet NSStepper      *widthValueAdjuster;
    IBOutlet NSStepper      *heightValueAdjuster;
    NSUInteger              heightValue, widthValue;
    
    IBOutlet NSPopUpButton  *layoutChoiceButton;
    IBOutlet NSTextField    *documentSizeIndicator;
    
    IBOutlet NSScrollView   *scrollView;  // Historic: could be really used if the scrolling was not causing trouble with NSOpenGLView
    IBOutlet PLDocumentView *fullDocumentView;
    paperSize               scrollViewFormat;
    NSLayoutConstraint      *ratioConstraint;
    NSInteger               currentPage;
    
    // Attributes specific to "whole serie import box"
    IBOutlet NSPanel        *importPanel;
    IBOutlet NSWindow       *importWindow;
    IBOutlet NSSlider       *importIntervalSlider;
    IBOutlet NSSlider       *importStartSlider;
    IBOutlet NSSlider       *importEndSlider;
    IBOutlet NSTextField    *importIntervalText;
    IBOutlet NSTextField    *importStartText;
    IBOutlet NSTextField    *importEndText;
    IBOutlet NSTextField    *pagesImport;
    NSUInteger              importInterval, importStart, importEnd, importWidth, importHeight;
    IBOutlet NSPopUpButton  *importLayoutButton;
}

@property NSUInteger                heightValue, widthValue;
@property paperSize                 scrollViewFormat;
@property NSInteger                 currentPage;
@property (readonly) PLDocumentView *fullDocumentView;
@property NSUInteger                importInterval, importStart, importEnd, importWidth, importHeight;
@property (readonly) NSWindow       *importWindow;

- (IBAction)pageAction:(id)sender;
- (IBAction)addPage:(id)sender;
- (IBAction)deletePage:(id)sender;
- (IBAction)insertPage:(id)sender;
- (IBAction)updateViewRatio:(id)sender;
- (IBAction)updateGridLayoutFromButton:(id)sender;
- (IBAction)reshapeLayout:(id)sender;
- (IBAction)clearViewsInLayout:(id)sender;
- (IBAction)exportViewToDicom:(id)sender;
- (IBAction)exportViewToPDF:(id)sender;
- (IBAction)changeTool:(id)sender;
- (IBAction)adjustLayoutWidth:(id)sender;
- (IBAction)adjustLayoutHeight:(id)sender;
- (IBAction)pageByPageNavigation:(id)sender;
- (IBAction)importParameters:(id)sender;
- (IBAction)intervalSliderAction:(id)sender;
- (IBAction)startSliderAction:(id)sender;
- (IBAction)endSliderAction:(id)sender;
- (IBAction)importLayoutChoice:(id)sender;
- (IBAction)updateDocSizeIndicator:(id)sender;
- (void)updateImportPageNumber;
- (void)updateHeight;
- (void)updateWidth;
- (void)layoutMatrixUpdated;
- (void)updateWindowTitle;
- (void)currentPageUpdated:(NSNotification*)notification;
- (void)saveAllROIs;
- (void)prepareImportBox:(NSUInteger)serieSize;

@end

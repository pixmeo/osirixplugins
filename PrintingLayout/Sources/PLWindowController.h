//
//  PrintingLayoutController.h
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import <Cocoa/Cocoa.h>
#import "PLLayoutView.h"

typedef enum {
    paper_A4        = 0,
    paper_USletter, // 1
    paper_8x10,     // 2
    paper_11x14,    // 3
    paper_14x17     // 4
} paperSize;

@interface PLWindowController : NSWindowController
{
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSToolbar *toolbar;
    
    IBOutlet NSPopUpButton *layoutChoiceButton;
    IBOutlet NSButton *clearViewsButton;
    IBOutlet NSMatrix *toolsMatrix;
    IBOutlet NSToolbarItem *toolMatrix;
    IBOutlet NSTextField *widthTextField;
    IBOutlet NSTextField *heightTextField;
    IBOutlet NSStepper *widthValueAdjuster;
    IBOutlet NSStepper *heightValueAdjuster;
    NSUInteger heightValue;
    NSUInteger widthValue;
    
    IBOutlet NSScrollView *scrollView;
    IBOutlet PLLayoutView *layoutView;
    paperSize scrollViewFormat;
}

@property NSUInteger heightValue;
@property NSUInteger widthValue;

- (IBAction)updateLayoutFromButton:(id)sender;
- (IBAction)clearViewsInLayout:(id)sender;
- (IBAction)exportViewToDicom:(id)sender;
- (IBAction)changeTool:(id)sender;
- (IBAction)adjustLayoutWidth:(id)sender;
- (IBAction)adjustLayoutHeight:(id)sender;
- (void)updateHeight;
- (void)updateWidth;
- (IBAction)updateViewRatio:(id)sender;
- (CGFloat)getRatioFrom:(paperSize)format;

@end

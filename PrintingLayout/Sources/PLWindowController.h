//
//  PrintingLayoutController.h
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import <Cocoa/Cocoa.h>
#import "PLLayoutView.h"

@interface PLWindowController : NSWindowController
{
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSPopUpButton *layoutChoiceButton;
    IBOutlet NSButton *clearViewsButton;
    IBOutlet PLLayoutView *layoutView;
    IBOutlet NSMatrix *toolsMatrix;
    IBOutlet NSToolbarItem *toolMatrix;
    IBOutlet NSTextField *widthTextField;
    IBOutlet NSTextField *heightTextField;
    IBOutlet NSStepper *widthValueAdjuster;
    IBOutlet NSStepper *heightValueAdjuster;
}

- (IBAction)updateLayoutFromButton:(id)sender;
- (IBAction)clearViewsInLayout:(id)sender;
- (IBAction)exportViewToDicom:(id)sender;
- (IBAction)changeTool:(id)sender;
- (IBAction)adjustLayoutWidth:(id)sender;
- (IBAction)adjustLayoutHeight:(id)sender;
- (IBAction)clearView:(id)sender;
- (IBAction)resetView:(id)sender;
- (IBAction)selectView:(id)sender;

@end

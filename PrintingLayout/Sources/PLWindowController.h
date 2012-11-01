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
}

- (IBAction)updateLayoutFromButton:(id)sender;
- (IBAction)clearViewsInLayout:(id)sender;
- (IBAction)exportViewToDicom:(id)sender;
- (IBAction)changeTool:(id)sender;

@end

//
//  PrintingLayoutController.m
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import "PLWindowController.h"
#import "OsiriXAPI/N2CustomTitledPopUpButtonCell.h"

@interface PLWindowController ()

@end

@implementation PLWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"PrintingLayoutWindow"];
    if (self)
    {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    return;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [layoutChoiceButton.cell setDisplayedTitle:@"Layout Choice"];
}

- (IBAction)updateLayoutFromButton:(id)sender
{
    NSString * name = [[layoutChoiceButton selectedItem] title];
    NSArray * c = [name componentsSeparatedByString:@"x"];
    NSUInteger x = [[c objectAtIndex:0] integerValue];
    NSUInteger y = [[c objectAtIndex:1] integerValue];
    [layoutView updateLayoutViewWidth:x height:y];
    [layoutView reorderLayoutMatrix];
    [layoutView resizeLayoutView];
}

- (void)windowDidResize:(NSNotification *)notification
{
    [layoutView resizeLayoutView];
}

- (IBAction)clearViewsInLayout:(id)sender
{
    [layoutView clearAllThumbnailsViews];
}

- (IBAction)exportViewToDicom:(id)sender
{
    [layoutView saveLayoutViewToDicom];
}

- (IBAction)changeTool:(id)sender
{
    // Copy/paste from M/CPRController.m
	int toolIndex = 0;
	
	if ([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if ([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
    
    [layoutView setMouseTool:toolIndex];
}

- (IBAction)adjustLayoutWidth:(id)sender
{
    [widthTextField setIntValue:[sender intValue]];
    [layoutView updateLayoutViewWidth:[widthTextField integerValue] height:[heightTextField integerValue]];
    [layoutView reorderLayoutMatrix];
    [layoutView resizeLayoutView];
}

- (IBAction)adjustLayoutHeight:(id)sender
{
    [heightTextField setIntValue:[sender intValue]];
    [layoutView updateLayoutViewWidth:[widthTextField integerValue] height:[heightTextField integerValue]];
    [layoutView reorderLayoutMatrix];
    [layoutView resizeLayoutView];
}

- (IBAction)clearView:(id)sender
{
    
}

- (IBAction)resetView:(id)sender
{
}

- (IBAction)selectView:(id)sender
{
}

@end





















































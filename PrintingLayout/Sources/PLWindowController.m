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

@synthesize heightValue;
@synthesize widthValue;

- (id)init
{
    self = [super initWithWindowNibName:@"PrintingLayoutWindow"];
    if (self)
    {
        // Initialization code here.
        scrollViewFormat    = paper_none;
        heightValue         = 0;
        widthValue          = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutMatrixUpdated) name:@"PLLayoutMatrixUpdated" object:nil];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [scrollView setBackgroundColor:[NSColor colorWithCalibratedWhite:.3 alpha:1]];    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [layoutChoiceButton.cell setDisplayedTitle:@"Layout Choice"];
    
    [layoutView setLayoutFormat:scrollViewFormat];
    if (scrollViewFormat)
    {
        ratioConstraint = [NSLayoutConstraint constraintWithItem:layoutView
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:layoutView
                                                       attribute:NSLayoutAttributeWidth
                                                      multiplier:[self getRatioFrom:scrollViewFormat]
                                                        constant:0];
        [layoutView addConstraint:ratioConstraint];
    }
}

- (IBAction)updateLayoutFromButton:(id)sender
{
    NSString * name = [[layoutChoiceButton selectedItem] title];
    NSArray * c = [name componentsSeparatedByString:@"x"];
    widthValue = [[c objectAtIndex:0] integerValue];
    heightValue = [[c objectAtIndex:1] integerValue];
    [self updateWidth];
    [self updateHeight];
    [layoutView updateLayoutViewWidth:widthValue height:heightValue];
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
    NSUInteger newWidth = [sender integerValue];
    if ([layoutView updateLayoutViewWidth:newWidth height:heightValue])
    {
        widthValue = newWidth;
        [self updateWidth];
        [layoutView reorderLayoutMatrix];
        [layoutView resizeLayoutView];
    }
}

- (IBAction)adjustLayoutHeight:(id)sender
{
    NSUInteger newHeight = [sender integerValue];
    if ([layoutView updateLayoutViewWidth:widthValue height:newHeight])
    {
        heightValue = newHeight;
        [self updateHeight];
        [layoutView reorderLayoutMatrix];
        [layoutView resizeLayoutView];
    }
}

- (void)updateHeight
{
    [heightTextField setIntegerValue:[self heightValue]];
    [heightValueAdjuster setIntegerValue:[self heightValue]];
}

- (void)updateWidth
{
    [widthTextField setIntegerValue:[self widthValue]];
    [widthValueAdjuster setIntegerValue:[self widthValue]];
}

// Used when the stepper and text field need to be updated from the layout view (adding a column or line)
- (void)layoutMatrixUpdated
{
    heightValue = [layoutView layoutMatrixHeight];
    widthValue = [layoutView layoutMatrixWidth];
    [self updateHeight];
    [self updateWidth];
}

- (IBAction)updateViewRatio:(id)sender
{
    [layoutView removeConstraint:ratioConstraint];
    
    scrollViewFormat = [[sender selectedItem] tag];
    [layoutView setLayoutFormat:scrollViewFormat];
    
    if (scrollViewFormat)
    {
        ratioConstraint = [NSLayoutConstraint constraintWithItem:layoutView
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:layoutView
                                                       attribute:NSLayoutAttributeWidth
                                                      multiplier:[self getRatioFrom:scrollViewFormat]
                                                        constant:0];
        [layoutView addConstraint:ratioConstraint];
    }
}

- (CGFloat)getRatioFrom:(paperSize)format
{
    switch (scrollViewFormat)
    {
        case paper_A4:
            return 1.4142;
            
        case paper_11x14:
            return 14./11.;
            
        case paper_14x17:
            return 17./14;
            
        case paper_8x10:
            return 1.25;
            
        case paper_USletter:
            return 1.2941;
            
        default: //paper_none
            return 0.;
    }
}


@end





















































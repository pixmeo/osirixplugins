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
        scrollViewFormat = paper_A4;
        heightValue = 0;
        widthValue = 0;
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
    NSLayoutConstraint *ratioConstraint = [NSLayoutConstraint constraintWithItem:scrollView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:scrollView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:[self getRatioFrom:scrollViewFormat]
                                                                        constant:0];
    [scrollView addConstraint:ratioConstraint];
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
    NSUInteger newWidth = [sender integerValue];
//    if ([[layoutView subviews] count] <= newWidth * heightValue)
    {
        widthValue = newWidth;
        [self updateWidth];
        [layoutView updateLayoutViewWidth:widthValue height:heightValue];
        [layoutView reorderLayoutMatrix];
        [layoutView resizeLayoutView];
    }
}

- (IBAction)adjustLayoutHeight:(id)sender
{
    NSUInteger newHeight = [sender integerValue];
//    if ([[layoutView subviews] count] <= newHeight * widthValue)
    {
        heightValue = newHeight;
        [self updateHeight];
        [layoutView updateLayoutViewWidth:widthValue height:heightValue];
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

- (IBAction)updateViewRatio:(id)sender
{
    NSLayoutConstraint *ratioConstraint = [NSLayoutConstraint constraintWithItem:scrollView
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:scrollView
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:[self getRatioFrom:scrollViewFormat]
                                                                        constant:0];
    [scrollView removeConstraint:ratioConstraint];
    
    NSLog(@"");
    scrollViewFormat = [sender intValue];
    NSLog(@"");
//    ratioConstraint = [NSLayoutConstraint constraintWithItem:scrollView
//                                                   attribute:NSLayoutAttributeHeight
//                                                   relatedBy:NSLayoutRelationEqual
//                                                      toItem:scrollView
//                                                   attribute:NSLayoutAttributeWidth
//                                                  multiplier:[self getRatioFrom:scrollViewFormat]
//                                                    constant:0];
//    [scrollView addConstraint:ratioConstraint];
}

- (CGFloat)getRatioFrom:(paperSize)format
{
    switch (scrollViewFormat)
    {
        case paper_A4:
            return 1.4142;
            
        case paper_11x14:
            return 14/11;
            
        case paper_14x17:
            return 17/14;
            
        case paper_8x10:
            return 1.25;
            
        case paper_USletter:
            return 1.2941;
            
        default:
            return 1.;
    }
}


@end





















































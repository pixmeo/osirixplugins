//
//  PrintingLayoutController.m
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import "PLWindowController.h"
#import <OsiriXAPI/N2CustomTitledPopUpButtonCell.h>
#import <OsiriXAPI/ROI.h>

@interface PLWindowController ()

@end

@implementation PLWindowController

@synthesize heightValue, widthValue;
@synthesize scrollViewFormat;
@synthesize currentPage;

- (id)init
{
    self = [super initWithWindowNibName:@"PrintingLayoutWindow"];
    if (self)
    {
        // Initialization code here.
        self.scrollViewFormat    = paper_A4;
        self.heightValue         = 0;
        self.widthValue          = 0;
        self.currentPage         = -1;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPageUpdated) name:NSViewBoundsDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [layoutChoiceButton.cell setDisplayedTitle:@"Layout Choice"];
//    NSUInteger numberOfPages = [[fullDocumentView subviews] count];
//    for (NSUInteger i = 0; i < numberOfPages; ++i)
//    {
//        [[[fullDocumentView subviews] objectAtIndex:i] setLayoutFormat:scrollViewFormat];
//    }
    
//    if (scrollViewFormat)
//    {
//        ratioConstraint = [NSLayoutConstraint constraintWithItem:scrollView.contentView
//                                                       attribute:NSLayoutAttributeHeight
//                                                       relatedBy:NSLayoutRelationEqual
//                                                          toItem:scrollView.contentView
//                                                       attribute:NSLayoutAttributeWidth
//                                                      multiplier:getRatioFromPaperFormat(scrollViewFormat)
//                                                        constant:0];
//    }
}

#pragma mark-Action based methods

- (IBAction)updateViewRatio:(id)sender
{
    self.scrollViewFormat = [[sender selectedItem] tag];
    [fullDocumentView setPageFormat:scrollViewFormat];
    [self updateWindowTitle];
    
//    if (ratioConstraint)
//    {
//        [scrollView.contentView removeConstraint:ratioConstraint];
//    }
//    
//    if (scrollViewFormat)
//    {
//        ratioConstraint = [NSLayoutConstraint constraintWithItem:scrollView.contentView
//                                                       attribute:NSLayoutAttributeHeight
//                                                       relatedBy:NSLayoutRelationEqual
//                                                          toItem:scrollView.contentView
//                                                       attribute:NSLayoutAttributeWidth
//                                                      multiplier:getRatioFromPaperFormat(scrollViewFormat)
//                                                        constant:0];
//    }
//    else
//    {
//        ratioConstraint = nil;
//    }
}

- (IBAction)displayModeChanged:(id)sender
{
    [fullDocumentView setFullWidth:[[sender selectedCell] tag]];
    [fullDocumentView setScrollingMode:[[sender selectedCell] tag]];
    [fullDocumentView resizePLDocumentView];
}

- (IBAction)exportViewToDicom:(id)sender
{
    [[[fullDocumentView subviews] objectAtIndex:currentPage] saveLayoutViewToDicom];
}

- (IBAction)changeTool:(id)sender
{
    // Copy/paste from M/CPRController.m
	int toolIndex = 0;
	
	if ([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if ([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
    
    [[[fullDocumentView subviews] objectAtIndex:currentPage] setMouseTool:toolIndex];
}

- (IBAction)addPage:(id)sender
{
    [fullDocumentView newPage];
    [self updateWindowTitle];
}

- (void)pageDown:(id)sender
{
    if (currentPage < fullDocumentView.subviews.count - 1)
    {
        ++(self.currentPage);
        fullDocumentView.currentPage = currentPage;
        [fullDocumentView pageDown:sender];
    }
}

- (void)pageUp:(id)sender
{
    if (currentPage > 0)
    {
        --(self.currentPage);
        fullDocumentView.currentPage = currentPage;
        [fullDocumentView pageUp:sender];
    }
}

- (IBAction)updateGridLayoutFromButton:(id)sender
{
    NSString * name = [[layoutChoiceButton selectedItem] title];
    NSArray * c = [name componentsSeparatedByString:@"x"];
    
    NSUInteger newWidth = [[c objectAtIndex:0] integerValue];
    NSUInteger newHeight = [[c objectAtIndex:1] integerValue];
    
    if ([[[fullDocumentView subviews] objectAtIndex:currentPage] updateLayoutViewWidth:widthValue height:heightValue])
    {
        self.widthValue = newWidth;
        self.heightValue = newHeight;
        [self updateWidth];
        [self updateHeight];
        
        [[[fullDocumentView subviews] objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView];
    }
}

- (IBAction)adjustLayoutWidth:(id)sender
{
    NSUInteger newWidth = [sender integerValue];
    
    if ([[[fullDocumentView subviews] objectAtIndex:currentPage] updateLayoutViewWidth:newWidth height:heightValue])
    {
        self.widthValue = newWidth;
        [self updateWidth];
        
        [[[fullDocumentView subviews] objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView];
    }
}

- (IBAction)adjustLayoutHeight:(id)sender
{
    NSUInteger newHeight = [sender integerValue];
    
    if ([[[fullDocumentView subviews] objectAtIndex:currentPage] updateLayoutViewWidth:widthValue height:newHeight])
    {
        self.heightValue = newHeight;
        [self updateHeight];
        
        [[[fullDocumentView subviews] objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView];
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
    [self currentPageUpdated];
    self.heightValue = [[[fullDocumentView subviews] objectAtIndex:currentPage] layoutMatrixHeight];
    self.widthValue = [[[fullDocumentView subviews] objectAtIndex:currentPage] layoutMatrixWidth];
    [self updateHeight];
    [self updateWidth];
}

- (IBAction)clearViewsInLayout:(id)sender
{
    [[[fullDocumentView subviews] objectAtIndex:currentPage] clearAllThumbnailsViews];
}

#pragma mark-Notification based methods

- (void)updateWindowTitle
{
    if (scrollViewFormat)
    {
        [[self window] setTitle:[NSString stringWithFormat:@"Printing Layout (page %d of %d)", currentPage < 0 ? 1 : (int)currentPage + 1, (int)[[fullDocumentView subviews] count]]];
    }
    else
    {
        [[self window] setTitle:@"Printing Layout"];
    }
}

- (void)currentPageUpdated
{
    PLDocumentView* docView = [[scrollView.documentView subviews] objectAtIndex:0];
    
    NSUInteger bottom = docView.bottomMargin;
    NSUInteger pageHeight = [[docView.subviews objectAtIndex:0] frame].size.height;
    int yPosition = scrollView.documentVisibleRect.origin.y;
    
    if (pageHeight || bottom)
    {
        NSUInteger currentPosition = (yPosition + pageHeight/2) / (pageHeight + bottom);
        
        if (yPosition >= 0 && currentPage != currentPosition)
        {
            self.currentPage = currentPosition;
            [self updateWindowTitle];
            [self layoutMatrixUpdated];
        }
    }
}

//#pragma mark-Events handling
//- (void)keyDown:(NSEvent *)event
//{
//    unichar key = [event.characters characterAtIndex:0];
//    switch (key)
//    {
//        case NSPageUpFunctionKey:
//            [self pageUp:nil];
//            break;
//            
//        case NSPageDownFunctionKey:
//            [self pageDown:nil];
//            break;
//            
//        default:
//            break;
//    }
//}

#pragma mark-Needed for ROIs to work

- (void)addToUndoQueue:(NSString*)string
{
	NSLog( @"addToUndoQueue: currently unavailable in the Printing Layout.");
}

- (void)bringToFrontROI:(ROI*)roi
{
	NSLog( @"bringToFrontROI: not currently available in the Printing Layout.");
}

#pragma mark-Needed for down key to work (zoom out?)
- (void)maxMovieIndex
{
	NSLog( @"maxMovieIndex not currently available in the Printing Layout.");
}

@end





















































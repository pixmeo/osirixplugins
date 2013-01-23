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
@synthesize fullDocumentView;

#define UNDOQUEUESIZE 40

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
    [layoutChoiceButton.cell    setDisplayedTitle:@"Layout Choice"];
//    [exportButton.cell          setDisplayedTitle:@"Export…"];
}

#pragma mark-Action based methods

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

#pragma mark-Layout management

- (IBAction)updateViewRatio:(id)sender
{
    self.scrollViewFormat = [[sender selectedItem] tag];
    [fullDocumentView setPageFormat:scrollViewFormat];
    [self updateWindowTitle];
}

- (IBAction)addPage:(id)sender
{
    [fullDocumentView newPage];
    [self updateWindowTitle];
}

- (IBAction)deletePage:(id)sender
{
    if (currentPage >= 0)
    {
        [fullDocumentView removeCurrentPage];
        if (currentPage >= fullDocumentView.subviews.count)
        {
            --currentPage;
            fullDocumentView.currentPageIndex--;
            [fullDocumentView goToPage:currentPage];
        }

        [self updateWindowTitle];
    }
}

- (IBAction)insertPage:(id)sender
{
    [fullDocumentView insertPageAtIndex:currentPage];
    [self updateWindowTitle];
}

- (IBAction)updateGridLayoutFromButton:(id)sender
{
    NSString * name = [[layoutChoiceButton selectedItem] title];
    NSArray * c = [name componentsSeparatedByString:@"x"];
    
    NSUInteger newWidth = [[c objectAtIndex:0] integerValue];
    NSUInteger newHeight = [[c objectAtIndex:1] integerValue];
    
    if ([[[fullDocumentView subviews] objectAtIndex:currentPage] updateLayoutViewWidth:newWidth height:newHeight])
    {
        self.widthValue = newWidth;
        self.heightValue = newHeight;
        [self updateWidth];
        [self updateHeight];
        
        [[[fullDocumentView subviews] objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView];
    }
}

- (IBAction)reshapeLayout:(id)sender {
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

#pragma mark-Export actions

- (void)saveAllROIs
{
    NSArray * windowList = [NSApp windows];
    NSUInteger nbWindows = [windowList count];
    
    for (NSUInteger i = 0; i < nbWindows; ++i)
    {
        ViewerController *originalWindow = [[windowList objectAtIndex:i] windowController];
        
        if ([originalWindow.className isEqualToString:@"ViewerController"])
        {
            for (NSUInteger j = 0; j < originalWindow.maxMovieIndex; ++j)
                [originalWindow saveROI:j];
        }
    }
}

- (IBAction)exportViewToDicom:(id)sender
{
    // Save all ROIs
    [self saveAllROIs];
    
    // Export the PLDocumentView into a DICOM file
    [[[fullDocumentView subviews] objectAtIndex:currentPage] saveLayoutViewToDicom];
}

- (IBAction)exportViewToPDF:(id)sender
{
    // Save all ROIs
    [self saveAllROIs];

    // Export the PLDocumentView to a PDF file
    [fullDocumentView saveDocumentViewToPDF];
}

#pragma mark-Page navigation

- (void)pageDown:(id)sender
{
    if (currentPage < fullDocumentView.subviews.count - 1)
    {
        ++(self.currentPage);
        fullDocumentView.currentPageIndex = currentPage;
        [fullDocumentView pageDown:sender];
        [self updateWindowTitle];
    }
}

- (void)pageUp:(id)sender
{
    if (currentPage > 0)
    {
        --(self.currentPage);
        fullDocumentView.currentPageIndex = currentPage;
        [fullDocumentView pageUp:sender];
        [self updateWindowTitle];
    }
}

- (IBAction)pageByPageNavigation:(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    
    switch (clickedSegment)
    {
        case 0:
            [self pageUp:sender];
            break;
            
        case 1:
            [self pageDown:sender];
            break;
            
        default:
            break;
    }
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
            docView.currentPageIndex = currentPage;
            [self updateWindowTitle];
            [self layoutMatrixUpdated];
        }
    }
}

#pragma mark-Undo management
//Cf. ViewerController.m

- (void)bringToFrontROI:(ROI*)roi
{
    NSLog(@"bringToFrontROI not currently implemented in Printing Layout.");
}

- (void)addToUndoQueue:(NSString*) string
{
    NSLog(@"Undo currently unavailable for changes done inside Printing Layout.");
}

//- (void) windowDidBecomeKey:(NSNotification *)aNotification
//{
//}
//
//- (void) windowDidBecomeMain:(NSNotification *)aNotification
//{
//}
//
//- (BOOL)windowShouldClose:(id)sender
//{
//    return YES;
//}
//#pragma mark-Needed for down key to work (zoom out?)
//- (void)maxMovieIndex
//{
//	NSLog( @"maxMovieIndex currently unavailable in the Printing Layout.");
//}
//
//#pragma mark-Needed by DCMView when is2DViewer returns YES
//- (BOOL)isPostprocessed
//{
//    return NO;
//}
//
//- (void) setUpdateTilingViewsValue:(BOOL) v
//{
//	updateTilingViews = v;
//}
//
//- (BOOL)updateTilingViewsValue
//{
//    return updateTilingViews;
//}

@end





















































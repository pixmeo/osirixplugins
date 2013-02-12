//
//  PrintingLayoutController.m
//  PrintingLayout
//
//  Created by Benoit Deville on 21.08.12.
//
//

#import "PLLayoutView.h"
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
@synthesize importInterval, importStart, importEnd, importWidth, importHeight;
@synthesize importWindow;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPageUpdated:) name:NSViewBoundsDidChangeNotification object:scrollView.contentView];
    }
    
    return self;
}

//- (void)windowDidLoad
//{
//    [super windowDidLoad];
//
//    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
////    [layoutChoiceButton.cell    setDisplayedTitle:@"Layout Choice"];
////    [exportButton.cell          setDisplayedTitle:@"Export…"];
//}

#pragma mark-Action based methods

- (IBAction)changeTool:(id)sender
{
    // Copy/paste from M/CPRController.m
	int toolIndex = 0;
	
	if ([sender isKindOfClass:[NSMatrix class]])
		toolIndex = [[sender selectedCell] tag];
	else if ([sender respondsToSelector:@selector(tag)])
		toolIndex = [sender tag];
    
    [[fullDocumentView.subviews objectAtIndex:currentPage] setMouseTool:toolIndex];
}

- (IBAction)updateDocSizeIndicator:(id)sender
{
    NSString *name = [sender selectedItem].title;
    NSArray *c = [name componentsSeparatedByString:@"x"];
    
    NSUInteger pageSize = [[c objectAtIndex:0] integerValue] * [[c objectAtIndex:1] integerValue];
    NSUInteger nbImages = [fullDocumentView getNumberOfFilledViewsInDocument];
    NSUInteger nbPages  = nbImages % pageSize ? 1 + nbImages / pageSize : nbImages / pageSize;
    
    [documentSizeIndicator setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d %@", nil), nbPages ? nbPages : 1, nbPages > 1 ? @"pages" : @"page"]];
}

#pragma mark-Layout management

- (IBAction)updateViewRatio:(id)sender
{
    self.scrollViewFormat = [[sender selectedItem] tag];
    [fullDocumentView setPageFormat:scrollViewFormat];
    [self updateWindowTitle];
}

- (IBAction)pageAction:(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    
    switch (clickedSegment)
    {
        case 0:
            [self addPage:sender];
            break;
            
        case 1:
            [self insertPage:sender];
            break;
        
        case 2:
            [self deletePage:sender];
            break;
            
        default:
            break;
    }
}

- (IBAction)addPage:(id)sender
{
    [fullDocumentView newPage];
    
    //TODO Resolves a bug: if going from no pages to one page, the page exists but none of the views are displayed, even with setNeedsDisplay:YES
    if (fullDocumentView.subviews.count == 1)
    {
        [fullDocumentView newPage];
        [self deletePage:nil];
    }
    
    [self updateWindowTitle];
    if (currentPage < 0 || fullDocumentView.currentPageIndex < 0)
    {
        currentPage = 0;
        fullDocumentView.currentPageIndex = 0;
    }
}

- (IBAction)deletePage:(id)sender
{
    if (currentPage >= 0)
    {
        [fullDocumentView removeCurrentPage];
        NSUInteger nbPages = fullDocumentView.subviews.count;
        if (currentPage >= nbPages)
        {
            currentPage = nbPages - 1;
            fullDocumentView.currentPageIndex = currentPage;
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
//    NSString *name =[layoutChoiceButton selectedItem].title;
//    NSArray *c = [name componentsSeparatedByString:@"x"];
//    
//    NSUInteger newWidth = [[c objectAtIndex:0] integerValue];
//    NSUInteger newHeight = [[c objectAtIndex:1] integerValue];
//    
//    if ([[fullDocumentView.subviews objectAtIndex:currentPage] updateLayoutViewWidth:newWidth height:newHeight])
//    {
//        self.widthValue = newWidth;
//        self.heightValue = newHeight;
//        [self updateWidth];
//        [self updateHeight];
//        
//        [[fullDocumentView.subviews objectAtIndex:currentPage] reorderLayoutMatrix];
//        [fullDocumentView resizePLDocumentView];
//    }
}

- (IBAction)reshapeLayout:(id)sender
{
    NSString * name = [layoutChoiceButton selectedItem].title;
    NSArray * c = [name componentsSeparatedByString:@"x"];
    
    if (c.count == 2)
    {
        NSUInteger newWidth = [[c objectAtIndex:0] integerValue];
        NSUInteger newHeight = [[c objectAtIndex:1] integerValue];
        
        [fullDocumentView reshapeDocumentWithWidth:newWidth andHeight:newHeight];
        [self updateWindowTitle];
        [self layoutMatrixUpdated];
    }
}

- (IBAction)adjustLayoutWidth:(id)sender
{
    NSUInteger newWidth = [sender integerValue];
    
    if ([[fullDocumentView.subviews objectAtIndex:currentPage] updateLayoutViewWidth:newWidth height:heightValue])
    {
        self.widthValue = newWidth;
        [self updateWidth];
        
        [[fullDocumentView.subviews objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView:nil];
    }
}

- (IBAction)adjustLayoutHeight:(id)sender
{
    NSUInteger newHeight = [sender integerValue];
    
    if ([[fullDocumentView.subviews objectAtIndex:currentPage] updateLayoutViewWidth:widthValue height:newHeight])
    {
        self.heightValue = newHeight;
        [self updateHeight];
        
        [[fullDocumentView.subviews objectAtIndex:currentPage] reorderLayoutMatrix];
        [fullDocumentView resizePLDocumentView:nil];
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
    NSUInteger nbPages = fullDocumentView.subviews.count;
    if (nbPages && currentPage < nbPages)
    {
        self.heightValue    = [[fullDocumentView.subviews objectAtIndex:currentPage] layoutMatrixHeight];
        self.widthValue     = [[fullDocumentView.subviews objectAtIndex:currentPage] layoutMatrixWidth];
        [self updateHeight];
        [self updateWidth];
    }
}

- (IBAction)clearViewsInLayout:(id)sender
{
    if (fullDocumentView.subviews.count && currentPage > -1)
        [[fullDocumentView.subviews objectAtIndex:currentPage] clearAllThumbnailsViews];
}

#pragma mark-Import actions

- (void)prepareImportBox:(NSUInteger)serieSize
{
    [importStartSlider  setMaxValue:serieSize];
    [importEndSlider    setMaxValue:serieSize];
    
    [importStartSlider  setNumberOfTickMarks:serieSize];
    [importEndSlider    setNumberOfTickMarks:serieSize];
    
    [importIntervalSlider   setIntValue:1];
    [importStartSlider      setIntValue:1];
    [importEndSlider        setIntValue:serieSize];
    
    [importStartText    setIntValue:importStartSlider.intValue];
    [importEndText      setIntValue:importEndSlider.intValue];
    [importIntervalText setIntValue:importIntervalSlider.intValue];
    
    if (serieSize == 1)
    {
        [importIntervalSlider   setEnabled:NO];
        [importStartSlider      setEnabled:NO];
        [importEndSlider        setEnabled:NO];
    }
    else
    {
        [importIntervalSlider   setEnabled:YES];
        [importStartSlider      setEnabled:YES];
        [importEndSlider        setEnabled:YES];
    }
    
    self.importInterval = importIntervalSlider.integerValue;
    self.importStart    = importStartSlider.integerValue;
    self.importEnd      = importEndSlider.integerValue;
    self.importWidth    = 1;
    self.importHeight   = 1;
    
    [self updateImportPageNumber];
}

- (IBAction)importParameters:(id)sender
{
    [NSApp endSheet:importWindow];
    [importWindow orderOut:self];
}

- (IBAction)intervalSliderAction:(id)sender
{
    [importIntervalText takeIntegerValueFrom:importIntervalSlider];
    self.importInterval = importIntervalSlider.integerValue;
    
    [self updateImportPageNumber];
}

- (IBAction)startSliderAction:(id)sender
{
    [importStartText    takeIntValueFrom:importStartSlider];
    self.importStart = importStartSlider.integerValue;
    
    if (importStartSlider.intValue > importEndSlider.intValue)
    {
        self.importEnd = importStart;
        [importEndSlider    setIntegerValue:importEnd];
        [importEndText      setIntegerValue:importEnd];
    }
    
    [self updateImportPageNumber];
}

- (IBAction)endSliderAction:(id)sender
{
    [importEndText  takeIntValueFrom:importEndSlider];
    self.importEnd = importEndSlider.integerValue;
    
    if (importStartSlider.intValue > importEndSlider.intValue)
    {
        self.importStart = importEnd;
        [importStartSlider  setIntegerValue:importStart];
        [importStartText    setIntegerValue:importStart];
    }
    
    [self updateImportPageNumber];
}

- (IBAction)importLayoutChoice:(id)sender
{
    NSString * name = [[importLayoutButton selectedItem] title];
    NSArray * c = [name componentsSeparatedByString:@"x"];
    
    self.importWidth    = [[c objectAtIndex:0] integerValue];
    self.importHeight   = [[c objectAtIndex:1] integerValue];
    
    [self updateImportPageNumber];
}

- (void)updateImportPageNumber
{
    NSUInteger nbImages, imgPerPage, nbPages;
    nbImages = (importEnd - importStart + 1) / importInterval;
    imgPerPage = importWidth * importHeight;
    
    if (nbImages % imgPerPage)
        nbPages = 1 + nbImages / imgPerPage;
    else
        nbPages = nbImages / imgPerPage;

    [pagesImport setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d %@", nil), nbPages ? nbPages : 1, nbPages > 1 ? @"pages" : @"page"]];
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
            for (NSUInteger j = 0; j < originalWindow.maxMovieIndex; ++j)
                [originalWindow saveROI:j];
    }
}

- (IBAction)exportViewToDicom:(id)sender
{
    // Save all ROIs
    [self saveAllROIs];
    
    // Export the PLDocumentView into a DICOM file
//    [[fullDocumentView.subviews objectAtIndex:currentPage] saveLayoutViewToDicom];
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
        self.currentPage++;
        fullDocumentView.currentPageIndex = currentPage;
        [fullDocumentView pageDown:sender];
        [self updateWindowTitle];
    }
}

- (void)pageUp:(id)sender
{
    if (currentPage > 0)
    {
        self.currentPage--;
        fullDocumentView.currentPageIndex = currentPage;
        [fullDocumentView pageUp:sender];
        [self updateWindowTitle];
    }
}

- (void)scrollToBeginningOfDocument:(id)sender
{
    NSLog(@"go to beginning");
}

- (void)scrollToEndOfDocument:(id)sender
{
    NSLog(@"go to end");
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
    if (scrollViewFormat && [[[scrollView.documentView subviews] objectAtIndex:0] subviews].count)
        [self.window setTitle:[NSString stringWithFormat:@"Printing Layout (page %d of %d)", currentPage < 0 ? 1 : (int)currentPage + 1, (int)[fullDocumentView.subviews count]]];
    else
        [self.window setTitle:@"Printing Layout"];
}

- (void)currentPageUpdated:(NSNotification*)notification
{
    PLDocumentView* docView = [[scrollView.documentView subviews] objectAtIndex:0];
    
    if (docView.subviews.count)
    {
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
                [self layoutMatrixUpdated];
                [self updateWindowTitle];
            }
        }
    }
}

#pragma mark-Undo management
//Cf. ViewerController.m from OsiriX API

- (void)bringToFrontROI:(ROI*)roi
{
    NSLog(@"bringToFrontROI not currently implemented in Printing Layout.");
}

- (void)addToUndoQueue:(NSString*) string
{
    NSLog(@"Undo currently unavailable for changes done inside Printing Layout.");
}

#pragma mark-Specific to ViewerController.m

- (BOOL)registeredViewer
{
    return NO;
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





















































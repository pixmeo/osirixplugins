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
        
        undoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
        redoQueue = [[NSMutableArray alloc] initWithCapacity: 0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentPageUpdated) name:NSViewBoundsDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [layoutChoiceButton.cell setDisplayedTitle:@"Layout Choice"];    
}

- (void)dealloc
{
	[undoQueue removeAllObjects];
	[redoQueue removeAllObjects];

    [undoQueue release];
    [redoQueue release];
    
    [super dealloc];
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

//- (IBAction)displayModeChanged:(id)sender
//{
//    [fullDocumentView setFullWidth:[[sender selectedCell] tag]];
////    [fullDocumentView setScrollingMode:[[sender selectedCell] tag]];
//    [fullDocumentView resizePLDocumentView];
//}

- (IBAction)addPage:(id)sender
{
    [fullDocumentView newPage];
    [self updateWindowTitle];
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

- (IBAction)exportViewToDicom:(id)sender
{
    [[[fullDocumentView subviews] objectAtIndex:currentPage] saveLayoutViewToDicom];
}

- (IBAction)exportViewToPDF:(id)sender
{
    [fullDocumentView saveDocumentViewToPDF];
}

#pragma mark-Page navigation

- (void)pageDown:(id)sender
{
    if (currentPage < fullDocumentView.subviews.count - 1)
    {
        ++(self.currentPage);
        fullDocumentView.currentPage = currentPage;
        [fullDocumentView pageDown:sender];
        [self updateWindowTitle];
    }
}

- (void)pageUp:(id)sender
{
    if (currentPage > 0)
    {
        --(self.currentPage);
        fullDocumentView.currentPage = currentPage;
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
            // Open dialog box with current page index and let the user enter the new one
        {
            NSUInteger newPageNumber = 0;
            if (newPageNumber && newPageNumber <= fullDocumentView.subviews.count)
            {
                [fullDocumentView goToPage:newPageNumber];
                [self updateWindowTitle];
            }
        }
            break;
            
        case 2:
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
//
//#pragma mark-OsiriX ViewerController methods disabled
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

#pragma mark-Undo

// Based on OsiriXAPI/ViewerController.m

- (id) prepareObjectForUndo:(NSString*) string
{
	NSLog( @"prepareObjectForUndo: currently unavailable in the Printing Layout.");
//	if( [string isEqualToString: @"roi"])
//	{
//		NSMutableArray	*rois = [NSMutableArray array];
//		
//        NSMutableArray *array = [NSMutableArray array];
//        for( NSArray *ar in roiList)
//        {
//            NSMutableArray	*a = [NSMutableArray array];
//            
//            for( ROI *r in ar)
//                [a addObject: [[r copy] autorelease]];
//            
//            [array addObject: a];
//        }
//        [rois addObject: array];
//		
//		return [NSDictionary dictionaryWithObjectsAndKeys: string, @"type", rois, @"rois", nil];
//	}
	return nil;
}

- (void)addToUndoQueue:(NSString*)string
{
	NSLog( @"addToUndoQueue: currently unavailable in the Printing Layout.");
//	[undoQueue addObject: [self prepareObjectForUndo: string]];
//	
//	if( [undoQueue count] > UNDOQUEUESIZE)
//	{
//		[undoQueue removeObjectAtIndex: 0];
//	}
}

- (void)bringToFrontROI:(ROI*)roi
{
	NSLog( @"bringToFrontROI: currently unavailable in the Printing Layout.");
}

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





















































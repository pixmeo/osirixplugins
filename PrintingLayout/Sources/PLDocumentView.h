//
//  PLDocumentView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 19.11.12.
//
//

#import <Cocoa/Cocoa.h>
#import <OsiriXAPI/DCMView.h>
#import "PLLayoutView.h"
#import "PLUtils.h"

@interface PLDocumentView : NSView
{
    BOOL        isDraggingDestination;
    BOOL        fullWidth;
    
    CGFloat     sideMargin;
    CGFloat     topMargin;
    CGFloat     bottomMargin;
    
    paperSize   pageFormat;
    CGFloat     pageWidth;
    CGFloat     pageHeight;
    
    int         currentPageIndex;
}

@property BOOL fullWidth, isDraggingDestination;
@property CGFloat topMargin, bottomMargin, sideMargin;
@property (nonatomic, setter = setPageFormat:) paperSize pageFormat;
@property int currentPageIndex;

- (BOOL)handleViewerEvent:(NSEvent*)event;
- (void)resizePLDocumentView:(NSNotification*)notification;
- (PLLayoutView*)newPage;
- (void)removeCurrentPage;
- (void)clearDocument;
- (void)insertPageAtIndex:(NSUInteger)index;
- (void)goToPage:(NSUInteger)pageNumber;
- (void)saveDocumentViewToPDF;
- (IBAction)insertImage:(id)sender;
- (IBAction)insertSeries:(id)sender;
- (IBAction)insertPartial:(id)sender;
- (void)insertImage:(DCMView*)dcm atIndex:(short)imgIndex toPage:(int)pageIndex inView:(NSUInteger)viewIndex;
- (void)reshapeDocumentWithWidth:(NSUInteger)width andHeight:(NSUInteger)height;
- (NSUInteger)getNumberOfFilledViewsInDocument;

@end

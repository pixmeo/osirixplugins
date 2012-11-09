//
//  LayoutView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 31.08.12.
//
//

#import <Cocoa/Cocoa.h>

typedef enum {
    paper_none      = 0,
    paper_A4,       // 1
    paper_USletter, // 2
    paper_8x10,     // 3
    paper_11x14,    // 4
    paper_14x17,    // 5
} paperSize;

@interface PLLayoutView : NSView
{
//    NSArray *layout; // subviews existe déjà dans la classe NSView
    NSUInteger layoutMatrixWidth, layoutMatrixHeight;
    NSUInteger filledThumbs;
    BOOL isDraggingDestination;
    int currentInsertingIndex;
    int draggedThumbnailIndex;
    int previousLeftShrink;
    int previousRightShrink;
    int mouseTool;
    paperSize layoutFormat;
    NSUInteger numberOfPages;
}

@property NSUInteger layoutMatrixWidth, layoutMatrixHeight;
@property NSUInteger filledThumbs;
@property int mouseTool;
@property paperSize layoutFormat;
@property int draggedThumbnailIndex;

- (BOOL)updateLayoutViewWidth:(NSUInteger)w height:(NSUInteger)h;
- (void)reorderLayoutMatrix; // not sure it is really useful
- (void)resizeLayoutView;
- (void)clearAllThumbnailsViews;
- (int)inThumbnailView:(NSPoint)p margin:(NSUInteger)m;
- (int)getSubviewInsertIndexFrom:(NSPoint)p;
- (void)insertImageAtIndex:(NSUInteger)index from:(id<NSDraggingInfo>)sender;
- (int)findNextEmptyViewFrom:(NSUInteger)index;
- (void)saveLayoutViewToDicom;

@end

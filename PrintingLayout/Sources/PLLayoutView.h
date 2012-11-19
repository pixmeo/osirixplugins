//
//  LayoutView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 31.08.12.
//
//

#import <Cocoa/Cocoa.h>
#import "PLUtils.h"

@interface PLLayoutView : NSView
{
//    NSArray *layout; // subviews already exists in NSView
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
//    NSMutableArray *pages;
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

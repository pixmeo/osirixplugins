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
    NSUInteger layoutMatrixWidth, layoutMatrixHeight;
    NSUInteger filledThumbs;
    BOOL isDraggingDestination;
    int currentInsertingIndex;
    int draggedThumbnailIndex;
    int previousLeftShrink;
    int previousRightShrink;
    int mouseTool;
    
    NSPasteboard *pasteboard;
    
//    paperSize layoutFormat;
}

@property NSUInteger layoutMatrixWidth, layoutMatrixHeight;
@property NSUInteger filledThumbs;
@property BOOL isDraggingDestination;
@property int mouseTool;
//@property paperSize layoutFormat;
@property int draggedThumbnailIndex, currentInsertingIndex;
@property int previousLeftShrink, previousRightShrink;

- (BOOL)updateLayoutViewWidth:(NSUInteger)w height:(NSUInteger)h;
- (void)reorderLayoutMatrix; // not sure it is really useful
- (void)resizeLayoutView:(NSRect)frame;
- (void)clearAllThumbnailsViews;
- (int)inThumbnailView:(NSPoint)p margin:(NSUInteger)m;
- (int)getSubviewInsertIndexFrom:(NSPoint)p;
- (void)insertImageAtIndex:(NSUInteger)index from:(id<NSDraggingInfo>)sender;
- (int)findNextEmptyViewFrom:(NSUInteger)index;
- (void)saveLayoutViewToDicom;
- (void)importImage;//:(id)sender;
- (void)importSerie;//:(id)sender;

@end

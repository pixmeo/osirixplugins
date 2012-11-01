//
//  LayoutView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 31.08.12.
//
//

#import <Cocoa/Cocoa.h>

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
}

@property NSUInteger filledThumbs;
@property int mouseTool;

- (void)updateLayoutViewWidth:(NSUInteger)w height:(NSUInteger)h;
- (void)reorderLayoutMatrix; // not sure its realls useful
- (void)resizeLayoutView;
- (void)clearAllThumbnailsViews;
- (int)inThumbnailView:(NSPoint)p margin:(NSUInteger)m;
- (int)getSubviewInsertIndexFrom:(NSPoint)p;
- (void)insertImageAtIndex:(NSUInteger)index from:(id<NSDraggingInfo>)sender;
- (int)findNextEmptyViewFrom:(NSUInteger)index;
- (void)saveLayoutViewToDicom;

@end

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
}

@property NSUInteger layoutMatrixWidth, layoutMatrixHeight;
@property NSUInteger filledThumbs;
@property BOOL isDraggingDestination;
@property int mouseTool;
@property int draggedThumbnailIndex, currentInsertingIndex;
@property int previousLeftShrink, previousRightShrink;

- (BOOL)updateLayoutViewWidth:(NSUInteger)w height:(NSUInteger)h;
- (void)reorderLayoutMatrix; // not sure it is really useful
- (void)resizeLayoutView:(NSRect)frame;
- (void)clearAllThumbnailsViews;
- (void)insertImageAtIndex:(NSUInteger)index from:(id<NSDraggingInfo>)sender;
- (void)saveLayoutViewToDicom;
- (int)inThumbnailView:(NSPoint)p margin:(NSUInteger)m;
- (int)getSubviewInsertIndexFrom:(NSPoint)p;
- (int)findNextEmptyViewFrom:(NSUInteger)index;
- (IBAction)importImage:(id)sender;
- (IBAction)importSeries:(id)sender;
- (IBAction)importPartialSeries:(id)sender;

@end

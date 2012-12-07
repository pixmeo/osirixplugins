//
//  PLThumbnailView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 03.09.12.
//
//

#import <Cocoa/Cocoa.h>
#import <OsiriXAPI/DCMView.h>

typedef enum shrinkTypeEnum {
    none    = 0,
    left,   //1
    right,  //2
/*    top,    //4
    bottom  //5*/
} shrinkType;

@interface PLThumbnailView : DCMView <NSDraggingDestination>
{
    BOOL isGoingToBeSelected;
    BOOL isSelected;
    BOOL isDraggingDestination;
    shrinkType shrinking;   // side where the shrinking has been done
    NSRect originalFrame;   // in case of shrinking
    NSInteger layoutIndex;
}

@property BOOL isDraggingDestination, isGoingToBeSelected, isSelected;
@property shrinkType shrinking;
@property NSRect originalFrame;
@property NSInteger layoutIndex;

- (void)fillViewWith:(NSPasteboard*)pasteboard atIndex:(NSInteger)gridIndex;
//- (void)fillViewFrom:(id <NSDraggingInfo>)sender;
- (void)shrinkWidth:(int)marginSize onIts:(shrinkType)side;
- (void)backToOriginalSize;
- (void)clearView;
- (void)selectView;

@end

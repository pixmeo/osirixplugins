//
//  PLDocumentView.h
//  PrintingLayout
//
//  Created by Benoit Deville on 19.11.12.
//
//

#import <Cocoa/Cocoa.h>
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
}

@property BOOL fullWidth;
//@property (readonly) CGFloat sideMargin;
@property (nonatomic, setter = setPageFormat:) paperSize pageFormat;

- (void)resizePLDocumentView;

@end

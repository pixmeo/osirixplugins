//
//  HSSCell.m
//  HSS
//
//  Created by Alessandro Volz on 11.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSCell.h"
#import "OsiriXAPI/NSString+N2.h"
#import "OsiriXAPI/NS(Attributed)String+Geometrics.h"

/*@interface NSCell (Secret)

-(void)_drawAttributedText:(NSAttributedString*)str inFrame:(NSRect)frame;

@end*/

@implementation HSSCell

+ (NSAttributedString*)suspendedAttributedStringWithAttributedString:(NSAttributedString*)s size:(NSSize)size {
    if ([s sizeForWidth:FLT_MAX height:FLT_MAX].width <= size.width)
        return s;
    
    NSString* const suspension = @"...";
    
    NSInteger m = 0, M = s.length, pivot;
    while ((pivot = (m+M)/2) > m) {
        NSMutableAttributedString* ms = [[[s attributedSubstringFromRange:NSMakeRange(0, pivot)] mutableCopy] autorelease];
        [ms appendAttributedString:[[[NSAttributedString alloc] initWithString:suspension attributes:[s attributesAtIndex:pivot-1 effectiveRange:NULL]] autorelease]];
        if ([ms sizeForWidth:FLT_MAX height:FLT_MAX].width <= size.width)
            m = pivot;
        else M = pivot;
    }
    
    if (M < s.length) {
        NSMutableAttributedString* ms;
        while ([s.string characterAtIndex:M-1] == ' ') --M;
        ms = [[[s attributedSubstringFromRange:NSMakeRange(0,M)] mutableCopy] autorelease];
        [ms appendAttributedString:[[[NSAttributedString alloc] initWithString:suspension attributes:[s attributesAtIndex:M-1 effectiveRange:NULL]] autorelease]];
        return ms;
    }
    
    return s;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView {
    NSAttributedString* backup = [self.attributedStringValue retain];

    NSRect drawingFrame = [self drawingRectForBounds:cellFrame];
    
    if (self.isBordered || self.isBezeled) {
        drawingFrame.origin.x += 3;
        drawingFrame.size.width -= 6;
        drawingFrame.origin.y += 1;
        drawingFrame.size.height -= 2;
    }
    
    NSRect titleRect = [self titleRectForBounds:drawingFrame];
    
    self.attributedStringValue = [[self class] suspendedAttributedStringWithAttributedString:backup size:titleRect.size];
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
    
    self.attributedStringValue = [backup autorelease];
}

@end

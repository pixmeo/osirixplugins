//
//  HSSPopUpButtonCell.m
//  HSS
//
//  Created by Alessandro Volz on 10.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSPopUpButtonCell.h"

@implementation HSSPopUpButtonCell

-(NSRect)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView {
    title = [[[NSAttributedString alloc] initWithString:self.alternateTitle attributes:[title attributesAtIndex:0 effectiveRange:NULL]] autorelease];
    return [super drawTitle:title withFrame:frame inView:controlView];
}

@end

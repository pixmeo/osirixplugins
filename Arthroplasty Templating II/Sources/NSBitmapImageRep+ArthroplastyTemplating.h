//
//  NSBitmapImageRep+ArthroplastyTemplating.h
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 2/1/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBitmapImageRep (ArthroplastyTemplating)

-(void)detectAndApplyBorderTransparency:(uint8)alphaThreshold;
-(void)setColor:(NSColor*)color;

@end

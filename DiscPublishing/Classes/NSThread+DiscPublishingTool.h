//
//  NSThread+DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSThread (DiscPublishingTool)

extern NSString* const NSThreadStatusKey;
extern NSString* const NSThreadAdvancementKey;

-(void)setStatus:(NSString*)status;
-(NSString*)status;
-(void)setAdvancement:(CGFloat)advancement;
-(CGFloat)advancement;

@end

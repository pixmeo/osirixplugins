//
//  NSThread+DiscPublishingTool.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 5/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSThread (N2)


extern NSString* const NSThreadUniqueIdKey;
-(NSString*)uniqueId;
-(void)setUniqueId:(NSString*)uniqueId;

extern NSString* const NSThreadSupportsCancelKey;
-(BOOL)supportsCancel;
-(void)setSupportsCancel:(BOOL)supportsCancel;

extern NSString* const NSThreadIsCancelledKey;
//-(BOOL)isCancelled;
-(void)setIsCancelled:(BOOL)isCancelled;

extern NSString* const NSThreadStatusKey;
-(NSString*)status;
-(void)setStatus:(NSString*)status;

extern NSString* const NSThreadProgressKey;
-(CGFloat)progress;
-(void)setProgress:(CGFloat)progress;

@end

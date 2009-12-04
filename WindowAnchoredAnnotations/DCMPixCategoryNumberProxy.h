//
//  DCMPixCategoryNumberProxy.h
//  WindowAnchoredAnnotations
//
//  Created by ibook on 2007-01-22.
//  Copyright 2007 __ jacques.fauquex@opendicom.com
//

#import <Cocoa/Cocoa.h>
#import "DCMPix.h"


@interface DCMPix (DCMPixCategoryNumberProxy)

- (NSNumber *) NumberCurMask;
- (NSNumber *) NumberFrameTime;
- (NSNumber *) NumberMaskTime;
//- (NSNumber *) NumberPrimaryAngle;
//- (NSNumber *) NumberSecondaryAngle;

@end

//
//  DCMPixCategoryNumberProxy.m
//  WindowAnchoredAnnotations
//
//  Created by ibook on 2007-01-22.
//  Copyright 2007 __ jacques.fauquex@opendicom.com
//

#import "DCMPixCategoryNumberProxy.h"


@implementation DCMPix (DCMPixCategoryNumberProxy)
- (NSNumber *) NumberCurMask{return [NSNumber numberWithInt:[self maskID]+1];}

- (NSNumber *) NumberFrameTime{return [NSNumber numberWithFloat:[self fImageTime]];}

- (NSNumber *) NumberMaskTime{return [NSNumber numberWithFloat:[self maskTime]];}

//- (NSNumber *) NumberPrimaryAngle{return [NSNumber numberWithFloat:[self rot]];}
//(0018,1510)(0018,9463) rot [NSNumber numberWithFloat:[[dcmPixList objectAtIndex: curImage] rot]];

//- (NSNumber *) NumberSecondaryAngle{return [NSNumber numberWithFloat:[self ang]];}
//(0018,1511)(0018,9464) ang [NSNumber numberWithFloat:[[dcmPixList objectAtIndex: curImage] ang]];



@end

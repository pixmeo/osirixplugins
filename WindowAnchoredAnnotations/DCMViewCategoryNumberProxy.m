//
//  DCMViewCategoryNumberProxy.m
//  WindowAnchoredAnnotations
//
//  Created by ibook on 2007-01-22.
//  Copyright 2007 __ jacques.fauquex@opendicom.com
//

#import "DCMViewCategoryNumberProxy.h"


@implementation DCMView (DCMViewCategoryNumberProxy)
-(NSNumber *) image {return [NSNumber numberWithInt:curImage+1];}
-(NSNumber *) pixCount {return [NSNumber numberWithInt:[dcmPixList count]];}
-(NSNumber *) windowWidth {return [NSNumber numberWithFloat:curWW];}
-(NSNumber *) windowLevel {return [NSNumber numberWithFloat:curWL];}
-(NSString *) yearOld {return yearOld;}

@end

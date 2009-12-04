//
//  DCMViewCategoryNumberProxy.h
//  WindowAnchoredAnnotations
//
//  Created by ibook on 2007-01-22.
//  Copyright 2007 __ jacques.fauquex@opendicom.com
//

#import <Cocoa/Cocoa.h>
#import "DCMView.h"


@interface DCMView (DCMViewCategoryNumberProxy)
-(NSNumber *) pixCount;
-(NSNumber *) image;
-(NSNumber *) windowWidth;
-(NSNumber *) windowLevel;
-(NSString *) yearOld;
@end

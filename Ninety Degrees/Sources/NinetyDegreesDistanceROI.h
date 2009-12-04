//
//  NinetyDegreesDistanceROI.h
//  Ninety Degrees
//
//  Created by Alessandro Volz on 03.11.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "NinetyDegreesROI.h"


@interface NinetyDegreesDistanceROI : NinetyDegreesROI {
}

-(id)initWithRoi1:(ROI*)roi1 roi2:(ROI*)roi2;
-(void)update;

@end

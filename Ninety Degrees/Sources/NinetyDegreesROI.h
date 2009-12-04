//
//  NinetyDegreesROI.h
//  Ninety Degrees
//
//  Created by Alessandro Volz on 02.11.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import <OsiriX Headers/ROI.h>


@interface NinetyDegreesROI : ROI {
	ROI* _roi1;
	ROI* _roi2;
}

@property(readonly) ROI* roi1;
@property(readonly) ROI* roi2;

-(id)initWithRoi1:(ROI*)roi1 roi2:(ROI*)roi2 type:(long)roitype;
-(BOOL)isOnROI:(ROI*)roi;

@end

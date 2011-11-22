//
//  GantryTiltCorrection.m
//  Apply same orientation to all images of a series
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Rosset Antoine. All rights reserved.
//

#import "GantryTiltCorrection.h"
#include <Accelerate/Accelerate.h>
#import "ITKTransform.h"

@implementation GantryTiltCorrection

- (long) filterImage:(NSString*) menuName
{
	DCMPix *curPix;
    BOOL OK = YES;
	
	curPix = [[viewerController pixList] objectAtIndex: 0];
	
	long imageSize, size;
	NSArray *pixList = [viewerController pixList];
	
	id w = [viewerController startWaitWindow: @"Gantry Tilt Correction"];
	
	imageSize = [curPix pwidth] * [curPix pheight];
	size = sizeof(float) * [pixList count]/2 * imageSize;
	
	float orientation[ 9];
	float origin[ 3];
	double matrix[ 12];
	
	[curPix orientation: orientation];
	origin[ 0] = [curPix originX]; origin[ 1] = [curPix originY]; origin[ 2] = [curPix originZ];
	
	for( DCMPix *p in pixList)
	{
		float o[ 9];
		float xyz[ 3];
		
		[p orientation: o];
		xyz[ 0] = [p originX]; xyz[ 1] = [p originY]; xyz[ 2] = [p originZ];
		
		BOOL equal = YES;
		for( int i = 0 ; i < 6 ; i++)
		{
			if( o[ i] != orientation[ i])
				equal = NO;
		}
		
		if( equal == NO)
		{
			NSRunInformationalAlertPanel( NSLocalizedString(@"Error!", nil), NSLocalizedString(@"These slices have not the same orientation. Gantry Tilt Correction cannot be applied to this dataset.", nil), NSLocalizedString(@"OK", nil), 0L, 0L);
            OK = NO;
            break;
		}
	}
	
    if( OK)
    {
        for( DCMPix *p in pixList)
        {
            float o[ 9];
            float xyz[ 3];
            
            [p orientation: o];
            xyz[ 0] = [p originX]; xyz[ 1] = [p originY]; xyz[ 2] = [p originZ];
            
            float vectorModel[ 9], vectorSensor[ 9];
            
            [p orientation: vectorSensor];
            [curPix orientation: vectorModel];
            
            double length;
            
            // --
            matrix[ 9] = xyz[ 0] - origin[ 0];
            matrix[ 10] = xyz[ 1] - origin[ 1];
            matrix[ 11] = xyz[ 2] - origin[ 2];
            // --
            
            matrix[ 0] = vectorSensor[ 0] * vectorModel[ 0] + vectorSensor[ 1] * vectorModel[ 1] + vectorSensor[ 2] * vectorModel[ 2];
            matrix[ 1] = vectorSensor[ 0] * vectorModel[ 3] + vectorSensor[ 1] * vectorModel[ 4] + vectorSensor[ 2] * vectorModel[ 5];
            matrix[ 2] = vectorSensor[ 0] * vectorModel[ 6] + vectorSensor[ 1] * vectorModel[ 7] + vectorSensor[ 2] * vectorModel[ 8];
            
            length = sqrt(matrix[0]*matrix[0] + matrix[1]*matrix[1] + matrix[2]*matrix[2]);
            
            matrix[0] = matrix[ 0] / length;
            matrix[1] = matrix[ 1] / length;
            matrix[2] = matrix[ 2] / length;
            
            // --
            
            matrix[ 3] = vectorSensor[ 3] * vectorModel[ 0] + vectorSensor[ 4] * vectorModel[ 1] + vectorSensor[ 5] * vectorModel[ 2];
            matrix[ 4] = vectorSensor[ 3] * vectorModel[ 3] + vectorSensor[ 4] * vectorModel[ 4] + vectorSensor[ 5] * vectorModel[ 5];
            matrix[ 5] = vectorSensor[ 3] * vectorModel[ 6] + vectorSensor[ 4] * vectorModel[ 7] + vectorSensor[ 5] * vectorModel[ 8];
            
            length = sqrt(matrix[3]*matrix[3] + matrix[4]*matrix[4] + matrix[5]*matrix[5]);
            
            matrix[3] = matrix[ 3] / length;
            matrix[4] = matrix[ 4] / length;
            matrix[5] = matrix[ 5] / length;
            
            // --
            
            matrix[6] = matrix[1]*matrix[5] - matrix[2]*matrix[4];
            matrix[7] = matrix[2]*matrix[3] - matrix[0]*matrix[5];
            matrix[8] = matrix[0]*matrix[4] - matrix[1]*matrix[3];
            
            length = sqrt(matrix[6]*matrix[6] + matrix[7]*matrix[7] + matrix[8]*matrix[8]);
            
            matrix[6] = matrix[ 6] / length;
            matrix[7] = matrix[ 7] / length;
            matrix[8] = matrix[ 8] / length;
            
            long size;
            
            float *resultBuff = [ITKTransform reorient2Dimage: matrix firstObject: curPix firstObjectOriginal: p length: &size];
            memcpy( [p fImage] , resultBuff, size);
            free( resultBuff);
            
            xyz[ 0] = origin[ 0];
            xyz[ 1] = origin[ 1];
            [p setOrigin: xyz];
        }
        
        for( DCMPix *p in pixList)
        {
            [p setOrientationDouble: matrix];
            [p setSliceInterval: 0];
        }
    }
	[viewerController endWaitWindow: w];
	
	// We modified the view: OsiriX please update the display!
	[viewerController needsDisplayUpdate];

	return 0;
}

@end

//
//  SeriesSameOrientation.m
//  Apply same orientation to all images of a series
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Rosset Antoine. All rights reserved.
//

#import "SeriesSameOrientation.h"
#include <Accelerate/Accelerate.h>
#import "ITKTransform.h"

@implementation SeriesSameOrientation

- (long) filterImage:(NSString*) menuName
{
	float vecteur;
	
	if( [menuName isEqualToString: @"Vector Up"])
		vecteur = -1.;
	else
		vecteur = 1.;

		DCMPix *curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
		long imageSize, size;
		NSArray *pixList = [viewerController pixList];
		
		id w = [viewerController startWaitWindow: @"Series Same Orientation"];
		
		imageSize = [curPix pwidth] * [curPix pheight];
		size = sizeof(float) * [pixList count]/2 * imageSize;
		
		for( DCMPix *p in pixList)
		{
			double o[ 9];
			
			[p orientationDouble: o];
			
			for( int i = 0 ; i < 6 ; i++)
			{
				int r = ( vecteur * o[ i]*1000);
				
				o[i] = (float) r / 1000;
				
				NSLog( @"%f", o[i]);
			}
			
			[p setOrientationDouble: o];
			
		}

		for( DCMPix *p in pixList)
		{
			double o[ 3];
			
			[p originDouble: o];
			
			for( int i = 0 ; i < 3 ; i++)
			{
				int r = ( o[ i]*1000.);
				
				o[i] = (float) r / 1000.;
				
				NSLog( @"%f", o[i]);
			}
			
			[p setOriginDouble: o];
			
		}

		float orientation[ 9];		
		[curPix orientation: orientation];
		
		for( DCMPix *p in pixList)
		{
			float o[ 9];
			
			[p orientation: o];
			
			BOOL equal = YES;
			for( int i = 0 ; i < 6 ; i++)
			{
				if( o[ i] != orientation[ i])
					equal = NO;
			}
			
			if( equal == NO)	// Change the orientation of the image according to the selected image
			{
				float vectorModel[ 9], vectorSensor[ 9];
				
				[p orientation: vectorSensor];
				[curPix orientation: vectorModel];
				
				double matrix[ 12], length;
				
				// No translation -> same origin, same study
				matrix[ 9] = 0;
				matrix[ 10] = 0;
				matrix[ 11] = 0;
				
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
				
				[p setOrientation: orientation];
			}
		}
		
		[viewerController endWaitWindow: w];
		
		// We modified the view: OsiriX please update the display!
		[viewerController needsDisplayUpdate];

	return 0;
}

@end

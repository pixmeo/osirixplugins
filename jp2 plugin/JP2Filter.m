//
//  JP2Filter.m

//
//  Created by Lance Pysher on Monday August 1, 2005.
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import "JP2Filter.h"
//#import <OsiriX/DCM.h>



@implementation JP2Filter

+ (float *)decodedDataAtPath:(NSString *)path{
	JP2Filter *decoder = [[[JP2Filter alloc] init] autorelease];
	return [decoder checkLoadAtPath:path];
}

- (id)init {
	if (self = [super init])
		NSLog(@"init jp2 Filter");
	return self;
}

- (float *)checkLoadAtPath:(NSString *)path{
	//[othercheckLoadAtPath:Image setBackgroundColor: [NSColor whiteColor]];
	//NSLog(@"checkLoadAtPath: %@", path);
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];				
	NSBitmapImageRep	*imageRep = (NSBitmapImageRep *)[image bestRepresentationForDevice:nil];
	unsigned char   *argbImage, *tmpPtr, *srcPtr, *srcImage;
	long			 x, y, totSize;
	
	_height = [[NSNumber numberWithFloat:[imageRep pixelsHigh]] retain];
	//NSLog(@"height %d", [_height intValue]);
	
	_width = [[NSNumber numberWithFloat:[imageRep pixelsWide]] retain];
	//NSLog(@"width %d", [_width intValue]);
	
	_rowBytes = [[NSNumber numberWithFloat:[imageRep bytesPerRow]] retain];
	//short *oImage = 0L;
	srcImage = [imageRep bitmapData];
	_isRGB= YES;
	totSize = [_height intValue] * [_width intValue] * 4;
	argbImage = malloc( totSize);
	
	switch( [imageRep bitsPerPixel])
	{
		case 8:
			//NSLog(@"8 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < [_height intValue]; y++)
			{
				srcPtr = srcImage + y*[_rowBytes intValue];
				
				x = [_width intValue];
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr;
					*tmpPtr++ = *srcPtr;
					*tmpPtr++ = *srcPtr;
					srcPtr++;
				}
			}
		break;
		
		case 32:
			//NSLog(@"32 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < [_height intValue]; y++)
			{
				srcPtr = srcImage + y*[_rowBytes intValue];
				
				x = [_width intValue];
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr++;
					*tmpPtr++ = *srcPtr++;
					*tmpPtr++ = *srcPtr++;
					srcPtr++;
				}
				
				//BlockMoveData( srcPtr, tmpPtr, width*4);
				//tmpPtr += width*4;
			}
		break;
		
		case 24:
			//NSLog(@"24 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < [_height intValue]; y++)
			{
				srcPtr = srcImage + y*[_rowBytes intValue];
				
				x = [_width intValue];
				while( x-->0)
				{
					tmpPtr++;
					
					*((short*)tmpPtr) = *((short*)srcPtr);
					tmpPtr+=2;
					srcPtr+=2;
					
					*tmpPtr++ = *srcPtr++;
					
					
				}
			}
		break;
		
		case 48:
			//NSLog(@"48 bits");
			tmpPtr = argbImage;
			for( y = 0 ; y < [_height intValue]; y++)
			{
				srcPtr = srcImage + y*[_rowBytes intValue];
				
				x = [_width intValue];
				while( x-->0)
				{
					tmpPtr++;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
					*tmpPtr++ = *srcPtr;	srcPtr += 2;
				}
				
				//BlockMoveData( srcPtr, tmpPtr, width*4);
				//tmpPtr += width*4;
			}
		break;
		
		default:
			NSLog(@"Error - Unknow...");
		break;
	}
	
	_fImage = (float*) argbImage;
	[_rowBytes release];
	_rowBytes  = [[NSNumber numberWithInt:[_width intValue] * 4] retain];
	//NSLog(@"return fImage");
	return _fImage;
}







	


@end

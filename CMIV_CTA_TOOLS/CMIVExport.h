/*=========================================================================
CMIVExport

modified from DICOMExport of OsiriX. Keep most tag unchanged when
store the 2d images into the OsiriX.

Modified by: Chunliang Wang (chunliang.wang@imv.liu.se)



Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=========================================================================*/

#import <Cocoa/Cocoa.h>
#include <Accelerate/Accelerate.h>
#import "DCMObject.h"
#import "OsiriX Headers/DCMCalendarDate.h"
#import "OsiriX Headers/PluginFilter.h"
#import "OsiriX Headers/dicomFile.h"
#import "OsiriX Headers/DCMPixelDataAttribute.h"
#import "OsiriX Headers/DCMDataContainer.h"
enum DCM_CompressionQuality {DCMLosslessQuality, DCMHighQuality, DCMMediumQuality, DCMLowQuality};
@interface CMIVExport : NSObject {

	NSString			*dcmSourcePath;
		
	// Raw data support
	unsigned char		*data;
	unsigned char		*dicomFileData;
	int tlength;
	long				width, height, spp, bpp;
	
	// NSImage support
	NSImage				*image;
	NSBitmapImageRep	*imageRepresentation;
	unsigned char		*imageData;
	BOOL				freeImageData;
	
	int					exportInstanceNumber, exportSeriesNumber;
	NSString			*exportSeriesUID;
	NSString			*exportSeriesDescription;
	NSString			*sopInstanceUID;
	long				ww, wl;
	float				spacingX, spacingY;
	float				sliceThickness;
	float				sliceInterval;
	float				orientation[ 6];
	float				position[ 3];
	float				slicePosition;
	unsigned short *tempuint;
}

// Is this DCM file based on another DCM file?
- (void) setSourceFile:(NSString*) isource;

	// Set Pixel Data from a raw source
- (long) setPixelData:		(unsigned char*) idata
	   samplePerPixel:		(long) ispp
		 bitsPerPixel:		(long) ibpp
				width:				(long) iwidth
			   height:				(long) iheight;

	// Write the image data
- (long) writeDCMFile: (NSString*) dstPath;

- (void) setSeriesDescription: (NSString*) desc;
- (void) setSeriesNumber: (long) no;
- (void) setDefaultWWWL: (long) ww :(long) wl;
- (void) setPixelSpacing: (float) x :(float) y;
- (void) setSliceThickness: (float) t;
- (void) setOrientation: (float*) o;
- (void) setPosition: (float*) p;
- (void) setSlicePosition: (float) p;
- (void) exportCurrentSeries: (ViewerController *)originalViewController;
- (NSString*)osirixDocumentPath;
- (NSString*)exportSeriesUID;
@end

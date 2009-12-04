//
//  FloatDICOMExport.m
//  FloatDICOMExport
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import "FloatDICOMExport.h"
#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMTransferSyntax.h"
#import "DCMPix.h"

#import "DICOMExport.h"
#import "BrowserController.h"

@implementation FloatDICOMExport


- (long) filterImage:(NSString*) menuName
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray *pixList = [viewerController pixList];	
	
	// Current image
	DCMPix *curPix = [pixList objectAtIndex: [[viewerController imageView] curImage]];
	
	DICOMExport *xport = [[[DICOMExport alloc] init] autorelease];
	
	[xport setSourceFile: [curPix sourceFile]];
	[xport setPixelData: (unsigned char*) [curPix fImage] samplesPerPixel: 1 bitsPerSample: sizeof( float) * 8 width: [curPix pwidth] height: [curPix pheight]];
	[xport writeDCMFile: [[[BrowserController currentBrowser] fixedDocumentsDirectory] stringByAppendingPathComponent: @"INCOMING.noindex/dicom-in-32-bit-float.dcm"]];
	 
	return 0;   // No Errors
}

@end

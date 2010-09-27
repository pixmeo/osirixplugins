//
//  FloatDICOMExport.m
//  FloatDICOMExport
//
//  Copyright (c) 2009 Antoine Rosset. All rights reserved.
//

#import "FloatDICOMExport.h"
#import "OsiriX/DCMObject.h"
#import "OsiriX/DCMTransferSyntax.h"
#import "OsiriX Headers/DCMPix.h"

#import "OsiriX Headers/DICOMExport.h"
#import "OsiriX Headers/BrowserController.h"

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
	NSString *f = [xport writeDCMFile: nil];
	 
	 if( f)
		[BrowserController addFiles: [NSArray arrayWithObject: f]
					 toContext: [[BrowserController currentBrowser] managedObjectContext]
					toDatabase: [BrowserController currentBrowser]
					 onlyDICOM: YES 
			  notifyAddedFiles: YES
		   parseExistingObject: YES
					  dbFolder: [[BrowserController currentBrowser] documentsDirectory]
			 generatedByOsiriX: YES];
	 
	return 0;   // No Errors
}

@end

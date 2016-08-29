//
//   Quicktime2DICOM
//  

#import "Quicktime2DICOM.h"
#import <OsiriX/DCM.h>
#import "QTKit/QTMovie.h"
#import "OsiriXAPI/browserController.h"
#import "OsiriXAPI/WaitRendering.h"
#import "OsiriXAPI/DICOMExport.h"
#import "OsiriXAPI/BrowserController.h"

@implementation Quicktime2DICOM

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *currentSelection = [[BrowserController currentBrowser] databaseSelection];
	if ([currentSelection count] > 0)
	{
		id selection = [currentSelection objectAtIndex:0];
		DicomImage *image;
		
		if ([[[selection entity] name] isEqualToString:@"Study"]) 
			image = [[[[selection valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject];
		else
			image = [[selection valueForKey:@"images"] anyObject];
		
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories: NO];
		[openPanel setAllowsMultipleSelection: YES];
		[openPanel setTitle:NSLocalizedString( @"Import", nil)];
		[openPanel setMessage:NSLocalizedString( @"Select a movie to convert to DICOM", nil)];
		if([openPanel runModalForTypes: [QTMovie movieFileTypes: 0]] == NSOKButton)
		{
			NSEnumerator *enumerator = [[openPanel filenames] objectEnumerator];
			NSString *fpath;
			while(fpath = [enumerator nextObject])
			{
				[self convertMovieToDICOM: fpath source: image];
			}
		}
	}
	[pool release];
	
	return -1;
}

- (float*) getDataFromNSImage:(NSImage*) otherImage w: (int*) width h: (int*) height rgb: (BOOL*) isRGB
{
    float *fImage = nil;
    
    @try
    {
        int x, y;
        
        NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData: [otherImage TIFFRepresentation]];
        
        NSImage *r = [[[NSImage alloc] initWithSize: NSMakeSize( [rep pixelsWide], [rep pixelsHigh])] autorelease];
        
        [r lockFocus];
        [[NSColor whiteColor] set];
        NSRectFill( NSMakeRect( 0, 0, [r size].width, [r size].height));
        [otherImage drawInRect: NSMakeRect(0,0,[r size].width, [r size].height) fromRect:NSMakeRect(0,0,[otherImage size].width, [otherImage size].height) operation: NSCompositeSourceOver fraction: 1.0];
        [r unlockFocus];
        
        NSBitmapImageRep *TIFFRep = [[[NSBitmapImageRep alloc] initWithData: [r TIFFRepresentation]] autorelease];
        
        *height = [TIFFRep pixelsHigh];
        *width = [TIFFRep pixelsWide];
        
        unsigned char *srcImage = [TIFFRep bitmapData];
        unsigned char *rgbImage = nil, *srcPtr = nil, *tmpPtr = nil;
        
        int totSize = *height * *width * 3;

        rgbImage = malloc( totSize);
        if( rgbImage)
        {
            switch( [TIFFRep bitsPerPixel])
            {
                case 8:
                    tmpPtr = rgbImage;
                    for( y = 0 ; y < *height; y++)
                    {
                        srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                        
                        x = *width;
                        while( x-->0)
                        {
                            *tmpPtr++ = *srcPtr;
                            *tmpPtr++ = *srcPtr;
                            *tmpPtr++ = *srcPtr;
                            srcPtr++;
                        }
                    }
                break;
                    
                case 32:
                    tmpPtr = rgbImage;
                    for( y = 0 ; y < *height; y++)
                    {
                        srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                        
                        x = *width;
                        while( x-->0)
                        {
                            *tmpPtr++ = *srcPtr++;
                            *tmpPtr++ = *srcPtr++;
                            *tmpPtr++ = *srcPtr++;
                            srcPtr++;
                        }
                    }
                break;
                    
                case 24:
                    tmpPtr = rgbImage;
                    for( y = 0 ; y < *height; y++)
                    {
                        srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                        
                        x = *width;
                        while( x-->0)
                        {
                            *((short*)tmpPtr) = *((short*)srcPtr);
                            tmpPtr+=2;
                            srcPtr+=2;
                            
                            *tmpPtr++ = *srcPtr++;
                        }
                    }
                break;
                    
                case 48:
                    tmpPtr = rgbImage;
                    for( y = 0 ; y < *height; y++)
                    {
                        srcPtr = srcImage + y*[TIFFRep bytesPerRow];
                        
                        x = *width;
                        while( x-->0)
                        {
                            *tmpPtr++ = *srcPtr;	srcPtr += 2;
                            *tmpPtr++ = *srcPtr;	srcPtr += 2;
                            *tmpPtr++ = *srcPtr;	srcPtr += 2;
                        }
                    }
                break;
                    
                default:
                    NSLog(@"Error - Unknow bitsPerPixel ...");
                break;
            }
        }
        
        fImage = (float*) rgbImage;
        *isRGB = YES;
    }
    @catch( NSException *e)
    {
        NSLog( @"%@", e);
    }
        
	return fImage;
}

- (void)convertMovieToDICOM:(NSString *)path source:(DicomImage*) src
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[QTMovie enterQTKitOnThreadDisablingThreadSafetyProtection];
	
	NSError	*error = nil;
	
	QTMovie *movie = [[[QTMovie alloc] initWithFile: path error: &error] autorelease];
	WaitRendering *wait = [[[WaitRendering alloc] init: @"OsiriX is pure energy..."] autorelease];
	[wait showWindow:self];
	
	if( movie)
	{
		[movie attachToCurrentThread];
		
		int curFrame = 0;
		[movie gotoBeginning];
		
		QTTime previousTime = [movie currentTime];
		
		curFrame = 0;
		
		DICOMExport *e = [[[DICOMExport alloc] init] autorelease];
		[e setSourceDicomImage: src];
		[e setSeriesDescription: [[path lastPathComponent] stringByDeletingPathExtension]];
		
		BOOL stop = NO;
		do
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			
			int width, height;
			BOOL isRGB;
			float *data = [self getDataFromNSImage: [movie currentFrameImage] w: &width h: &height rgb: &isRGB];
			
			if( data)
			{
				int spp = 1;
				if( isRGB)
					spp = 3;
				
				[e setPixelData: (unsigned char*) data samplesPerPixel: spp bitsPerSample: 8 width:width height:height];
				NSString *f = [e writeDCMFile: nil];
	 
				 if( f)
                     [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: f]
                                                              postNotifications: YES
                                                                      dicomOnly: YES
                                                            rereadExistingItems: YES
                                                              generatedByOsiriX: YES];
				
				free( data);
			}
			previousTime = [movie currentTime];
			curFrame++;
			[movie stepForward];
			
			if( QTTimeCompare( previousTime, [movie currentTime]) != NSOrderedAscending) stop = YES;
			
			[pool release];
		}
		while( stop == NO);
	}
	
	[wait close];
	
	[QTMovie exitQTKitOnThread];
	
	[pool release];
}
@end

//
//   DCMJpegImportFilter
//  
//

#import "DCMJpegImportFilter.h"
#import <OsiriX/DCM.h>
#import "OsiriX Headers/browserController.h"
#import "OsiriX Headers/DICOMExport.h"

@implementation DCMJpegImportFilter

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *currentSelection = [[BrowserController currentBrowser] databaseSelection];
	if ([currentSelection count] > 0)
	{
		id selection = [currentSelection objectAtIndex:0];
		NSString *source;
		
		if ([[[selection entity] name] isEqualToString:@"Study"]) 
			source = [[[[[selection valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
		else
			source = [[[selection valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
	
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		
		[openPanel setCanChooseDirectories: YES];
		[openPanel setAllowsMultipleSelection: YES];
		[openPanel setTitle:NSLocalizedString( @"Import", nil)];
		[openPanel setMessage:NSLocalizedString( @"Select image or folder of images to convert to DICOM", nil)];
		
		if( e == nil)
			e = [[DICOMExport alloc] init];
		
		if([openPanel runModalForTypes:[NSImage imageFileTypes]] == NSOKButton)
		{
			imageNumber = 0;
			NSEnumerator *enumerator = [[openPanel filenames] objectEnumerator];
			NSString *fpath;
			BOOL isDir;
			while(fpath = [enumerator nextObject])
			{
				[[NSFileManager defaultManager] fileExistsAtPath:fpath isDirectory:&isDir];
				
				if (isDir)
				{
					[e setSeriesDescription: [[fpath lastPathComponent] stringByDeletingPathExtension]];
					
					NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath: fpath];
					NSString *path;
					while( path = [dirEnumerator nextObject])
						if( [[NSImage imageFileTypes] containsObject:[path pathExtension]] 
						|| [[NSImage imageFileTypes] containsObject:NSFileTypeForHFSTypeCode([[[[NSFileManager defaultManager] fileSystemAttributesAtPath:path] objectForKey:NSFileHFSTypeCode] longValue])])
							[self convertImageToDICOM:[fpath stringByAppendingPathComponent:path] source: source];
				}
				else
				{
					[e setSeriesDescription: [[fpath lastPathComponent] stringByDeletingPathExtension]];
						
					[self convertImageToDICOM: fpath source: source];
				}
			}
			
			[e release];
			e = nil;
		}
	}
	[pool release];
	
	return -1;
}

- (void)convertImageToDICOM:(NSString *)path source:(NSString *)src
{
	//create image
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	
	//if we have an image  get the info we need from the imageRep.
	if (image)
	{
		NSBitmapImageRep *rep = (NSBitmapImageRep*) [image bestRepresentationForDevice:nil];
		
		if ([rep isMemberOfClass: [NSBitmapImageRep class]])
		{
			[e setSourceFile: src];
			
			int bpp = [rep bitsPerPixel]/[rep samplesPerPixel];
			int spp = [rep samplesPerPixel];
			
			if( [rep bitsPerPixel] == 32 && spp == 3)
			{
				bpp = 8;
				spp = 4;
			}
			
			[e setPixelData: [rep bitmapData] samplesPerPixel: spp bitsPerSample: bpp width:[rep pixelsWide] height:[rep pixelsHigh]];
			
			if( [rep isPlanar])
				NSLog( @"********** DCMJpegImportFilter Planar is not yet supported....");
			
			[e writeDCMFile: [NSString stringWithFormat: @"%@/INCOMING.noindex/JTD%d.dcm", [[BrowserController currentBrowser] documentsDirectory], imageNumber++]];
		}
	}
	[pool release];
}
@end

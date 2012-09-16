//
//   DCMJpegImportFilter
//  
//

#import "DCMJpegImportFilter.h"
#import "OsiriXAPI/browserController.h"
#import "OsiriXAPI/DICOMExport.h"

@implementation DCMJpegImportFilter

- (id)init
{
    [super init];
    
	[NSBundle loadNibNamed: @"Options" owner:self];
	
	return self;
}

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    NSMutableArray *images = [NSMutableArray array];
    
    if( [[[BrowserController currentBrowser] window] firstResponder] == [[BrowserController currentBrowser] oMatrix]) [[BrowserController currentBrowser] filesForDatabaseMatrixSelection: images];
    else [[BrowserController currentBrowser] filesForDatabaseOutlineSelection: images];
    
    NSString *source = nil;
    
    if( [images count])
        source = [[images objectAtIndex: 0] valueForKey:@"completePath"];
    
    if( e == nil)
    {
        e = [[DICOMExport alloc] init];
        [e setSeriesNumber: 86532 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute]];
    }

    BOOL supportCustomMetaData = NO;
    
    if( [e respondsToSelector: @selector( metaDataDict)])
        supportCustomMetaData = YES;
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories: YES];
    [openPanel setAllowsMultipleSelection: YES];
    [openPanel setTitle:NSLocalizedString( @"Import", nil)];
    [openPanel setMessage:NSLocalizedString( @"Select image or folder of images to convert to DICOM", nil)];
    
    if( supportCustomMetaData)
        [openPanel setAccessoryView: accessoryView];
    
    if([openPanel runModalForTypes:[NSImage imageFileTypes]] == NSOKButton)
    {
        BOOL valid = YES;
        
        if( supportCustomMetaData && [[NSUserDefaults standardUserDefaults] integerForKey: @"JPEGtoDICOMMetaDataTag"] == 0)
        {
            source = nil;
            
            NSMutableDictionary *metaData = e.metaDataDict;
            NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
            
            [metaData setValue: [d valueForKey: @"JPEGtoDICOMPatientsName"] forKey: @"patientsName"];
            [metaData setValue: [d valueForKey: @"JPEGtoDICOMPatientsID"] forKey: @"patientID"];
            [metaData setValue: [d objectForKey: @"JPEGtoDICOMPatientsDOB"] forKey: @"patientsBirthdate"];
            if( [d integerForKey: @"JPEGtoDICOMPatientsSex"])
                [metaData setValue: @"F" forKey: @"patientsSex"];
            else
                [metaData setValue: @"M" forKey: @"patientsSex"];
            
            [metaData setValue: [d objectForKey: @"JPEGtoDICOMStudyDate"] forKey: @"studyDate"];
            
            [metaData setValue: [d valueForKey: @"JPEGtoDICOMStudyDescription"] forKey: @"studyDescription"];
            [metaData setValue: [d valueForKey: @"JPEGtoDICOMModality"] forKey: @"modality"];
            
            [e setModalityAsSource: YES];
        }
        else if( [images count] == 0)
        {
            NSRunAlertPanel( @"JPEG to DICOM", @"Select a study in the database where to put the image.", @"OK", nil, nil);
            valid = NO;
        }
        else
            [e setModalityAsSource: NO];
        
        if( valid)
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
                        if( [[NSImage imageFileTypes] containsObject: [path pathExtension]] 
                        || [[NSImage imageFileTypes] containsObject: NSFileTypeForHFSTypeCode( [[[[NSFileManager defaultManager] attributesOfFileSystemForPath: path error: nil] objectForKey: NSFileHFSTypeCode] longValue])])
                            [self convertImageToDICOM:[fpath stringByAppendingPathComponent:path] source: source];
                }
                else
                {
                    [e setSeriesDescription: [[fpath lastPathComponent] stringByDeletingPathExtension]];
                        
                    [self convertImageToDICOM: fpath source: source];
                }
            }
        }
        
        [e release];
        e = nil;
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
			
			NSString *f = [e writeDCMFile: nil];
	
			if( f)
				[BrowserController addFiles: [NSArray arrayWithObject: f]
							 toContext: [[BrowserController currentBrowser] managedObjectContext]
							toDatabase: [BrowserController currentBrowser]
							 onlyDICOM: YES 
					  notifyAddedFiles: YES
				   parseExistingObject: YES
							  dbFolder: [[BrowserController currentBrowser] documentsDirectory]
					 generatedByOsiriX: YES];
		}
	}
	[pool release];
}
@end

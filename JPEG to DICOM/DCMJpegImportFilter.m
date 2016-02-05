//
//   DCMJpegImportFilter
//  
//

#import "DCMJpegImportFilter.h"
#import "OsiriXAPI/browserController.h"
#import "OsiriXAPI/DICOMExport.h"

@implementation DCMJpegImportFilter

@synthesize selectedStudyAvailable;

- (id)init
{
    [super init];
    
	[NSBundle loadNibNamed: @"Options" owner:self];
	
	return self;
}

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    @try
    {
        NSMutableArray *images = [NSMutableArray array];
        
        if( [[[BrowserController currentBrowser] window] firstResponder] == [[BrowserController currentBrowser] oMatrix]) [[BrowserController currentBrowser] filesForDatabaseMatrixSelection: images];
        else
            [[BrowserController currentBrowser] filesForDatabaseOutlineSelection: images];
        
        NSString *source = nil;
        id sourceStudy = nil;
        
        if( [images count])
        {
            self.selectedStudyAvailable = YES;
            source = [[images objectAtIndex: 0] valueForKey:@"completePath"];
        }
        else
        {
            id study = [[BrowserController currentBrowser] selectedStudy];
            
            if( study == nil)
                self.selectedStudyAvailable = NO;
            else
            {
                self.selectedStudyAvailable = YES;
                sourceStudy = study;
            }
        }
        
        if( e == nil)
            e = [[DICOMExport alloc] init];
        
        int seriesNumber = 86532 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute];
        [e setSeriesNumber: seriesNumber];

        BOOL supportCustomMetaData = NO;
        
        if( [e respondsToSelector: @selector( metaDataDict)])
            supportCustomMetaData = YES;
        
        if( self.selectedStudyAvailable == NO)
        {
            if( supportCustomMetaData == NO)
            {
                NSRunAlertPanel( @"JPEG to DICOM", @"First, select a study in the database where to put the image.", @"OK", nil, nil);
                return -1;
            }
            
            [[NSUserDefaults standardUserDefaults] setInteger: 0 forKey: @"JPEGtoDICOMMetaDataTag"];
        }
        
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel setCanChooseDirectories: YES];
        [openPanel setAllowsMultipleSelection: YES];
        [openPanel setTitle:NSLocalizedString( @"Import", nil)];
        [openPanel setMessage:NSLocalizedString( @"Select image or folder of images to convert to DICOM", nil)];
        
        if( supportCustomMetaData)
            [openPanel setAccessoryView: accessoryView];
        
        if( [openPanel runModalForTypes:[NSImage imageFileTypes]] == NSOKButton)
        {
            BOOL valid = YES;
            
            if( supportCustomMetaData && ([[NSUserDefaults standardUserDefaults] integerForKey: @"JPEGtoDICOMMetaDataTag"] == 0 || (source == nil && [[NSUserDefaults standardUserDefaults] integerForKey: @"JPEGtoDICOMMetaDataTag"] == 1 && sourceStudy != nil)))
            {
                source = nil;
                
                NSMutableDictionary *metaData = e.metaDataDict;
                
                if( [[NSUserDefaults standardUserDefaults] integerForKey: @"JPEGtoDICOMMetaDataTag"] == 1)
                {
                    [metaData setValue: [sourceStudy valueForKey: @"name"] forKey: @"patientsName"];
                    [metaData setValue: [sourceStudy valueForKey: @"name"] forKey: @"patientName"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"patientID"] forKey: @"patientID"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"dateOfBirth"] forKey: @"patientsBirthdate"];
                    [metaData setValue: [sourceStudy valueForKey: @"dateOfBirth"] forKey: @"patientBirthdate"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"patientSex"] forKey: @"patientsSex"];
                    [metaData setValue: [sourceStudy valueForKey: @"patientSex"] forKey: @"patientSex"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"date"] forKey: @"studyDate"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"studyName"] forKey: @"studyDescription"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"modality"] forKey: @"modality"];
                    
                    [metaData setValue: [sourceStudy valueForKey: @"studyInstanceUID"] forKey: @"studyUID"];
                    [metaData setValue: [sourceStudy valueForKey: @"studyID"] forKey: @"studyID"];
                }
                else
                {
                    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
                    
                    [metaData setValue: [d valueForKey: @"JPEGtoDICOMPatientsName"] forKey: @"patientsName"];
                    [metaData setValue: [d valueForKey: @"JPEGtoDICOMPatientsName"] forKey: @"patientName"];
                    
                    [metaData setValue: [d valueForKey: @"JPEGtoDICOMPatientsID"] forKey: @"patientID"];
                    
                    [metaData setValue: [d objectForKey: @"JPEGtoDICOMPatientsDOB"] forKey: @"patientsBirthdate"];
                    [metaData setValue: [d objectForKey: @"JPEGtoDICOMPatientsDOB"] forKey: @"patientBirthdate"];
                    
                    if( [d integerForKey: @"JPEGtoDICOMPatientsSex"])
                    {
                        [metaData setValue: @"F" forKey: @"patientsSex"];
                        [metaData setValue: @"F" forKey: @"patientSex"];
                    }
                    else
                    {
                        [metaData setValue: @"M" forKey: @"patientsSex"];
                        [metaData setValue: @"M" forKey: @"patientSex"];
                    }
                    
                    [metaData setValue: [d objectForKey: @"JPEGtoDICOMStudyDate"] forKey: @"studyDate"];
                    
                    [metaData setValue: [d valueForKey: @"JPEGtoDICOMStudyDescription"] forKey: @"studyDescription"];
                    
                    [metaData setValue: [d valueForKey: @"JPEGtoDICOMModality"] forKey: @"modality"];
                }
                
                [e setModalityAsSource: YES];
            }
            else
                [e setModalityAsSource: NO];
            
            if( valid)
            {
                imageNumber = 0;
                BOOL seriesDescriptionSet = NO;
                
                for( NSString *fpath in [openPanel filenames])
                {
                    BOOL isDir;
                    if( [[NSFileManager defaultManager] fileExistsAtPath:fpath isDirectory:&isDir])
                    {
                        if (isDir)
                        {
                            [e setSeriesDescription: [[fpath lastPathComponent] stringByDeletingPathExtension]];
                            [e setSeriesNumber: seriesNumber++];
                            
                            NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath: fpath];
                            NSString *path;
                            while( path = [dirEnumerator nextObject])
                                if( [[NSImage imageFileTypes] containsObject: [path pathExtension]] 
                                || [[NSImage imageFileTypes] containsObject: NSFileTypeForHFSTypeCode( [[[[NSFileManager defaultManager] attributesOfFileSystemForPath: path error: nil] objectForKey: NSFileHFSTypeCode] longValue])])
                                {
                                    NSString *f = [self convertImageToDICOM:[fpath stringByAppendingPathComponent:path] source: source];
                                    
                                    if( source == nil)
                                        source = f;
                                }
                        }
                        else
                        {
                            if( seriesDescriptionSet == NO)
                            {
                                [e setSeriesDescription: [[fpath lastPathComponent] stringByDeletingPathExtension]];
                                seriesDescriptionSet = YES;
                            }
                            
                            NSString *f = [self convertImageToDICOM: fpath source: source];
                            
                            if( source == nil)
                                source = f;
                        }
                    }
                }
            }
        }
    }
    @catch ( NSException *ex) {
        NSLog( @"%@", ex);
    }
    @finally {
        [e release];
        e = nil;
        [pool release];
	}
    
	return 0;
}

- (NSString*) convertImageToDICOM:(NSString *)path source:(NSString *)src
{
    NSString *createdFile = nil;
    
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
			
            createdFile = [[e writeDCMFile: nil] retain];
	
			if( createdFile)
                [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: createdFile]
                                                                            postNotifications: YES
                                                                                    dicomOnly: YES
                                                                          rereadExistingItems: YES
                                                                            generatedByOsiriX: YES];
		}
	}
	[pool release];
    
    return [createdFile autorelease];
}
@end

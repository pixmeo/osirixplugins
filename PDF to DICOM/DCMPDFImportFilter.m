//
//   DCMPDFImportFilter
//  
//

#import "DCMPDFImportFilter.h"
#import <OsiriX/DCM.h>

#import "OsiriXAPI/browserController.h"
#import "OsiriXAPI/DicomFile.h"
#import "OsiriXAPI/DicomDatabase.h"
#import "OsiriXAPI/DicomStudy+Report.h"

@implementation DCMPDFImportFilter

- (long) filterImage:(NSString*) menuName
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *currentSelection = [[BrowserController currentBrowser] databaseSelection];
	if( [currentSelection count] > 0 && [[currentSelection objectAtIndex:0] isDistant] == NO)
	{
		id selection = [currentSelection objectAtIndex:0];
        
		NSString *source = nil;
		
		if ([[[selection entity] name] isEqualToString:@"Study"]) 
			source = [[[[[selection valueForKey:@"series"] anyObject] valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
		else
			source = [[[selection valueForKey:@"images"] anyObject] valueForKey:@"completePath"];
		
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:YES];
		[openPanel setTitle:NSLocalizedString(@"Import", nil)];
		[openPanel setMessage:NSLocalizedString(@"Select PDF or folder of PDFs to convert to DICOM", nil)];
		
		if( [openPanel runModalForTypes:[NSArray arrayWithObject:@"pdf"]] == NSOKButton)
		{
			NSEnumerator *enumerator = [[openPanel filenames] objectEnumerator];
			NSString *fpath;
			BOOL isDir;
			while(fpath = [enumerator nextObject])
			{
				[[NSFileManager defaultManager] fileExistsAtPath:fpath isDirectory:&isDir];
				
				//loop through directory if true
				if (isDir)
				{
					NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:fpath];
					NSString *path;
					while (path = [dirEnumerator nextObject])
                    {
						if  ([[NSImage imageFileTypes] containsObject:[path pathExtension]])
                        {
                            NSString *newDCM = [[[BrowserController currentBrowser] database] uniquePathForNewDataFileWithExtension: @"dcm"];
                            
                            [DicomStudy transformPdfAtPath: [fpath stringByAppendingPathComponent:path] toDicomAtPath: newDCM usingSourceDicomAtPath: source];
                            
                            [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: newDCM]
                               postNotifications: YES
                                       dicomOnly: YES
                             rereadExistingItems: YES
                               generatedByOsiriX: YES];
                        }
                    }
				}
				else
                {
                    NSString *newDCM = [[[BrowserController currentBrowser] database] uniquePathForNewDataFileWithExtension: @"dcm"];
                    
                    [DicomStudy transformPdfAtPath: fpath toDicomAtPath: newDCM usingSourceDicomAtPath: source];
                    
                    [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: newDCM]
                                                             postNotifications: YES
                                                                     dicomOnly: YES
                                                           rereadExistingItems: YES
                                                             generatedByOsiriX: YES];
                }
			}
		}
	}
    else NSRunAlertPanel( @"PDF to DICOM", @"First, select a local study in the database where to put the PDF.", @"OK", nil, nil);
	
	[pool release];
	
	return 0;
}
@end

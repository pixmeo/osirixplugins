
#import <SandboxWindowController.h>

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "AppController.h"
#import "BrowserController.h"
#import "ThreadsManager.h"
#import "NSThread+N2.h"


#import <XMLGenerator.h>
#import <DAVKit/DAVKit.h>


@implementation SandboxWindowController


- (id)initWithFiles:(NSArray *)theFiles managedObjects:(NSArray *)managedObjects
{
	if( self = [super initWithWindowNibName:@"SandboxViewer"])
	{
		[[NSFileManager defaultManager] removeFileAtPath:[self folderToBurn] handler:nil];
		
		files = [theFiles mutableCopy]; // file paths
		dbObjectsID = [managedObjects mutableCopy];
		originalDbObjectsID = [dbObjectsID mutableCopy];
		
		[files removeDuplicatedStringsInSyncWithThisArray: dbObjectsID];
		
		id managedObject;
		id patient = nil;
		_multiplePatients = NO;
		
		for (managedObject in [[[BrowserController currentBrowser] database] objectsWithIDs: dbObjectsID])
		{
			NSString *newPatient = [managedObject valueForKeyPath:@"series.study.patientUID"];
			
			if( patient == nil)
				patient = newPatient;
			else if( [patient compare: newPatient options: NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch] != NSOrderedSame)
			{
				_multiplePatients = YES;
				break;
			}
			patient = newPatient;
		}
		
		burning = NO;
		
		[[self window] center];
		
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidMountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidUnmountNotification object:nil];
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(_observeVolumeNotification:) name:NSWorkspaceDidRenameVolumeNotification object:nil];
		
		NSLog(@"SandBox allocated");
	}
	return self;
}


#if (1)
- (void) prepareCDContent: (NSMutableArray*) dbObjects :(NSMutableArray*) originalDbObjects
{
	//NSLog(@"=========================");
	
	[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
	
	@try
	{
		NSEnumerator *enumerator;
		if( anonymizedFiles)
			enumerator = [anonymizedFiles objectEnumerator];
		else
			enumerator = [files objectEnumerator];
		
		NSString *file;
    NSString *burnFolder = [self folderToBurn];
		NSString *subFolder = [NSString stringWithFormat:@"%@/DICOM",burnFolder];
    NSFileManager *manager = [NSFileManager defaultManager];
		int i = 0;
		
		if( ![manager fileExistsAtPath:burnFolder])
			[manager createDirectoryAtPath:burnFolder attributes:nil];
		
		NSString *dicomFolder = [burnFolder stringByAppendingPathComponent:cdName];
		[manager createDirectoryAtPath:dicomFolder withIntermediateDirectories:FALSE attributes:nil error:nil];
		
		NSMutableArray *dicomImages = [DicomImage dicomImagesInObjects:dbObjects];
		[XMLGenerator createDicomStructureAtPath:dicomFolder withFiles:files withCorrespondingImages:dicomImages];
		
		
		
		
		
		// Test call [DicomImage image]
		
		//NSLog(@"[dicomImages lastObject] class name : %@", [[dicomImages lastObject] className]);
		//NSSize size;
		//size = NSMakeSize(70, 70);
		//NSImage* test = [[dicomImages lastObject] imageByScalingProportionallyToSize:size];
		
		//NSImage* test2 = [[dicomImages lastObject] image];
		
		//[test2 saveAsJpegWithName:[dicomFolder stringByAppendingPathComponent:@"thumbnail_2.jpg"]];
		
	}
	@catch( NSException * e)
  {
		N2LogException( e);
	}
	
	//NSLog(@"--------------------------");
}


#else


- (void) prepareCDContent: (NSMutableArray*) dbObjects :(NSMutableArray*) originalDbObjects
{
	NSThread* thread = [NSThread currentThread];
	
	[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:@"" waitUntilDone:YES];
	
	@try
	{
		NSEnumerator *enumerator;
		if( anonymizedFiles) enumerator = [anonymizedFiles objectEnumerator];
		else enumerator = [files objectEnumerator];
		
		NSString *file;
		NSString *burnFolder = [self folderToBurn];
		NSString *dicomdirPath = [NSString stringWithFormat:@"%@/DICOMDIR",burnFolder];
		NSString *subFolder = [NSString stringWithFormat:@"%@/DICOM",burnFolder];
		NSFileManager *manager = [NSFileManager defaultManager];
		int i = 0;
		
		//create burn Folder and dicomdir.
		
		if( ![manager fileExistsAtPath:burnFolder])
			[manager createDirectoryAtPath:burnFolder attributes:nil];
		if( ![manager fileExistsAtPath:subFolder])
			[manager createDirectoryAtPath:subFolder attributes:nil];
		if( ![manager fileExistsAtPath:dicomdirPath])
			[manager copyPath:[[NSBundle mainBundle] pathForResource:@"DICOMDIR" ofType:nil] toPath:dicomdirPath handler:nil];
		
		NSMutableArray *newFiles = [NSMutableArray array];
		NSMutableArray *compressedArray = [NSMutableArray array];
		
		while((file = [enumerator nextObject]) && cancelled == NO)
		{
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			NSString *newPath = [NSString stringWithFormat:@"%@/%05d", subFolder, i++];
			DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:file decodingPixelData:NO];
			//Don't want Big Endian, May not be readable
			if( [[dcmObject transferSyntax] isEqualToTransferSyntax:[DCMTransferSyntax ExplicitVRBigEndianTransferSyntax]])
				[dcmObject writeToFile:newPath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality: DCMLosslessQuality atomically:YES];
			else
				[manager copyPath:file toPath:newPath handler:nil];
			
			if( dcmObject)	// <- it's a DICOM file
			{
				switch( [compressionMode selectedTag])
				{
					case 0:
						break;
						
					case 1:
						[compressedArray addObject: newPath];
						break;
						
					case 2:
						[compressedArray addObject: newPath];
						break;
				}
			}
			
			[newFiles addObject:newPath];
			[pool release];
		}
		
		if( [newFiles count] > 0 && cancelled == NO)
		{
			NSArray *copyCompressionSettings = nil;
			NSArray *copyCompressionSettingsLowRes = nil;
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"JPEGinsteadJPEG2000"] && [compressionMode selectedTag] == 1) // Temporarily switch the prefs... ugly....
			{
				copyCompressionSettings = [[NSUserDefaults standardUserDefaults] objectForKey: @"CompressionSettings"];
				copyCompressionSettingsLowRes = [[NSUserDefaults standardUserDefaults] objectForKey: @"CompressionSettingsLowRes"];
				
				[[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", [NSNumber numberWithInt: compression_JPEG], @"compression", @"0", @"quality", nil]] forKey: @"CompressionSettings"];
				
				[[NSUserDefaults standardUserDefaults] setObject: [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString( @"default", nil), @"modality", [NSNumber numberWithInt: compression_JPEG], @"compression", @"0", @"quality", nil]] forKey: @"CompressionSettingsLowRes"];
				
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
			@try
			{
				switch( [compressionMode selectedTag])
				{
					case 1:
						[[BrowserController currentBrowser] decompressArrayOfFiles: compressedArray work: [NSNumber numberWithChar: 'C']];
						break;
						
					case 2:
						[[BrowserController currentBrowser] decompressArrayOfFiles: compressedArray work: [NSNumber numberWithChar: 'D']];
						break;
				}
			}
			@catch (NSException *e) {
				NSLog(@"Exception while prepareCDContent compression: %@", e);
			}
			
			if( copyCompressionSettings && copyCompressionSettingsLowRes)
			{
				[[NSUserDefaults standardUserDefaults] setObject: copyCompressionSettings forKey:@"CompressionSettings"];
				[[NSUserDefaults standardUserDefaults] setObject: copyCompressionSettingsLowRes forKey:@"CompressionSettingsLowRes"];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
			thread.name = NSLocalizedString( @"Burning...", nil);
			thread.status = NSLocalizedString( @"Writing DICOMDIR...", nil);
			[self addDICOMDIRUsingDCMTK_forFilesAtPaths:newFiles dicomImages:dbObjects];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnWeasis"] && cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Adding Weasis...", nil);
				NSString* weasisPath = [[AppController sharedAppController] weasisBasePath];
				for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:weasisPath error:NULL])
					[[NSFileManager defaultManager] copyItemAtPath:[weasisPath stringByAppendingPathComponent:subpath] toPath:[burnFolder stringByAppendingPathComponent:subpath] error:NULL];
				
				// Change Label in Autorun.inf
				NSStringEncoding encoding;
				NSString *autorunInf = [NSString stringWithContentsOfFile: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] usedEncoding: &encoding error: nil];
				
				if( autorunInf.length)
				{
					autorunInf = [autorunInf stringByReplacingOccurrencesOfString: @"Label=Weasis" withString: [NSString stringWithFormat: @"Label=%@", cdName]];
					
					[[NSFileManager defaultManager] removeItemAtPath: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] error: nil];
					[autorunInf writeToFile: [burnFolder stringByAppendingPathComponent: @"Autorun.inf"] atomically: YES encoding: encoding  error: nil];
				}
			}
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnOsirixApplication"] && cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Adding OsiriX Lite...", nil);
				// unzip the file
				NSTask *unzipTask = [[NSTask alloc] init];
				[unzipTask setLaunchPath: @"/usr/bin/unzip"];
				[unzipTask setCurrentDirectoryPath: burnFolder];
				[unzipTask setArguments: [NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: @"OsiriX Launcher.zip"], nil]]; // -o to override existing report w/ same name
				[unzipTask launch];
				
				while( [unzipTask isRunning])
					[NSThread sleepForTimeInterval: 0.1];
				
				//[unzipTask waitUntilExit];		// <- This is VERY DANGEROUS : the main runloop is continuing...
				
				[unzipTask release];
			}
			
			if(  [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnHtml"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO && cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Adding HTML pages...", nil);
				[self produceHtml: burnFolder dicomObjects: originalDbObjects];
			}
			
			if( [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"].length <= 1)
				[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
			
			if( [[NSFileManager defaultManager] fileExistsAtPath: [[[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"] stringByExpandingTildeInPath]] == NO)
				[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"BurnSupplementaryFolder"] && cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Adding Supplementary folder...", nil);
				NSString *supplementaryBurnPath = [[NSUserDefaults standardUserDefaults] stringForKey: @"SupplementaryBurnPath"];
				if( supplementaryBurnPath)
				{
					supplementaryBurnPath = [supplementaryBurnPath stringByExpandingTildeInPath];
					if( [manager fileExistsAtPath: supplementaryBurnPath])
					{
						NSEnumerator *enumerator = [manager enumeratorAtPath: supplementaryBurnPath];
						while (file=[enumerator nextObject])
						{
							[manager copyPath: [NSString stringWithFormat:@"%@/%@", supplementaryBurnPath,file] toPath: [NSString stringWithFormat:@"%@/%@", burnFolder,file] handler:nil];
						}
					}
					else [[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"BurnSupplementaryFolder"];
				}
			}
			
			if( [[NSUserDefaults standardUserDefaults] boolForKey: @"copyReportsToCD"] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"anonymizedBeforeBurning"] == NO && cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Adding Reports...", nil);
				
				NSMutableArray *studies = [NSMutableArray array];
				
				for( NSManagedObject *im in dbObjects)
				{
					if( [im valueForKeyPath:@"series.study.reportURL"])
					{
						if( [studies containsObject: [im valueForKeyPath:@"series.study"]] == NO)
							[studies addObject: [im valueForKeyPath:@"series.study"]];
					}
				}
				
				for( DicomStudy *study in studies)
				{
					if( [[study valueForKey: @"reportURL"] hasPrefix: @"http://"] || [[study valueForKey: @"reportURL"] hasPrefix: @"https://"])
					{
						NSString *urlContent = [NSString stringWithContentsOfURL: [NSURL URLWithString: [study valueForKey: @"reportURL"]]];
						
						[urlContent writeToFile: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] atomically: YES];
					}
					else
					{
						// Convert to PDF
						
						NSString *pdfPath = [study saveReportAsPdfInTmp];
						
						if( [manager fileExistsAtPath: pdfPath] == NO)
							[manager copyPath: [study valueForKey:@"reportURL"] toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.%@", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]], [self cleanStringForFile: [[study valueForKey:@"reportURL"] pathExtension]]] handler:nil];
						else
							[manager copyPath: pdfPath toPath: [NSString stringWithFormat:@"%@/Report-%@ %@.pdf", burnFolder, [self cleanStringForFile: [study valueForKey:@"modality"]], [self cleanStringForFile: [BrowserController DateTimeWithSecondsFormat: [study valueForKey:@"date"]]]] handler: nil];
					}
					
					if( cancelled)
						break;
				}
			}
		}
		
		if( [[NSUserDefaults standardUserDefaults] boolForKey: @"EncryptCD"] && cancelled == NO)
		{
			if( cancelled == NO)
			{
				thread.name = NSLocalizedString( @"Burning...", nil);
				thread.status = NSLocalizedString( @"Encrypting...", nil);
				
				// ZIP method - zip test.zip /testFolder -r -e -P hello
				
				[BrowserController encryptFileOrFolder: burnFolder inZIPFile: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] password: self.password];
				self.password = @"";
				
				[[NSFileManager defaultManager] removeItemAtPath: burnFolder error: nil];
				[[NSFileManager defaultManager] createDirectoryAtPath: burnFolder attributes: nil];
				
				[[NSFileManager defaultManager] moveItemAtPath: [[burnFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent: @"encryptedDICOM.zip"] toPath: [burnFolder stringByAppendingPathComponent: @"encryptedDICOM.zip"] error: nil];
				[[NSString stringWithString: NSLocalizedString( @"The images are encrypted with a password in this ZIP file: first, unzip this file to read the content. Use an Unzip application to extract the files.", nil)] writeToFile: [burnFolder stringByAppendingPathComponent: @"ReadMe.txt"] atomically: YES encoding: NSASCIIStringEncoding error: nil];
			}
		}
		
		thread.name = NSLocalizedString( @"Burning...", nil);
		thread.status = [NSString stringWithFormat: NSLocalizedString( @"Writing %3.2fMB...", nil), (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)];
		
		[finalSizeField performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:@"Final files size to burn: %3.2fMB", (float) ([[self getSizeOfDirectory: burnFolder] longLongValue] / 1024)] waitUntilDone:YES];
	}
	@catch( NSException * e)
	{
		N2LogException( e);
	}
}


#endif



@end


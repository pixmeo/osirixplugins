//
//  DiscPublishingPatientDisc.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPatientDisc.h"
#import "DiscBurningOptions.h"
#import "ThreadsManagerThreadInfo.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublisher.h"
#import "DiscPublisher+Constants.h"
#import "ThreadsManager.h"
#import "NSFileManager+DiscPublisher.h"
#import "DicomCompressor.h"
#import <OsiriX Headers/QTExportHTMLSummary.h>
#import <OsiriX Headers/DicomSeries.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX Headers/DicomImage.h>
#import <OsiriX Headers/NSString+N2.h>
#import <OsiriX Headers/BrowserController.h>
#import <JobManager/PTJobManager.h>
#import <QTKit/QTKit.h>
#import "DiscPublishingJob+Info.h"
#import "DiscPublishing.h"
#import "NSAppleEventDescriptor+N2.h"


@implementation DiscPublishingPatientDisc

-(id)initWithFiles:(NSArray*)files options:(DiscBurningOptions*)options {
	self = [super init];
	self.name = [NSString stringWithFormat:@"Preparing disc data for %@", [[files objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
	
	_files = [[NSMutableArray alloc] initWithArray:files];
	_options = [options retain];

	_tmpPath = [[[NSFileManager defaultManager] tmpFilePathInDir:@"/tmp"] retain];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:_tmpPath];

	[self start];
	
	return self;
}

-(void)dealloc {
	[[NSFileManager defaultManager] removeItemAtPath:_tmpPath error:NULL];
	[_tmpPath release];
	[_options release];
	[_files release];
	[super dealloc];
}

-(NSArray*)imagesBelongingToSeries:(DicomSeries*)series {
	NSMutableArray* ret = [[NSMutableArray alloc] init];
	
	for (DicomImage* image in _files)
		if ([image.series.seriesDICOMUID isEqual:series.seriesDICOMUID])
			[ret addObject:image];
	
	return [ret autorelease];
}

+(NSArray*)selectSeriesOfSizes:(NSDictionary*)seriesSizes forDiscWithCapacity:(NSUInteger)mediaCapacity {
	// if all fits in a disk, return all
	NSUInteger sum = 0;
	for (NSValue* serieValue in seriesSizes)
		sum += [[seriesSizes objectForKey:serieValue] unsignedIntValue];
	if (sum <= mediaCapacity)
		return [seriesSizes allKeys];
	
	// else combine the blocks
	NSArray* series = [seriesSizes allKeys];
	NSMutableArray* selectedSeries = [NSMutableArray array];
	
	sum = 0;
	// TODO: use a better algorithm (bin packing, ideally)
	for (NSValue* serieValue in series) {
		NSUInteger size = [[seriesSizes objectForKey:serieValue] unsignedIntValue];
		if (sum+size <= mediaCapacity)  {
			sum += size;
			[selectedSeries addObject:serieValue];
		}
	}
	
	return selectedSeries;
}

+(NSString*)dirPathForSeries:(DicomSeries*)series inBaseDir:(NSString*)basePath {
	return [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", [series valueForKeyPath:@"seriesDICOMUID"]]];
}

+(void)copyOsirixLiteToPath:(NSString*)path {
	NSTask *unzipTask = [[NSTask alloc] init];
	[unzipTask setLaunchPath: @"/usr/bin/unzip"];
	[unzipTask setCurrentDirectoryPath:path];
	[unzipTask setArguments:[NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"OsiriX Launcher.zip"], NULL]];
	[unzipTask launch];
	[unzipTask waitUntilExit];
	[unzipTask release];
}

+(void)copyContentsOfDirectory:(NSString*)auxDir toPath:(NSString*)path {
	for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:auxDir error:NULL])
		[[NSFileManager defaultManager] copyPath:[auxDir stringByAppendingPathComponent:subpath] toPath:[path stringByAppendingPathComponent:subpath] handler:NULL];
}

+(NSString*)discNameForSeries:(NSArray*)series {
	NSMutableArray* names = [NSMutableArray array];
	for (DicomSeries* serie in series)
		if (![names containsObject:serie.study.name])
			[names addObject:serie.study.name];
	
	if (names.count == 1)
		return [names objectAtIndex:0];
	
	return [NSString stringWithFormat:@"Archive %@", [[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d-%H%M%S" timeZone:NULL locale:NULL]];
}

+(NSString*)descriptionForSeries:(NSArray*)series {
	return @"This is the description for thecontent of this disc";
}

+(void)generateDICOMDIRAtDirectory:(NSString*)root withDICOMFilesInDirectory:(NSString*)dicomPath {
	if ([dicomPath hasPrefix:root]) {
		NSUInteger index = root.length;
		if ([dicomPath characterAtIndex:index] == '/')
			++index;
		dicomPath = [dicomPath substringFromIndex:index];
	}
	
	NSTask* dcmmkdirTask = [[NSTask alloc] init];
	[dcmmkdirTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dicom.dic"] forKey:@"DCMDICTPATH"]];
	[dcmmkdirTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dcmmkdir"]];
	[dcmmkdirTask setCurrentDirectoryPath:root];
	[dcmmkdirTask setArguments:[NSArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc", @"+I", @"+m", @"+id", dicomPath, NULL]];		
	[dcmmkdirTask launch];
	[dcmmkdirTask waitUntilExit];
	[dcmmkdirTask release];
}

-(void)spawnDiscWrite:(NSString*)discRootDirPath info:(NSDictionary*)info {
	NSDictionary* errors = [NSDictionary dictionary];
	
	NSString* scptPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"DiscPublishingTool.scpt"];
	NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scptPath] error:&errors];
	if (!appleScript)
		[NSException raise:NSGenericException format:[errors description]];
	
	ProcessSerialNumber psn = {0, kCurrentProcess};
	NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&psn length:sizeof(ProcessSerialNumber)];
	
	NSAppleEventDescriptor* event = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:target returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[@"PublishDisc" lowercaseString]] forKeyword:keyASSubroutineName];
	
	NSAppleEventDescriptor* params = [NSAppleEventDescriptor listDescriptor];
	[params insertDescriptor:[[info objectForKey:DiscPublishingJobInfoDiscNameKey] appleEventDescriptor] atIndex:1];
	[params insertDescriptor:[discRootDirPath appleEventDescriptor] atIndex:2];
	[params insertDescriptor:[info appleEventDescriptor] atIndex:3];
	[event setParamDescriptor:params forKeyword:keyDirectObject];
	
	if (![appleScript executeAppleEvent:event error:&errors])
		[NSException raise:NSGenericException format:[errors description]];
	
	[appleScript release];
}

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	ThreadsManagerThreadInfo* threadInfo = [[ThreadsManager defaultManager] addThread:self name:[self name]];
	
	[threadInfo setStatus:@"Detecting image series..."];
	NSMutableArray* series = [[NSMutableArray alloc] init];
	for (DicomImage* image in _files) {
		DicomSeries* serie = [image valueForKeyPath:@"series"];
		if (![series containsObject:serie])
			[series addObject:serie];
	}
	
	NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	[persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:NULL URL:NULL options:NULL error:NULL];
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
	managedObjectContext.undoManager.levelsOfUndo = 1;	
	[managedObjectContext.undoManager disableUndoRegistration];

	NSMutableDictionary* seriesSizes = [[NSMutableDictionary alloc] initWithCapacity:series.count];
	NSMutableDictionary* seriesPaths = [[NSMutableDictionary alloc] initWithCapacity:series.count];
	for (DicomSeries* serie in series) {
		[threadInfo setStatus:[NSString stringWithFormat:@"Preparing data for series %@...", [serie valueForKeyPath:@"name"]]];
		
		NSArray* images = [self imagesBelongingToSeries:serie];
		images = [DiscPublishingPatientDisc prepareSeriesDataForImages:images inDirectory:_tmpPath options:_options context:managedObjectContext seriesPaths:seriesPaths];
		
		if (images.count) {
			serie = [[images objectAtIndex:0] valueForKeyPath:@"series"];
			NSString* tmpPath = [DiscPublishingPatientDisc dirPathForSeries:serie inBaseDir:_tmpPath];
				
			NSUInteger size;
			if ([_options zip]) {
				NSString* tmpZipPath = [[[NSFileManager defaultManager] tmpFilePathInTmp] stringByAppendingPathExtension:@"zip"];
				
				NSTask* task = [[NSTask alloc] init];
				[task setLaunchPath:@"/usr/bin/zip"];
				[task setArguments:[NSArray arrayWithObjects: @"-rq", tmpZipPath, tmpPath, NULL]];
				[task launch];
				[task waitUntilExit];
				[task release];
				
				size = [[[NSFileManager defaultManager] attributesOfItemAtPath:tmpZipPath error:NULL] fileSize];
				
				[[NSFileManager defaultManager] removeItemAtPath:tmpZipPath error:NULL];			
			} else size = [[NSFileManager defaultManager] sizeAtPath:tmpPath];
			[seriesSizes setObject:[NSNumber numberWithUnsignedInteger:size] forKey:[NSValue valueWithPointer:serie]];
		}
	}
	
//	NSLog(@"paths: %@", seriesPaths);

	[threadInfo setStatus:@"Preparing report data..."];

	if (_options.includeReports) {
		NSString* reportsTmpPath = [_tmpPath stringByAppendingPathComponent:@"Reports"];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:reportsTmpPath];
		; // TODO: copy reports
	}

	NSUInteger discNumber = 1;
	while (seriesSizes.count) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		[threadInfo setStatus:[NSString stringWithFormat:@"Preparing data for disc %d...", discNumber]];
		
		@try {
			NSMutableArray* privateFiles = [NSMutableArray array];

			NSString* discBaseDirPath = [[NSFileManager defaultManager] tmpFilePathInTmp];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:discBaseDirPath];
	//		NSString* discBaseDirPath = [discTmpDirPath stringByAppendingPathComponent:@"DATA"];
	//		[[NSFileManager defaultManager] confirmDirectoryAtPath:discBaseDirPath];
	//		NSString* discFinalDirPath = [discTmpDirPath stringByAppendingPathComponent:@"FINAL"];
	//		[[NSFileManager defaultManager] confirmDirectoryAtPath:discFinalDirPath];
			
			NSUInteger mediaCapacityBytes = [[NSUserDefaultsController sharedUserDefaultsController] mediaCapacityBytes];
			
			if (_options.includeOsirixLite)
				[DiscPublishingPatientDisc copyOsirixLiteToPath:discBaseDirPath];
			if (_options.includeAuxiliaryDir)
				[DiscPublishingPatientDisc copyContentsOfDirectory:_options.auxiliaryDirPath toPath:discBaseDirPath];
			mediaCapacityBytes -= [[NSFileManager defaultManager] sizeAtPath:discBaseDirPath];
				
			NSArray* discSeriesValues = [DiscPublishingPatientDisc selectSeriesOfSizes:seriesSizes forDiscWithCapacity:mediaCapacityBytes];
			[seriesSizes removeObjectsForKeys:discSeriesValues];
			NSMutableArray* discSeries = [NSMutableArray arrayWithCapacity:discSeriesValues.count];
			for (NSValue* serieValue in discSeriesValues)
				[discSeries addObject:(id)serieValue.pointerValue];
			
			NSString* discName = [DiscPublishingPatientDisc discNameForSeries:discSeries];
			NSString* safeDiscName = [discName filenameString];
			
			// prepare patients dictionary for html generation
			
			NSMutableDictionary* htmlExportDic = [NSMutableDictionary dictionary];
			for (DicomSeries* serie in discSeries) {
				NSMutableArray* patientSeries = [htmlExportDic objectForKey:serie.study.name];
				if (!patientSeries) {
					patientSeries = [NSMutableArray array];
					[htmlExportDic setObject:patientSeries forKey:serie.study.name];
				}
				
				for (DicomImage* image in [serie sortedImages])
					[patientSeries addObject:image.series];
			}
			
			// move DICOM files
			
			NSString* dicomDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:@"DICOM"];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDiscBaseDirPath];
			[privateFiles addObject:@"DICOM"];
			
			NSUInteger fileNumber = 0;
			for (DicomSeries* serie in discSeries)
				for (DicomImage* image in [serie sortedImages]) {
					NSString* newPath = [dicomDiscBaseDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", fileNumber++]];
					[[NSFileManager defaultManager] moveItemAtPath:image.pathString toPath:newPath error:NULL];
					image.pathString = newPath;
				}
			
			// generate DICOMDIR
			[DiscPublishingPatientDisc generateDICOMDIRAtDirectory:discBaseDirPath withDICOMFilesInDirectory:dicomDiscBaseDirPath];
			[privateFiles addObject:@"DICOMDIR"];
			
			// move QTHTML files
			
			if (_options.includeHTMLQT) {
				NSString* htmlqtDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:@"HTML"];
				[[NSFileManager defaultManager] confirmDirectoryAtPath:htmlqtDiscBaseDirPath];
				[privateFiles addObject:@"HTML"];

				for (DicomSeries* serie in discSeries) {
					NSString* serieHtmlQtBase = [[DiscPublishingPatientDisc dirPathForSeries:serie inBaseDir:_tmpPath] stringByAppendingPathComponent:@"HTMLQT"];
					// in in this series htmlqt folder, remove the html-extra folder: it will be generated later
					[[NSFileManager defaultManager] removeItemAtPath:[serieHtmlQtBase stringByAppendingPathComponent:@"html-extra"] error:NULL];
					// also remove all HTML files: they will be regenerated later, more complete
					NSDirectoryEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:serieHtmlQtBase];
					NSMutableArray* files = [NSMutableArray array];
					while (NSString* subpath = [e nextObject]) {
						NSString* completePath = [serieHtmlQtBase stringByAppendingPathComponent:subpath];
						BOOL isDir;
						if ([[NSFileManager defaultManager] fileExistsAtPath:completePath isDirectory:&isDir] && !isDir && [completePath hasSuffix:@".html"])
							[[NSFileManager defaultManager] removeItemAtPath:completePath error:NULL];
						else if (!isDir)
							[files addObject:subpath];
					}
					
					// now that the folder has been cleaned, merge its contents
						
					for (NSString* subpath in files) {
						NSString* completePath = [serieHtmlQtBase stringByAppendingPathComponent:subpath];
						NSString* subDirPath = [subpath stringByDeletingLastPathComponent];
						NSString* destinationDirPath = [htmlqtDiscBaseDirPath stringByAppendingPathComponent:subDirPath];
						[[NSFileManager defaultManager] confirmDirectoryAtPath:destinationDirPath];
						
						NSString* destinationPath = [htmlqtDiscBaseDirPath stringByAppendingPathComponent:subpath];
						// does such file already exist?
						if ([[NSFileManager defaultManager] fileExistsAtPath:destinationPath]) { // yes, change the destination name
							NSString* destinationFilename = [destinationPath lastPathComponent];
							NSString* destinationDir = [destinationPath substringToIndex:destinationPath.length-destinationFilename.length];
							NSString* destinationFilenameExt = [destinationFilename pathExtension];
							NSString* destinationFilenamePre = [destinationFilename substringToIndex:destinationFilename.length-destinationFilenameExt.length-1];
							
							for (NSUInteger i = 0; ; ++i) {
								destinationFilename = [NSString stringWithFormat:@"%@_%i.%@", destinationFilenamePre, i, destinationFilenameExt];
								destinationPath = [destinationDir stringByAppendingPathComponent:destinationFilename];
								if (![[NSFileManager defaultManager] fileExistsAtPath:destinationPath])
									break;
							}
							
							NSString* kind = [QTExportHTMLSummary kindOfPath:subpath forSeriesId:serie.id.intValue inSeriesPaths:seriesPaths];
							if (kind) {
								[BrowserController setPath:destinationPath relativeTo:htmlqtDiscBaseDirPath forSeriesId:serie.id.intValue kind:kind toSeriesPaths:seriesPaths];
								NSLog(@"renaming %@ to %@", subpath, destinationFilename);
							}
						}
						
						[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:NULL];
						[[NSFileManager defaultManager] moveItemAtPath:completePath toPath:destinationPath error:NULL];
					}
					
					[[NSFileManager defaultManager] removeItemAtPath:serieHtmlQtBase error:NULL];
				}
				
				// generate html
				
				for (NSString* k in htmlExportDic)
					NSLog(@"%@ has %d images", k, [[htmlExportDic objectForKey:k] count]);
				
				QTExportHTMLSummary* htmlExport = [[QTExportHTMLSummary alloc] init];
				[htmlExport setPatientsDictionary:htmlExportDic];
				[htmlExport setPath:htmlqtDiscBaseDirPath];
				[htmlExport setImagePathsDictionary:seriesPaths];
				[htmlExport createHTMLfiles];
				[htmlExport release];
			}
			
			if (_options.zip) {
				NSMutableArray* args = [NSMutableArray arrayWithObject:@"-r"];
				if (_options.zipEncrypt && [NSUserDefaultsController isValidDiscPublishingPassword:_options.zipEncryptPassword]) {
					[args addObject:@"-eP"];
					[args addObject:_options.zipEncryptPassword];
					[args addObject:@"encryptedDICOM.zip"];
				} else 
					[args addObject:@"DICOM.zip"];
				
				[args addObjectsFromArray:privateFiles];
				
				NSTask* zipTask = [[NSTask alloc] init];
				[zipTask setLaunchPath: @"/usr/bin/zip"];
				[zipTask setCurrentDirectoryPath:discBaseDirPath];
				[zipTask setArguments:args];
				[zipTask launch];
				[zipTask waitUntilExit]; 
				[zipTask release];
				
				for (NSString* path in [discBaseDirPath stringsByAppendingPaths:privateFiles])
					[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
			}
			
			// move data to ~/Library/Application Support/OsiriX/DiscPublishing/Discs/<safeDiscName>
			
			NSString* discsDir = [[DiscPublishing baseDirPath] stringByAppendingPathComponent:@"Discs"];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:discsDir];
			
			NSString* discDir = [discsDir stringByAppendingPathComponent:safeDiscName];
			NSUInteger i = 0;
			while ([[NSFileManager defaultManager] fileExistsAtPath:discDir])
				discDir = [discsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%d", safeDiscName, ++i]];
			[[NSFileManager defaultManager] moveItemAtPath:discBaseDirPath toPath:discDir error:NULL];
			
			// save information dict
			
			NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
			[dateFormatter setDateFormat:[[NSUserDefaults standardUserDefaults] stringForKey:@"DBDateOfBirthFormat2"]];
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
								  safeDiscName, DiscPublishingJobInfoDiscNameKey,
								  _options, DiscPublishingJobInfoOptionsKey,
								  [NSNumber numberWithUnsignedInt:[[NSUserDefaultsController sharedUserDefaultsController] mediaType]], DiscPublishingJobInfoMediaTypeKey,
								  [NSArray arrayWithObjects:
									/* 1 */	discName,
								    /* 2 */ [dateFormatter stringFromDate:[[discSeries objectAtIndex:0] study].dateOfBirth],
								    /* 3 */ [dateFormatter stringFromDate:[[discSeries objectAtIndex:0] study].date],
								    /* 4 */	[dateFormatter stringFromDate:[NSDate date]],
								   NULL], DiscPublishingJobInfoMergeValuesKey,
								  NULL];
			[self spawnDiscWrite:discDir info:info];
			
		} @catch (NSException* e) {
			NSLog(@"[DiscPublishingPatientDisc main] error: %@", e);
		}
		
		[NSThread sleepForTimeInterval:0.01];
		[pool release];
	}
	
//	NSLog(@"paths: %@", seriesPaths);
	
	[seriesPaths release];
	[seriesSizes release];
	[series release];

	[managedObjectContext release];
	[persistentStoreCoordinator release];
	[managedObjectModel release];
	
	[pool release];
}

+(NSArray*)prepareSeriesDataForImages:(NSArray*)imagesIn inDirectory:(NSString*)basePath options:(DiscBurningOptions*)options context:(NSManagedObjectContext*)managedObjectContext seriesPaths:(NSMutableDictionary*)seriesPaths {
	NSString* dirPath = [[NSFileManager defaultManager] tmpFilePathInDir:basePath];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:dirPath];
	
//	NSLog(@"dirPath is %@", dirPath);
	
	// copy files by considering anonymize
	NSString* dicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM"];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
	
//	NSLog(@"copying %d files to %@", imagesIn.count, dicomDirPath);

	NSMutableArray* fileNames = [NSMutableArray arrayWithCapacity:imagesIn.count];
	for (NSUInteger i = 0; i < imagesIn.count; ++i) {
		DicomImage* image = [imagesIn objectAtIndex:i];
		NSString* filePath = [image completePathResolved];
		NSString* toFilePath = [dicomDirPath stringByAppendingPathComponent:[filePath lastPathComponent]];
		
		if (options.anonymize)
			[DCMObject anonymizeContentsOfFile:filePath tags:options.anonymizationTags writingToFile:toFilePath];
		else [[NSFileManager defaultManager] copyPath:filePath toPath:toFilePath handler:NULL]; // TODO: handle copy errors
		
		[fileNames addObject:[toFilePath lastPathComponent]];
	}
	
//	NSLog(@"importing %d images to context", fileNames.count);

//	NSString* dbPath = [dirPath stringByAppendingPathComponent:@"OsiriX Data"];
//	[[NSFileManager defaultManager] confirmDirectoryAtPath:dbPath];
	NSArray* images = [BrowserController addFiles:[dicomDirPath stringsByAppendingPaths:fileNames] toContext:managedObjectContext onlyDICOM:YES  notifyAddedFiles:NO parseExistingObject:NO dbFolder:NULL];
	
	NSString* oldDirPath = dirPath;
	dirPath = [self dirPathForSeries:[[images objectAtIndex:0] valueForKeyPath:@"series"] inBaseDir:basePath];
//	NSLog(@"moving %@ to %@", oldDirPath, dirPath);
	[[NSFileManager defaultManager] moveItemAtPath:oldDirPath toPath:dirPath error:NULL];
	for (DicomImage* image in images)
		[image setPathString:[[image pathString] stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath]];
	dicomDirPath = [dicomDirPath stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath];
	
//	NSLog(@"decompressing");
	
	if (options.compression == CompressionDecompress || (options.compression == CompressionCompress && options.compressJPEGNotJPEG2000)) {
		NSString* beforeDicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM_before_decompression"];
		[[NSFileManager defaultManager] movePath:dicomDirPath toPath:beforeDicomDirPath handler:NULL];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
		[DicomCompressor decompressFiles:[beforeDicomDirPath stringsByAppendingPaths:fileNames] toDirectory:dicomDirPath withOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"DecompressMoveIfFail"]];
		[[NSFileManager defaultManager] removeItemAtPath:beforeDicomDirPath error:NULL];
	}
	
//	NSLog(@"compressing");

	if (options.compression == CompressionCompress) {
		NSMutableDictionary* execOptions = [NSMutableDictionary dictionary];
		[execOptions setObject:[NSNumber numberWithBool:options.compressJPEGNotJPEG2000] forKey:@"JPEGinsteadJPEG2000"];
		[execOptions setObject:[NSNumber numberWithBool:YES] forKey:@"DecompressMoveIfFail"];
		if (options.compressJPEGNotJPEG2000) {
			[execOptions setObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"default", nil), @"modality", @"2", @"compression", @"1", @"quality", nil]] forKey: @"CompressionSettings"];
			[execOptions setObject:@"1" forKey:@"CompressionResolutionLimit"];
		}
		
		NSString* beforeDicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM_before_compression"];
		[[NSFileManager defaultManager] movePath:dicomDirPath toPath:beforeDicomDirPath handler:NULL];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
		[DicomCompressor compressFiles:[beforeDicomDirPath stringsByAppendingPaths:fileNames] toDirectory:dicomDirPath withOptions:execOptions];
		[[NSFileManager defaultManager] removeItemAtPath:beforeDicomDirPath error:NULL];
	}
	
	[DiscPublishingPatientDisc generateDICOMDIRAtDirectory:dirPath withDICOMFilesInDirectory:dicomDirPath];
	
//	NSLog(@"generating QTHTML");

	if (options.includeHTMLQT) {
		NSString* htmlqtTmpPath = [dirPath stringByAppendingPathComponent:@"HTMLQT"];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:htmlqtTmpPath];
		NSArray* sortedImages = [images sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]]];
		[BrowserController exportQuicktime:sortedImages:htmlqtTmpPath:YES:NULL:seriesPaths];
	}
	
//	NSLog(@"done");

	return images;
}

@end

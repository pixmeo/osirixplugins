//
//  DiscPublishingPatientDisc.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPatientDisc.h"
#import "DiscPublishingOptions.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscPublisher.h"
#import "DiscPublisher+Constants.h"
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/DicomCompressor.h>
#import <OsiriXAPI/QTExportHTMLSummary.h>
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/AppController.h>
#import <OsiriX/DCMObject.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <JobManager/PTJobManager.h>
#import <QTKit/QTKit.h>
#import "DiscPublishing.h"
#import "DiscPublishingJob+Info.h"
#import "DiscPublishingTasksManager.h"
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/N2Debug.h>


static NSString* PreventNullString(NSString* s) {
	return s? s : @"";
}


@implementation DiscPublishingPatientDisc

-(id)initWithFiles:(NSArray*)files options:(DiscPublishingOptions*)options {
	self = [super init];
	self.name = [NSString stringWithFormat:@"Preparing disc data for %@", [[files objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
	
	_files = [[NSMutableArray alloc] initWithArray:files];
	_options = [options retain];

	_tmpPath = [[[NSFileManager defaultManager] tmpFilePathInDir:@"/tmp"] retain];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:_tmpPath];
	
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

+(NSArray*)selectSeriesOfSizes:(NSDictionary*)seriesSizes forDiscWithCapacity:(CGFloat)mediaCapacity {
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

+(NSString*)dicomDirName {
	NSDictionary* info = [[NSBundle bundleForClass:[self class]] infoDictionary];
	
	NSString* dicomDirName = [info objectForKey:@"DicomDirectoryName"];
	if ([dicomDirName isKindOfClass:[NSString class]] && dicomDirName.length)
		return dicomDirName;
	
	return @"DICOM";
}

+(void)copyOsirixLiteToPath:(NSString*)path {
	NSTask* unzipTask = [[NSTask alloc] init];
	[unzipTask setLaunchPath: @"/usr/bin/unzip"];
	[unzipTask setCurrentDirectoryPath:path];
	[unzipTask setArguments:[NSArray arrayWithObjects: @"-o", [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"OsiriX Launcher.zip"], NULL]];
	[unzipTask launch];
	[unzipTask waitUntilExit];
	[unzipTask release];
}

+(void)copyContentsOfDirectory:(NSString*)auxDir toPath:(NSString*)path {
	for (NSString* subpath in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:auxDir error:NULL])
		[[NSFileManager defaultManager] copyItemAtPath:[auxDir stringByAppendingPathComponent:subpath] toPath:[path stringByAppendingPathComponent:subpath] error:NULL];
}

+(void)copyWeasisToPath:(NSString*)path {
	if ([[AppController sharedAppController] respondsToSelector:@selector(weasisBasePath)])
		[self copyContentsOfDirectory:[[AppController sharedAppController] weasisBasePath] toPath:path];
	else NSLog(@"Warning: attempt to copy weasis on OsiriX prior to version 3.9");
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

+(void)generateDICOMDIRAtDirectory:(NSString*)root withDICOMFilesInDirectory:(NSString*)dicomPath {
/*	if ([dicomPath hasPrefix:root]) {
		NSUInteger index = root.length;
		if ([dicomPath characterAtIndex:index] == '/')
			++index;
		dicomPath = [dicomPath substringFromIndex:index];
	}*/
	
	NSTask* dcmmkdirTask = [[NSTask alloc] init];
	[dcmmkdirTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dicom.dic"] forKey:@"DCMDICTPATH"]];
	[dcmmkdirTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"dcmmkdir"]];
	[dcmmkdirTask setCurrentDirectoryPath:root];
	[dcmmkdirTask setArguments:[NSArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc", @"+I", @"+m", @"+id", dicomPath, NULL]];		
	[dcmmkdirTask launch];
	[dcmmkdirTask waitUntilExit];
	[dcmmkdirTask release];
}

-(void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	// [[ThreadsManager defaultManager] addThreadAndStart:self];
	
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:[[NSUserDefaultsController sharedUserDefaultsController] stringForKey:@"DBDateOfBirthFormat2"]];

	self.status = @"Detecting image series and studies...";
	NSMutableArray* series = [[NSMutableArray alloc] init];
	NSMutableArray* studies = [[NSMutableArray alloc] init];
	for (DicomImage* image in _files) {
		if (![series containsObject:image.series])
			[series addObject:image.series];
		if (![studies containsObject:image.series.study])
			[studies addObject:image.series.study];
	}
	
    DicomDatabase* database = [DicomDatabase databaseAtPath:[[NSFileManager defaultManager] tmpFilePathInTmp]];
    
/*	NSManagedObjectModel* managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/OsiriXDB_DataModel.mom"]]];
	NSPersistentStoreCoordinator* persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	[persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:NULL URL:NULL options:NULL error:NULL];
    NSManagedObjectContext* managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
	managedObjectContext.undoManager.levelsOfUndo = 1;	
	[managedObjectContext.undoManager disableUndoRegistration];*/
	
	NSMutableDictionary* seriesSizes = [[NSMutableDictionary alloc] initWithCapacity:series.count];
	NSMutableDictionary* seriesPaths = [[NSMutableDictionary alloc] initWithCapacity:series.count];
	NSUInteger processedImagesCount = 0;
	for (DicomSeries* serie in series)
	{
		@try
		{
			self.status = [NSString stringWithFormat:@"Preparing data for series %@...", serie.name];

			NSArray* images = [self imagesBelongingToSeries:serie];
			[self enterSubthreadWithRange:1.*processedImagesCount/_files.count:1.*images.count/_files.count];
			images = [DiscPublishingPatientDisc prepareSeriesDataForImages:images inDirectory:_tmpPath options:_options database:database seriesPaths:seriesPaths];
			
			if (images.count) {
				serie = [(DicomImage*)[images objectAtIndex:0] series];
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

				processedImagesCount += images.count;
			}
			
			[self exitSubthread];
		}
		@catch (NSException* e) {
			N2LogExceptionWithStackTrace(e);
		}
	}
	
	NSString* reportsTmpPath = [_tmpPath stringByAppendingPathComponent:@"Reports"];
	if (_options.includeReports)
	{
		[[NSFileManager defaultManager] confirmDirectoryAtPath:reportsTmpPath];
		
		for (DicomStudy* study in studies)
		{
			if (study.reportURL)
			{
				if( [study.reportURL hasPrefix: @"http://"] || [study.reportURL hasPrefix: @"https://"])
				{
					NSStringEncoding se = NULL;
					NSString *urlContent = [NSString stringWithContentsOfURL:[NSURL URLWithString:study.reportURL] usedEncoding:&se error:NULL];
					[urlContent writeToFile: [reportsTmpPath stringByAppendingPathComponent:[study.reportURL lastPathComponent]] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
				}
				else
					[[NSFileManager defaultManager] copyItemAtPath:study.reportURL toPath:[reportsTmpPath stringByAppendingPathComponent:[study.reportURL lastPathComponent]] error:NULL];
			}
		}
	}
	
//	DLog(@"paths: %@", seriesPaths);

	NSUInteger discNumber = 1;
	while (seriesSizes.count) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		
		self.status = [NSString stringWithFormat:@"Preparing data for disc %d...", discNumber];
		
		@try {
			NSMutableArray* privateFiles = [NSMutableArray array];

			NSString* discBaseDirPath = [[NSFileManager defaultManager] tmpFilePathInTmp];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:discBaseDirPath];
	//		NSString* discBaseDirPath = [discTmpDirPath stringByAppendingPathComponent:@"DATA"];
	//		[[NSFileManager defaultManager] confirmDirectoryAtPath:discBaseDirPath];
	//		NSString* discFinalDirPath = [discTmpDirPath stringByAppendingPathComponent:@"FINAL"];
	//		[[NSFileManager defaultManager] confirmDirectoryAtPath:discFinalDirPath];
			
			NSDictionary* mediaCapacitiesBytes = [[NSUserDefaultsController sharedUserDefaultsController] discPublishingMediaCapacities];
		//	NSLog(@"----- mcb %@", mediaCapacitiesBytes);
			
			if ([_options respondsToSelector:@selector(includeWeasis)] && _options.includeWeasis)
				[DiscPublishingPatientDisc copyWeasisToPath:discBaseDirPath];
			if (_options.includeOsirixLite)
				[DiscPublishingPatientDisc copyOsirixLiteToPath:discBaseDirPath];
			if (_options.includeAuxiliaryDir)
				[DiscPublishingPatientDisc copyContentsOfDirectory:_options.auxiliaryDirPath toPath:discBaseDirPath];
			if (_options.includeReports) {
				NSString* reportsDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:@"Reports"];
				[privateFiles addObject:@"Reports"];
				[[NSFileManager defaultManager] copyItemAtPath:reportsTmpPath toPath:reportsDiscBaseDirPath error:NULL];
			}
			
			NSUInteger tempSizeAtDiscBaseDir = [[NSFileManager defaultManager] sizeAtPath:discBaseDirPath];
			NSMutableDictionary* mediaCapacitiesBytesTemp = [NSMutableDictionary dictionaryWithCapacity:mediaCapacitiesBytes.count];
			for (id key in mediaCapacitiesBytes)
				[mediaCapacitiesBytesTemp setObject:[NSNumber numberWithFloat:[[mediaCapacitiesBytes objectForKey:key] floatValue]-tempSizeAtDiscBaseDir] forKey:key];
			mediaCapacitiesBytes = mediaCapacitiesBytesTemp;
		//	NSLog(@"----- mcb %@", mediaCapacitiesBytes);
			
			// mediaCapacitiesBytes contains one or more disc capacities and seriesSizes contains the series still needing to be burnt
			// what disc type between these in mediaCapacitiesBytes will we use?
			NSUInteger totalSeriesSizes = 0;
			for (id serie in seriesSizes)
				totalSeriesSizes += [[seriesSizes objectForKey:serie] unsignedIntValue];
			id pickedMediaKey = nil;
			// try pick the smallest that fits the data
			//NSLog(@"----- Picking media... totalSeriesSizes is %d", totalSeriesSizes);
			for (id key in mediaCapacitiesBytes) {
			//	NSLog(@"Will it be %@ sized %f ?", key, [[mediaCapacitiesBytes objectForKey:key] floatValue]);
				if ([[mediaCapacitiesBytes objectForKey:key] floatValue] > totalSeriesSizes) { // fits
			//		NSLog(@"\tIt may be...");
					if (!pickedMediaKey || [[mediaCapacitiesBytes objectForKey:key] floatValue] < [[mediaCapacitiesBytes objectForKey:pickedMediaKey] floatValue]) { // forst OR is smaller than the one we picked earlier
			//			NSLog(@"\tIt really may be...");
						pickedMediaKey = key;
					}
				}
			}
			//NSLog(@"Picked media key %@", pickedMediaKey);
			if (!pickedMediaKey) // data won't fit a single disc, pick the biggest of discs available
				for (id key in mediaCapacitiesBytes)
					if (!pickedMediaKey || [[mediaCapacitiesBytes objectForKey:key] floatValue] > [[mediaCapacitiesBytes objectForKey:pickedMediaKey] floatValue]) // forst OR is bigger than the one we picked earlier
						pickedMediaKey = key;
			
			DLog(@"media type will be: %@", pickedMediaKey);
			
			NSArray* discSeriesValues = [DiscPublishingPatientDisc selectSeriesOfSizes:seriesSizes forDiscWithCapacity:[[mediaCapacitiesBytes objectForKey:pickedMediaKey] floatValue]];
			[seriesSizes removeObjectsForKeys:discSeriesValues];
			NSMutableArray* discSeries = [NSMutableArray arrayWithCapacity:discSeriesValues.count];
			for (NSValue* serieValue in discSeriesValues)
				[discSeries addObject:(id)serieValue.pointerValue];
			
			NSString* discName = [DiscPublishingPatientDisc discNameForSeries:discSeries];
			NSString* safeDiscName = [discName filenameString];
			
			NSMutableArray* discModalities = [NSMutableArray array];
			for (DicomSeries* serie in discSeries)
				if (![discModalities containsObject:serie.modality])
					[discModalities addObject:serie.modality];
			NSString* modalities = [discModalities componentsJoinedByString:@", "];
			
			NSMutableArray* discStudyNames = [NSMutableArray array];
			for (DicomSeries* serie in discSeries)
				if (![discStudyNames containsObject:serie.study.studyName])
					[discStudyNames addObject:serie.study.studyName];
			NSString* studyNames = [discStudyNames componentsJoinedByString:@", "];
			
			NSMutableArray* discStudyDates = [NSMutableArray array];
			for (DicomSeries* serie in discSeries) {
				NSString* date = [dateFormatter stringFromDate:serie.study.date];
				if (![discStudyDates containsObject:date])
					[discStudyDates addObject:date];
			}
			NSString* studyDates = [discStudyDates componentsJoinedByString:@", "];			
			
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
			
			NSString* dicomDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:[DiscPublishingPatientDisc dicomDirName]];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDiscBaseDirPath];
			[privateFiles addObject:[DiscPublishingPatientDisc dicomDirName]];
			
			NSUInteger fileNumber = 0;
			for (DicomSeries* serie in discSeries)
				for (DicomImage* image in [serie sortedImages]) {
					NSString* newPath = [dicomDiscBaseDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", fileNumber++]];
					[[NSFileManager defaultManager] moveItemAtPath:image.pathString toPath:newPath error:NULL];
					image.pathString = newPath;
				}
			
			// generate DICOMDIR
			[DiscPublishingPatientDisc generateDICOMDIRAtDirectory:discBaseDirPath withDICOMFilesInDirectory:discBaseDirPath];
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
								DLog(@"renaming %@ to %@", subpath, destinationFilename);
							}
						}
						
						[[NSFileManager defaultManager] removeItemAtPath:destinationPath error:NULL];
						[[NSFileManager defaultManager] moveItemAtPath:completePath toPath:destinationPath error:NULL];
					}
					
					[[NSFileManager defaultManager] removeItemAtPath:serieHtmlQtBase error:NULL];
				}
				
				// generate html
				
//				for (NSString* k in htmlExportDic)
//					NSLog(@"%@ has %d images", k, [[htmlExportDic objectForKey:k] count]);
				
				QTExportHTMLSummary* htmlExport = [[QTExportHTMLSummary alloc] init];
				[htmlExport setPatientsDictionary:htmlExportDic];
				[htmlExport setPath:htmlqtDiscBaseDirPath];
				[htmlExport setImagePathsDictionary:seriesPaths];
				[htmlExport createHTMLfiles];
				[htmlExport release];
			}
			
			if (_options.zip) {
				NSMutableArray* args = [NSMutableArray arrayWithObject:@"-r"];
				if (_options.zipEncrypt && [NSUserDefaultsController discPublishingIsValidPassword:_options.zipEncryptPassword]) {
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
			
			NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
								  safeDiscName, DiscPublishingJobInfoDiscNameKey,
			  //				  _options, DiscPublishingJobInfoOptionsKey,
								  _options.discCoverTemplatePath, DiscPublishingJobInfoTemplatePathKey,
								  pickedMediaKey, DiscPublishingJobInfoMediaTypeKey,
								  [[NSUserDefaultsController sharedUserDefaultsController] valueForValuesKey:DiscPublishingBurnSpeedDefaultsKey], DiscPublishingJobInfoBurnSpeedKey,
								  [NSArray arrayWithObjects:
									/* 1 */	PreventNullString(discName),
								    /* 2 */ PreventNullString([dateFormatter stringFromDate:[[discSeries objectAtIndex:0] study].dateOfBirth]),
								    /* 3 */	PreventNullString(studyNames),
								    /* 4 */	PreventNullString(modalities),
								    /* 5 */ PreventNullString(studyDates),
								    /* 6 */	PreventNullString([dateFormatter stringFromDate:[NSDate date]]),
								   NULL], DiscPublishingJobInfoMergeValuesKey,
								  NULL];
			[[DiscPublishingTasksManager defaultManager] spawnDiscWrite:discDir info:info];
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
	[studies release];

/*	[managedObjectContext release];
	[persistentStoreCoordinator release];
	[managedObjectModel release];*/
	
	[pool release];
}

+(NSArray*)prepareSeriesDataForImages:(NSArray*)imagesIn inDirectory:(NSString*)basePath options:(DiscBurningOptions*)options database:(DicomDatabase*)database seriesPaths:(NSMutableDictionary*)seriesPaths
{
	NSThread* currentThread = [NSThread currentThread];
	NSString* baseStatus = currentThread.status;
//	CGFloat baseProgress = currentThread.progress;
	
	NSString* dirPath = [[NSFileManager defaultManager] tmpFilePathInDir:basePath];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:dirPath];
	
	DLog(@"dirPath is %@", dirPath);
	
	// copy files by considering anonymize
	NSString* dicomDirPath = [dirPath stringByAppendingPathComponent:[DiscPublishingPatientDisc dicomDirName]];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
	
	DLog(@"copying %d files to %@", imagesIn.count, dicomDirPath);
	
	currentThread.status = [baseStatus stringByAppendingFormat:@" %@", options.anonymize? NSLocalizedString(@"Anonymizing files...", NULL) : NSLocalizedString(@"Copying files...", NULL) ];
	NSMutableArray* fileNames = [NSMutableArray arrayWithCapacity:imagesIn.count];
	NSMutableArray* originalCopiedFiles = [NSMutableArray array]; // to avoid double copies (multiframe dicom)
	[currentThread enterSubthreadWithRange:0:0.5];
	for (NSUInteger i = 0; i < imagesIn.count; ++i)
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		currentThread.progress = CGFloat(i)/imagesIn.count;
		
		DicomImage* image = [imagesIn objectAtIndex:i];
		NSString* filePath = [image completePathResolved];
		
		if (![originalCopiedFiles containsObject:filePath])
		{
			[originalCopiedFiles addObject:filePath];
		
			if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
			{
				NSLog(@"Warning: file unavailable at path %@", filePath);
				goto continueFor;
			}
			
			NSString* filename = [NSString stringWithFormat:@"%d", i];
			NSString* toFilePath = [dicomDirPath stringByAppendingPathComponent:filename];
			
			if (options.anonymize)
			{
				@try
				{
					[DCMObject anonymizeContentsOfFile:filePath tags:options.anonymizationTags writingToFile:toFilePath];
				}
				@catch (NSException * e)
				{
					NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
				}
			}
			else [[NSFileManager defaultManager] copyItemAtPath:filePath toPath:toFilePath error:NULL]; // TODO: handle copy errors
			
			[fileNames addObject:filename];
		}
		
		continueFor:
		
		[pool release];
	}
	
	currentThread.status = baseStatus;
	[currentThread exitSubthread];

	if (!fileNames.count)
		return fileNames;
	
	[currentThread enterSubthreadWithRange:0.5:0.5];
	currentThread.status = [baseStatus stringByAppendingFormat:@" %@", NSLocalizedString(@"Importing files...", NULL)];
	DLog(@"importing %d images to context", fileNames.count);
	
//	NSString* dbPath = [dirPath stringByAppendingPathComponent:@"OsiriX Data"];
//	[[NSFileManager defaultManager] confirmDirectoryAtPath:dbPath];
	NSMutableArray* images = [[[database addFilesAtPaths:[dicomDirPath stringsByAppendingPaths:fileNames] postNotifications:NO dicomOnly:YES rereadExistingItems:NO] mutableCopy] autorelease];
	for (NSInteger i = images.count-1; i >= 0; --i)
		if (![[images objectAtIndex:i] pathString] || ![[[images objectAtIndex:i] pathString] hasPrefix:dirPath])
			[images removeObjectAtIndex:i];
	
	DLog(@"    %d files to %d images", fileNames.count, images.count);
	
	if (!images.count)
		return images;
	
	NSString* oldDirPath = dirPath;
	dirPath = [self dirPathForSeries:[[images objectAtIndex:0] valueForKeyPath:@"series"] inBaseDir:basePath];
	DLog(@"moving %@ to %@", oldDirPath, dirPath);
	[[NSFileManager defaultManager] moveItemAtPath:oldDirPath toPath:dirPath error:NULL];
	for (DicomImage* image in images)
		[image setPathString:[[image pathString] stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath]];
	dicomDirPath = [dicomDirPath stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath];
	
	DLog(@"decompressing");
	
	currentThread.progress = 0.3;
	if (options.compression == CompressionDecompress || (options.compression == CompressionCompress && options.compressJPEGNotJPEG2000)) {
		currentThread.status = [baseStatus stringByAppendingFormat:@" %@", NSLocalizedString(@"Decompressing files...", NULL)];
		NSString* beforeDicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM_before_decompression"];
		[[NSFileManager defaultManager] moveItemAtPath:dicomDirPath toPath:beforeDicomDirPath error:NULL];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
		[DicomCompressor decompressFiles:[beforeDicomDirPath stringsByAppendingPaths:fileNames] toDirectory:dicomDirPath withOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"DecompressMoveIfFail"]];
		[[NSFileManager defaultManager] removeItemAtPath:beforeDicomDirPath error:NULL];
	}
	
	DLog(@"compressing");

	currentThread.progress = 0.4;
	if (options.compression == CompressionCompress) {
		currentThread.status = [baseStatus stringByAppendingFormat:@" %@", NSLocalizedString(@"Compressing files...", NULL)];
		NSMutableDictionary* execOptions = [NSMutableDictionary dictionary];
		[execOptions setObject:[NSNumber numberWithBool:options.compressJPEGNotJPEG2000] forKey:@"JPEGinsteadJPEG2000"];
		[execOptions setObject:[NSNumber numberWithBool:YES] forKey:@"DecompressMoveIfFail"];
		if (options.compressJPEGNotJPEG2000) {
			[execOptions setObject:[NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys: NSLocalizedString(@"default", nil), @"modality", @"2", @"compression", @"1", @"quality", nil]] forKey: @"CompressionSettings"];
			[execOptions setObject:@"1" forKey:@"CompressionResolutionLimit"];
		}
		
		NSString* beforeDicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM_before_compression"];
		[[NSFileManager defaultManager] moveItemAtPath:dicomDirPath toPath:beforeDicomDirPath error:NULL];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
		[DicomCompressor compressFiles:[beforeDicomDirPath stringsByAppendingPaths:fileNames] toDirectory:dicomDirPath withOptions:execOptions];
		[[NSFileManager defaultManager] removeItemAtPath:beforeDicomDirPath error:NULL];
	}
	
	[DiscPublishingPatientDisc generateDICOMDIRAtDirectory:dirPath withDICOMFilesInDirectory:dicomDirPath];
	
	DLog(@"generating QTHTML");

	currentThread.progress = 0.7;
	if (options.includeHTMLQT) {
		currentThread.status = [baseStatus stringByAppendingFormat:@" %@", NSLocalizedString(@"Generating HTML/Quicktime files...", NULL)];
		NSString* htmlqtTmpPath = [dirPath stringByAppendingPathComponent:@"HTMLQT"];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:htmlqtTmpPath];
		NSArray* sortedImages = [images sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]]];
		[BrowserController exportQuicktime :sortedImages :htmlqtTmpPath :YES :NULL :seriesPaths];
	}
	
	DLog(@"done");
	[currentThread exitSubthread];
	currentThread.status = baseStatus;
	
	return images;
}

@end

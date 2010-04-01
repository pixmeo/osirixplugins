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
#import "DiscPublishingUserDefaultsController.h"
#import "ThreadsManager.h"
#import "NSFileManager+DiscPublisher.h"
#import "DicomCompressor.h"
#import <OsiriX Headers/QTExportHTMLSummary.h>
#import <OsiriX Headers/DicomSeries.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX Headers/DicomImage.h>
#import <OsiriX Headers/BrowserController.h>
#import <JobManager/PTJobManager.h>
#import <QTKit/QTKit.h>

#include <iostream>


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
		if ([[image valueForKeyPath:@"series.seriesDICOMUID"] isEqual: [series valueForKeyPath:@"seriesDICOMUID"]])
			[ret addObject:image];
	
	return [ret autorelease];
}

+(NSArray*)selectSeries:(NSDictionary*)seriesSizes forDiscWithCapacity:(NSUInteger)mediaCapacity {
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
	// TODO: this
}

+(void)copyContentsOfDirectory:(NSString*)auxDir toPath:(NSString*)path {
	// TODO: this
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
	
	NSLog(@"paths: %@", seriesPaths);

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
			NSString* discBaseDirPath = [[NSFileManager defaultManager] tmpFilePathInTmp];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:discBaseDirPath];
			
			NSUInteger mediaCapacityBytes = 0;
			switch ([DiscPublishingUserDefaultsController sharedUserDefaultsController].media) {
				case DISCTYPE_CD: mediaCapacityBytes = 700; break;
				case DISCTYPE_DVD: mediaCapacityBytes = 4700; break;
				case DISCTYPE_DVDDL: mediaCapacityBytes = 8500; break;
				case DISCTYPE_BR: mediaCapacityBytes = 25000; break;
				case DISCTYPE_BR_DL: mediaCapacityBytes = 50000; break;
			} mediaCapacityBytes *= 1000000;
			
			if (_options.includeOsirixLite)
				[DiscPublishingPatientDisc copyOsirixLiteToPath:discBaseDirPath];
				
			if (_options.includeAuxiliaryDir)
				[DiscPublishingPatientDisc copyContentsOfDirectory:_options.auxiliaryDirPath toPath:discBaseDirPath];
			
			mediaCapacityBytes -= [[NSFileManager defaultManager] sizeAtPath:discBaseDirPath];
				
			NSArray* discSeriesValues = [DiscPublishingPatientDisc selectSeries:seriesSizes forDiscWithCapacity:mediaCapacityBytes];
			[seriesSizes removeObjectsForKeys:discSeriesValues];
			
			// prepare patients dictionary for html generation
			
			NSMutableDictionary* htmlExportDic = [NSMutableDictionary dictionary];
			for (NSValue* serieValue in discSeriesValues) {
				DicomSeries* serie = (id)[serieValue pointerValue];
				NSString* patient = [serie valueForKeyPath:@"study.name"];
	
				NSMutableArray* patientSeries = [htmlExportDic objectForKey:patient];
				if (!patientSeries) {
					patientSeries = [NSMutableArray array];
					[htmlExportDic setObject:patientSeries forKey:patient];
				}
				
				for (DicomImage* image in [serie sortedImages])
					[patientSeries addObject:[image valueForKeyPath:@"series"]];
			}
			
			// move DICOM files
			
			NSString* dicomDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:@"DICOM"];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDiscBaseDirPath];
			
			for (NSValue* serieValue in discSeriesValues)
				[[NSFileManager defaultManager] movePath:[[DiscPublishingPatientDisc dirPathForSeries:(id)[serieValue pointerValue] inBaseDir:_tmpPath] stringByAppendingPathComponent:@"DICOM"] toPath:[DiscPublishingPatientDisc dirPathForSeries:(id)[serieValue pointerValue] inBaseDir:dicomDiscBaseDirPath] handler:NULL];
			
			// move QTHTML files
			
			NSString* htmlqtDiscBaseDirPath = [discBaseDirPath stringByAppendingPathComponent:@"HTMLQT"];
			[[NSFileManager defaultManager] confirmDirectoryAtPath:htmlqtDiscBaseDirPath];

			for (NSValue* serieValue in discSeriesValues) {
				DicomSeries* serie = (id)[serieValue pointerValue];
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
						
						NSString* kind = [QTExportHTMLSummary kindOfPath:subpath forSeriesId:[[serie valueForKeyPath:@"id"] intValue] inSeriesPaths:seriesPaths];
						if (kind) {
							[BrowserController setPath:destinationPath relativeTo:htmlqtDiscBaseDirPath forSeriesId:[[serie valueForKeyPath:@"id"] intValue] kind:kind toSeriesPaths:seriesPaths];
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
			
			//TODO: consider zipEncrypt, passw, ..
 
 
 
		} @catch (NSException* e) {
			NSLog(@"[DiscPublishingPatientBurn main] error: %@", e);
		}
		
		[NSThread sleepForTimeInterval:0.01];
		[pool release];
	}
	
	NSLog(@"paths: %@", seriesPaths);
	
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
	
	NSLog(@"dirPath is %@", dirPath);
	
	// copy files by considering anonymize
	NSString* dicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM"];
	[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
	
	NSLog(@"copying %d files to %@", imagesIn.count, dicomDirPath);

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
	
	NSLog(@"importing %d images to context", fileNames.count);

//	NSString* dbPath = [dirPath stringByAppendingPathComponent:@"OsiriX Data"];
//	[[NSFileManager defaultManager] confirmDirectoryAtPath:dbPath];
	NSArray* images = [BrowserController addFiles:[dicomDirPath stringsByAppendingPaths:fileNames] toContext:managedObjectContext onlyDICOM:YES safeRebuild:NO notifyAddedFiles:NO parseExistingObject:NO dbFolder:NULL];
	
	NSString* oldDirPath = dirPath;
	dirPath = [self dirPathForSeries:[[images objectAtIndex:0] valueForKeyPath:@"series"] inBaseDir:basePath];
	NSLog(@"moving %@ to %@", oldDirPath, dirPath);
	[[NSFileManager defaultManager] moveItemAtPath:oldDirPath toPath:dirPath error:NULL];
	for (DicomImage* image in images)
		[image setPathString:[[image pathString] stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath]];
	dicomDirPath = [dicomDirPath stringByReplacingCharactersInRange:NSMakeRange(0, [oldDirPath length]) withString:dirPath];
	
	NSLog(@"decompressing");
	
	if (options.compression == CompressionDecompress || (options.compression == CompressionCompress && options.compressJPEGNotJPEG2000)) {
		NSString* beforeDicomDirPath = [dirPath stringByAppendingPathComponent:@"DICOM_before_decompression"];
		[[NSFileManager defaultManager] movePath:dicomDirPath toPath:beforeDicomDirPath handler:NULL];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:dicomDirPath];
		[DicomCompressor decompressFiles:[beforeDicomDirPath stringsByAppendingPaths:fileNames] toDirectory:dicomDirPath withOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"DecompressMoveIfFail"]];
		[[NSFileManager defaultManager] removeItemAtPath:beforeDicomDirPath error:NULL];
	}
	
	NSLog(@"compressing");

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
	
	NSLog(@"generating QTHTML");

	if (options.includeHTMLQT) {
		NSString* htmlqtTmpPath = [dirPath stringByAppendingPathComponent:@"HTMLQT"];
		[[NSFileManager defaultManager] confirmDirectoryAtPath:htmlqtTmpPath];
		NSArray* sortedImages = [images sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"instanceNumber" ascending:YES] autorelease]]];
		[BrowserController exportQuicktime:sortedImages:htmlqtTmpPath:YES:NULL:seriesPaths];
	}
	
	NSLog(@"done");

	return images;
}

@end

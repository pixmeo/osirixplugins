//
//  DMGSFilter.m
//  DMGS
//
//  Copyright (c) 2009 jacques.fauquex@opendicom.com All rights reserved.
//

#import "DMGSFilter.h"
#import "browserController.h"
#import "MutableArrayCategory.h"

static NSFileManager *fileManager;
static NSString      *DMGS;

@implementation DMGSFilter

- (void) initPlugin
{
	fileManager = [[NSFileManager defaultManager]retain];	
	DMGS = [[[NSBundle bundleForClass:[self class]]objectForInfoDictionaryKey:@"DMGS"]retain];
	if (![fileManager fileExistsAtPath:DMGS])
	{
		if([fileManager createDirectoryAtPath:DMGS withIntermediateDirectories:NO attributes:nil error:NULL]) NSLog(@"DMGS -> folder DMGS created into OsiriX Folder");
	}
	
	NSLog([NSString stringWithFormat:@"DMGS -> INIT homeFolder=%@",DMGS]);
}

- (void)dealloc {NSLog(@"DMGS -> dealloc"); [super dealloc];}


//-------------------------------------------------------------


- (long) filterImage:(NSString*) menuName
{
	//copied from [browserController burnDICOM:]
	NSMutableArray *managedObjects = [NSMutableArray array];
	//from fileList
	NSMutableArray *filesToBurn = [[BrowserController currentBrowser] filesForDatabaseOutlineSelection:managedObjects onlyImages:NO];
	//from left icons  if( [sender isKindOfClass:[NSMenuItem class]] && [sender menu] == [oMatrix menu])
	//NSMutableArray *filesToBurn = [[BrowserController currentBrowser] filesForDatabaseMatrixSelection:managedObjects onlyImages:NO];	
	[filesToBurn removeDuplicatedStringsInSyncWithThisArray: managedObjects];
	
	[managedObjects retain];
	[filesToBurn retain];
	
	//DMG tasklist
	NSMutableArray *dmgTaskList = [NSMutableArray arrayWithCapacity:31]; 
	
	//classify by study UID
	NSInteger i;
	for (i=0; i < [managedObjects count]; i++)
	{
		//create folder date?
		NSString *studyDate = [[[managedObjects objectAtIndex:i] valueForKeyPath:@"series.study.date"] descriptionWithCalendarFormat:@"%Y-%m-%d" timeZone:nil locale:nil];
		NSString *dateFolder = [DMGS stringByAppendingPathComponent:studyDate];
			
		//create folder date/studyUID?
		NSString *studyUID = [[managedObjects objectAtIndex:i] valueForKeyPath:@"series.study.studyInstanceUID"];
		NSString *dateStudyUIDFolder = [dateFolder stringByAppendingPathComponent:studyUID];
		
		//folder not yet in dmgTaskList?
		if ([dmgTaskList indexOfObject:dateStudyUIDFolder] == NSNotFound) [dmgTaskList addObject:dateStudyUIDFolder];
		
		//create folder date/studyUID/DICOM/seriesID?
		NSInteger seriesID = [[[managedObjects objectAtIndex:i] valueForKeyPath:@"series.id"]integerValue];
		if (seriesID < 0) seriesID = -seriesID * 1000;
		
		NSString *dateStudyUIDDICOMSeriesIDFolder = [NSString stringWithFormat:@"%@/DICOM/%d", dateStudyUIDFolder, seriesID];
		if (![fileManager fileExistsAtPath:dateStudyUIDDICOMSeriesIDFolder])
		{
			if([fileManager createDirectoryAtPath:dateStudyUIDDICOMSeriesIDFolder withIntermediateDirectories:YES attributes:nil error:NULL]) NSLog(dateStudyUIDDICOMSeriesIDFolder);
		}
		
		//copy file
		NSString *fileName = [NSString stringWithFormat:@"%d",[[fileManager contentsOfDirectoryAtPath:dateStudyUIDDICOMSeriesIDFolder error:NULL]count]];
		if (![fileManager copyItemAtPath:[filesToBurn objectAtIndex:i] toPath:[dateStudyUIDDICOMSeriesIDFolder stringByAppendingPathComponent:fileName] error:NULL]) NSLog([NSString stringWithFormat:@"DMGS -> couldn't link to %@",[filesToBurn objectAtIndex:i]]);
	}
	
	//start new threads with each of the studyUID folders
	for (i=0; i < [dmgTaskList count]; i++)
	{
		[NSThread detachNewThreadSelector:@selector(performBurn:) toTarget:self withObject:[dmgTaskList objectAtIndex:i]];		
	}
	NSLog([NSString stringWithFormat:@"DMGS -> detached %d threads", [dmgTaskList count]]);

	[managedObjects release];
	[filesToBurn release];

	return 0;
}

- (void)performBurn: (id) object
{	
	//The detached thread is exited (using the exit class method) as soon as aTarget has completed executing the aSelector method.	
	//autorealeasePool made necesary because of NSThread detachNewThread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	//----------------------------------
	//BurnerWindowController addDicomdir
	//----------------------------------
	
	//receiving path to DMGS/date/studyUID folder
	//This folder contains DICOM/(positive)seriesID/dicomFile
 
	NS_DURING
	
	//---------------------
	//addDICOMDIRUsingDCMTK
	//---------------------
				
	NSTask *theTask;
	NSMutableArray *theArguments = [NSMutableArray arrayWithObjects:@"+r", @"-Pfl", @"-W", @"-Nxc",@"+I",@"+id", object,  nil];
	theTask = [[NSTask alloc] init];
	[theTask setEnvironment:[NSDictionary dictionaryWithObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dicom.dic"] forKey:@"DCMDICTPATH"]];
	[theTask setLaunchPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/dcmmkdir"]];
	[theTask setCurrentDirectoryPath:object];
	[theTask setArguments:theArguments];		
		
	[theTask launch];
    while( [theTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
    [theTask interrupt];
	[theTask release];

	NS_HANDLER
	NSLog(@"Exception while creating DICOMDIR %@: %@", object, [localException name]);
	NS_ENDHANDLER
	
	//----------
	//create DMG
	//----------
	
	NSTask* makeImageTask = [[[NSTask alloc]init]autorelease];		
	[makeImageTask setLaunchPath: @"/bin/sh"];		
	[makeImageTask setArguments:[NSArray arrayWithObjects: @"-c", [NSString stringWithFormat: @"hdiutil create '%@' -srcfolder '%@'", [object stringByAppendingPathExtension:@"dmg"], object], nil]];
	[makeImageTask launch];
    while( [makeImageTask isRunning]) [NSThread sleepForTimeInterval: 0.01];
    [makeImageTask interrupt];
	
	[pool release];
}


@end

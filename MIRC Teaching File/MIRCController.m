//
//  MIRCController.m
//  
//
//  Created by Lance Pysher July 22, 2005
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCController.h"
#import "MIRCFilter.h"
#import "DCMView.h"
#import <QuartzCore/QuartzCore.h>
#import "MIRCXMLController.h"
#import "MIRCWebController.h"
#import "MIRCImage.h"
#import "browserController.h"
 #import <OsiriX/DCM.h>

//enum { annotNone = 0, annotGraphics = 1, annotBase = 2, annotFull = 3};

@implementation MIRCController

//extern short annotations;

//Core Data Managed Objects
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) return _managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
	[allBundles addObjectsFromArray: [NSBundle allFrameworks]];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingString:@"/TeachingFile.mom"]]];
    [allBundles release];
    
    return _managedObjectModel;
}

- (NSManagedObjectContext *) managedObjectContext
{
    NSError *error = 0L;
    NSString *localizedDescription;
	NSFileManager *fileManager;

	
    if (_managedObjectContext) return _managedObjectContext;
		
	fileManager = [NSFileManager defaultManager];
	
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator: coordinator];
	
	NSString *dbPath = [[self path] stringByAppendingPathComponent:@"teachingFile.sql"];
	//NSLog(@"PATH TO TEAHCING FILE SQL FILE	: %@, TF path: %@", dbPath, _path);
    NSURL *url = [NSURL fileURLWithPath: dbPath];

	if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error])
	{	// NSSQLiteStoreType - NSXMLStoreType
      localizedDescription = [error localizedDescription];
		error = [NSError errorWithDomain:@"OsiriXDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error, NSUnderlyingErrorKey, [NSString stringWithFormat:@"Store Configuration Failure: %@", ((localizedDescription != nil) ? localizedDescription : @"Unknown Error")], NSLocalizedDescriptionKey, nil]];
    }
	
	[coordinator release];
	
	[_managedObjectContext setStalenessInterval: 1200];
	
    return _managedObjectContext;
}

- (void)save{
//	NSManagedObjectModel *model = [self managedObjectModel];
	NSManagedObjectContext *context = [self managedObjectContext];
	NSError *error = nil;
	[context save: &error];
	if (error)
	{
		NSLog(@"error saving DB: %@", [[error userInfo] description]);
		NSLog( @"saveDatabase ERROR: %@", [error localizedDescription]);
	}
	else
		NSLog(@"MIRC TF saved");
		
		
	//[context unlock];
	//[context release];
}


- (id) initWithFilter:(id)filter
{
	self = [super initWithWindowNibName:@"MIRC"];
	//NSLog(@"init MIRC filter");
	_filter = filter;
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	_path = [[[NSUserDefaults standardUserDefaults] stringForKey:@"MIRCFolderPath"] retain];
	if ([[NSUserDefaults standardUserDefaults] stringForKey:@"MIRCurl"])
		[self setUrl:[[NSUserDefaults standardUserDefaults] stringForKey:@"MIRCurl"]];
	if (!_path)
		_path = [[_filter teachingFileFolder] retain];
	[titleField setStringValue:_path];
	
	//Get Cases
	NSError *error = nil;	
	NSPredicate * predicate = [NSPredicate predicateWithValue:YES];
	NSFetchRequest *dbRequest = [[[NSFetchRequest alloc] init] autorelease];
	[dbRequest setEntity: [[[self managedObjectModel] entitiesByName] objectForKey:@"teachingFile"]];
	[dbRequest setPredicate:predicate];
	_teachingFiles = [[[self managedObjectContext] executeFetchRequest:dbRequest error:&error] retain];
	if( [_teachingFiles count]) {
		NSEnumerator *enumerator = [_teachingFiles objectEnumerator];
		id tf;
		while (tf = [enumerator nextObject]) {}
			//NSLog(@"images %@", [tf valueForKey:@"images"]);
		
	}
	
	return self;
}

- (void)windowDidLoad{
}

- (void)windowWillClose:(NSNotification *)note{

	[self save];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification{

	[self save];
}



- (void) dealloc
{	
	[self save];
	[_teachingFiles release];
	[_xmlController release];
	[_webController release];
	[_caseName release];
	[_path release];
	[_url release];
	[super dealloc];
}

- (IBAction)controlAction: (id)sender {
	if ([sender selectedSegment] == 0) 
	{
		//[self selectCurrentImage:nil];
	}
	else if ([sender selectedSegment] == 1) 
		[self createCase:nil];
	else if ([sender selectedSegment] == 2)
		[self createArchive:sender];
	else
		[self connectToMIRC:nil]; 
}





- (IBAction)connectToMIRC:(id)sender{
	// run archive and send tasks
}

- (NSString *)url{

	return _url;
}

- (void)setUrl:(NSString *)url{
	[_url release];
	if ([url hasPrefix:@"http://"])
		_url = [url retain];
	else
		_url = [[NSString stringWithFormat:@"http://%@", url] retain];

	[[NSUserDefaults standardUserDefaults] setObject:_url forKey:@"MIRCurl"];
}




- (IBAction)createArchive:(id)sender{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel beginSheetForDirectory:[self folder] 
		file:@"archive.zip" 
		modalForWindow:[self window]
		modalDelegate:self 
		didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil];
}
	
- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	if (returnCode == NSOKButton){
		//delete archive is present
		NSString *path = [sheet filename];
		if (![[path pathExtension] isEqualToString:@"zip"]) {
			path = [path stringByDeletingPathExtension];
			path = [path stringByAppendingPathExtension:@"zip"];
		}
			
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager fileExistsAtPath:path])
			[manager removeFileAtPath:path handler:nil];
		//create Zip with NSTask
		NSTask *task = [[NSTask alloc] init];
		[task setCurrentDirectoryPath:[self folder]];
		[task setLaunchPath:@"/usr/bin/zip/"];
		NSMutableArray*args = [NSMutableArray arrayWithObject:path];
		[args addObjectsFromArray:[[NSFileManager defaultManager] directoryContentsAtPath:[self folder]]];
		[task setArguments:args];
		//NSLog(@"Create archive args: %@ path: %@", [args description], [self folder]);
		[task  launch];
		while( [task isRunning]) [NSThread sleepForTimeInterval: 0.01];
		[task release];
	}
}

- (NSString *)caseName{
	return _caseName;
}

- (void) setCaseName: (NSString *)caseName{

	[_caseName release];
	_caseName = [caseName retain];
	[tableView reloadData];
}

- (NSString *)path{
	if (!_path)
	_path = [[[NSUserDefaults standardUserDefaults] stringForKey:@"MIRCFolderPath"] retain];
	if (!_path)
		_path = [[_filter teachingFileFolder] retain];
	return _path;
}







- (NSArray *)teachingFiles{
	return _teachingFiles;
}
- (void)setTeachingFiles:(NSArray *)teachingFiles{
	[_teachingFiles release];
	_teachingFiles = [teachingFiles retain];
}

- (IBAction)openMIRCSettings:(id)sender{
	[NSApp beginSheet:_mircSettings modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
- (IBAction)closeMIRCSettings:(id)sender{
	[NSApp endSheet:_mircSettings];
	[_mircSettings  orderOut:self];
	[NSApp beginSheet:_loginPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)endLoginPanel:(id)sender{
	[NSApp endSheet:_loginPanel];
	[_loginPanel orderOut:self];
	if ([sender tag] == 1) {
			NSString *destinationIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_IPAddress"];
	if (!destinationIP) 
		destinationIP = @"localhost";
	NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_Port"];
	if (!port) 
		port = @"8080";
		
	NSString *storageService = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_StorageService"];
	if (!storageService)
		storageService = @"storageService";
		NSString *destination = [NSString stringWithFormat:@"http://%@:%@/%@/submit/doc", destinationIP , port, storageService];
		NSURL *url = [NSURL URLWithString:destination];
		[[NSWorkspace sharedWorkspace] openURL:url];
	}
}


@end

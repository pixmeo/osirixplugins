//
//  DuplicateFilter.m
//  Duplicate
//
//  Created by Lance Pysher on Monday August 1, 2005.
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import "DBFilter.h"
#import <OsiriX/DCM.h>
#import "browserController.h"

// You will need to link to the  OsiriX frameworks  on your computer to compile


@implementation DBFilter

- (long) filterImage:(NSString*) menuName
{
	return 0;
}


- (void) initPlugin{
//register for this notification.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedToDB:) name:@"OsirixAddToDBNotification" object:nil];
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	// documentsDirectory() is a function in OsiriX to find the OsiriX Data Folder
	NSString *folder = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingString:@"/xmlExport"];
	BOOL isDir;
	//create folder in absent
	if (!([defaultManager fileExistsAtPath:folder isDirectory:&isDir] && isDir)) {
		NSLog(@"Create Folder: %@", folder);
		[defaultManager createDirectoryAtPath:folder attributes:nil];
	}
	
}

- (void) addedToDB:(NSNotification *)note{
// This is the array of files added [[note userInfo] objectForKey:@"OsiriXAddToDBArray"] 
	NSEnumerator *enumerator = [[[note userInfo] objectForKey:@"OsiriXAddToDBArray"] objectEnumerator];
	/*
	file is of type DicomImage 
	Accessing the path let's you open the file and access the DICOM info using DCmObject
	Use tagDictionary.plist in the OsiriX folder to find the attribute mame 
	to access the info using attributeValueWithName: method
	For Example to find the Patient's Name attribute name:
	
	<key>0010,0010</key>
	<dict>
		<key>Description</key>
		<string>PatientsName</string>
		<key>VM</key>
		<string>1</string>
		<key>VR</key>
		<string>PN</string>
	</dict>
		
	*/
		
	id file;
	//enumerate through array of files
	while (file = [enumerator nextObject]){
	// have a pool so we don't waste memory
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSString *path = [file valueForKey:@"path"];
		DCMObject *dcmObject = [DCMObject  objectWithContentsOfFile:path decodingPixelData:NO];
		NSXMLDocument *xmlDocument = [dcmObject xmlDocument];
		/* 
		If you want to parse the xml Document and select certain elements read up on NSXMLDocument and NSXMLElement
		The other option would be to select the tags you want ffrom the dcmObject and create a new object with them. It depends on how many tags you want to save.
		*/
		NSString *folder = [[[BrowserController currentBrowser] documentsDirectory] stringByAppendingString:@"/xmlExport"];
		NSString *destination = [NSString stringWithFormat:@"%@/%@", folder, [dcmObject attributeValueWithName:@"SOPInstanceUID"]];
		[[xmlDocument XMLData] writeToFile:destination  atomically:YES];
		[pool release];
	}
	
}

	


@end

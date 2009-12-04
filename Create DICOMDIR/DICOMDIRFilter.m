//
//   DICOMDIRFilter
//  
//

//  Copyright (c) 2005 Macrad, LL. All rights reserved.
//

#import "DICOMDIRFilter.h"
#import <OsiriX/DCM.h>
//#import <OsiriX/DCMLimitedObject.h>

#import "browserController.h"



@implementation DICOMDIRFilter

- (long) filterImage:(NSString*) menuName
{
	NSArray *topLevelObjects;
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"Verify" bundle:thisBundle];
	[nib instantiateNibWithOwner:self topLevelObjects:&topLevelObjects];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setTitle:NSLocalizedString(@"Import", nil)];
	[openPanel setMessage:NSLocalizedString(@"Select Folder for DICOMDIR", nil)];
	if([openPanel runModalForTypes:nil] == NSOKButton){
		NSString *folder = [openPanel filename];
		DCMDirectory *directory = [DCMDirectory directory];
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:folder];
		NSString *file;
		while (file = [enumerator nextObject]) {
			NSLog(@"Add File to DIDOMDIR: %@", file);
			NSString *path = [folder stringByAppendingPathComponent:file];
			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[directory addObjectAtPath:path];
			[pool release];
		}
		NSLog(@"Write DICOMDIR");
		NSString *dicomdirPath = [folder stringByAppendingPathComponent:@"DICOMDIR"];
		[directory writeToFile:dicomdirPath];
	}
	return 0;
}

- (void)dealloc{
	[super dealloc];
}



@end

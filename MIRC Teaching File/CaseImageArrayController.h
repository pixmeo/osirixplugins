//
//  CaseImageArrayController.h
//  TeachingFile
//
//  Created by Lance Pysher on 2/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCMView;
@interface CaseImageArrayController : NSArrayController {
	IBOutlet NSTableView *tableView;
	IBOutlet NSWindow *_window;
	IBOutlet NSPanel *_imageImportPanel;
	BOOL _addOrginalFormatImage;
	BOOL _addAnnotatedImage;
	BOOL _addOriginalDimensionImage;
	BOOL _addOriginalDimensionAsMovie;
	id _imageWaitingForMovie;
}

- (void)insertImageAtRow:(int)row fromView:(DCMView *)vi;
- (IBAction)selectCurrentImage:(id)sender;
- (IBAction)addOrDelete:(id)sender;
- (void)newMovie:(NSNotification *)note;


@end

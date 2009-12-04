//
//  CoronaryController.h
//  Coronary
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CoronaryController : NSWindowController
{
	IBOutlet NSTableView *presetsTable;
	IBOutlet NSArrayController *presetCoronary, *presetsList;
}

@property (readonly) NSArrayController *presetsList, *presetCoronary;

- (NSArray*) presetCoronaryArray;
- (IBAction) refresh: (id) sender;
- (void) saveAs:(NSString*) format accessoryView: (NSView*) accessoryView;
- (IBAction) saveDICOM:(id) sender;
- (IBAction) saveAsPDF:(id) sender;
- (IBAction) saveAsTIFF:(id) sender;
- (IBAction) saveAsDICOM:(id) sender;
- (IBAction) saveAsCSV:(id)sender;
- (void) dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename;

@end

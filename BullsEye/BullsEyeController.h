//
//  BullsEyeController.h
//  BullsEye
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BullsEyeController : NSWindowController
{
	IBOutlet NSTableView *presetsTable;
	IBOutlet NSArrayController *presetBullsEye, *presetsList;
}

@property (readonly) NSArrayController *presetsList, *presetBullsEye;

-(IBAction) savePresets:(id)sender;
-(IBAction) loadPresets:(id)sender;
- (NSArray*) presetBullsEyeArray;
- (IBAction) refresh: (id) sender;
- (void) saveAs:(NSString*) format accessoryView: (NSView*) accessoryView;
- (IBAction) saveDICOM:(id) sender;
- (IBAction) saveAsPDF:(id) sender;
- (IBAction) saveAsTIFF:(id) sender;
- (IBAction) saveAsJPEG:(id) sender;
- (IBAction) copyToClipboard:(id) sender;
- (IBAction) saveAsDICOM:(id) sender;
- (IBAction) saveAsCSV:(id)sender;
- (void) dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename;

@end

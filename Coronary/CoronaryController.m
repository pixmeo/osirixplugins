//
//  CoronaryController.m
//  Coronary
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "CoronaryController.h"
#import "ColorCell.h"
#import "CoronaryView.h"
#import "OsiriX Headers/BrowserController.h"
#import "OsiriX Headers/DICOMExport.h"
#import "OsiriX Headers/ViewerController.h"
#import "OsiriX Headers/DCMView.h"
#import "OsiriX Headers/DCMPix.h"

const NSString* FileTypePDF = @"pdf";
const NSString* FileTypeTIFF = @"tiff";
const NSString* FileTypeDICOM = @"dcm";
const NSString* FileTypeCSV = @"csv";

@implementation CoronaryController

@synthesize presetsList, presetCoronary;

- (void) dealloc
{
	[super dealloc];
}

- (NSArray*) presetCoronaryArray
{
	return [presetCoronary arrangedObjects];
}

- (void) windowWillClose:(NSNotification*)notification
{
	if ([notification object] == [self window])
	{
		[[NSUserDefaults standardUserDefaults] setValue: [presetsList arrangedObjects] forKey: @"presetsCoronaryList"];
		
		[[self window] orderOut: self];
		[self autorelease];
	}
}
- (IBAction) refresh: (id) sender
{
	[[CoronaryView view] refresh];
}

- (id) initWithWindowNibName:(NSString *)windowNibName
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"presetsCoronaryList"] == nil)
	{
		NSDictionary *dict1, *dict2, *dict3, *dict4;
		NSMutableArray *list = [NSMutableArray array];
		
		dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"normal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"color", nil];
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"hypokinesia", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"akinesia", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @"dyskinesia", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, nil], @"array", @"Wall Motion", @"name", nil]];
		
		dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"normal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"color", nil];
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"<25%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"25%-75%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @">75%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, nil], @"array", @"Enhancement", @"name", nil]];
		
		dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"normal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"color", nil];
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"artefact", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"physiologic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @"pathologic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, nil], @"array", @"Perfusion", @"name", nil]];
		
		dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"normal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"color", nil];
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"hypotrophic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"hypertrophic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @"aneurysmal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, nil], @"array", @"Wall Thickness", @"name", nil]];
		
		[[NSUserDefaults standardUserDefaults] setValue: list forKey: @"presetsCoronaryList"];
	}
	
	self = [super initWithWindowNibName: windowNibName];
	
	[self setWindowFrameAutosaveName: @"CoronaryWindowPosition"];
	
	return self;
}

- (void) awakeFromNib
{
	NSTableColumn* column = [presetsTable tableColumnWithIdentifier: @"color"];	// get the first column in the table
	ColorCell* colorCell = [[[ColorCell alloc] init] autorelease];			// create the special color well cell
    [colorCell setEditable: YES];								// allow user to change the color
	[colorCell setTarget: self];								// set colorClick as the method to call
	[colorCell setAction: @selector (colorClick:)];				// when the color well is clicked on
	[column setDataCell: colorCell];							// sets the columns cell to the color well cell

	[[CoronaryView view] refresh];
}

- (void) colorClick: (id) sender		// sender is the table view
{	
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
	[panel setTarget: self];			// send the color changed messages to colorChanged
	[panel setAction: @selector (colorChanged:)];
	[panel setShowsAlpha: YES];			// per ber to show the opacity slider
	[panel setColor: [NSUnarchiver unarchiveObjectWithData: [[[presetCoronary arrangedObjects] objectAtIndex: [presetsTable selectedRow]] objectForKey: @"color"]]];	// set the starting color
	[panel makeKeyAndOrderFront: self];	// show the panel
}

- (void) colorChanged: (id) sender		// sender is the NSColorPanel
{	
	[[[presetCoronary arrangedObjects] objectAtIndex: [presetsTable selectedRow]]  setObject: [NSArchiver archivedDataWithRootObject: [sender color]] forKey: @"color"]; // use saved row index to change the correct in the color array (the model)
}

-(void) saveAs:(NSString*)format accessoryView:(NSView*)accessoryView
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:format];
	
	if (accessoryView)
		[panel setAccessoryView:accessoryView];
	
	[panel beginSheetForDirectory:NULL file: [[presetsList selection] valueForKey: @"name"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo:format];
}

-(IBAction) saveDICOM:(id)sender
{
	[self dicomSave: [[presetsList selection] valueForKey: @"name"] backgroundColor: [NSColor whiteColor] toFile: nil];
}

-(IBAction)saveAsPDF:(id)sender
{
	[self saveAs: (NSString*) FileTypePDF accessoryView: nil];
}

-(IBAction)saveAsTIFF:(id)sender
{
	[self saveAs: (NSString*) FileTypeTIFF accessoryView: nil];
}

-(IBAction)saveAsDICOM:(id)sender
{
	[self saveAs: (NSString*) FileTypeDICOM accessoryView: nil];
}

-(IBAction)saveAsCSV:(id)sender
{
	[self saveAs: (NSString*) FileTypeCSV accessoryView: nil];
}

-(void)dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename
{
	NSBitmapImageRep* bitmapImageRep = [[CoronaryView view] bitmapImageRepForCachingDisplayInRect:[[CoronaryView view] squareBounds]];
	[[CoronaryView view] cacheDisplayInRect:[[CoronaryView view] squareBounds] toBitmapImageRep:bitmapImageRep];
	NSInteger bytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
	CGFloat backgroundRGBA[4]; [[backgroundColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getComponents:backgroundRGBA];
	
	// convert RGBA to RGB - alpha values are considered when mixing the background color with the actual pixel color
	NSMutableData* bitmapRGBData = [NSMutableData dataWithCapacity: [bitmapImageRep size].width*[bitmapImageRep size].height*3];
	for (int y = 0; y < [bitmapImageRep size].height; ++y)
	{
		unsigned char* rowStart = [bitmapImageRep bitmapData]+[bitmapImageRep bytesPerRow]*y;
		for (int x = 0; x < [bitmapImageRep size].width; ++x)
		{
			unsigned char rgba[4];
			memcpy(rgba, rowStart+bytesPerPixel*x, 4);
			
			float ratio = (float) rgba[3] /255.;
			
			rgba[0] = ratio*rgba[0]+(1-ratio)*backgroundRGBA[0]*255;
			rgba[1] = ratio*rgba[1]+(1-ratio)*backgroundRGBA[1]*255;
			rgba[2] = ratio*rgba[2]+(1-ratio)*backgroundRGBA[2]*255;
			[bitmapRGBData appendBytes:rgba length:3];
		}
	}
	
	if( [[ViewerController getDisplayed2DViewers] count])
	{
		DICOMExport* dicomExport = [[DICOMExport alloc] init];
		
		NSString *dicomSourceFile = [[[[[ViewerController getDisplayed2DViewers] objectAtIndex: 0] imageView] curDCM] sourceFile];
		
		[dicomExport setSourceFile: dicomSourceFile];
		[dicomExport setSeriesDescription: seriesDescription];
		[dicomExport setSeriesNumber: 85469];
		[dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplePerPixel:3 bitsPerPixel:8 width:[bitmapImageRep size].width height:[bitmapImageRep size].height];
		NSString *f = [dicomExport writeDCMFile: nil];
	
		if( f)
		[BrowserController addFiles: [NSArray arrayWithObject: f]
					 toContext: [[BrowserController currentBrowser] managedObjectContext]
					toDatabase: [BrowserController currentBrowser]
					 onlyDICOM: YES 
			  notifyAddedFiles: YES
		   parseExistingObject: YES
					  dbFolder: [[BrowserController currentBrowser] documentsDirectory]
			 generatedByOsiriX: YES];
		
		[dicomExport release];
	}
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format
{
    NSError* error = 0;
	
	if (code == NSOKButton)
		if (format == FileTypePDF)
		{
			[[[CoronaryView view] dataWithPDFInsideRect:[[CoronaryView view] squareBounds]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			
		}
		else if (format == FileTypeCSV)
		{
			[[[CoronaryView view] csv: YES] writeToFile: [panel filename] atomically: YES encoding: NSUTF8StringEncoding error:&error];
		}
		else if (format == FileTypeTIFF)
		{
			NSBitmapImageRep* bitmapImageRep = [[CoronaryView view] bitmapImageRepForCachingDisplayInRect:[[CoronaryView view] squareBounds]];
			[[CoronaryView view] cacheDisplayInRect:[[CoronaryView view] squareBounds] toBitmapImageRep:bitmapImageRep];
			NSImage* image = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
			[image addRepresentation:bitmapImageRep];
			[[image TIFFRepresentation] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			[image release];
		}
		else
		{ // dicom
			[self dicomSave: [[presetsList selection] valueForKey: @"name"] backgroundColor: [NSColor whiteColor] toFile:[panel filename]];
		}
	
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

@end

//
//  BullsEyeController.m
//  BullsEye
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "BullsEyeController.h"
#import "ColorCell.h"
#import "BullsEyeView.h"
#import "OsiriXAPI/BrowserController.h"
#import "OsiriXAPI/DICOMExport.h"
#import "OsiriXAPI/ViewerController.h"
#import "OsiriXAPI/DCMView.h"
#import "OsiriXAPI/DCMPix.h"
#import "OsiriXAPI/DicomDatabase.h"

const NSString* FileTypePDF = @"pdf";
const NSString* FileTypeTIFF = @"tiff";
const NSString* FileTypeJPEG = @"jpeg";
const NSString* FileTypePNG = @"png";
const NSString* FileTypeClipboard = @"clip";
const NSString* FileTypeDICOM = @"dcm";
const NSString* FileTypeCSV = @"csv";

@implementation BullsEyeController

@synthesize presetsList, presetBullsEye;

- (void) dealloc
{
	[super dealloc];
}

- (NSArray*) presetBullsEyeArray
{
	return [presetBullsEye arrangedObjects];
}

- (void) windowWillClose:(NSNotification*)notification
{
	if ([notification object] == [self window])
	{
		[[NSUserDefaults standardUserDefaults] setValue: [presetsList arrangedObjects] forKey: @"presetsBullsEyeList"];
		
		[[self window] orderOut: self];
		[self autorelease];
	}
}
- (IBAction) refresh: (id) sender
{
	[[BullsEyeView view] refresh];
}

- (id) initWithWindowNibName:(NSString *)windowNibName
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"presetsBullsEyeList"] == nil)
	{
		NSDictionary *dict1, *dict2, *dict3, *dict4, *dict5;
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
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"artefact", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"<25%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"25%-75%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		dict5 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @">75%", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, dict5, nil], @"array", @"Perfusion", @"name", nil]];
		
		dict1 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 0], @"score", @"normal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor whiteColor]], @"color", nil];
		dict2 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 1], @"score", @"hypotrophic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor yellowColor]], @"color", nil];
		dict3 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 2], @"score", @"hypertrophic", @"state", [NSArchiver archivedDataWithRootObject: [NSColor orangeColor]], @"color", nil];
		dict4 = [NSMutableDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: 3], @"score", @"aneurysmal", @"state", [NSArchiver archivedDataWithRootObject: [NSColor redColor]], @"color", nil];
		[list addObject: [NSDictionary dictionaryWithObjectsAndKeys: [NSArray arrayWithObjects: dict1, dict2, dict3, dict4, nil], @"array", @"Wall Thickness", @"name", nil]];
		
		[[NSUserDefaults standardUserDefaults] setValue: list forKey: @"presetsBullsEyeList"];
	}
	
	self = [super initWithWindowNibName: windowNibName];
	
	[self setWindowFrameAutosaveName: @"bullsEyeWindowPosition"];
	
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

	[[BullsEyeView view] refresh];
}

- (void) colorClick: (id) sender		// sender is the table view
{	
	NSColorPanel* panel = [NSColorPanel sharedColorPanel];
	[panel setTarget: self];			// send the color changed messages to colorChanged
	[panel setAction: @selector (colorChanged:)];
	[panel setShowsAlpha: YES];			// per ber to show the opacity slider
	[panel setColor: [NSUnarchiver unarchiveObjectWithData: [[[presetBullsEye arrangedObjects] objectAtIndex: [presetsTable selectedRow]] objectForKey: @"color"]]];	// set the starting color
	[panel makeKeyAndOrderFront: self];	// show the panel
}

- (void) colorChanged: (id) sender		// sender is the NSColorPanel
{	
	[[[presetBullsEye arrangedObjects] objectAtIndex: [presetsTable selectedRow]]  setObject: [NSArchiver archivedDataWithRootObject: [sender color]] forKey: @"color"]; // use saved row index to change the correct in the color array (the model)
}

-(void) saveAs:(NSString*)format accessoryView:(NSView*)accessoryView
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:format];
	
    if (accessoryView)
        [panel setAccessoryView:accessoryView];
    
	[panel beginSheetForDirectory:NULL file: [[presetsList selection] valueForKey: @"name"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo:format];
}

-(IBAction) savePresets:(id)sender
{
	NSSavePanel *panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"bullsEyePresets"];
    
    if( [panel runModalForDirectory:nil file: @"preset.bullsEyePresets"] == NSFileHandlingPanelOKButton)
    {
        NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey: @"presetsBullsEyeList"];
        
        [[NSFileManager defaultManager] removeItemAtPath: [[panel URL] path] error: nil];
        [[NSKeyedArchiver archivedDataWithRootObject: array] writeToFile: [[panel URL] path] atomically: YES];
    }
}

-(IBAction) loadPresets:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
    
	if ([panel runModalForDirectory: nil file:nil types:[NSArray arrayWithObject:@"bullsEyePresets"]] == NSFileHandlingPanelOKButton)
	{
        NSArray *array = [NSKeyedUnarchiver unarchiveObjectWithFile: [[panel URL] path]];
        
        NSInteger response = NSRunInformationalAlertPanel(  NSLocalizedString(@"Presets", nil),
                                                            NSLocalizedString(@"Do you want to add these presets or replace the current presets", nil),
                                                            NSLocalizedString(@"Add",nil),
                                                            NSLocalizedString(@"Replace",nil),
                                                            NSLocalizedString(@"Cancel",nil));
        
        if( response == NSAlertDefaultReturn)
        {
            NSArray *existingPresets = [[[[NSUserDefaults standardUserDefaults] objectForKey: @"presetsBullsEyeList"] mutableCopy] autorelease];
            
            [[NSUserDefaults standardUserDefaults] setObject: [existingPresets arrayByAddingObjectsFromArray: array] forKey: @"presetsBullsEyeList"];
        }
        
        if( response == NSAlertAlternateReturn)
        {
            [[NSUserDefaults standardUserDefaults] setObject: array forKey: @"presetsBullsEyeList"];
        }
        
        if( response == NSAlertOtherReturn)
        {
            
        }
    }
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

-(IBAction)saveAsJPEG:(id)sender
{
    [self saveAs: (NSString*) FileTypeJPEG accessoryView: nil];
}

-(IBAction)saveAsPNG:(id)sender
{
    [self saveAs: (NSString*) FileTypePNG accessoryView: nil];
}

-(IBAction)copyToClipboard:(id)sender
{
    [self saveAsPanelDidEnd: nil returnCode: NSOKButton contextInfo: FileTypeClipboard];
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
    NSRect r = [[BullsEyeView view] bounds];
    
    r.size.width /= [[[BullsEyeView view] window] backingScaleFactor];
    r.size.height /= [[[BullsEyeView view] window] backingScaleFactor];
    
    NSBitmapImageRep* bitmapImageRep = [[BullsEyeView view] bitmapImageRepForCachingDisplayInRect: r];
    [[BullsEyeView view] cacheDisplayInRect: r toBitmapImageRep:bitmapImageRep];
    
	NSInteger bytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
	CGFloat backgroundRGBA[4]; [[backgroundColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getComponents:backgroundRGBA];
	
	// convert RGBA to RGB - alpha values are considered when mixing the background color with the actual pixel color
	NSMutableData* bitmapRGBData = [NSMutableData dataWithCapacity: [bitmapImageRep pixelsWide]*[bitmapImageRep pixelsHigh]*3];
	for (int y = 0; y < [bitmapImageRep pixelsHigh]; ++y)
	{
		unsigned char* rowStart = [bitmapImageRep bitmapData]+[bitmapImageRep bytesPerRow]*y;
		for (int x = 0; x < [bitmapImageRep pixelsWide]; ++x)
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
		
        ViewerController *firstViewer = [[ViewerController getDisplayed2DViewers] firstObject];
        
		[dicomExport setSourceDicomImage: firstViewer.imageView.curDCM.imageObj];
		[dicomExport setSeriesDescription: seriesDescription];
		[dicomExport setSeriesNumber: 85469];
        [dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplesPerPixel:3 bitsPerSample:8 width:[bitmapImageRep pixelsWide] height:[bitmapImageRep pixelsHigh]];
		NSString *f = [dicomExport writeDCMFile: nil];
	
		if( f)
            [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: f]
                                                                        postNotifications: YES
                                                                                dicomOnly: YES
                                                                      rereadExistingItems: YES
                                                                        generatedByOsiriX: YES];
			 
		[dicomExport release];
	}
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format
{
    NSError* error = 0;
	
	if (code == NSOKButton)
    {
        NSRect r = [[BullsEyeView view] squareBounds];
        
        r.size.width /= [[[BullsEyeView view] window] backingScaleFactor];
        r.size.height /= [[[BullsEyeView view] window] backingScaleFactor];
        
        NSBitmapImageRep* bitmapImageRep = [[BullsEyeView view] bitmapImageRepForCachingDisplayInRect:r];
        [[BullsEyeView view] cacheDisplayInRect:r toBitmapImageRep:bitmapImageRep];
        NSImage* image = [[[NSImage alloc] initWithSize: r.size] autorelease];
        [image addRepresentation:bitmapImageRep];
        
		if (format == FileTypePDF)
		{
			[[[BullsEyeView view] dataWithPDFInsideRect:[[BullsEyeView view] squareBounds]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			
		}
		else if (format == FileTypeCSV)
		{
			[[[BullsEyeView view] csv: YES] writeToFile: [panel filename] atomically: YES encoding: NSUTF8StringEncoding error:&error];
		}
		else if (format == FileTypeTIFF)
		{
			[[image TIFFRepresentation] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
		}
        else if (format == FileTypeJPEG)
        {
            [[[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
        }
        else if (format == FileTypePNG)
        {
            [[[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSPNGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
        }
        else if (format == FileTypeClipboard)
        {
            [[NSPasteboard generalPasteboard] declareTypes: [NSArray arrayWithObjects: NSTIFFPboardType, NSPDFPboardType, nil] owner:self];
            [[NSPasteboard generalPasteboard] setData: [[BullsEyeView view] dataWithPDFInsideRect:[[BullsEyeView view] squareBounds]] forType: NSPDFPboardType];
            [[NSPasteboard generalPasteboard] setData: [[NSBitmapImageRep imageRepWithData: [image TIFFRepresentation]] representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]] forType: NSTIFFPboardType];
        }
		else
		{
			[self dicomSave: [[presetsList selection] valueForKey: @"name"] backgroundColor: [NSColor whiteColor] toFile:[panel filename]];
		}
	}
    
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

@end

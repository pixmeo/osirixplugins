/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "RoiEnhancementInterface.h"
#import "OsiriXAPI/ViewerController.h"
#import "RoiEnhancementROIList.h"
#import "RoiEnhancementChart.h"
#import "RoiEnhancementOptions.h"
#import <OsiriXAPI/DICOMExport.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomDatabase.h>
#import "RoiEnhancementUserDefaults.h"
#import "RoiEnhancementDicomSaveDialog.h"
#import "OsiriXAPI/Notifications.h"

NSString* const FileTypePDF = @"pdf";
NSString* const FileTypeTIFF = @"tiff";
NSString* const FileTypeCSV = @"csv";


@implementation RoiEnhancementInterface
@synthesize viewer = _viewer;
@synthesize roiList = _roiList;
@synthesize chart = _chart;
@synthesize options = _options;
@synthesize decimalFormatter = _decimalFormatter;
@synthesize floatFormatter = _floatFormatter;
@synthesize userDefaults = _userDefaults;

-(id)initForViewer:(ViewerController*)viewer
{
	_viewer = [viewer retain];
	self = [super initWithWindowNibName:@"Interface"];
	[self window]; // triggers nib loading
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:OsirixCloseViewerNotification object:viewer];
	
	_userDefaults = [[RoiEnhancementUserDefaults alloc] init];
	[_options loadUserDefaults];

	[_roiList loadViewerROIs];
	
	if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] intValue] < 5466)
		if (![_userDefaults bool:@"alert.version.dontshowagain" otherwise:NO]) {
			NSAlert* alert = [NSAlert alertWithMessageText:@"The OsiriX application you are running is out of date." defaultButton:@"Close" alternateButton:@"Continue" otherButton:NULL informativeTextWithFormat:@"This plugin is usable in the current environment but its behaviour when following ROI selection is undefined."];
			[alert setShowsSuppressionButton:YES];
			[[alert suppressionButton] setTitle:@"Do not show this message again."];
			[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(versionAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		}
	
	return self;
}

-(void)dealloc
{
	[_viewer release]; _viewer = NULL;
	
	[super dealloc];
}

-(void)windowWillClose:(NSNotification*)notification {
	if ([notification object] == [self window]) {
		_chart.stopDraw = YES;
		[[self window] orderOut: self];
		[self autorelease];
	}
}

-(void)viewerWillClose:(NSNotification*)notification {
	[[self window] orderOut: self];
	[[self window] close];
}

-(void)versionAlertDidEnd:(NSAlert*)alert returnCode:(int)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == 1)
		[[self window] close];
	else if ([[alert suppressionButton] state])
		[_userDefaults setBool:YES forKey:@"alert.version.dontshowagain"];
}

-(BOOL) hasOSXElCapitan
{
    static int hasOSXElCapitan = -1;
    
    if( hasOSXElCapitan != -1)
        return hasOSXElCapitan;
    
    SInt32 osVersion;
    hasOSXElCapitan = YES;
    if( Gestalt( gestaltSystemVersionMinor, &osVersion) == noErr)
    {
        if( osVersion < 11)
            hasOSXElCapitan = NO;
    }
    
    return hasOSXElCapitan;
}

-(void)saveAs:(NSString*)format accessoryView:(NSView*)accessoryView
{
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:format];

    if (accessoryView)
		[panel setAccessoryView:accessoryView];
    
	NSManagedObject* infoData = (NSManagedObject*)[[[_viewer imageView] curDCM] imageObj];
	NSString* filename = [NSString stringWithFormat:@"%@ ROI Enhancement", [infoData valueForKeyPath:@"series.study.name"]];
	
	[panel beginSheetForDirectory:NULL file:filename modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo:format];
}

-(IBAction)saveDICOM:(id)sender {
	[_dicomSaveDialog setImageBackgroundColor:[_userDefaults color:@"dicom.color.background" otherwise:[_dicomSaveDialog imageBackgroundColor]]];
	[_dicomSaveDialog setSeriesName:@"ROI Enhancement"];
	[NSApp beginSheet:_dicomSaveDialog modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveDicomSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(IBAction)saveAsPDF:(id)sender {
	[self saveAs:FileTypePDF accessoryView:NULL];
}

-(IBAction)saveAsTIFF:(id)sender {
	[self saveAs:FileTypeTIFF accessoryView:NULL];
}

//-(IBAction)saveAsDICOM:(id)sender {
//	[_dicomSaveOptionsBackgroundColor setColor:[_userDefaults color:@"dicom.color.background" otherwise:[_dicomSaveOptionsBackgroundColor color]]];
//	[self saveAs:FileTypeDICOM accessoryView:_dicomSaveOptions];
//}

-(IBAction)saveAsCSV:(id)sender {
	[_csvSaveOptionsIncludeHeaders setState:[_userDefaults bool:@"csv.headers.include" otherwise:[_csvSaveOptionsIncludeHeaders state]]];
	[self saveAs: FileTypeCSV accessoryView:_csvSaveOptionsIncludeHeaders];
}

-(void)dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename
{
    NSRect r = [_chart bounds];
    
//    r.size.width /= [[_chart window] backingScaleFactor];
//    r.size.height /= [[_chart window] backingScaleFactor];
    
    NSBitmapImageRep* bitmapImageRep = [_chart bitmapImageRepForCachingDisplayInRect: r];
    [_chart cacheDisplayInRect: r toBitmapImageRep:bitmapImageRep];
    
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
	
	DICOMExport* dicomExport = [[DICOMExport alloc] init];
	[dicomExport setSourceDicomImage: [[_viewer fileList] firstObject]];
	[dicomExport setSeriesDescription: seriesDescription];
	[dicomExport setSeriesNumber: 35466];
    [dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplesPerPixel:3 bitsPerSample:8 width:[bitmapImageRep pixelsWide] height:[bitmapImageRep pixelsHigh]];
	NSString* f = [dicomExport writeDCMFile: nil];
	
	if (f)
        [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: f]
                                                 postNotifications: YES
                                                         dicomOnly: YES
                                               rereadExistingItems: YES
                                                 generatedByOsiriX: YES];
	
	[dicomExport release];
}

-(void)saveDicomSheetDidEnd:(NSWindow*)sheet returnCode:(int)code contextInfo:(void*)contextInfo {
	if (code == NSOKButton) {
		[_userDefaults setColor:[_dicomSaveDialog imageBackgroundColor] forKey:@"dicom.color.background"];
		[self dicomSave:[_dicomSaveDialog seriesName] backgroundColor:[_dicomSaveDialog imageBackgroundColor] toFile:NULL];
	}
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format {
    NSError* error = 0;
	
	if (code == NSOKButton)
		if (format == FileTypePDF) {
			[[_chart dataWithPDFInsideRect:[_chart bounds]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			
		} else if (format == FileTypeCSV)
        {
			[_userDefaults setBool:[_csvSaveOptionsIncludeHeaders state] forKey:@"csv.headers.include"];
			[[_chart csv: [_csvSaveOptionsIncludeHeaders state]] writeToFile:[panel filename] atomically:YES encoding:NSUTF8StringEncoding error:&error];
			
		} else if (format == FileTypeTIFF) {
            NSRect r = [_chart bounds];
            
//            r.size.width /= [[_chart window] backingScaleFactor];
//            r.size.height /= [[_chart window] backingScaleFactor];
            
            NSBitmapImageRep* bitmapImageRep = [_chart bitmapImageRepForCachingDisplayInRect:r];
            [_chart cacheDisplayInRect:r toBitmapImageRep:bitmapImageRep];
            NSImage* image = [[[NSImage alloc] initWithSize: r.size] autorelease];
            [image addRepresentation:bitmapImageRep];
            
			[[image TIFFRepresentation] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			
		} else { // dicom
			[_userDefaults setColor:[_dicomSaveOptionsBackgroundColor color] forKey:@"dicom.color.background"];
			unsigned lastSlash = [[panel filename] rangeOfString:@"/" options:NSBackwardsSearch].location+1;
			[self dicomSave:[[panel filename] substringWithRange: NSMakeRange(lastSlash, [[panel filename] rangeOfString:@"." options:NSBackwardsSearch].location-lastSlash)] backgroundColor:[_dicomSaveOptionsBackgroundColor color] toFile:[panel filename]];
		}
	
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

@end

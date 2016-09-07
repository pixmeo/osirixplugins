//
//  EjectionFractionResultsController.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionResultsController.h"
#import "EjectionFractionWorkflow.h"
#import "EjectionFractionWorkflow+OsiriX.h"
#import "EjectionFractionAlgorithm.h"
#import "EjectionFractionDicomSaveDialog.h"
#import "EjectionFractionImageView.h"
#import <OsiriXAPI/N2ColumnLayout.h>
#import <OsiriXAPI/N2CellDescriptor.h>
#import <OsiriXAPI/NSTextView+N2.h>
#import <OsiriXAPI/N2View.h>
#import <OsiriXAPI/N2MinMax.h>
#import <OsiriXAPI/N2Window.h>
#import <OsiriXAPI/NSWindow+N2.h>
#import <OsiriXAPI/N2ImageView.h>
#import <OsiriXAPI/NSImageView+N2.h>
#import <OsiriXAPI/N2Operators.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/MyPoint.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DICOMExport.h>
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/DicomImage.h>
#import "EjectionFractionZoomView.h"

NSString* const FileTypePDF = @"pdf";
NSString* const FileTypeTIFF = @"tiff";
NSString* const FileTypeDICOM = @"dcm";

@interface EjectionFractionResultsController (Private)

-(NSImage*)imageFromPic:(DCMPix*)dcm includingRois:(NSArray*)rois;
-(NSImage*)imageFromRois:(NSArray*)rois;

@end

@implementation EjectionFractionResultsController
@synthesize workflow = _workflow;

-(NSArray*)roisAndPixForId:(NSString*)roiId {
	ROI* roi = [_workflow roiForId:roiId];
	DCMView* view = [roi curView];
	
	// find slice roilist containing roi
	NSArray* sliceRois = NULL;
	for (NSArray* irois in [view dcmRoiList])
		if ([irois containsObject:roi]) {
			sliceRois = irois;
			break;
		}
	if (!sliceRois) [NSException raise:NSGenericException format:@"Couldn't find ROI in list"];
	
	// find rois that are in slice roilist and in algorithm roigroup
	NSMutableArray* roisAndPix = [NSMutableArray arrayWithCapacity:4];
	for (roiId in [[_workflow algorithm] roiIdsGroupContainingRoiId:roiId]) {
		roi = [_workflow roiForId:roiId];
		if ([sliceRois containsObject:roi])
			[roisAndPix addObject:roi];
	}
	
	// add pix
	[roisAndPix addObject:[[view dcmPixList] objectAtIndex:[[view dcmRoiList] indexOfObject:sliceRois]]];
	
	return roisAndPix;
}

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow {
	self = [super initWithWindowNibName:@"EjectionFractionResults"];
	[self setWorkflow:workflow];
	
	[[self window] setDelegate:self];
	
	//self = [super initWithWindow:[[N2Window alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:YES]];
	//[[self window] setTitle:@"Ejection Fraction: Results"];
	
	NSMutableArray* imageViewRows = [NSMutableArray arrayWithCapacity:0];
	for (NSArray* group in [[workflow algorithm] pairedRoiIds]) {
		NSMutableArray* views = [NSMutableArray arrayWithCapacity:3];
		[views addObject:[EjectionFractionImageView viewWithObjects:[self roisAndPixForId:[group objectAtIndex:0]]]];
		[views addObject:[EjectionFractionImageView viewWithObjects:[self roisAndPixForId:[group objectAtIndex:1]]]];
		[views addObject:[EjectionFractionImageView viewWithObjects:[workflow roisForIds:group]]];
		[imageViewRows addObject:views];
	}
	
	NSUInteger rowsCount = [imageViewRows count];
	
	// info
	
	N2View* info = [[N2View alloc] initWithSize:NSZeroSize];
	N2ColumnLayout* infoLayout = [[N2ColumnLayout alloc] initForView:info columnDescriptors:[NSArray arrayWithObjects:[N2CellDescriptor descriptor], [N2CellDescriptor descriptor], NULL] controlSize:NSSmallControlSize];
	[infoLayout setMargin:NSZeroRect];
	[infoLayout setForcesSuperviewHeight:YES];
	[infoLayout setForcesSuperviewWidth:YES];
	[infoLayout setEnabled:NO];
	
	// header
	
	NSManagedObject* infoData = [[[workflow roiForId:[[[workflow algorithm] roiIds] objectAtIndex:0]] pix] imageObj];
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
	[infoLayout appendRow:[NSArray arrayWithObjects:
						   [NSTextView labelWithText:@"Algorithm:" alignment:NSRightTextAlignment],
						   [NSTextView labelWithText:[[_workflow algorithm] description]], NULL]];
	[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[[[NSView alloc] initWithSize:NSMakeSize(0)] autorelease]] colSpan:2]]];
	if ([infoData valueForKeyPath:@"series.study.patientID"])
		[infoLayout appendRow:[NSArray arrayWithObjects:
								[NSTextView labelWithText:@"Patient ID:" alignment:NSRightTextAlignment],
								[NSTextView labelWithText:[infoData valueForKeyPath:@"series.study.patientID"]], NULL]];
	if ([infoData valueForKeyPath:@"series.study.name"])
		[infoLayout appendRow:[NSArray arrayWithObjects:
								[NSTextView labelWithText:@"Name:" alignment:NSRightTextAlignment],
								[NSTextView labelWithText:[infoData valueForKeyPath:@"series.study.name"]], NULL]];
	if ([infoData valueForKeyPath:@"series.study.dateOfBirth"])
		[infoLayout appendRow:[NSArray arrayWithObjects:
								[NSTextView labelWithText:@"Date of Birth:" alignment:NSRightTextAlignment],
							   [NSTextView labelWithText:[dateFormatter stringFromDate:[infoData valueForKeyPath:@"series.study.dateOfBirth"]]], NULL]];
	

	// algorithm description image
	
	[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[[[NSView alloc] initWithSize:NSMakeSize(0)] autorelease]] colSpan:2]]];
	NSImage* image = [[workflow algorithm] image];
	if (image) {
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[N2ImageView createWithImage:image]] colSpan:2]]];
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[[[NSView alloc] initWithSize:NSMakeSize(0)] autorelease]] colSpan:2]]];
	}
	
	// result
	
	CGFloat diasVol, systVol, ejectionFraction = [workflow computeAndOutputDiastoleVolume:diasVol systoleVolume:systVol];
	
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Diastole volume:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:[NSString stringWithFormat:@"%.2f ml", diasVol]], NULL]];
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Systole volume:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:[NSString stringWithFormat:@"%.2f ml", systVol]], NULL]];
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Ejection fraction:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:[NSString stringWithFormat:@"%.1f %%", ejectionFraction*100]], NULL]];
	
	[infoLayout setEnabled:YES];
	[infoLayout layOut];
	[infoLayout setEnabled:NO];
	
	// done
	
	NSArray* colDescriptors;
	switch (rowsCount) {
		case 0: {
			colDescriptors = [NSArray arrayWithObject:[[N2CellDescriptor descriptor] filled:NO]];
		} break;
		case 1: {
			colDescriptors = [NSArray arrayWithObjects: [[N2CellDescriptor descriptor] invasivity:1], [[N2CellDescriptor descriptor] invasivity:1], NULL];
		} break;
		default: {
			colDescriptors = [NSArray arrayWithObjects: [[N2CellDescriptor descriptor] invasivity:1], [[N2CellDescriptor descriptor] invasivity:1], [N2CellDescriptor descriptor], NULL];
		} break;
	}
	
	NSWindow* window = [self window];
	N2View* content = [window contentView];
	
	N2ColumnLayout* contentLayout = [[N2ColumnLayout alloc] initForView:content columnDescriptors:colDescriptors controlSize:NSRegularControlSize];
	[contentLayout setForcesSuperviewWidth:YES];
	[contentLayout setForcesSuperviewHeight:YES];
	[contentLayout setSeparation:NSMakeSize(5)];

	switch (rowsCount) {
		case 0: {
			[contentLayout appendRow:[NSArray arrayWithObject:info]];
		} break;
		case 1: {
			[contentLayout appendRow:[NSArray arrayWithObjects: [[imageViewRows objectAtIndex:0] objectAtIndex:0], [[imageViewRows objectAtIndex:0] objectAtIndex:1], NULL]];
			[contentLayout appendRow:[NSArray arrayWithObjects: [[N2CellDescriptor descriptorWithView:[[imageViewRows objectAtIndex:0] objectAtIndex:2]] alignment:N2Top], [[[N2CellDescriptor descriptorWithView:[EjectionFractionZoomView zoomWithView:info]] alignment:0] filled:YES], NULL]];
		} break;
		default: {
			for (NSArray* views in imageViewRows)
				[contentLayout appendRow:[NSArray arrayWithObjects: [views objectAtIndex:0], [views objectAtIndex:1], [views objectAtIndex:2], NULL]];
			[contentLayout appendRow:[NSArray arrayWithObject:[[[[N2CellDescriptor descriptorWithView:info] colSpan:3] filled:NO] alignment:0]]];
		}
	}
	
	[contentLayout setForcesSuperviewWidth:NO];
	[contentLayout setForcesSuperviewHeight:NO];
	
	// set window size
	NSRect frame = [window frame];
	NSRect screen = [[[[workflow steps] window] screen] visibleFrame];
	if (frame.size.width > screen.size.width || frame.size.height >= screen.size.height) {
		if (frame.size.width > screen.size.width)
			frame.size.width = screen.size.width;
		NSUInteger step = MAX(NSUInteger(frame.size.width/10), NSUInteger(1));
		frame.size.width += step;
		do { // decrease window width until its height fits in the screen
			frame.size.width -= step;
			NSSize optimalSize = [contentLayout optimalSizeForWidth:[window contentSizeForFrameSize:frame.size].width];
			frame.size = [window frameSizeForContentSize:optimalSize];
			if (frame.size.height <= screen.size.height && step > 1) {
				frame.size.width += step;
				step = MAX(step/10, NSUInteger(1));
				frame.size.height = screen.size.height+1;
			}
		} while (frame.size.height > screen.size.height && frame.size.width > 20);
	}
	
	frame.origin = screen.origin+(screen.size-frame.size)/2;
	[window setFrame:frame display:YES];
	
	[window makeKeyAndOrderFront:self];
	return self;
}

-(void)windowWillClose:(NSNotification*)notification {
//	NSLog(@"results windowWillClose, rc = %d, win rc = %d", [self retainCount], [[self window] retainCount]);
	NSLog(@"results controller window will close, my rc is %d", [self retainCount]);
	[self autorelease]; // TODO: this is UNSAFE, [NSWindow dealloc] should release the controller? the problem is, NSWindow's retain count is huge, so it won't be released
}

-(void)dealloc {
	NSLog(@"results controller dealloc");
	[self setWorkflow:NULL];
	[super dealloc];
}

-(IBAction)print:(id)sender {
	NSPrintInfo* info = [[[NSPrintInfo alloc] initWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys: NULL]] autorelease];
	
	NSSize size = [[[self window] contentView] frame].size;

	if (size.height > size.width) {
		[info setOrientation:NSPortraitOrientation];
		[info setVerticalPagination:NSFitPagination];
	} else {
		[info setOrientation:NSLandscapeOrientation];
		[info setHorizontalPagination:NSFitPagination];
	}
	
	[[NSPrintOperation printOperationWithView:[[self window] contentView] printInfo:info] runOperation];
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

-(void)saveAs:(NSString*)format accessoryView:(NSView*)accessoryView {
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:format];
    if (accessoryView)
        [panel setAccessoryView:accessoryView];
    
	NSManagedObject* infoData = [[[_workflow roiForId:[[[_workflow algorithm] roiIds] objectAtIndex:0]] pix] imageObj];
	NSString* filename = [NSString stringWithFormat:@"%@ EF %@", [infoData valueForKeyPath:@"series.study.name"], [[_workflow algorithm] description]];

	[panel beginSheetForDirectory:NULL file:filename modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo:format];
}

-(void)dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename {
	NSBitmapImageRep* bitmapImageRep = [[[self window] contentView] bitmapImageRepForCachingDisplayInRect:[[[self window] contentView] bounds]];
	[[[self window] contentView] cacheDisplayInRect:[[[self window] contentView] bounds] toBitmapImageRep:bitmapImageRep];
	NSInteger bytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
	CGFloat backgroundRGBA[4]; [[backgroundColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getComponents:backgroundRGBA];
	
	// convert RGBA to RGB - alpha values are considered when mixing the background color with the actual pixel color
	NSMutableData* bitmapRGBData = [NSMutableData dataWithCapacity: [bitmapImageRep size].width*[bitmapImageRep size].height*3];
	for (int y = 0; y < [bitmapImageRep pixelsHigh]; ++y) {
		unsigned char* rowStart = [bitmapImageRep bitmapData]+[bitmapImageRep bytesPerRow]*y;
		for (int x = 0; x < [bitmapImageRep pixelsWide]; ++x) {
			unsigned char rgba[4]; memcpy(rgba, rowStart+bytesPerPixel*x, 4);
			float ratio = float(rgba[3])/255;
			// rgba[0], [1] and [2] are premultiplied by [3]
			rgba[0] = rgba[0]+(1-ratio)*backgroundRGBA[0]*255;
			rgba[1] = rgba[1]+(1-ratio)*backgroundRGBA[1]*255;
			rgba[2] = rgba[2]+(1-ratio)*backgroundRGBA[2]*255;
			[bitmapRGBData appendBytes:rgba length:3];
		}
	}
	
	DICOMExport* dicomExport = [[DICOMExport alloc] init];
	[dicomExport setSourceFile:[[[[_workflow roiForId:[[[_workflow algorithm] roiIds] objectAtIndex:0]] curView] curDCM] srcFile]];
	[dicomExport setSeriesDescription:seriesDescription];
	[dicomExport setSeriesNumber:35466];
	[dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplePerPixel:3 bitsPerPixel:8 width:[bitmapImageRep size].width height:[bitmapImageRep size].height];
	NSString *f = [dicomExport writeDCMFile: nil];
	
	if( f)
        [BrowserController.currentBrowser.database addFilesAtPaths: [NSArray arrayWithObject: f]
                                                 postNotifications: YES
                                                         dicomOnly: YES
                                               rereadExistingItems: YES
                                                 generatedByOsiriX: YES];
	
	[dicomExport release];
}

-(IBAction)saveDICOM:(id)sender {
//	[_dicomSaveDialog setImageBackgroundColor:[_userDefaults color:@"dicom.color.background" otherwise:[_dicomSaveDialog imageBackgroundColor]]];
	[_dicomSaveDialog setSeriesName:[[_workflow algorithm] description]];
	[NSApp beginSheet:_dicomSaveDialog modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveDicomSheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

-(IBAction)saveAsPDF:(id)sender {
	[self saveAs:FileTypePDF accessoryView:NULL];
}

-(IBAction)saveAsTIFF:(id)sender {
	[self saveAs:FileTypeTIFF accessoryView:NULL];
}

-(IBAction)saveAsDICOM:(id)sender {
//	[_dicomSaveOptionsBackgroundColor setColor:[_userDefaults color:@"dicom.color.background" otherwise:[_dicomSaveOptionsBackgroundColor color]]];
	[self saveAs:FileTypeDICOM accessoryView:_dicomSaveOptions];
}

-(void)saveDicomSheetDidEnd:(NSWindow*)sheet returnCode:(int)code contextInfo:(void*)contextInfo {
	if (code == NSOKButton) {
//		[_userDefaults setColor:[_dicomSaveDialog imageBackgroundColor] forKey:@"dicom.color.background"];
		[self dicomSave:[_dicomSaveDialog seriesName] backgroundColor:[_dicomSaveDialog imageBackgroundColor] toFile:NULL];
	}
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format {
    NSError* error = 0;
	
	if (code == NSOKButton) {
		if (format == FileTypePDF) {
			[[[[self window] contentView] dataWithPDFInsideRect:[[[self window] contentView] bounds]] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			
		} else if (format == FileTypeTIFF) {
			NSBitmapImageRep* bitmapImageRep = [[[self window] contentView] bitmapImageRepForCachingDisplayInRect:[[[self window] contentView] bounds]];
			[[[self window] contentView] cacheDisplayInRect:[[[self window] contentView] bounds] toBitmapImageRep:bitmapImageRep];
			NSImage* image = [[NSImage alloc] initWithSize:[bitmapImageRep size]];
			[image addRepresentation:bitmapImageRep];
			[[image TIFFRepresentation] writeToFile:[panel filename] options:NSAtomicWrite error:&error];
			[image release];
			
		} else { // dicom
//			[_userDefaults setColor:[_dicomSaveOptionsBackgroundColor color] forKey:@"dicom.color.background"];
			unsigned lastSlash = [[panel filename] rangeOfString:@"/" options:NSBackwardsSearch].location+1;
			[self dicomSave:[[panel filename] substringWithRange: NSMakeRange(lastSlash, [[panel filename] rangeOfString:@"." options:NSBackwardsSearch].location-lastSlash)] backgroundColor:[_dicomSaveOptionsBackgroundColor color] toFile:[panel filename]];
		}
		
		if (format == FileTypePDF || format == FileTypeTIFF)
			[[NSWorkspace sharedWorkspace] openFile:[panel filename]];
	}
	
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

@end

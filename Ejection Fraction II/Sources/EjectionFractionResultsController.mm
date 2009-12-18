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
#import "EjectionFractionImage.h"
#import <Nitrogen/N2ColumnLayout.h>
#import <Nitrogen/N2CellDescriptor.h>
#import <Nitrogen/NSTextView+N2.h>
#import <Nitrogen/N2View.h>
#import <Nitrogen/N2MinMax.h>
#import <Nitrogen/N2Window.h>
#import <Nitrogen/NSImageView+N2.h>
#import <Nitrogen/N2Operators.h>
#import <OsiriX Headers/ROI.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/MyPoint.h>
#import <OsiriX Headers/DCMPix.h>
#import <OsiriX Headers/DICOMExport.h>

const NSString* FileTypePDF = @"pdf";
const NSString* FileTypeTIFF = @"tiff";
const NSString* FileTypeDICOM = @"dcm";

@interface EjectionFractionResultsController (Private)

-(NSImage*)imageFromPic:(DCMPix*)dcm includingRois:(NSArray*)rois;
-(NSImage*)imageFromRois:(NSArray*)rois;

@end

@implementation EjectionFractionResultsController
@synthesize workflow = _workflow;

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow {
	self = [super initWithWindowNibName:@"EjectionFractionResults"];
	[self setWorkflow:workflow];
	
	//self = [super initWithWindow:[[N2Window alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:YES]];
	//[[self window] setTitle:@"Ejection Fraction: Results"];
	
	N2ColumnLayout* contentLayout = [[N2ColumnLayout alloc] initForView:[[self window] contentView] columnDescriptors:[NSArray arrayWithObjects: [[N2CellDescriptor descriptor] alignment:N2Right], [N2CellDescriptor descriptor], NULL] controlSize:NSRegularControlSize];
	[contentLayout setForcesSuperviewWidth:YES];
	[contentLayout setForcesSuperviewHeight:YES];
	[contentLayout setSeparation:NSMakeSize([contentLayout margin].size.width/2, [contentLayout separation].height)];
	
	// body
	NSMutableArray* imagesDias = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray* imagesSyst = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray* imagesComp = [NSMutableArray arrayWithCapacity:4];
	// create images
	for (NSArray* group in [[workflow algorithm] pairedRoiIds]) {
		[imagesDias addObject:[EjectionFractionImage imageWithObjects:[[workflow roisForIds:[[workflow algorithm] roiIdsGroupContainingRoiId:[group objectAtIndex:0]]] arrayByAddingObject:[[[workflow roiForId:[group objectAtIndex:0]] curView] curDCM]]]];
		[imagesSyst addObject:[EjectionFractionImage imageWithObjects:[[workflow roisForIds:[[workflow algorithm] roiIdsGroupContainingRoiId:[group objectAtIndex:1]]] arrayByAddingObject:[[[workflow roiForId:[group objectAtIndex:1]] curView] curDCM]]]];
		[imagesComp addObject:[EjectionFractionImage imageWithObjects:[workflow roisForIds:group]]];
	}
	
	// count images
	NSUInteger imagesCount = [imagesDias count];
	
	NSMutableArray* columnDescriptors = [NSMutableArray arrayWithCapacity:4];
	for (NSUInteger i = 0; i < [[[workflow algorithm] groupedRoiIds] count]+1; ++i)
		[columnDescriptors addObject:[N2CellDescriptor descriptor]];
	
	N2View* body = [[N2View alloc] initWithSize:NSZeroSize];
	N2ColumnLayout* bodyLayout = [[N2ColumnLayout alloc] initForView:body columnDescriptors:columnDescriptors controlSize:NSSmallControlSize];
	[bodyLayout setMargin:NSZeroRect];
	[bodyLayout setSeparation:NSMakeSize(5)];
	[bodyLayout setForcesSuperviewHeight:YES];
	[bodyLayout setForcesSuperviewWidth:YES];
		
	for (NSUInteger i = 0; i < imagesCount; ++i) {
		NSMutableArray* views = [NSMutableArray arrayWithCapacity:0];
		
		NSImageView* viewDias = [N2ImageView createWithImage:[imagesDias objectAtIndex:i]];
//		[viewDias setImageScaling:NSImageScaleProportionallyUpOrDown];
		[views addObject:viewDias];
		
		NSImageView* viewSyst = [N2ImageView createWithImage:[imagesSyst objectAtIndex:i]];
		[viewSyst setFrameSize:[viewDias frame].size];
//		[viewSyst setImageScaling:NSImageScaleProportionallyUpOrDown];
		[views addObject:viewSyst];
		
		NSImageView* viewComp = [N2ImageView createWithImage:[imagesComp objectAtIndex:i]];
//		[viewComp setImageScaling:NSImageScaleProportionallyUpOrDown];
		[viewComp setFrameSize:[viewDias frame].size];
		[views addObject:viewComp];
		
		[bodyLayout appendRow:views];
	}
	
	// info
	
	N2View* info = [[N2View alloc] initWithSize:NSZeroSize];
	N2ColumnLayout* infoLayout = [[N2ColumnLayout alloc] initForView:info columnDescriptors:[NSArray arrayWithObjects:[N2CellDescriptor descriptor], [N2CellDescriptor descriptor], NULL] controlSize:NSSmallControlSize];
	[infoLayout setMargin:NSZeroRect];
//	[infoLayout setSeparation:NSMakeSize(0)];
	[infoLayout setForcesSuperviewHeight:YES];
	[infoLayout setForcesSuperviewWidth:YES];
	
	// header
	
	NSManagedObject* infoData = [[[workflow roiForId:[[[workflow algorithm] roiIds] objectAtIndex:0]] pix] imageObj];
	NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	
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
	
	NSImage* image = [[workflow algorithm] image];
	if (image) {
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[[[NSView alloc] initWithSize:NSMakeSize(10)] autorelease]] colSpan:2]]];
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[NSImageView createWithImage:image]] colSpan:2]]];
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:[[[NSView alloc] initWithSize:NSMakeSize(10)] autorelease]] colSpan:2]]];
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
	
	// done
	
	[infoLayout setEnabled:NO];
	
	[contentLayout appendRow:[NSArray arrayWithObjects: body, [[N2CellDescriptor descriptorWithView:info] widthConstraints:N2MakeMinMax([info frame].size.width)], NULL]];
	
	[[self window] makeKeyAndOrderFront:self];

	[contentLayout setForcesSuperviewWidth:NO];
	[contentLayout setForcesSuperviewHeight:NO];
	[bodyLayout setForcesSuperviewWidth:NO];
//	[bodyLayout setForcesSuperviewHeight:NO];

	return self;
}

-(void)dealloc {
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

-(void)saveAs:(NSString*)format accessoryView:(NSView*)accessoryView {
	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType:format];
	if (accessoryView)
		[panel setAccessoryView:accessoryView];
	[panel beginSheetForDirectory:NULL file:NULL modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveAsPanelDidEnd:returnCode:contextInfo:) contextInfo:format];
}

-(void)dicomSave:(NSString*)seriesDescription backgroundColor:(NSColor*)backgroundColor toFile:(NSString*)filename {
	NSBitmapImageRep* bitmapImageRep = [[[self window] contentView] bitmapImageRepForCachingDisplayInRect:[[[self window] contentView] bounds]];
	[[[self window] contentView] cacheDisplayInRect:[[[self window] contentView] bounds] toBitmapImageRep:bitmapImageRep];
	NSInteger bytesPerPixel = [bitmapImageRep bitsPerPixel]/8;
	CGFloat backgroundRGBA[4]; [[backgroundColor colorUsingColorSpace:[NSColorSpace genericRGBColorSpace]] getComponents:backgroundRGBA];
	
	// convert RGBA to RGB - alpha values are considered when mixing the background color with the actual pixel color
	NSMutableData* bitmapRGBData = [NSMutableData dataWithCapacity: [bitmapImageRep size].width*[bitmapImageRep size].height*3];
	for (int y = 0; y < [bitmapImageRep size].height; ++y) {
		unsigned char* rowStart = [bitmapImageRep bitmapData]+[bitmapImageRep bytesPerRow]*y;
		for (int x = 0; x < [bitmapImageRep size].width; ++x) {
			unsigned char rgba[4]; memcpy(rgba, rowStart+bytesPerPixel*x, 4);
			float ratio = float(rgba[3])/255;
			rgba[0] = ratio*rgba[0]+(1-ratio)*backgroundRGBA[0]*255;
			rgba[1] = ratio*rgba[1]+(1-ratio)*backgroundRGBA[1]*255;
			rgba[2] = ratio*rgba[2]+(1-ratio)*backgroundRGBA[2]*255;
			[bitmapRGBData appendBytes:rgba length:3];
		}
	}
	
	DICOMExport* dicomExport = [[DICOMExport alloc] init];
	[dicomExport setSourceFile:[[[[_workflow roiForId:[[[_workflow algorithm] pairedRoiIds] objectAtIndex:0]] curView] curDCM] srcFile]];
	[dicomExport setSeriesDescription:seriesDescription];
	[dicomExport setSeriesNumber:35466];
	[dicomExport setPixelData:(unsigned char*)[bitmapRGBData bytes] samplePerPixel:3 bitsPerPixel:8 width:[bitmapImageRep size].width height:[bitmapImageRep size].height];
	[dicomExport writeDCMFile:filename];
	[dicomExport release];
}

-(IBAction)saveDICOM:(id)sender {
//	[_dicomSaveDialog setImageBackgroundColor:[_userDefaults color:@"dicom.color.background" otherwise:[_dicomSaveDialog imageBackgroundColor]]];
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
		[self dicomSave:[[NSUserDefaults standardUserDefaults] stringForKey:@"defaultNameForChart"] backgroundColor:[_dicomSaveDialog imageBackgroundColor] toFile:NULL];
	}
}

-(void)saveAsPanelDidEnd:(NSSavePanel*)panel returnCode:(int)code contextInfo:(void*)format {
    NSError* error = 0;
	
	if (code == NSOKButton)
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
	
	if (error)
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:NULL didEndSelector:NULL contextInfo:NULL];
}

@end

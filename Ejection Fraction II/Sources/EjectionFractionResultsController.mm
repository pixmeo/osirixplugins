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

@interface EjectionFractionResultsController (Private)

-(NSImage*)imageFromPic:(DCMPix*)dcm includingRois:(NSArray*)rois;
-(NSImage*)imageFromRois:(NSArray*)rois;

@end

@implementation EjectionFractionResultsController

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow {
	self = [super initWithWindowNibName:@"EjectionFractionResults"];
	
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

-(IBAction)print:(id)sender {
	[[NSPrintOperation printOperationWithView:[[self window] contentView]] runOperation];
}

@end

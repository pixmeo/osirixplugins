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
	self = [super initWithWindow:[[N2Window alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask|NSResizableWindowMask|NSClosableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:YES]];
	[[self window] setTitle:@"Ejection Fraction: Results"];
	
	N2ColumnLayout* contentLayout = [[N2ColumnLayout alloc] initForView:[[self window] contentView] columnDescriptors:[NSArray arrayWithObjects: [[N2CellDescriptor descriptor] alignment:N2Right], [N2CellDescriptor descriptor], NULL] controlSize:NSRegularControlSize];
	[contentLayout setForcesSuperviewWidth:YES];
	[contentLayout setForcesSuperviewHeight:YES];
	
	// body
	NSMutableArray* imagesDias = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray* imagesSyst = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray* imagesComp = [NSMutableArray arrayWithCapacity:4];
	// create images
	for (NSArray* group in [[workflow algorithm] pairedRoiIds]) {
		[imagesDias addObject:[self imageFromPic:[[[workflow roiForId:[group objectAtIndex:0]] curView] curDCM] includingRois:[workflow roisForIds:[[workflow algorithm] roiIdsGroupContainingRoiId:[group objectAtIndex:0]]]]];
		[imagesSyst addObject:[self imageFromPic:[[[workflow roiForId:[group objectAtIndex:1]] curView] curDCM] includingRois:[workflow roisForIds:[[workflow algorithm] roiIdsGroupContainingRoiId:[group objectAtIndex:1]]]]];
		[imagesComp addObject:[self imageFromRois:[workflow roisForIds:group]]];
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
		
		NSImageView* viewDias = [NSImageView createWithImage:[imagesDias objectAtIndex:i]];
		[viewDias setFrameSize:NSMakeSize(128)];
		[views addObject:viewDias];
		
		NSImageView* viewSyst = [NSImageView createWithImage:[imagesSyst objectAtIndex:i]];
		[viewSyst setFrameSize:NSMakeSize(128)];
		[views addObject:viewSyst];
		
		NSImageView* viewComp = [NSImageView createWithImage:[imagesComp objectAtIndex:i]];
		[viewComp setFrameSize:NSMakeSize(128)];
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
	
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Patient ID:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"TESTTESTTEST"], NULL]];
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Name:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"Aless Aless Aless\nAless"], NULL]];
	[infoLayout appendRow:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Date of Birth:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"12/05/1981"], NULL]];
	
	// algorithm description image
	
	NSImage* image = [[workflow algorithm] image];
	if (image) {
		NSImageView* algorithmView = [NSImageView createWithImage:image];
		[algorithmView setFrameSize:[algorithmView frame].size+NSMakeSize(0,20)]; // view is 20 pixels higher so we have an extra 10 pixels on top and under the view
		[infoLayout appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:algorithmView] colSpan:2]]];
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
	
	[contentLayout appendRow:[NSArray arrayWithObjects: body, [[N2CellDescriptor descriptorWithView:info] widthConstraints:N2MakeMinMax([info frame].size.width)], NULL]];

	[[self window] makeKeyAndOrderFront:self];
	
	return self;
}

-(void)drawRoi:(ROI*)roi onImage:(NSImage*)image withColor:(NSColor*)color usingTransform:(NSAffineTransform*)transform {
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSMutableArray* points = [roi splinePoints];
	[path moveToPoint:[[points objectAtIndex:0] point]];
	//[points removeObjectAtIndex:0];
	for (MyPoint* p in points)
		[path lineToPoint:[p point]];
	[path closePath];
	[path transformUsingAffineTransform:transform];
	
	[image lockFocus];
	
	[color set];
	NSSize size = [transform transformSize:[image size]];
	[path setLineWidth:(size.width+size.height)/128];
	[path stroke];
	
	[image unlockFocus];
}

-(void)drawRoi:(ROI*)roi onImage:(NSImage*)image withColor:(NSColor*)color {
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform scaleXBy:1 yBy:-1];
	[transform translateXBy:0 yBy:-[image size].height];
	[self drawRoi:roi onImage:image withColor:color usingTransform:transform];
}

-(NSImage*)imageFromPic:(DCMPix*)dcm includingRois:(NSArray*)rois {
	if (!dcm) return NULL;
	
	NSImage* image = [dcm image];

	for (ROI* roi in rois)
		[self drawRoi:roi onImage:image withColor:[NSColor redColor]];
	
	return image;
}

-(NSImage*)imageFromRois:(NSArray*)rois {
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:0];
	for (ROI* roi in rois)
		[points addObjectsFromArray:[roi splinePoints]];
	N2MinMax x = N2MakeMinMax([[points objectAtIndex:0] x]);
	N2MinMax y = N2MakeMinMax([[points objectAtIndex:0] y]);
	for (MyPoint* p in points) {
		N2ExtendMinMax(x, p.x);
		N2ExtendMinMax(y, p.y);
	}
	
	NSRect space = NSMakeRect(x.min, y.min, x.max-x.min, y.max-y.min), squareSpace;
	squareSpace.size = NSMakeSize(std::max(space.size.width, space.size.height));
	squareSpace.origin = space.origin - (squareSpace.size-space.size)/2;
	squareSpace = NSInsetRect(squareSpace, -squareSpace.size.width/100, -squareSpace.size.height/100);
	
	NSSize size = NSMakeSize(256);
	NSImage* image = [[NSImage alloc] initWithSize:size];
	
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform scaleXBy:1 yBy:-1];
	[transform translateXBy:0 yBy:-[image size].height];
	[transform translateXBy:-squareSpace.origin.x*size.width/squareSpace.size.width yBy:-squareSpace.origin.y*size.height/squareSpace.size.height];
	[transform scaleXBy:size.width/squareSpace.size.width yBy:size.height/squareSpace.size.height];
	
	for (ROI* roi in rois)
		[self drawRoi:roi onImage:image withColor:[NSColor redColor] usingTransform:transform];
			
	return [image autorelease];
}

@end

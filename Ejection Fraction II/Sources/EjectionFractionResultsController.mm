//
//  EjectionFractionResultsController.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 02.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionResultsController.h"
#import "EjectionFractionWorkflow.h"
#import "EjectionFractionAlgorithm.h"
#import <Nitrogen/N2ColumnLayout.h>
#import <Nitrogen/N2ColumnDescriptor.h>
#import <Nitrogen/NSTextView+N2.h>
#import <Nitrogen/N2View.h>
#import <Nitrogen/N2Window.h>
#import <Nitrogen/NSImageView+N2.h>

@interface EjectionFractionResultsController (Private)

-(NSImage*)imageFromRois:(NSArray*)rois;

@end

@implementation EjectionFractionResultsController

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow {
	self = [super initWithWindow:[[N2Window alloc] initWithContentRect:NSZeroRect styleMask:NSTitledWindowMask|NSClosableWindowMask|NSTexturedBackgroundWindowMask backing:NSBackingStoreBuffered defer:YES]];
	[[self window] setTitle:@"Ejection Fraction: Results"];
	
	N2ColumnLayout* contentLayout = [[N2ColumnLayout alloc] initForView:[[self window] contentView] columnDescriptors:[NSArray arrayWithObject:[N2ColumnDescriptor descriptor]] controlSize:NSRegularControlSize];
	[contentLayout setForcesSuperviewWidth:YES];
	[contentLayout setForcesSuperviewHeight:YES];
	
	// header
	
	N2View* header = [[N2View alloc] initWithSize:NSZeroSize];
	N2ColumnLayout* headerLayout = [[N2ColumnLayout alloc] initForView:header columnDescriptors:[NSArray arrayWithObjects:[N2ColumnDescriptor descriptor], [N2ColumnDescriptor descriptor], NULL] controlSize:NSSmallControlSize];
	[headerLayout setMargin:NSZeroRect];
	[headerLayout setForcesSuperviewHeight:YES];
	[headerLayout setForcesSuperviewWidth:YES];
	
	[headerLayout appendLine:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Patient ID:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"TESTTESTTEST"], NULL]];
	[headerLayout appendLine:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Name:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"Aless Aless Aless"], NULL]];
	[headerLayout appendLine:[NSArray arrayWithObjects:
							  [NSTextView labelWithText:@"Date of Birth:" alignment:NSRightTextAlignment],
							  [NSTextView labelWithText:@"12/05/1981"], NULL]];
	
	[contentLayout appendLine:[NSArray arrayWithObject:header]];
	
	// separator
	
	NSBox* separator = [[NSBox alloc] initWithSize:NSMakeSize(10, 5)];
	[separator setBoxType:NSBoxSeparator];
	[contentLayout appendLine:[NSArray arrayWithObject:separator]];
	
	// body
	
	N2View* body = [[N2View alloc] initWithSize:NSZeroSize];
	N2ColumnLayout* bodyLayout = [[N2ColumnLayout alloc] initForView:body columnDescriptors:[NSArray arrayWithObjects:[N2ColumnDescriptor descriptor], [N2ColumnDescriptor descriptor], NULL] controlSize:NSSmallControlSize];
	[bodyLayout setMargin:NSZeroRect];
	[bodyLayout setForcesSuperviewHeight:YES];
	[bodyLayout setForcesSuperviewWidth:YES];
	
	for (NSArray* group in [[workflow algorithm] groupedRoiIds])
		[headerLayout appendLine:[NSArray arrayWithObjects:
								  [NSImageView createWithImage:[self imageFromRois:[workflow roisForIds:group]]], NULL]];
	
	[contentLayout appendLine:[NSArray arrayWithObject:body]];

//	[headerLayout layOut];
//	[contentLayout layOut];
	[[self window] makeKeyAndOrderFront:self];
	
	return self;
}

-(NSImage*)imageFromRois:(NSArray*)rois {
	return NULL;
}

@end

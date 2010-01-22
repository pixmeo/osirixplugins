//
//  EjectionFractionStepsController.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 7/20/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionPlugin.h"
#import "EjectionFractionStepsController.h"
#import "EjectionFractionWorkflow.h"
#import "EjectionFractionWorkflow+OsiriX.h"
#import <Nitrogen/N2Operators.h>
#import <Nitrogen/N2ColumnLayout.h>
#import <Nitrogen/N2Resizer.h>
#import <Nitrogen/N2Button.h>
#import <Nitrogen/N2Step.h>
#import <Nitrogen/N2CellDescriptor.h>
#import <Nitrogen/N2Steps.h>
#import <Nitrogen/N2View.h>
#import <Nitrogen/N2Debug.h>

@interface EjectionFractionStepsController (Private)
-(void)algorithmSelected:(NSMenuItem*)selection;
@end

@implementation EjectionFractionStepsController
@synthesize stepsView = _stepsView, stepResult = _stepResult;

-(id)initWithWorkflow:(EjectionFractionWorkflow*)workflow {
	self = [self initWithWindowNibName:@"EjectionFractionSteps"];
	_workflow = workflow;
//	_activeSteps = [NSMutableArray arrayWithCapacity:8];
	
	[[self window] setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workflowRoiAssigned:) name:EjectionFractionWorkflowROIAssignedNotification object:workflow];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(workflowExpectedRoiChanged:) name:EjectionFractionWorkflowExpectedROIChangedNotification object:workflow];
	
	// place at viewer window upper right corner
	NSRect frame = [[self window] frame];
	NSRect screen = [[[[[ViewerController getDisplayed2DViewers] objectAtIndex:0] window] screen] frame];
	frame.origin.x = screen.origin.x+screen.size.width-frame.size.width;
	frame.origin.y = screen.origin.y+screen.size.height-frame.size.height;
	[[self window] setFrame:frame display:YES];	
	
	return self;
}

-(NSString*)windowFrameAutosaveName {
	return [self className];
}

-(void)addAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	NSMenuItem* item = [[[NSMenuItem alloc] initWithTitle:[algorithm description] action:@selector(algorithmSelected:) keyEquivalent:@""] autorelease];
	[item setRepresentedObject:algorithm];
	[[_viewAlgorithmChoice menu] addItem:item];
	if ([_viewAlgorithmChoice numberOfItems] == 1)
		[self algorithmSelected:item];
}

-(void)awakeFromNib {
	_checkmarkImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Checkmark" ofType:@"png"]];
	_arrowImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Arrow" ofType:@"png"]];
	
	_viewAlgorithmOriginalFrameHeight = [_viewAlgorithm frame].size.height;
	_viewROIsTextFormat = [[_viewROIsText stringValue] retain];
	_viewResultTextFormat = [[_viewResultText stringValue] retain];
	
	_stepROIsResizer = [[N2Resizer alloc] initByObservingView:_viewROIsList affecting:_viewROIs];
	
	[_stepsView setForeColor:[NSColor whiteColor]];
	[_stepsView setControlSize:NSSmallControlSize];
	
	[_viewROIsList setForeColor:[NSColor whiteColor]];
	N2CellDescriptor* invasiveColDesc = [[N2CellDescriptor descriptor] alignment:N2Left];
	if ([invasiveColDesc respondsToSelector:@selector(setInvasivity:)]) [invasiveColDesc setInvasivity:1];
	NSArray* columnDescriptors = [NSArray arrayWithObjects: [[N2CellDescriptor descriptor] alignment:N2Right], invasiveColDesc, NULL]; // , [N2CellDescriptor descriptor]
	N2ColumnLayout* layout = [[[N2ColumnLayout alloc] initForView:_viewROIsList columnDescriptors:columnDescriptors controlSize:NSMiniControlSize] autorelease];
	[layout setForcesSuperviewHeight:YES];
	[layout setMargin:NSZeroRect];
	[layout setSeparation:NSMakeSize(2,1)];

	[_steps addObject: _stepAlgorithm = [[[N2Step alloc] initWithTitle:@"Algorithm" enclosedView:_viewAlgorithm] autorelease]];
	[_stepAlgorithm setShouldStayVisibleWhenInactive:YES];
	
	[_steps addObject: _stepROIs = [[[N2Step alloc] initWithTitle:@"ROIs" enclosedView:_viewROIs] autorelease]];
	[_stepROIs setActive:YES];
	
	for (EjectionFractionAlgorithm* algorithm in [[_workflow plugin] algorithms]) [self addAlgorithm:algorithm];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(algorithmAddedNotification:) name:EjectionFractionAlgorithmAddedNotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(algorithmRemovedNotification:) name:EjectionFractionAlgorithmRemovedNotification object:NULL];	
	
	[_steps addObject: _stepResult = [[[N2Step alloc] initWithTitle:@"Result" enclosedView:_viewResult] autorelease]];
//	[_stepAlgorithm setShouldStayVisibleWhenInactive:YES];
}

-(void)dealloc {
	[_stepROIsResizer release];
	DLog(@"%X [EjectionFractionStepsController dealloc]", self);
	[_viewROIsTextFormat release];
	[_viewResultTextFormat release];
//	[_activeSteps release];
	[_checkmarkImage release];
	[_arrowImage release];
	[super dealloc];
}

-(void)windowWillClose:(NSNotification*)notification {
	//[self autorelease];
}

-(void)algorithmAddedNotification:(NSNotification*)notification {
	EjectionFractionAlgorithm* algorithm = [notification object];
	[self addAlgorithm:algorithm];
}

-(void)algorithmRemovedNotification:(NSNotification*)notification {
	EjectionFractionAlgorithm* algorithm = [notification object];
	[_viewAlgorithmChoice removeItemWithTitle:[algorithm description]];
}

-(void)algorithmSelected:(NSMenuItem*)selection {
	[_workflow setAlgorithm:[selection representedObject]];
}

-(void)setSelectedAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	for (NSMenuItem* item in [[_viewAlgorithmChoice menu] itemArray])
		if ([item representedObject]  == algorithm) {
			[_viewAlgorithmChoice selectItem:item];
			break;
		}
	
	[_viewROIsText setStringValue:[NSString stringWithFormat:_viewROIsTextFormat, [algorithm description]]];
	
	[[_viewROIsList layout] setEnabled:NO];
	[(N2ColumnLayout*)[_viewROIsList layout] removeAllRows];
	for (int i = 0; i < 2; ++i) {
		NSTextView* sect = [[[NSTextView alloc] initWithFrame:NSZeroRect] autorelease];
		[sect setString:[NSString stringWithFormat:@"%@:", !i? Dias : Syst ]];
		[sect setSelectable:NO];
		[sect setAlignment:NSRightTextAlignment range:NSMakeRange(0, [[sect string] length])];
		[sect setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
		NSColorWell* colr = [[[NSColorWell alloc] initWithSize:NSMakeSize(32,10)] autorelease];
		[colr setColor: !i? [EjectionFractionPlugin diasColor] : [EjectionFractionPlugin systColor]];
		[colr setBordered:NO];
		[colr setHidden:YES]; /// TODO: show this control and handle it
		[(N2ColumnLayout*)[_viewROIsList layout] appendRow:[NSArray arrayWithObjects: sect, colr, NULL]]; // image
		NSArray* groups = [algorithm groupedRoiIds];
		for (NSString* roiId in [groups objectAtIndex:i]) {
			NSString* title = [[roiId substringFromIndex:[roiId rangeOfString:@" "].location+1] capitalizedString];
			
			//NSTextView* text = [[[NSTextView alloc] initWithFrame:NSZeroRect] autorelease];
			//[text setString:roiId];
			//[text setSelectable:NO];
			//[text setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
			
			N2Button* button = [[[N2Button alloc] initWithFrame:NSZeroRect] autorelease];
			[button setTitle:title];
			[button setRepresentedObject:roiId];
			[button setBezelStyle:NSRecessedBezelStyle];
			[[button cell] setControlSize:NSMiniControlSize];
			[button setFont:[NSFont labelFontOfSize:[NSFont systemFontSizeForControlSize:NSMiniControlSize]]];
			[button setImagePosition:NSImageLeft];
			
			[button setTarget:self];
			[button setAction:@selector(roiButtonClicked:)];
			
			if ([_workflow roiForId:roiId])
				[button setImage:_checkmarkImage];
			
			[(N2ColumnLayout*)[_viewROIsList layout] appendRow:[NSArray arrayWithObject:[[N2CellDescriptor descriptorWithView:button] colSpan:2]]]; // image
		}
	}
	
	[[_viewROIsList layout] setEnabled:YES];
	[[_viewROIsList layout] layOut];
	
	[_stepAlgorithm setDone:YES];
	[_steps setCurrentStep:_stepROIs];
}

-(void)setResult:(CGFloat)ef {
	[_viewResultText setStringValue:[NSString stringWithFormat:_viewResultTextFormat, ef*100]];
	[_stepResult setActive: ef > 0];
}

-(void)updateButtons {
	NSString* roiId = [_workflow expectedRoiId];

	for (N2Button* view in [_viewROIsList subviews])
		if ([view isKindOfClass:[N2Button class]])
			if ([_workflow roiForId:[view representedObject]])
				[view setImage:_checkmarkImage];
			else if ([[view representedObject] isEqualToString:roiId])
				[view setImage:_arrowImage];
			else 
				[view setImage:NULL];
}

-(void)workflowRoiAssigned:(NSNotification*)notification {
	[self updateButtons];
}

-(void)workflowExpectedRoiChanged:(NSNotification*)notification {
	[self updateButtons];
}

-(void)steps:(N2Steps*)steps willBeginStep:(N2Step*)step {
}

-(void)steps:(N2Steps*)steps valueChanged:(id)sender {
}

-(BOOL)steps:(N2Steps*)steps shouldValidateStep:(N2Step*)step {
	return NO;
}

-(void)steps:(N2Steps*)steps validateStep:(N2Step*)step {
}

-(void)roiButtonClicked:(N2Button*)source {
//	DLog(@"EjectionFraction - ROI button clicked: %@, %d", [source representedObject], [[_workflow algorithm] typeForRoiId:[source representedObject]]);
	[_workflow selectOrOpenViewerForRoiWithId:[source representedObject]];
}

-(void)detailsButtonClicked:(id)sender {
	[_workflow showDetails];
}

/*
 
 NSImage* image = name? [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"png"]] autorelease] : NULL;
 
 NSSize size = NSMakeSize([_viewAlgorithmPreview frame].size.width, 0);
 if (image) {
 NSSize imageSize = [image size];
 size.height = ceilf(imageSize.height/imageSize.width*size.width);
 }
 
 [_viewAlgorithmPreview setFrameSize:size];
 [_viewAlgorithmPreview setImage:image];
 
 if (image)
 size.height += 10;
 
 [_viewAlgorithm setFrameSize:NSMakeSize([_viewAlgorithm frame].size.width, _viewAlgorithmOriginalFrameHeight+size.height)];
 
 */

@end

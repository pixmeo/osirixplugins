//
//  ArthroplastyTemplatingWindowController.m
//  Arthroplasty Templating II
//  Created by Joris Heuberger on 04/04/07.
//  Copyright (c) 2007-2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingWindowController.h"
#import "ArthroplastyTemplatingStepsController.h"
#import <OsiriXAPI/BrowserController.h>
#import <OsiriXAPI/ViewerController.h>
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/NSImage+N2.h>
#import <OsiriXAPI/N2Operators.h>
#import "ArthroplastyTemplateFamily.h"
#import "ArthroplastyTemplatingPlugin.h"
#include <cmath>
#include <algorithm>
#include <OsiriXAPI/Notifications.h>
#import "ArthroplastyTemplatingWindowController+Color.h"
#import "ArthroplastyTemplatingWindowController+Templates.h"
#import "ArthroplastyTemplatingWindowController+OsiriX.h"
#import "NSBitmapImageRep+ArthroplastyTemplating.h"

@implementation ArthroplastyTemplatingWindowController
@synthesize userDefaults = _userDefaults, plugin = _plugin;

-(id)initWithPlugin:(ArthroplastyTemplatingPlugin*)plugin {
	self = [self initWithWindowNibName:@"HipArthroplastyTemplatingWindow"];
	_plugin = plugin;
	
	_viewDirection = ArthroplastyTemplateAnteriorPosteriorDirection;
	
	_userDefaults = [[ArthroplastyTemplatingUserDefaults alloc] init];
	NSBundle* bundle = [NSBundle bundleForClass:[self class]];
	_presets = [[NSDictionary alloc] initWithContentsOfFile:[bundle pathForResource:[bundle bundleIdentifier] ofType:@"plist"]];
	
	_templates = [[NSMutableArray arrayWithCapacity:0] retain];
	_familiesArrayController = [[NSArrayController alloc] init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(performOsirixDragOperation:) name:OsirixPerformDragOperationNotification object:NULL];
	
	return self;
}

-(void)awakeFromNib {
	[self awakeColor];
	[_familiesArrayController setSortDescriptors:[_familiesTableView sortDescriptors]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfViewDocumentDidChange:) name:SelectablePDFViewDocumentDidChangeNotification object:_pdfView];
	[self awakeTemplates];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_familiesArrayController release];
//	[_families release];
	[_templates release];
	[_presets release];
	[_userDefaults release];
	[super dealloc];
}

-(NSString*)windowFrameAutosaveName {
	return @"ArthroplastyTemplatingWindow";
}

-(void)windowWillClose:(NSNotification *)aNotification {
	// [self release];
}

//-(NSSize)windowWillResize:(NSWindow*)window toSize:(NSSize)size {
//	return NSMakeSize(std::max(size.width, 208.f), std::max(size.height, 200.f));
//}

#pragma mark PDF preview

-(NSString*)pdfPathForFamilyAtIndex:(int)index {
	return index != -1? [[[self familyAtIndex:index] template:[_sizes indexOfSelectedItem]] pdfPathForDirection:_viewDirection] : NULL;//[[NSBundle bundleForClass:[self class]] pathForResource:@"empty" ofType:@"pdf"];
}

-(void)setFamily:(id)sender {
	if (sender == _familiesTableView) { // update sizes menu
		if ([_familiesTableView numberOfRows]) {
			[_familiesArrayController setSelectionIndex:[_familiesTableView selectedRow]];
			
			float selectedSize = [[_sizes titleOfSelectedItem] floatValue];
			[_sizes removeAllItems];
			ArthroplastyTemplateFamily* family = [self selectedFamily];
			float diffs[[[family templates] count]];
			for (NSUInteger fti = 0; fti < [[family templates] count]; ++fti) {
				ArthroplastyTemplate* ft = [[family templates] objectAtIndex:fti];
				NSString* size = [ft size];
				[_sizes addItemWithTitle:size];
				float currentSize = [size floatValue];
				diffs[fti] = fabsf(selectedSize-currentSize);
			}
			
			unsigned index = 0;
			for (unsigned i = 1; i < [[family templates] count]; ++i)
				if (diffs[i] < diffs[index])
					index = i;
			[_sizes selectItemAtIndex:index];
		} else
			[_pdfView setDocument:NULL];
	}
	
	if ([_familiesTableView selectedRow] < 0)
		if ([[_familiesArrayController arrangedObjects] count])
			[_familiesTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
		else return;
	
	NSString* pdfPath = [self pdfPathForFamilyAtIndex:[_familiesTableView selectedRow]];
	PDFDocument* doc = pdfPath? [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath]] : NULL;
	
//	[_pdfView setAutoScales:NO];
	[_pdfView setDocument:doc];
//	[_pdfView setAutoScales:YES];
	
	if (!doc && _viewDirection == ArthroplastyTemplateLateralDirection) {
		[_viewDirectionControl setSelectedSegment:ArthroplastyTemplateAnteriorPosteriorDirection];
		[self setViewDirection:_viewDirectionControl];
	}
}

-(NSString*)idForTemplate:(ArthroplastyTemplate*)templat {
	if (_viewDirection == ArthroplastyTemplateAnteriorPosteriorDirection)
		return [NSString stringWithFormat:@"%@/%@/%@", [templat manufacturer], [templat name], [templat size]];
	else return [NSString stringWithFormat:@"%@/%@/%@/Lateral", [templat manufacturer], [templat name], [templat size]];
}

-(BOOL)selectionForTemplate:(ArthroplastyTemplate*)templat into:(NSRect*)rect {
	NSRect temp;
	NSString* key = [self idForTemplate:templat];
	if ([_userDefaults keyExists:key])
		temp = [_userDefaults rect:key otherwise:NSZeroRect];
	else if ([_presets valueForKey:key]) {
		temp = [ArthroplastyTemplatingUserDefaults NSRectFromData:[_presets valueForKey:key] otherwise:NSZeroRect];
	} else return NO;
	if (temp.size.width < 0) { temp.origin.x += temp.size.width; temp.size.width = -temp.size.width; }
	if (temp.size.height < 0) { temp.origin.y += temp.size.height; temp.size.height = -temp.size.height; }
	memcpy(rect, &temp, sizeof(NSRect));
	return YES;	
}

-(BOOL)selectionForCurrentTemplate:(NSRect*)rect {
	return [self selectionForTemplate:[self currentTemplate] into:rect];
}

-(void)setSelectionForCurrentTemplate:(NSRect)rect {
	[_userDefaults setRect:rect forKey:[self idForTemplate:[self currentTemplate]]];
}

-(void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	[self setFamily:_familiesTableView];
}

-(N2Image*)templateImage:(ArthroplastyTemplate*)templat entirePageSizePixels:(NSSize)size color:(NSColor*)color {
	N2Image* image = [[N2Image alloc] initWithContentsOfFile:[templat pdfPathForDirection:_viewDirection]];
	NSSize imageSize = [image size];
	
	// size.width OR size.height can be qual to zero, in which case the zero value is set corresponding to the available value
	if (!size.width)
		size.width = std::floor(size.height/imageSize.height*imageSize.width);
	if (!size.height)
		size.height = std::floor(size.width/imageSize.width*imageSize.height);
	
	[image setScalesWhenResized:YES];
	[image setSize:size];
	
	// extract selected part
	NSRect sel; if ([self selectionForTemplate:templat into:&sel]) {
		sel = NSMakeRect(std::floor(sel.origin.x*size.width), std::floor(sel.origin.y*size.height), std::ceil(sel.size.width*size.width), std::ceil(sel.size.height*size.height));
		N2Image* temp = [image crop:sel];
		[image release];
		image = [temp retain];
	}
	
	if ([self mustFlipHorizontally])
		[image flipImageHorizontally];

	N2Image* temp = [[N2Image alloc] initWithSize:[image size] inches:[image inchSize] portion:[image portion]];
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];

	[bitmap detectAndApplyBorderTransparency:8];
	if (color)
		[bitmap setColor:color];

	[temp addRepresentation:bitmap];
	[bitmap release];
	
	[image release];
	image = temp;

	return [image autorelease];
}

-(N2Image*)templateImage:(ArthroplastyTemplate*)templat entirePageSizePixels:(NSSize)size {
	return [self templateImage:templat entirePageSizePixels:size color:[_shouldTransformColor state]? [_transformColor color] : NULL];
}

-(N2Image*)templateImage:(ArthroplastyTemplate*)templat {
	if ([_familiesTableView selectedRow] == -1) return NULL;
	PDFPage* page = [_pdfView currentPage];
	NSRect pageBox = [_pdfView convertRect:[page boundsForBox:kPDFDisplayBoxMediaBox] fromPage:page];
	pageBox.size = n2::round(pageBox.size);
	return [self templateImage:templat entirePageSizePixels:pageBox.size];
}

-(N2Image*)dragImageForTemplate:(ArthroplastyTemplate*)templat {
	return [self templateImage:templat];
}

#pragma mark Template View direction

- (IBAction)setViewDirection:(id)sender; {
	_viewDirection = ArthroplastyTemplateViewDirection([sender selectedSegment]);
	[self setFamily:_familiesTableView];
}


#pragma mark Flip Left/Right

-(IBAction)setSideAction:(id)sender; {
	[_pdfView setNeedsDisplay:YES];
}

-(ATSide)side {
	return ATSide([_sideControl selectedSegment]);
}

-(void)setSide:(ATSide)side {
	if (side != [self side]) {
		[_sideControl setSelectedSegment:side];
		[self setSideAction:_sideControl];
	}
}

-(BOOL)mustFlipHorizontally {
	//NSLog(@"mfh if %d != %d", [self side], [[self currentTemplate] side]);
	return [self side] != [[self currentTemplate] side];
}

#pragma mark Drag&Drop

-(void)addTemplate:(ArthroplastyTemplate*)templat toPasteboard:(NSPasteboard*)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:pasteBoardOsiriXPlugin, @"ArthroplastyTemplate*", NULL] owner:self];
	[pboard setData:[NSData dataWithBytes:&templat length:sizeof(ArthroplastyTemplate*)] forType:@"ArthroplastyTemplate*"];
}

- (BOOL)tableView:(NSTableView*)tv writeRowsWithIndexes:(NSIndexSet*)rowIndexes toPasteboard:(NSPasteboard*)pboard {
	[self addTemplate:[[self familyAtIndex:[rowIndexes firstIndex]] template:[_sizes indexOfSelectedItem]] toPasteboard:pboard];
	return YES;
}

-(void)dragTemplate:(ArthroplastyTemplate*)templat startedByEvent:(NSEvent*)event onView:(NSView*)view {
	NSPasteboard* pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	[self addTemplate:templat toPasteboard:pboard];
	
	N2Image* image = [self dragImageForTemplate:templat];
	
	NSPoint click = [view convertPoint:[event locationInWindow] fromView:NULL];
	
	NSSize size = [image size];
	NSPoint o = NSMakePoint(size)/2;
	if ([templat origin:&o forDirection:_viewDirection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if ([self mustFlipHorizontally])
			o.x = size.width-o.x;
	}

	[view dragImage:image at:click-o-NSMakePoint(1,-3) offset:NSMakeSize(0,0) event:event pasteboard:pboard source:view slideBack:YES];
}

-(ROI*)createROIFromTemplate:(ArthroplastyTemplate*)templat inViewer:(ViewerController*)destination centeredAt:(NSPoint)p {
	N2Image* image = [self templateImage:templat entirePageSizePixels:NSMakeSize(0,1800)]; // TODO: N -> adapted size
	
//	CGFloat magnification = [[_plugin windowControllerForViewer:destination] magnification];
//	if (!magnification) magnification = 1;
	float pixSpacing = (1.0 / [image resolution] * 25.4); // image is in 72 dpi, we work in milimeters
	
	ROI* newLayer = [destination addLayerRoiToCurrentSliceWithImage:image referenceFilePath:[templat path] layerPixelSpacingX:pixSpacing layerPixelSpacingY:pixSpacing];
	
//	[[newLayer pix] setPixel ];
	
	[destination bringToFrontROI:newLayer];
	[newLayer generateEncodedLayerImage];
	
	// find the center of the template
	NSSize imageSize = [image size];
	NSPoint imageCenter = NSMakePoint(imageSize/2);
	NSPoint o;
	if ([templat origin:&o forDirection:_viewDirection]) { // origin in inches
		o = [image convertPointFromPageInches:o];
		if ([self mustFlipHorizontally])
			o.x = imageSize.width-o.x;
		imageCenter = o;
		imageCenter.y = imageSize.height-imageCenter.y;
	}
	
	NSArray *layerPoints = [newLayer points];
	NSPoint layerSize = [[layerPoints objectAtIndex:2] point] - [[layerPoints objectAtIndex:0] point];
	
	NSPoint layerCenter = imageCenter/imageSize*layerSize;
	[[newLayer points] addObject:[MyPoint point:layerCenter]]; // center, index 4

	[newLayer setROIMode:ROI_selected]; // in order to make the roiMove method possible
	[newLayer rotate:[templat rotation]/pi*180*([self mustFlipHorizontally]?-1:1) :layerCenter];

	[[newLayer points] addObject:[MyPoint point:layerCenter+NSMakePoint(1,0)]]; // rotation reference, index 5
	
	// stem-cup magnets, indexes 6, 7, 8, 9, 10 for S, M, L, XL, XXL
	for (NSValue* value in [templat headRotationPointsForDirection:_viewDirection]) {
		NSPoint point = [value pointValue];
		point = [image convertPointFromPageInches:point];
		if ([self mustFlipHorizontally])
			point.x = imageSize.width-point.x;
		point.y = imageSize.height-point.y;
		point = point/imageSize*layerSize;
		[[newLayer points] addObject:[MyPoint point:point]];
	}
	
	// proximal-distal magnets, indexes 11, 12, 13, 14 for A, A2, B, B2; currently only A and A2 seem to be used
	for (NSValue* value in [templat matingPointsForDirection:_viewDirection]) {
		NSPoint point = [value pointValue];
		point = [image convertPointFromPageInches:point];
		if ([self mustFlipHorizontally])
			point.x = imageSize.width-point.x;
		point.y = imageSize.height-point.y;
		point = point/imageSize*layerSize;
		[[newLayer points] addObject:[MyPoint point:point]];
	}
	
	[newLayer roiMove:p-layerCenter :YES];
	
	// set the textual data
	[newLayer setName:[templat name]];
	NSArray *lines = [templat textualData];
	if([lines objectAtIndex:0]) [newLayer setTextualBoxLine1:[lines objectAtIndex:0]];
	if([lines objectAtIndex:1]) [newLayer setTextualBoxLine2:[lines objectAtIndex:1]];
	if([lines objectAtIndex:2]) [newLayer setTextualBoxLine3:[lines objectAtIndex:2]];
	if([lines objectAtIndex:3]) [newLayer setTextualBoxLine4:[lines objectAtIndex:3]];
	if([lines objectAtIndex:4]) [newLayer setTextualBoxLine5:[lines objectAtIndex:4]];

	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:newLayer userInfo: nil];
	
	return newLayer;
}

-(void)performOsirixDragOperation:(NSNotification*)notification {
	NSDictionary* userInfo = [notification userInfo];
	id <NSDraggingInfo> operation = [userInfo valueForKey:@"id<NSDraggingInfo>"];

	if (![[operation draggingPasteboard] dataForType:@"ArthroplastyTemplate*"])
		return; // no ArthroplastyTemplate pointer available
	if ([operation draggingSource] != _pdfView && [operation draggingSource] != _familiesTableView)
		return;
	
	ViewerController* destination = [notification object];
	
	ArthroplastyTemplate* templat; [[[operation draggingPasteboard] dataForType:@"ArthroplastyTemplate*"] getBytes:&templat length:sizeof(ArthroplastyTemplate*)];

	// find the location of the mouse in the OpenGL view
	NSPoint openGLLocation = [[destination imageView] ConvertFromNSView2GL:[[destination imageView] convertPoint:[operation draggingLocation] fromView:NULL]];
	
	[self createROIFromTemplate:templat inViewer:destination centeredAt:openGLLocation];
	
	[[destination window] makeKeyWindow];
	
	return;
}

- (NSRect)addMargin:(int)pixels toRect:(NSRect)rect;
{
	float x = rect.origin.x - pixels;
	if(x<0) x=0;
	float y = rect.origin.y - pixels;
	if(y<0) y=0;
	float width = rect.size.width + 2 * pixels;
	float height = rect.size.height + 2 * pixels;
	
	return NSMakeRect(x, y, width, height);
}

#pragma mark NSTableDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView*)table {
	return [[_familiesArrayController arrangedObjects] count];
}

- (id)tableView:(NSTableView*)table objectValueForTableColumn:(NSTableColumn*)col row:(NSInteger)i {
	return [[[_familiesArrayController arrangedObjects] objectAtIndex:i] performSelector:sel_registerName([[col identifier] UTF8String])];
}

- (void)tableView:(NSTableView*)table sortDescriptorsDidChange:(NSArray*)oldDescriptors {
	[_familiesArrayController setSortDescriptors:[_familiesTableView sortDescriptors]];
	[_familiesArrayController rearrangeObjects];
	[_familiesTableView selectRowIndexes:[_familiesArrayController selectionIndexes] byExtendingSelection:NO];
}

#pragma mark New

-(void)pdfViewDocumentDidChange:(NSNotification*)notification {
	BOOL enable = [_pdfView document] != NULL;
	[_sideControl setEnabled:enable];
	[_sizes setEnabled:enable];
}

@end

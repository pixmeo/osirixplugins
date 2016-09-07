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

#define OSIRIX_VIEWER

#import "RoiEnhancementChart.h"
#import <OsiriXAPI/DCMPix.h>
#import <GRAxes.h>
#import <GRLineDataSet.h>
#import "RoiEnhancementAreaDataSet.h"
#import "RoiEnhancementInterface.h"
#import <OsiriXAPI/ViewerController.h>
#import "RoiEnhancementROIList.h"
#import <OsiriXAPI/ROI.h>
#import <OsiriXAPI/DCMView.h>
#import <OsiriXAPI/DCMPix.h>
#import <OsiriXAPI/DicomImage.h>
#import "RoiEnhancementOptions.h"

@implementation RoiEnhancementChart
@synthesize xMin = _xMin, xMax = _xMax, drawsLegend = _drawsLegend, drawsBackground = _drawsBackground, stopDraw = _stopDraw;

-(void)awakeFromNib {
	[super awakeFromNib];
	
	_areaDataSets = [[NSMutableArray arrayWithCapacity:0] retain];
	_plotValues = [[NSMutableArray arrayWithCapacity:0] retain];
	_cache = [[NSMutableDictionary dictionaryWithCapacity:128] retain];
	
	[self setDelegate:self];
	[self setDataSource:self];

	[self setProperty:[NSNumber numberWithBool:NO] forKey:GRChartDrawBackground];
	[[self axes] setProperty:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]] forKey:GRAxesLabelFont];
	[[self axes] setProperty:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]] forKey:GRAxesLabelFont];
	[[self axes] setProperty:[NSArray array] forKey:GRAxesMinorLineDashPattern];
}

-(void)dealloc {
	[_plotValues release]; _plotValues = NULL;
	[_areaDataSets release]; _areaDataSets = NULL;
	[_cache release]; _cache = NULL;
	[super dealloc];
}

-(void)resetCursorRects {
	[self addCursorRect:[self bounds] cursor:[NSCursor crosshairCursor]];
}

-(void)constrainXRangeFrom:(unsigned)min to:(unsigned)max {
	_xMin = min; _xMax = max;
	[[self axes] setProperty:[NSNumber numberWithFloat:_xMin] forKey:GRAxesXPlotMin];
	[[self axes] setProperty:[NSNumber numberWithFloat:_xMin] forKey:GRAxesFixedXPlotMin];
	[[self axes] setProperty:[NSNumber numberWithFloat:_xMax] forKey:GRAxesXPlotMax];
	[[self axes] setProperty:[NSNumber numberWithFloat:_xMax] forKey:GRAxesFixedXPlotMax];
}

-(GRLineDataSet*)createOwnedLineDataSet {
	GRLineDataSet* dataSet = [[GRLineDataSet alloc] initWithOwnerChart:self];
	[dataSet setProperty:[NSNumber numberWithBool:NO] forKey:GRDataSetDrawMarkers];
	return [dataSet autorelease];
}

-(RoiEnhancementAreaDataSet*)createOwnedAreaDataSetFrom:(GRLineDataSet*)min to:(GRLineDataSet*)max {
	return [[[RoiEnhancementAreaDataSet alloc] initWithOwnerChart:self min:min max:max] autorelease];
}

-(void)refresh:(RoiEnhancementROIRec*)roiRec {
	// Set the color of the plot
	if (roiRec) {
		RGBColor rgb = [[roiRec roi] rgbcolor];
		NSColor* color = [NSColor colorWithDeviceRed:float(rgb.red)/0xffff green:float(rgb.green)/0xffff blue:float(rgb.blue)/0xffff alpha:1];
		[[roiRec minDataSet] setProperty:color forKey:GRDataSetPlotColor];
		[[roiRec meanDataSet] setProperty:color forKey:GRDataSetPlotColor];
		[[roiRec maxDataSet] setProperty:color forKey:GRDataSetPlotColor];
		// cache
		[_cache removeObjectForKey:[roiRec roi]];
		// TODO: the NAME in legend
	}
	
	if (!roiRec)
		[_cache removeAllObjects];
	
	[self setNeedsToReloadData:YES];
}

-(void)mouseDown:(NSEvent*)theEvent
{
	_tracking = YES;
	[NSCursor hide];
	
	[self mouseDragged:theEvent];
	[[self window] makeFirstResponder: self];
}

-(void)mouseDragged:(NSEvent*)theEvent {
	_mousePoint = [self convertPointFromBase:[theEvent locationInWindow]]; _newPlotValue = -1;
	[self setNeedsDisplay:YES];
}

-(void)mouseUp:(NSEvent*)theEvent {
	
	_tracking = false;
	if (_newPlotValue != -1)
		[_plotValues addObject:[NSNumber numberWithFloat:_newPlotValue]];
	_newPlotValue = -1;
	
	if ([theEvent clickCount] == 2)
		[_plotValues removeAllObjects];
	
	[NSCursor unhide];
	[self setNeedsDisplay:YES];
}

// GRChartView delegate/dataSource

-(NSInteger)chart:(GRChartView*)chart numberOfElementsForDataSet:(GRDataSet*)dataSet
{
	if ([[_interface options] xRangeMode] == XRange4thDimension)
    {
//        ROISel roiSel;
//        RoiEnhancementROIRec* roiRec = [[_interface roiList] findRecordByDataSet:dataSet sel:&roiSel];
        
//        DicomImage *start = [[[_interface viewer] fileList: 0] objectAtIndex: roiRec.roiIndexPixList];
//        DicomImage *end = [[[_interface viewer] fileList: [[_interface viewer] maxMovieIndex] -1] objectAtIndex: roiRec.roiIndexPixList];
//        
//        NSLog( @"start: %@", start.date);
//        NSLog( @"end: %@", end.date);
//        NSLog( @"seconds: %f", [end.date timeIntervalSinceReferenceDate] - [start.date timeIntervalSinceReferenceDate]);
        
        
		return [[_interface viewer] maxMovieIndex];
    }
	else
		return [[[_interface viewer] pixList] count];
}

-(void)yValueForROIRec:(RoiEnhancementROIRec*)roiRec element:(NSInteger)element min:(float*)min mean:(float*)mean max:(float*)max
{
	NSString *keyPix = nil;
    
    if( [[roiRec roi] type] == tBall) // tBall not supported, except in 4th Dimension
    {
        if( [[_interface options] xRangeMode] != XRange4thDimension)
        {
            if( mean)
                *mean = 0;
            
            if( min)
                *min = 0;
            
            if( max)
                *max = 0;
            
            return;
        }
    }
    
	if( [[_interface options] xRangeMode] == XRange4thDimension)
		keyPix = [NSString stringWithFormat: @"%lX", (unsigned long) [[_interface viewer] pixList: element]];
	else
        keyPix = [NSString stringWithFormat: @"%lX", (unsigned long) [[[_interface viewer] pixList] objectAtIndex:element]];
	
	NSMutableDictionary* cache = [_cache objectForKey:[roiRec roi]];
	
	if ([cache objectForKey:keyPix] == NULL)
    {
		if ([[_interface options] xRangeMode] == XRange4thDimension)
        {
//            DCMPix *p = [[[_interface viewer] pixList: element] objectAtIndex:[[[_interface viewer] imageView] curImage]];
            
            DCMPix *p = [[[_interface viewer] pixList: element] objectAtIndex: roiRec.roiIndexPixList];
            
            id backup = nil;
            if( [[roiRec roi] type] == tBall)
            {
                backup = [roiRec.roi.curView.dcmPixList retain];
                roiRec.roi.curView.dcmPixList = [[_interface viewer] pixList: element];
            }
            
			[p computeROI:[roiRec roi] :mean :NULL :NULL :min :max];
            
            if( backup)
            {
                roiRec.roi.curView.dcmPixList = backup;
                [backup release];
            }
		}
        else
        {
			if ([[[_interface viewer] imageView] flippedData])
				element = [[[_interface viewer] pixList] count]-element-1;
            
            DCMPix *p = [[[_interface viewer] pixList] objectAtIndex:element];
			[p computeROI:[roiRec roi] :mean :NULL :NULL :min :max];
		}
		
		NSMutableDictionary *imageCache = [NSMutableDictionary dictionary];
        
        if( mean)
            [imageCache setValue: [NSNumber numberWithFloat:*mean] forKey: @"mean"];
		
        if( min)
            [imageCache setValue: [NSNumber numberWithFloat:*min] forKey: @"min"];
		
        if( max)
            [imageCache setValue: [NSNumber numberWithFloat:*max] forKey: @"max"];
		
		if (!cache) {
			cache = [NSMutableDictionary dictionary];
			[_cache setObject:cache forKey:[roiRec roi]];
		}
		
		[cache setObject:imageCache forKey:keyPix];
	}
	else
	{
		NSDictionary *imageCache = [cache objectForKey:keyPix];
        
        if( mean)
            *mean = [[imageCache valueForKey:@"mean"] floatValue];
        
        if( min)
            *min = [[imageCache valueForKey:@"min"] floatValue];
		
        if( max)
            *max = [[imageCache valueForKey:@"max"] floatValue];
	}
}

-(double)chart:(GRChartView*)chart yValueForDataSet:(GRDataSet*)dataSet element:(NSInteger)element {
	ROISel roiSel; RoiEnhancementROIRec* roiRec = [[_interface roiList] findRecordByDataSet:dataSet sel:&roiSel];
	
	float min = 0, mean = 0, max = 0;
	[self yValueForROIRec:roiRec element:element min:&min mean:&mean max:&max];
	
	if (roiSel == ROIMin)
		return min;
	if (roiSel == ROIMean)
		return mean;
	if (roiSel == ROIMax)
		return max;
	
	return 0;
}

-(NSString*)chart:(GRChartView*)chart yLabelForAxes:(GRAxes*)axes value:(double)value defaultLabel:(NSString*)defaultLabel {
	return [[_interface decimalFormatter] stringFromNumber:[NSNumber numberWithDouble:value]];
}

//+(BOOL)instancesRespondToSelector:(SEL)aSelector {
//	BOOL responds = [super instancesRespondToSelector:aSelector];
//	if (!responds) NSLog(@"+Chart doesn't respond to -  %@", NSStringFromSelector(aSelector));
//	return responds;
//}
//
//-(BOOL)respondsToSelector:(SEL)aSelector {
//	BOOL responds = [super respondsToSelector:aSelector];
//	if (!responds) NSLog(@"-Chart doesn't respond to - %@", NSStringFromSelector(aSelector));
//	return responds;
//}

// options

-(void)freeYRange {
	[[self axes] setProperty:NULL forKey:GRAxesYPlotMin]; // [NSNumber numberWithInt:0]
	[[self axes] setProperty:NULL forKey:GRAxesYPlotMax];
	[[self axes] setProperty:NULL forKey:GRAxesFixedYPlotMin];
	[[self axes] setProperty:NULL forKey:GRAxesFixedYPlotMax];
}

-(void)constrainYRangeFrom:(float)min {
	[[self axes] setProperty:[NSNumber numberWithFloat:min] forKey:GRAxesYPlotMin];
	[[self axes] setProperty:NULL forKey:GRAxesYPlotMax];
	[[self axes] setProperty:[NSNumber numberWithFloat:min] forKey:GRAxesFixedYPlotMin];
	[[self axes] setProperty:NULL forKey:GRAxesFixedYPlotMax];
}

-(void)constrainYRangeFrom:(float)min to:(float)max {
	min -= 0.00000001; max += 0.00000001;
	[[self axes] setProperty:[NSNumber numberWithFloat:min] forKey:GRAxesYPlotMin];
	[[self axes] setProperty:[NSNumber numberWithFloat:max] forKey:GRAxesYPlotMax];
	[[self axes] setProperty:[NSNumber numberWithFloat:min] forKey:GRAxesFixedYPlotMin];
	[[self axes] setProperty:[NSNumber numberWithFloat:max] forKey:GRAxesFixedYPlotMax];
}

// areas

-(void)addAreaDataSet:(RoiEnhancementAreaDataSet*)dataSet {
	[_areaDataSets addObject:[dataSet retain]];
	[self setNeedsDisplay:YES];
}

-(void)removeAreaDataSet:(RoiEnhancementAreaDataSet*)dataSet {
	[_areaDataSets removeObject:dataSet];
	[dataSet release];
}

-(void)setDrawsBackground:(BOOL)drawsBackground {
	_drawsBackground = drawsBackground;
	[self setNeedsDisplay:YES];
}

-(void)setDrawsLegend:(BOOL)drawsLegend {
	_drawsLegend = drawsLegend;
	[self setNeedsDisplay:YES];
}

-(void)drawTrackingGizmoAtPoint:(NSPoint)point withValue:(float)value
{
    if( point.y == point.y && point.x == point.x && value == value) // test for nan
    {
        NSGraphicsContext* context = [NSGraphicsContext currentContext];
        [context saveGraphicsState];
        
        static NSDictionary* attributes = [[NSDictionary dictionaryWithObjectsAndKeys: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]-2], NSFontAttributeName, NULL] retain];
        
        NSString* string = [[_interface floatFormatter] stringFromNumber:[NSNumber numberWithFloat:value]];
        NSSize size = [string sizeWithAttributes:attributes];
        
        [NSBezierPath strokeLineFromPoint:point toPoint:NSMakePoint(point.x+5, point.y)];
        [NSBezierPath setDefaultLineWidth: 0];
        [[[NSColor whiteColor] colorWithAlphaComponent:.5] setFill];
        NSRect rect = NSMakeRect(point.x+4, point.y+2, size.width, size.height);
        [[NSBezierPath bezierPathWithRect:NSMakeRect(rect.origin.x-2, rect.origin.y, rect.size.width+3, rect.size.height-1)] fill];
        [string drawInRect:rect withAttributes:attributes];
        
        [context restoreGraphicsState];
    }
}

-(BOOL)computeLayout {
	BOOL retVal = [super computeLayout];
	
	NSRect r = [[self axes] plotRect];
	float p0x = [[self axes] xValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)];
	float p0y = [[self axes] yValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)];
	float p1x = [[self axes] xValueAtPoint: NSMakePoint(r.origin.x+r.size.width, r.origin.y+r.size.height)];
	float p1y = [[self axes] yValueAtPoint: NSMakePoint(r.origin.x+r.size.width, r.origin.y+r.size.height)];
	
	const int tickWidth = 4;
	
	const int multiplySequence[] = {5,2};
	const int multiplySequenceLength = sizeof(multiplySequence)/sizeof(int);
	
	const float valueWidth = p1x-p0x;
	
	int sequenceIndex = 0;
	int ticksEveryValue = 1;
	while (valueWidth/ticksEveryValue > r.size.width/tickWidth)
		ticksEveryValue *= multiplySequence[sequenceIndex++%multiplySequenceLength];
	
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue] forKey:GRAxesXMinorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue] forKey:GRAxesFixedXMinorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue*5] forKey:GRAxesXMajorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue*5] forKey:GRAxesFixedXMajorUnit];	
	
	const float valueHeight = p1y-p0y;
	
	sequenceIndex = 0;
	ticksEveryValue = 1;
	while (valueHeight/ticksEveryValue > r.size.height/tickWidth)
		ticksEveryValue *= multiplySequence[sequenceIndex++%multiplySequenceLength];
	
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue] forKey:GRAxesYMinorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue] forKey:GRAxesFixedYMinorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue*5] forKey:GRAxesYMajorUnit];
	[[self axes] setProperty:[NSNumber numberWithInt:ticksEveryValue*5] forKey:GRAxesFixedYMajorUnit];	
	
	return retVal | [super computeLayout]; // yes, again
}

-(void)drawValue:(float)value {
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	
	if (value >= _xMin && value <= _xMax && _xMin != _xMax) {
        
		float pointX = [[self axes] locationForXValue:value yValue:0].x;
        
        if( pointX == pointX) // test for nan
        {
            // line
            [context saveGraphicsState];
            [[NSBezierPath bezierPathWithRect:[[self axes] plotRect]] setClip];
            [[NSColor blackColor] setStroke];
            [NSBezierPath setDefaultLineWidth: 1];
            
            [NSBezierPath strokeLineFromPoint:NSMakePoint(pointX, [[self axes] plotRect].origin.y) toPoint:NSMakePoint(pointX, [[self axes] plotRect].origin.y+[[self axes] plotRect].size.height)];
            [context restoreGraphicsState];
            // values
            [context saveGraphicsState];
            [[NSColor blackColor] setStroke];
            [NSBezierPath setDefaultLineWidth: 1];
            for (unsigned i = 0; i < [[_interface roiList] countOfDisplayedROIs]; ++i)
            {
                RoiEnhancementROIRec* roiRec = [[_interface roiList] displayedROIRec:i];
                
                float min = 0, mean = 0, max = 0;
                [self yValueForROIRec:roiRec element:value min:&min mean:&mean max:&max];
                
                if ([[_interface options] min])
                    [self drawTrackingGizmoAtPoint:[[self axes] locationForXValue:value yValue:min] withValue:min];
                if ([[_interface options] mean])
                    [self drawTrackingGizmoAtPoint:[[self axes] locationForXValue:value yValue:mean] withValue:mean];
                if ([[_interface options] max])
                    [self drawTrackingGizmoAtPoint:[[self axes] locationForXValue:value yValue:max] withValue:max];
            }
            [context restoreGraphicsState];
        }
	}
}

-(void)drawValues {
	for (unsigned i = 0; i < [_plotValues count]; ++i) {
		float value = [[_plotValues objectAtIndex:i] floatValue];
		[self drawValue:value];
		if (_newPlotValue == value)
			_newPlotValue = -1;
	}
	
	if (_newPlotValue != -1)
		[self drawValue:_newPlotValue];
}

-(void)drawLegend {
	if (![self drawsLegend])
		return;
	
	float textWidth = 0, height = 0;
	NSFont* font = [[[_interface chart] axes] propertyForKey:GRAxesLabelFont];
	NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithCapacity:4];
	[attributes setObject:font forKey:NSFontAttributeName];
	
	for (unsigned i = 0; i < [[_interface roiList] countOfDisplayedROIs]; ++i) {
		RoiEnhancementROIRec* roiRec = [[_interface roiList] displayedROIRec:i];
		NSSize size = [[[roiRec roi] name] sizeWithAttributes:attributes];
		height += size.height;
		if (size.width > textWidth)
			textWidth = size.width;
	}
	
	NSRect plotRect = [[self axes] plotRect];
	
	const float sampleWidth = 20, padding = 5, margin = 5;
	NSRect legendRect = NSMakeRect(0, 0, padding*3+textWidth+sampleWidth, padding+height);

	if ([[_interface options] legendPositionX] == LegendPositionLeft)
		legendRect.origin.x = plotRect.origin.x+margin;
	else legendRect.origin.x = plotRect.origin.x+plotRect.size.width-margin-legendRect.size.width;
	if ([[_interface options] legendPositionY] == LegendPositionTop)
		legendRect.origin.y = plotRect.origin.y+plotRect.size.height-margin-legendRect.size.height;
	else legendRect.origin.y = plotRect.origin.y+margin;
	
	NSGraphicsContext* context = [NSGraphicsContext currentContext];
	[context saveGraphicsState];
	
	[[[_interface options] backgroundColor] setFill];
	[[[_interface options] majorColor] setStroke];
	[NSBezierPath fillRect:legendRect];
	[NSBezierPath strokeRect:legendRect];
	
	float h = 0;
	for (unsigned i = 0; i < [[_interface roiList] countOfDisplayedROIs]; ++i) {
		RoiEnhancementROIRec* roiRec = [[_interface roiList] displayedROIRec:i];
		NSSize size = [[[roiRec roi] name] sizeWithAttributes:attributes];
		[[[roiRec roi] name] drawWithRect:NSMakeRect(legendRect.origin.x+padding+(textWidth-size.width), legendRect.origin.y+h+padding, textWidth, size.height) options:0 attributes:attributes];
		[[roiRec meanDataSet] drawLegendSampleInRect:NSMakeRect(legendRect.origin.x+padding*2+textWidth, legendRect.origin.y+h+padding/2, sampleWidth, size.height)];
		h += size.height;
	}	
	
	[context restoreGraphicsState];
}

-(IBAction) copy:(id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
	
	[pb declareTypes: [NSArray arrayWithObject: NSPDFPboardType] owner: self];
	[pb setData: [self dataWithPDFInsideRect:[self bounds]] forType: NSPDFPboardType];
}

-(void)drawRect:(NSRect)dirtyRect {
	if (_stopDraw) return;

	if( [_interface viewer] == nil)
		return;
	
	// update the view's layout
	if ([self needsLayout])
		[self computeLayout];
	
	// draw first the background and the areas
	
	NSGraphicsContext* context = [NSGraphicsContext currentContext];

	if (_drawsBackground) {
		[context saveGraphicsState];
		[(NSColor*)[[self axes] propertyForKey:GRAxesBackgroundColor] setFill];
		[NSBezierPath fillRect:[[self axes] plotRect]];
		[context restoreGraphicsState];
	}
	
	for (unsigned i = 0; i < [_areaDataSets count]; ++i)
		[[_areaDataSets objectAtIndex:i] drawRect: dirtyRect];
	
	[super drawRect:dirtyRect];
	
	if (_tracking)
		if (_newPlotValue == -1)
			_newPlotValue = round([[self axes] xValueAtPoint:_mousePoint]);
	
	[self drawValues];
	[self drawLegend];
	
	[[_interface options] updateYRange];
	[[_interface options] updateXRange];
}

-(NSString*)csv:(BOOL)includeHeaders {
	NSMutableString* csv = [[NSMutableString alloc] initWithCapacity:512];
	
	if (includeHeaders) {
		[csv appendString:@"\"index\","];
		for (unsigned i = 0; i < [[_interface roiList] countOfDisplayedROIs]; ++i) {
			NSMutableString* name = [[[[[[_interface roiList] displayedROIRec:i] roi] name] mutableCopy] autorelease];
			[name replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:0 range:NSMakeRange(0, [name length])];
			if ([[_interface options] mean])
				[csv appendFormat: @"\"%@ mean\",", name];
			if ([[_interface options] min] || [[_interface options] fill])
				[csv appendFormat: @"\"%@ min\",", name];
			if ([[_interface options] max] || [[_interface options] fill])
				[csv appendFormat: @"\"%@ max\",", name];
		}

		[csv deleteCharactersInRange:NSMakeRange([csv length]-1, 1)];
		[csv appendString:@"\n"];
	}
	
	for (int x = _xMin; x <= _xMax; ++x) {
		[csv appendFormat:@"\"%d\",", x];
		for (unsigned i = 0; i < [[_interface roiList] countOfDisplayedROIs]; ++i) {
			RoiEnhancementROIRec* roiRec = [[_interface roiList] displayedROIRec:i];
			if ([[_interface options] mean])
				[csv appendFormat: @"\"%f\",", [self chart:self yValueForDataSet:[roiRec meanDataSet] element:x]];
			if ([[_interface options] min] || [[_interface options] fill])
				[csv appendFormat: @"\"%f\",", [self chart:self yValueForDataSet:[roiRec minDataSet] element:x]];
			if ([[_interface options] max] || [[_interface options] fill])
				[csv appendFormat: @"\"%f\",", [self chart:self yValueForDataSet:[roiRec maxDataSet] element:x]];
		}
		
		[csv deleteCharactersInRange:NSMakeRange([csv length]-1, 1)];
		[csv appendString:@"\n"];
	}
	
	return [csv autorelease];
}

@end

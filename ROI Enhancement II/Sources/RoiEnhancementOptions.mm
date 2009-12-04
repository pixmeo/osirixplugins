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

#import "RoiEnhancementOptions.h"
#import "RoiEnhancementChart.h"
#import "RoiEnhancementInterface.h"
#import "RoiEnhancementROIList.h"
#import <GRAxes.h>
#import "RoiEnhancementUserDefaults.h"
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/Notifications.h>

@implementation RoiEnhancementOptions

-(void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCurrentImage:) name:OsirixDCMUpdateCurrentImageNotification object:NULL];
}

-(void)loadUserDefaults {
	// curves
	[_meanCurve setState:[[_interface userDefaults] bool:@"curves.mean" otherwise:[_meanCurve state]]];
	[_minCurve setState:[[_interface userDefaults] bool:@"curves.min" otherwise:[_minCurve state]]];
	[_maxCurve setState:[[_interface userDefaults] bool:@"curves.max" otherwise:[_maxCurve state]]];
	[_minmaxFill setState:[[_interface userDefaults] bool:@"curves.minmax.fill" otherwise:[_minmaxFill state]]];
	
	// ranges
	[_xRangeMode selectItemAtIndex: [[_interface userDefaults] int:@"ranges.x.mode" otherwise:[_xRangeMode indexOfSelectedItem]]];
	if ([self xRangeMode] == XRangeDefinedByUser) {
		[_xRangeMin setFloatValue:[[_interface userDefaults] float:@"ranges.x.min" otherwise:0]];
		[_xRangeMax setFloatValue:[[_interface userDefaults] float:@"ranges.x.max" otherwise:0]];
	}
	
	[_logscaleYRange setState:[[_interface userDefaults] bool:@"ranges.y.logscale" otherwise:[_logscaleYRange state]]];
	[_constrainYRange setState:[[_interface userDefaults] bool:@"ranges.y.constrain" otherwise:[_constrainYRange state]]];
	if ([_constrainYRange state]) {
		[_yRangeMin setFloatValue:[[_interface userDefaults] float:@"ranges.y.min" otherwise:0]];
		[_yRangeMax setFloatValue:[[_interface userDefaults] float:@"ranges.y.max" otherwise:0]];
	}
	
	// legend
	[_legend setState:[[_interface userDefaults] bool:@"legend.display" otherwise:[_legend state]]];
	[_leftRight selectCellAtRow:0 column:[[_interface userDefaults] int:@"legend.x" otherwise:[_leftRight selectedColumn]]];
	[_topBottom selectCellAtRow:0 column:[[_interface userDefaults] int:@"legend.y" otherwise:[_topBottom selectedColumn]]];
	
	// decorations
	[_xAxis setState:[[_interface userDefaults] bool:@"decorations.x.axis" otherwise:[_xAxis state]]];
	[_xTicks setState:[[_interface userDefaults] bool:@"decorations.x.ticks" otherwise:[_xTicks state]]];
	[_xGrid setState:[[_interface userDefaults] bool:@"decorations.x.grid" otherwise:[_xGrid state]]];
	[_xLabels setState:[[_interface userDefaults] bool:@"decorations.x.labels" otherwise:[_xLabels state]]];
	[_yAxis setState:[[_interface userDefaults] bool:@"decorations.y.axis" otherwise:[_yAxis state]]];
	[_yTicks setState:[[_interface userDefaults] bool:@"decorations.y.ticks" otherwise:[_yTicks state]]];
	[_yGrid setState:[[_interface userDefaults] bool:@"decorations.y.grid" otherwise:[_yGrid state]]];
	[_yLabels setState:[[_interface userDefaults] bool:@"decorations.y.labels" otherwise:[_yLabels state]]];
	[_background setState:[[_interface userDefaults] bool:@"decorations.background" otherwise:[_background state]]];
	
	[_majorLineColor setColor:[[_interface userDefaults] color:@"decorations.majorlinecolor" otherwise:[_majorLineColor color]]];
	[_minorLineColor setColor:[[_interface userDefaults] color:@"decorations.minorlinecolor" otherwise:[_minorLineColor color]]];
	[_backgroundColor setColor:[[_interface userDefaults] color:@"decorations.background.color" otherwise:[_backgroundColor color]]];
	
	// as we know [interface viewer] is set, enable/disable 4th dimension graphing
	[_xRange4thDimension setHidden:[[_interface viewer] maxMovieIndex]==1];
	
	[self curvesChanged:NULL];
	[self xRangeChanged:NULL];
	[self yRangeChanged:NULL];
	[self legendChanged:NULL];
	[self decorationsChanged:NULL];
}

-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(IBAction)curvesChanged:(id)sender {
	[[_interface roiList] changedMin:[_minCurve state] mean:[_meanCurve state] max:[_maxCurve state] fill:[_minmaxFill state]];
	
	if (sender == _meanCurve)
		[[_interface userDefaults] setBool:[_meanCurve state] forKey:@"curves.mean"];
	if (sender == _minCurve)
		[[_interface userDefaults] setBool:[_minCurve state] forKey:@"curves.min"];
	if (sender == _maxCurve)
		[[_interface userDefaults] setBool:[_maxCurve state] forKey:@"curves.max"];
	if (sender == _minmaxFill)
		[[_interface userDefaults] setBool:[_minmaxFill state] forKey:@"curves.minmax.fill"];
}

-(XRangeMode)xRangeMode {
	NSMenuItem* selectedItem = [_xRangeMode selectedItem];
	
	if (selectedItem == _xRangeEntireStack)
		return XRangeEntireStack;
	if (selectedItem == _xRangeFromCurrentToEnd)
		return XRangeFromCurrentToEnd;
	if (selectedItem == _xRange4thDimension)
		return XRange4thDimension;
	if (selectedItem == _xRangeDefinedByUser)
		return XRangeDefinedByUser;

	return (XRangeMode)-1;
}

-(void)updateCurrentImage:(NSNotification*)notification {
	if ([self xRangeMode] == XRangeFromCurrentToEnd || [self xRangeMode] == XRange4thDimension)
		[self xRangeChanged:NULL];
}

-(IBAction)xRangeChanged:(id)sender {
	XRangeMode xRangeMode = [self xRangeMode];
	BOOL constrain = xRangeMode == XRangeDefinedByUser;
	
	// affect the GUI
	[_xRangeMin setEnabled: constrain];
	[_xRangeMax setEnabled: constrain];
	
	// correct the range
	if ([_xRangeMin intValue] < 0)
		[_xRangeMin setIntValue: 0];
	if ([_xRangeMax intValue] > (int)[[[_interface viewer] pixList] count]-1)
		[_xRangeMax setIntValue: (int)[[[_interface viewer] pixList] count]-1];
	
	// affect the range
	if (xRangeMode == XRangeEntireStack)
		[[_interface chart] constrainXRangeFrom:0 to:[[_interface chart] chart:[_interface chart] numberOfElementsForDataSet:NULL]-1];
	else if (xRangeMode == XRangeFromCurrentToEnd)
		[[_interface chart] constrainXRangeFrom:[[[_interface viewer] imageView] flippedData]? [[[_interface viewer] pixList] count]-[[[_interface viewer] imageView] curImage]-1 : [[[_interface viewer] imageView] curImage] to:[[[_interface viewer] pixList] count]-1];
	else if (xRangeMode == XRange4thDimension) {
		[[_interface chart] constrainXRangeFrom:0 to:[[_interface chart] chart:[_interface chart] numberOfElementsForDataSet:NULL]-1];
	} else if (xRangeMode == XRangeDefinedByUser)
		[[_interface chart] constrainXRangeFrom:[_xRangeMin intValue] to:[_xRangeMax intValue]];
	[[_interface chart] reloadData];
	
	[self updateXRange];
	
	// defaults
	[[_interface userDefaults] setInt:xRangeMode forKey:@"ranges.x.mode"];
	if (constrain) {
		[[_interface userDefaults] setFloat:[_xRangeMin floatValue] forKey:@"ranges.x.min"];
		[[_interface userDefaults] setFloat:[_xRangeMax floatValue] forKey:@"ranges.x.max"];
	}
}

-(void)updateXRange {
	if ([self xRangeMode] != XRangeDefinedByUser) { // display current range
		NSRect r = [[[_interface chart] axes] plotRect];
		[_xRangeMin setFloatValue:[[[_interface chart] axes] xValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)]];
		[_xRangeMax setFloatValue:[[[_interface chart] axes] xValueAtPoint: NSMakePoint(r.origin.x+r.size.width, r.origin.y)]];
	}
}

-(IBAction)yRangeChanged:(id)sender {
	BOOL logscale = [_logscaleYRange state];
	BOOL constrain = [_constrainYRange state];
	
	// affect the GUI
	[_constrainYRange setEnabled:!logscale];
	[_yRangeMin setEnabled:!logscale && constrain];
	[_yRangeMax setEnabled:!logscale && constrain];
	
	[[[_interface chart] axes] setProperty:(logscale? GRAxesLog10Scale : GRAxesLinearScale) forKey:GRAxesYAxisScale];

	// affect the range
	if (logscale) {
		[[_interface chart] constrainYRangeFrom:1];
	} else
		if (constrain)
			[[_interface chart] constrainYRangeFrom:[_yRangeMin floatValue] to:[_yRangeMax floatValue]];
		else [[_interface chart] freeYRange];
	
	[self updateYRange];
	
	// defaults
	[[_interface userDefaults] setBool:constrain forKey:@"ranges.y.constrain"];
	[[_interface userDefaults] setBool:[_logscaleYRange state] forKey:@"ranges.y.logscale"];
	if (constrain) {
		[[_interface userDefaults] setFloat:[_yRangeMin floatValue] forKey:@"ranges.y.min"];
		[[_interface userDefaults] setFloat:[_yRangeMax floatValue] forKey:@"ranges.y.max"];
	}
}

-(void)updateYRange {
	if ([_logscaleYRange state] || ![_constrainYRange state]) { // display current range
		NSRect r = [[[_interface chart] axes] plotRect];
		[_yRangeMin setFloatValue:[[[_interface chart] axes] yValueAtPoint: NSMakePoint(r.origin.x, r.origin.y)]];
		[_yRangeMax setFloatValue:[[[_interface chart] axes] yValueAtPoint: NSMakePoint(r.origin.x, r.origin.y+r.size.height)]];
	}
}

-(IBAction)legendChanged:(id)sender {
	BOOL legend = [_legend state];
	
	// affect the GUI
	[_leftRight setEnabled:legend];
	[_topBottom setEnabled:legend];
	
	if (!sender || sender == _legend)
		[[_interface chart] setDrawsLegend:legend];
	
	[[_interface chart] setNeedsDisplay:YES];
	
	[[_interface userDefaults] setBool:legend forKey:@"legend.display"];
	[[_interface userDefaults] setInt:[_leftRight selectedColumn] forKey:@"legend.x"];
	[[_interface userDefaults] setInt:[_topBottom selectedColumn] forKey:@"legend.y"];
}

-(IBAction)decorationsChanged:(id)sender {
	RoiEnhancementChart* chart = [_interface chart];
	GRAxes* axes = [chart axes];
	
	if (!sender || sender == _xAxis) {
		BOOL active = [_xAxis state];
		[axes setProperty:[NSNumber numberWithBool:active] forKey:GRAxesDrawXAxis];
		[_xTicks setEnabled:active];
		[_xGrid setEnabled:active];
	}
	
	if (!sender || sender == _xTicks) {
		[axes setProperty:[NSNumber numberWithBool:[_xTicks state]] forKey:GRAxesDrawXMajorTicks];
		[axes setProperty:[NSNumber numberWithBool:[_xTicks state]] forKey:GRAxesDrawXMinorTicks];
	}
	
	if (!sender || sender == _xGrid) {
		[axes setProperty:[NSNumber numberWithBool:[_xGrid state]] forKey:GRAxesDrawXMajorLines];
		[axes setProperty:[NSNumber numberWithBool:[_xGrid state]] forKey:GRAxesDrawXMinorLines];
	}
	
	[_xLabels setEnabled:[_xAxis state] && ([_xTicks state] || [_xGrid state])];
	if (!sender || sender == _xLabels || sender == _xTicks || sender == _xGrid || sender == _xAxis)
		[axes setProperty:[NSNumber numberWithBool:[_xLabels state] && ([_xAxis state] && ([_xTicks state] || [_xGrid state]))] forKey:GRAxesDrawXLabels];
	
	if (!sender || sender == _yAxis) {
		BOOL state = [_yAxis state];
		[axes setProperty:[NSNumber numberWithBool:state] forKey:GRAxesDrawYAxis];
		[_yTicks setEnabled:state];
		[_yGrid setEnabled:state];
	}
	
	if (!sender || sender == _yTicks) {
		[axes setProperty:[NSNumber numberWithBool:[_yTicks state]] forKey:GRAxesDrawYMajorTicks];
		[axes setProperty:[NSNumber numberWithBool:[_yTicks state]] forKey:GRAxesDrawYMinorTicks];
	}
	
	if (!sender || sender == _yGrid) {
		[axes setProperty:[NSNumber numberWithBool:[_yGrid state]] forKey:GRAxesDrawYMajorLines];
		[axes setProperty:[NSNumber numberWithBool:[_yGrid state]] forKey:GRAxesDrawYMinorLines];
	}
	
	[_yLabels setEnabled:[_yAxis state] && ([_yTicks state] || [_yGrid state])];
	if (!sender || sender == _yLabels || sender == _yTicks || sender == _yGrid || sender == _yAxis)
		[axes setProperty:[NSNumber numberWithBool:[_yLabels state] && ([_yAxis state] && ([_yTicks state] || [_yGrid state]))] forKey:GRAxesDrawYLabels];
	
	if (!sender || sender == _majorLineColor)
		[axes setProperty:[_majorLineColor color] forKey:GRAxesMajorLineColor];
	
	if (!sender || sender == _minorLineColor)
		[axes setProperty:[_minorLineColor color] forKey:GRAxesMinorLineColor];
	
	if (!sender || sender == _background) {
		BOOL state = [_background state];
		[chart setDrawsBackground:state];
		[_backgroundColor setEnabled:state];
	}
	
	if (!sender || sender == _backgroundColor)
		[axes setProperty:[_backgroundColor color] forKey:GRAxesBackgroundColor];

	if (sender == _xAxis) [[_interface userDefaults] setBool:[_xAxis state] forKey:@"decorations.x.axis"];
	if (sender == _xTicks) [[_interface userDefaults] setBool:[_xTicks state] forKey:@"decorations.x.ticks"];
	if (sender == _xGrid) [[_interface userDefaults] setBool:[_xGrid state] forKey:@"decorations.x.grid"];
	if (sender == _xLabels) [[_interface userDefaults] setBool:[_xLabels state] forKey:@"decorations.x.labels"];
	if (sender == _yAxis) [[_interface userDefaults] setBool:[_yAxis state] forKey:@"decorations.y.axis"];
	if (sender == _yTicks) [[_interface userDefaults] setBool:[_yTicks state] forKey:@"decorations.y.ticks"];
	if (sender == _yGrid) [[_interface userDefaults] setBool:[_yGrid state] forKey:@"decorations.y.grid"];
	if (sender == _yLabels) [[_interface userDefaults] setBool:[_yLabels state] forKey:@"decorations.y.labels"];
	if (sender == _background) [[_interface userDefaults] setBool:[_background state] forKey:@"decorations.background"];
	if (sender == _majorLineColor) [[_interface userDefaults] setColor:[_majorLineColor color] forKey:@"decorations.majorlinecolor"];
	if (sender == _minorLineColor) [[_interface userDefaults] setColor:[_minorLineColor color] forKey:@"decorations.minorlinecolor"];
	if (sender == _backgroundColor) [[_interface userDefaults] setColor:[_backgroundColor color] forKey:@"decorations.background.color"];
}

-(BOOL)min {
	return [_minCurve state];
}

-(BOOL)mean {
	return [_meanCurve state];
}

-(BOOL)max {
	return [_maxCurve state];
}

-(BOOL)fill {
	return [_minmaxFill state];
}

-(NSColor*)backgroundColor {
	return [_backgroundColor color];
}

-(NSColor*)majorColor {
	return [_majorLineColor color];
}

-(LegendPositionX)legendPositionX {
	return [_leftRight selectedColumn]==0? LegendPositionLeft : LegendPositionRight;
}

-(LegendPositionY)legendPositionY {
	return [_topBottom selectedColumn]==0? LegendPositionTop : LegendPositionBottom;
}

@end

//
//  Controller.h
//  Mapping
//
//  Created by Antoine Rosset on Mon Aug 02 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Graph.h"

@interface ControllerT2Fit : NSWindowController {

					MappingT2FitFilter	*filter;
					ViewerController	*blendedWindow;

					float				TEValues[ 1000];

	IBOutlet		NSTextField			*factorText, *meanT2Value, *backgroundSignal;
	IBOutlet		GraphT2Fit			*resultView;
	IBOutlet		NSMatrix			*mode;
	IBOutlet		NSButton			*logScale;
	IBOutlet		NSTableView			*TETable;
	
					ViewerController	*new2DViewer;
					ROI					*curROI;
					float				slope, intercept;
					
	IBOutlet		NSWindow			*fillWindow;
	IBOutlet		NSTextField			*startFill, *endFill, *intervalFill;
	IBOutlet		NSMatrix			*fillMode;
	
					NSMutableArray		*pixListArrays;
					
					NSMutableArray		*pixListResult;
					NSMutableArray		*fileListResult;
}

-(IBAction) compute:(id) sender;
- (id) init:(MappingT2FitFilter*) f ;
- (IBAction) refreshGraph:(id) sender;
-(IBAction) endFill:(id) sender;
- (IBAction) startFill:(id) sender;
@end

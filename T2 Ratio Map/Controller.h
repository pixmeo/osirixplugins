//
//  Controller.h
//  Mapping
//
//  Created by Antoine Rosset on Mon Aug 02 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "Graph.h"

@interface Controller : NSWindowController {

					MappingFilter		*filter;
					ViewerController	*blendedWindow;

	IBOutlet		NSTextField			*K, *factorText, *thresholdText, *thresholdSetText;
	IBOutlet		Graph				*resultView;
	IBOutlet		NSMatrix			*mode;
}

-(IBAction) compute:(id) sender;
- (id) init:(MappingFilter*) f ;

@end

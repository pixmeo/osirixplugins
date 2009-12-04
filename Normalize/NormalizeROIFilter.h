//
//  NormalizeROIFilter.h
//  Normalize
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface NormalizeROIFilter : PluginFilter {

	IBOutlet	NSWindow		*window;
	IBOutlet	NSTextField		*meanValue, *normValue, *factorValue;
}

- (long) filterImage:(NSString*) menuName;
- (IBAction) endDialog:(id) sender;
- (IBAction) setFactor:(id) sender;
- (IBAction) setNormalize:(id) sender;
@end

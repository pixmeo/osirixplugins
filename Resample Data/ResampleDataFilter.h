//
//  ResampleDataFilter.h
//  Resample Data
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2005 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsiriXAPI/PluginFilter.h"

@interface ResampleDataFilter : PluginFilter {

	IBOutlet	NSButton		*ForceRatioCheck;
	IBOutlet	NSWindow		*window;
	IBOutlet	NSTextField		*XText, *YText, *ZText, *RatioText;
	IBOutlet	NSTextField		*oXText, *oYText, *oZText, *MemoryText, *thicknessText;
	IBOutlet	NSSlider		*xSlider, *ySlider, *zSlider;
	
	long	originWidth, originHeight, originZ;
	float	originRatio;
}

- (long) filterImage:(NSString*) menuName;
- (IBAction) endDialog:(id) sender;
- (IBAction) setXYZValue:(id) sender;
- (IBAction) setXYZSlider:(id) sender;
- (IBAction) setForceRatio:(id) sender;
@end


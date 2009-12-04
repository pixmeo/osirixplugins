//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface OrthogonalReslicePlugin : PluginFilter {

	IBOutlet	NSMatrix		*direction;
	IBOutlet	NSTextField		*xResolution, *yResolution;
	IBOutlet	NSWindow		*window;
	IBOutlet	NSButton		*squarePixels;
	IBOutlet	NSButton		*newWindow;
}

- (long) filterImage:(NSString*) menuName;
- (IBAction) endDialog:(id) sender;

@end

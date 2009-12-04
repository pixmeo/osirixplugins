//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"

@interface ReduceSeries : PluginFilter {

	IBOutlet	NSForm		*form;
	IBOutlet	NSWindow	*window;
	IBOutlet	NSButton	*closeOriginal;
}

- (long) filterImage:(NSString*) menuName;
- (IBAction) endDialog:(id) sender;

@end

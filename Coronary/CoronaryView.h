//
//  CoronaryView.h
//  Coronary
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CoronaryController.h"

@interface CoronaryView : NSView
{
	NSMutableArray *segments;
	CoronaryController *c;
}

+ (CoronaryView*) view;
- (void) setText: (int) i :(NSMutableDictionary*) seg;
- (void) refresh;
- (NSRect) squareBounds;
- (IBAction) reset: (id) sender;
-(NSString*) csv:(BOOL) includeHeaders;
@end

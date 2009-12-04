//
//  BullsEyeView.h
//  BullsEye
//
//  Created by Antoine Rosset on 18.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BullsEyeController.h"

@interface BullsEyeView : NSView
{
	NSMutableArray *segments;
	BullsEyeController *c;
}

+ (BullsEyeView*) view;
- (void) setText: (int) i :(NSMutableDictionary*) seg;
- (void) refresh;
- (NSRect) squareBounds;
- (IBAction) reset: (id) sender;
-(NSString*) csv:(BOOL) includeHeaders;
@end

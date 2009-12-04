//
//  AlignController.h
//  Align
//
//  Created by Joël Spaltenstein on 7/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ViewerController.h"

typedef enum {AL_NORMAL = 0, AL_TILE, AL_MOSAIC, AL_BACKGROUND} al_state;


@interface AlignController : ViewerController {
}

+ (AlignController *) newAlignWindow:(NSMutableArray*)f :(NSMutableArray*)d :(NSData*) v;

- (id) viewCinit:(NSMutableArray*)f :(NSMutableArray*) d :(NSData*) v;
- (void) CloseViewerNotification: (NSNotification*) note;


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;
- (void) propagateSettings;
- (void) ActivateTiling:(AlignController*) tC;
- (void) ActivateBackground:(AlignController*) bC;
- (void) propagateControlPoints;


// work with virtual member variables
- (al_state) align_state;
- (void) setAlign_state:(al_state) state;

- (AlignController *) tileController;
- (void) setTileController:(AlignController *) controller;


// meothods to access new variables
- (id) aligncontroller__instanceID;
- (NSMutableDictionary *) aligncontroller__ivars;


@end

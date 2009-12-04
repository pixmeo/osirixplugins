//
//  AlignFilter.h
//  Align
//
//  Created by rossetantoine on Wed Jun 09 2004.
//  Copyright (c) 2004 Antoine Rosset. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PluginFilter.h"
#import "DCMPix.h"

@class DCMPix;

@class AlignController;

@interface AlignFilter : PluginFilter {

}

- (void) initPlugin;
- (void) setMenus;

- (void) makeAlignTile;
- (void) makeAlignBackground;
- (void) makeAlignMosaic;
- (void) makeNormal;
- (void) mergeImages;
- (void) setControlPointCount:(long) count;

- (long) filterImage:(NSString*) menuName;
- (AlignController*) duplicateCurrent2DViewerWindowToAlign;
- (long) buildAlignController;

@end

// stuff to swizzle out changeWLWW in DCMPix so that we can put the memory in a texture tiling friend arangment
@interface DCMPix (Align_Swizzle)
- (void) changeWLWW_swizzle:(float)newWL :(float)newWW;
- (char*) texturetiledImage:(char*) inputImage: (long) texture_width;
- (char*) deTexturetiledImage:(char*) inputImage: (long) texture_width;
@end

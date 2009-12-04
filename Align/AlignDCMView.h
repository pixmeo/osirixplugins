//
//  AlignDCMView.h
//  Align
//
//  Created by Jo‘l Spaltenstein on 7/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "DCMView.h"
#import "AlignController.h"
#import "AlignController.h"
#import "DCMPix.h"


@class BogusGLContext;

@interface AlignDCMView : DCMView
{ // since this classes poses as a DCMView, we can't add member variables
}
- (id)initWithFrame:(NSRect)frame imageRows:(int)rows  imageColumns:(int)columns;
- (void) dealloc;

-(void) becomeMainWindow;
- (void) drawRect:(NSRect)aRect;
- (void) drawBackgroundIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY: (float) scale;
- (void) drawTileIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY: (float) scale;

- (unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical;
- (void) drawControlPoints:(float) scaleValue :(float) offsetx :(float) offsety :(float) spacingx :(float) spacingy;

- (void) mergeImages;
- (void) renderToMemory: (NSRect) bounds: (unsigned char*) memory;

- (void) recalcTransMatrix;
- (void) setControlPointCount:(long) pointCount;
- (void) controlPointMovedInTile:(long) pt_num: (NSPoint) pt; 

-(void) setScaleValueCentered:(float) x;
-(void) setScaleValue:(float) x;

- (NSPoint) transformPoint:(NSPoint) pt;

- (void)mouseDown:(NSEvent *)event;
- (void)mouseDragged:(NSEvent *)event;
- (void)mouseUp:(NSEvent *)event;

- (void) resetCursorRects;
- (char*) texturetiledImage:(char*) inputImage: (long) width:(long) height: (long) rowBytes: (long) texture_width;

- (al_state) align_state;
- (void) propagateControlPoints;

-(void) setTiling:(AlignDCMView*) tV;
-(void) setBackground:(AlignDCMView*) tV;
-(void) loadBackgroundTexture:(AlignDCMView*) tV;

// instance variable accessors
- (AlignDCMView*) tileView;
- (void) setTileView:(AlignDCMView*) view;

- (float) tileBlendFactor; // not used
- (void) setTileBlendFactor: (float) factor;

- (long) tileTextureX;
- (void) setTileTextureX: (long) size;

- (long) tileTextureY;
- (void) setTileTextureY: (long) size;

- (GLuint*) tileTextureName;
- (void) setTileTextureName: (GLuint*) texture;

- (GLuint*) backgroundTextureName;
- (void) setBackgroundTextureName: (GLuint*) texture;

- (long) backgroundTextureX;
- (void) setBackgroundTextureX: (long) size;

- (long) backgroundTextureY;
- (void) setBackgroundTextureY: (long) size;

- (long) backgroundTextureWidth;
- (void) setBackgroundTextureWidth: (long) size;

- (long) backgroundTextureHeight;
- (void) setBackgroundTextureHeight: (long) size;

- (long) backgroundPWidth;
- (void) setBackgroundPWidth: (long) size;

- (long) backgroundPHeight;
- (void) setBackgroundPHeight: (long) size;

- (unsigned char*) backgroundColorBuf;
- (void) setBackgroundColorBuf: (unsigned char*) buf;

- (unsigned char*) tilingColorBuf;
- (void) setTilingColorBuf: (unsigned char*) buf;

- (NSPoint) controlPoint0;
- (void) setControlPoint0: (NSPoint) pt;

- (NSPoint) controlPoint1;
- (void) setControlPoint1: (NSPoint) pt;

- (NSPoint) controlPoint2;
- (void) setControlPoint2: (NSPoint) pt;

- (NSPoint) controlPoint3;
- (void) setControlPoint3: (NSPoint) pt;

- (NSPoint) controlPoint4;
- (void) setControlPoint4: (NSPoint) pt;

- (NSPoint) controlPoint:(long) pt_num;
- (void) setControlPoint:(long) pt_num: (NSPoint) pt;

- (long) activeControlPoints;
- (void) setActiveControlPoints:(long) pt_num;

- (long) draggingControlPoint;
- (void) setDraggingControlPoint:(long) pt;

- (float*) transformationMatrix;
- (void) setTransformationMatrix: (float*) trans_matrix;

- (float*) backgroundTransformationMatrix;
- (void) setBackgroundTransformationMatrix: (float*) trans_matrix;

- (float*) backgroundTransMatrixStart;
- (void) setBackgroundTransMatrixStart: (float*) trans_matrix;

// meothods to access new variables
- (id) aligndcmview__instanceID;
- (NSMutableDictionary *) aligndcmview__ivars;


@end


//
//  CMIRViewerController.h
//  CMIR_T2_Fit_Map
//
//  Created by lfexon on 5/12/09.
//  Copyright 2009 CSB_MGH. All rights reserved.
//
#import "GLString.h"
#import "IChatTheatreDelegate.h"
#import "ITKTransform.h"
#import "HornRegistration.h"
#import "PluginFilter.h"
#import "ViewerController.h"
#import "SeriesView.h"

@interface DCMView(CSB)

-(long*) getBlendingTextureXPtr;															// new methods to get private variables from DCMView object
-(long) getBlendingTextureX;																
-(long*) getBlendingTextureYPtr;
-(long) getBlendingTextureY;
-(long*) getBlendingTextureWidthPtr;
-(long) getBlendingTextureWidth;
-(long*) getBlendingTextureHeightPtr;
-(long) getBlendingTextureHeight;
-(int*) getBlendingResampledBaseAddrSizePtr;
-(GLuint*) getBlendingTextureName;
-(void) setBlendingTextureName: (GLuint*)p;
-(unsigned char**) getBlendingColorBufPtr;
-(char**) getBlendingResampledBaseAddrPtr;

- (void) drawRectFusion3:(NSRect)aRect withContext:(NSOpenGLContext *)ctx;						// overwriting drawRect in DCMView
- (void)loadTexturesComputeFusion3;																// overwrite loadTexturesCompute in DCMView
@end

@interface ViewerController(CSB)


- (ViewerController*) CSB_computeRegistrationWithMovingViewer:(ViewerController*) movingViewer; //used inside this plugin only, no overwriting
-(void) CSB_ActivateBlending:(ViewerController*) bC;											// overwriting ActivateBlending in ViewerController
-(void) CSB_ApplyCLUTString:(NSString*) str;													// overwriting ApplyCLUTString in ViewerController
@end



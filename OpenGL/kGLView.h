//
//  kGLView.h
//  CocoaGL
//
//  Created by Katherine Tattersall on Thu Jul 11 2002.
//  Copyright (c) 2001 ZeroByZero. All rights reserved.
// 

#import  <Cocoa/Cocoa.h>
#import  <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include <OpenGL/glext.h>

#define BITS_PER_PIXEL          32.0
#define DEPTH_SIZE              32.0
#define DEFAULT_TIME_INTERVAL 	0.002
#define NUMTEXTURES		1
#define NUMSTARS		50

typedef struct _star
{
    int r;
    int g;
    int b;
    float i;
    GLfloat distance;
    GLfloat angle;
    GLfloat tilt;
    GLfloat spin;
} Star;

@interface kGLView : NSOpenGLView
{
    bool FullScreenOn;
    bool first;
    bool lighting;
    bool blending;
    
    NSWindow *FullScreenWindow;
    NSWindow *StartingWindow;
    NSTimer  *time;
    
    GLint    drawing_type; 
    GLint    texture[ NUMTEXTURES ];
    Star     StarArray[ NUMSTARS ];
    
    float    dieangle;

    // we would need a set of these for however many lights we wanted to include
    GLfloat LightAmbient[4];
    GLfloat LightDiffuse[4];
    GLfloat LightPosition[4];
}
// Actions
- (IBAction)toggleFullScreen:(id)sender;
- (IBAction)setSolid:        (id)sender;
- (IBAction)setWireframe:    (id)sender;
- (IBAction)setPoints:       (id)sender;
- (IBAction)changeLighting:  (id)sender; 
- (IBAction)changeBlending:  (id)sender;

- (id)initWithFrame:(NSRect) frameRect;

- (void)getTextures;
- (void)loadPicture:(NSString *) name;

@end

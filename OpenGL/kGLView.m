//
//  kGLView.m
//  CocoaGL
//
//  Created by Katherine Tattersall on Thu Jul 11 2002.
//  Copyright (c) 2001 ZeroByZero. All rights reserved.
//  http://divide.zerobyzero.ca/

#import "kGLView.h"

@interface kGLView (privatestuff)
- (void) initGL;
- (void) setUpLights;
- (NSImage *) findImage: (NSString *)resource;
- (void) initStars;
- (void) drawStar;
@end


@implementation kGLView

- (id)initWithFrame:(NSRect) frameRect
{
    // First, we must create an NSOpenGLPixelFormatAttribute
    NSOpenGLPixelFormat *nsglFormat;
    NSOpenGLPixelFormatAttribute attr[] =
    {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
            NSOpenGLPFADoubleBuffer,
//			NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)32,
			0
	};


    [self setPostsFrameChangedNotifications: YES];

    // Next, we initialize the NSOpenGLPixelFormat itself
    nsglFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attr];

    // Check for errors in the creation of the NSOpenGLPixelFormat
    // If we could not create one, return nil (the OpenGL is not initialized, and
    // we should send an error message to the user at this point)
    if(!nsglFormat) { NSLog(@"Invalid format... terminating."); return nil; }

    // Now we create the the CocoaGL instance, using our initial frame and the NSOpenGLPixelFormat
    self = [super initWithFrame:frameRect pixelFormat:nsglFormat];
    [nsglFormat release];
    
    // If there was an error, we again should probably send an error message to the user
    if(!self) { NSLog(@"Self not created... terminating."); return nil; }

    // Now we set this context to the current context (means that its now drawable)
    [[self openGLContext] makeCurrentContext];

    // Finally, we call the initGL method (no need to make this method too long or complex)
    [self initGL];
    return self;
}

- (void)initGL
{    
    // Set the clear color to black. This is the color that your background will be if you don't draw to it
    // If setting to black, we needn't specifically say this, but it's good style to mention explicitly 
    // You can set the clear color to something else later, but it should not be between a glBegin and glEnd
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

    // Set the clear depth to 1. This is the initial (default) value.
    // Set the depth function. This specifies when something will be drawn. GL_LESS passes if the incoming
    // depth value is lESS than the current value
    // Turn the depth test on
    glClearDepth(1.0f);
    glDepthFunc(GL_LESS);
    glEnable(GL_DEPTH_TEST);

    // Set up a hint telling the computer to create the nicest (aka "costliest" or "most correct")
    // image it can
    // This hint is for the quality of color and texture mapping
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

    // This hint is for antialiasing
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

    glEnable(GL_TEXTURE_2D);
    glColorMaterial( GL_FRONT_AND_BACK, GL_DIFFUSE );
    glEnable(GL_COLOR_MATERIAL);
    
    [self setUpLights];
    [self getTextures];

    // the following two lines start blending
    glBlendFunc(GL_SRC_ALPHA,GL_ONE);
    glEnable( GL_BLEND );
    // unfortunately, the depth test will delete some of the sides if it isn't turned off
    // the correct way to do this is to sort the polygon
    glDisable(GL_DEPTH_TEST);
    blending = true;

    [self initStars];

    first = YES;
    drawing_type = GL_POLYGON;
    
    NSLog(@"end initGL");
}

- (void) setUpLights
{
    // enable the lighting and set our boolean to true
    glEnable(GL_LIGHTING);
    lighting = true;

    // set light 1's ambient light color
    LightAmbient[0] = 0.5f;
    LightAmbient[1] = 0.5f;
    LightAmbient[2] = 0.5f;
    LightAmbient[3] = 1.0f;

    // set light 1's diffuse light color
    LightDiffuse[0] = 1.0f;
    LightDiffuse[1] = 1.0f;
    LightDiffuse[2] = 1.0f;
    LightDiffuse[3] = 1.0f;

    // position light 1's origin
    LightPosition[0]= 0.0f;
    LightPosition[1]= 0.0f;
    LightPosition[2]= 2.0f;
    LightPosition[3]= 1.0f;

    // tell OpenGL about what we just did and turn the light on
    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);
    glLightfv(GL_LIGHT1, GL_POSITION,LightPosition);
    glEnable(GL_LIGHT1);
}

// awake from nib is called when the window opens
- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    time = [ [NSTimer scheduledTimerWithTimeInterval: DEFAULT_TIME_INTERVAL
                    target:self
                    selector:@selector(drawFrame)	//go to this method whenever the time comes
                    userInfo:nil
                    repeats:YES]
                    retain
                    ];
    // Add our timers to the EventTracking loop
    [[NSRunLoop currentRunLoop] addTimer: time forMode: NSEventTrackingRunLoopMode];
    // Add our timers to the ModelPanel loop
    [[NSRunLoop currentRunLoop] addTimer: time forMode: NSModalPanelRunLoopMode];
    NSLog(@"end awakeFromNib");
}


// this method is called whenever the window/control is reshaped
// it is also called when the control is first opened
- (void) reshape
{
    float aspect;
    NSSize bound = [self frame].size;
    aspect = bound.width / bound.height;
    // change the size of the viewport to the new width and height
    // this controls the affine transformation of x and y from normalized device 
    // coordinates to window coordinates (from the OpenGl 1.1 reference book, 2nd ed)
    glViewport(0, 0, bound.width, bound.height);
    glMatrixMode(GL_PROJECTION);
    // you must reload the identity before this or you'll lose your picture
    glLoadIdentity();
    gluPerspective(45.0f, (GLfloat)aspect, 0.1f,100.0f);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

- (void)drawFrame
{
    int i;
    // make this control the First Responder if this is the first time to draw the frame
    // there is probably some notification that would work more efficiently than this silly test
    // but I don't know what it is
    if( first )
    {
        first = NO; 
        if ([[NSApp keyWindow] makeFirstResponder:self] ) 
            NSLog( @"self apparently made first responder" );
        else 
            NSLog( @"self is not first responder"); 
    }

    // Make this context current
    [[self openGLContext] makeCurrentContext];
	[[self openGLContext] update];
	
    // Clear the buffers!
    glLoadIdentity();
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // this is where you would want to draw

    for( i = 0; i < NUMSTARS; i++ )
    {
        Star s = StarArray[i];
        // my god... it's full of stars....
    // in this case, we will not give the user the option to pick a different drawing style
    // since that would pretty much defeat the purpose of requiring the texture before we start
    // by the way, don't be stupid like me
    // load your identity :)
    glLoadIdentity();
    glTranslatef(0,0,-40); 		// move back so we can see the action

    glRotatef(s.tilt,1.0f,1.0f,0.0f);	// now tilt a bit
    glRotatef(s.angle,0.0,1.0,0.0);	// get the star to the proper angle
    glTranslatef(s.distance,0,0);	// set it away from the center
    glRotatef(-s.angle,0.0,1.0,0.0);	// bring it back to a normal (so we can see it)
    glRotatef(-s.tilt,1.0f,1.0f,0.0f);	// bring it back to a normal (so we can see it)

    glColor4ub(s.r,s.g,s.b,255);
    glBindTexture( GL_TEXTURE_2D, texture[0] );
    glBegin(GL_QUADS);
        glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,-1.0f, 0.0f);
	glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,-1.0f, 0.0f);
        glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f, 1.0f, 0.0f);
        glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f, 1.0f, 0.0f);
    glEnd();
        StarArray[i].distance-=0.05f;
        StarArray[i].angle+=(StarArray[i].i/(float)NUMSTARS); 

        if (StarArray[i].distance<0.0f)	// Is The Star In The Middle Yet
        {
            StarArray[i].distance+=20.0f;// Move The Star 5 Units From The Center
            StarArray[i].r=rand()%256;	// Give It A New Red Value
            StarArray[i].g=rand()%256;	// Give It A New Green Value
            StarArray[i].b=rand()%256;	// Give It A New Blue Value
        }
    }
	
    // flush the buffer! (send drawing to the screen)
    [[self openGLContext] flushBuffer];

}

- (void)initStars
{
    int i;
    for( i = 0; i < NUMSTARS; i++ )
    {
        // my god... it's full of stars....
        StarArray[i].distance = ((float)i/(float)NUMSTARS)*20.0f;
        StarArray[i].angle = (float)i/(float)NUMSTARS;
        StarArray[i].r = rand()%256; 
        StarArray[i].g = rand()%256; 
        StarArray[i].b = rand()%256; 
        StarArray[i].tilt = 90;
        StarArray[i].i = i;
        //NSLog(@"star %i: d=%f, a=%f", i, StarArray[i].distance, StarArray[i].angle);
    }
}

- (void)getTextures
{
    NSURL   *starURL;
    NSImage *starimage;
    
    NSLog(@"start getting the image");
    // get the URL for the star image
    // the application is in the build directory, one level up from our star
    starURL   = [[NSURL alloc] initFileURLWithPath: @"../star.bmp"];
    if( starURL != nil )
        NSLog(@"NSURL != nil");
    // load the star from the file
	
    starimage = [[NSImage alloc] initWithContentsOfFile:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Star.bmp"]];
    if( starimage == 0L) NSLog(@"no image...");
	
    [starimage setName:@"star"];
    
    // generate the texture objects references
    glGenTextures( NUMTEXTURES, texture );
    
    glBindTexture( GL_TEXTURE_2D, texture[0] );
    [self loadPicture: @"star"];

    // release the memory that was allocated
    [starURL release];
    [starimage release];
}

- (void) loadPicture: (NSString *) name
{
    NSBitmapImageRep *bitmap;
    // to use a picture, it must be included in the resources (under groups and files)
    NSImage *image; 
        
    // initialize the image to the correct file (name)
    image = [ NSImage imageNamed: name ];
    // create a bitmap with the correct image data
    bitmap = [[NSBitmapImageRep alloc]initWithData: [image TIFFRepresentation]];
    // if this bitmap is null, we should really free the texture
    if (bitmap == nil)
        { NSLog(@"in LoadGLTextures : NSBitmapImageRep not loaded"); return; }
    // we are aligned by BYTES in an NSBitmapImageRep
    glPixelStorei(GL_UNPACK_ALIGNMENT,   1   );
    // put the image into texture memory
    // the image has Red-Green-Blue-Alpha chanels, is width*height in size
    // and is made up of unsigned bytes
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 
                [bitmap size].width, [bitmap size].height, 0, 
                GL_RGB, GL_UNSIGNED_BYTE, [bitmap bitmapData]);
    // when we make the image smaller, use a linear filter on this texture
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    // when we magnify the image, use a linear filter on this texture
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    // let the bitmap go
    [bitmap release];
}



/* This is the preferred way to determine events */
// if you want to get events sent to you, you must make yourself a first responder
- (BOOL)acceptsFirstResponder
{
    return YES;
}
- (BOOL)becomeFirstResponder
{
    return YES;
}
// handle key down events
// if you don't handle this, the system beeps when you press a key (how annoying)
- (void)keyDown:(NSEvent *)theEvent
{
    NSLog( @"key down" );
}
// handle mouse up events (left mouse button)
- (void)mouseUp:(NSEvent *)theEvent
{
    NSLog( @"Mouse L up");    
}
// handle mouse up events (right mouse button)
- (void)rightMouseUp:(NSEvent *)theEvent
{
    NSLog( @"Mouse R up");
}
// handle mouse up events (other mouse button)
- (void)otherMouseUp:(NSEvent *)theEvent
{
    NSLog( @"Mouse O up");
}

@end

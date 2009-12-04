/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
			copyrights in this original Apple software (the "Apple Software"), to use,
			reproduce, modify and redistribute the Apple Software, with or without
			modifications, in source and/or binary forms; provided that if you redistribute
			the Apple Software in its entirety and without modifications, you must retain
			this notice and the following text and disclaimers in all such redistributions of
			the Apple Software.  Neither the name, trademarks, service marks or logos of
			Apple Computer, Inc. may be used to endorse or promote products derived from the
			Apple Software without specific prior written permission from Apple.  Except as
			expressly stated in this notice, no other rights or licenses, express or implied,
			are granted by Apple herein, including but not limited to any patent rights that
			may be infringed by your derivative works or by other works in which the Apple
			Software may be incorporated.

			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
			WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
			WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
			PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
			COMBINATION WITH YOUR PRODUCTS.

			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
			CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
			GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
			ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
			OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
			(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
			ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/* SampleCIView.m - simple OpenGL based CoreImage view */

#import "SampleCIView.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>

static CGRect centerSizeWithinRect(CGSize size, CGRect rect);

@implementation SampleCIView

+ (NSOpenGLPixelFormat *)defaultPixelFormat
{
    static NSOpenGLPixelFormat *pf;

    if (pf == nil)
    {
	/* Making sure the context's pixel format doesn't have a recovery
	 * renderer is important - otherwise CoreImage may not be able to
	 * create deeper context's that share textures with this one. */

	static const NSOpenGLPixelFormatAttribute attr[] = {
	    NSOpenGLPFAAccelerated,
	    NSOpenGLPFANoRecovery,
	    NSOpenGLPFAColorSize, 32,
	    0
	};

	pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];
    }

    return pf;
}

- (void)dealloc
{
	//NSLog(@"[SampleCIView dealloc]");
    [_image release];
    [_context release];

    [super dealloc];
}

- (CIImage *)image
{
    return [[_image retain] autorelease];
}

- (void)setImage:(CIImage *)image dirtyRect:(CGRect)r
{
    if (_image != image)
    {
	[_image release];
	_image = [image retain];

	if (CGRectIsInfinite (r))
	    [self setNeedsDisplay:YES];
	else
	    [self setNeedsDisplayInRect:*(NSRect *)&r];
    }
}

- (void)setImage:(CIImage *)image
{
    [self setImage:image dirtyRect:CGRectInfinite];
}

- (void)setCleanRect:(CGRect)cleanRect
{
	_cleanRect = cleanRect;
}

- (void)setDisplaySize:(CGSize)displaySize
{
	_displaySize = displaySize;
}

- (void)prepareOpenGL
{
    long parm = 1;

    /* Enable beam-synced updates. */

    [[self openGLContext] setValues:&parm forParameter:NSOpenGLCPSwapInterval];

    /* Make sure that everything we don't need is disabled. Some of these
     * are enabled by default and can slow down rendering. */

    glDisable (GL_ALPHA_TEST);
    glDisable (GL_DEPTH_TEST);
    glDisable (GL_SCISSOR_TEST);
    glDisable (GL_BLEND);
    glDisable (GL_DITHER);
    glDisable (GL_CULL_FACE);
    glColorMask (GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glDepthMask (GL_FALSE);
    glStencilMask (0);
    glClearColor (0.0f, 0.0f, 0.0f, 0.0f);
    glHint (GL_TRANSFORM_HINT_APPLE, GL_FASTEST);
}

- (void)viewBoundsDidChange:(NSRect)bounds
{
#pragma unused(bounds)
    /* For subclasses. */
}

- (void)updateMatrices
{
    NSRect r = [self bounds];

    if (!NSEqualRects (r, _lastBounds))
    {
	[[self openGLContext] update];

	/* Install an orthographic projection matrix (no perspective)
	 * with the origin in the bottom left and one unit equal to one
	 * device pixel. */

	glViewport (0, 0, r.size.width, r.size.height);

	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	glOrtho (0, r.size.width, 0, r.size.height, -1, 1);

	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();

	_lastBounds = r;

	[self viewBoundsDidChange:r];
    }
}

- (void)drawRect:(NSRect)r
{
    CGRect ir, rr;
    CGImageRef cgImage;

    [[self openGLContext] makeCurrentContext];

    /* Allocate a CoreImage rendering context using the view's OpenGL
     * context as its destination if none already exists. */

    if (_context == nil)
    {
	NSOpenGLPixelFormat *pf;

	pf = [self pixelFormat];
	if (pf == nil)
	    pf = [[self class] defaultPixelFormat];

	_context = [[CIContext contextWithCGLContext: CGLGetCurrentContext()
		     pixelFormat: [pf CGLPixelFormatObj] options: nil] retain];
    }

    ir = CGRectIntegral (*(CGRect *)&r);

    if ([NSGraphicsContext currentContextDrawingToScreen])
    {
	[self updateMatrices];

	/* Clear the specified subrect of the OpenGL surface then
	 * render the image into the view. Use the GL scissor test to
	 * clip to * the subrect. Ask CoreImage to generate an extra
	 * pixel in case * it has to interpolate (allow for hardware
	 * inaccuracies) */

	rr = CGRectIntersection (CGRectInset (ir, -1.0f, -1.0f),
				 *(CGRect *)&_lastBounds);

	glScissor (ir.origin.x, ir.origin.y, ir.size.width, ir.size.height);
	glEnable (GL_SCISSOR_TEST);

	glClear (GL_COLOR_BUFFER_BIT);

	if ([self respondsToSelector:@selector (drawRect:inCIContext:)])
	{
	    [self drawRect:*(NSRect *)&rr inCIContext:_context];
	}
	else if (_image != nil)
	{
		// use the commented out method if you don't want to perform scaling
	    //[_context drawImage:_image atPoint:rr.origin fromRect:rr];
		CGRect where = centerSizeWithinRect(_displaySize, *(CGRect *)&_lastBounds);
		[_context drawImage:_image inRect:where fromRect:_cleanRect];
	}

	glDisable (GL_SCISSOR_TEST);

	/* Flush the OpenGL command stream. If the view is double
	 * buffered this should be replaced by [[self openGLContext]
	 * flushBuffer]. */

	glFlush ();
    }
    else
    {
	/* Printing the view contents. Render using CG, not OpenGL. */

	if ([self respondsToSelector:@selector (drawRect:inCIContext:)])
	{
	    [self drawRect:*(NSRect *)&ir inCIContext:_context];
	}
	else if (_image != nil)
	{
	    cgImage = [_context createCGImage:_image fromRect:ir];

	    if (cgImage != NULL)
	    {
		CGContextDrawImage ([[NSGraphicsContext currentContext]
				     graphicsPort], ir, cgImage);
		CGImageRelease (cgImage);
	    }
	}
    }
}

@end

static CGRect centerSizeWithinRect(CGSize size, CGRect rect)
{
	float delta;
	if( CGRectGetHeight(rect) / CGRectGetWidth(rect) > size.height / size.width ) {
		// rect is taller: fit width
		delta = rect.size.height - size.height * CGRectGetWidth(rect) / size.width;
		rect.size.height -= delta;
		rect.origin.y += delta/2;
	}
	else {
		// rect is wider: fit height
		delta = rect.size.width - size.width * CGRectGetHeight(rect) / size.height;
		rect.size.width -= delta;
		rect.origin.x += delta/2;
	}
	return rect;
}

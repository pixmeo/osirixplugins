//
//  AlignDCMView.m
//  Align
//
//  Created by Jo‘l Spaltenstein on 7/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AlignDCMView.h"
#import "AlignController.h"
#import "AlignFilter.h"
#import "DCMPix.h"
#import "ROI.h"
#import "MPRController.h"
#import "gsl/gsl_linalg.h"
#import "AppController.h"

#include <Accelerate/Accelerate.h>


#define deg2rad (3.14159265358979/180.0)
#define BS 10.

@class OrthogonalMPRPETCTView;
@class OrthogonalMPRView;


static NSMutableDictionary *aligndcmview__instanceIDToIvars = nil;

static void DrawGLImageTile (unsigned long drawType, float imageWidth, float imageHeight, float textureWidth, float textureHeight, // stupid static function in DCMView, but at least I can make it work better in the trans. matrix stack....! -JS
                            float offsetX, float offsetY, float endX, float endY, Boolean texturesOverlap, Boolean textureRectangle)
{
	float startXDraw = offsetX;
	float endXDraw = endX;
	float startYDraw = offsetY;
	float endYDraw = endY;
	float texOverlap =  texturesOverlap ? 1.0f : 0.0f; // size of texture overlap, switch based on whether we are using overlap or not
	float startXTexCoord = texOverlap / (textureWidth + 2.0f * texOverlap); // texture right edge coordinate (stepped in one pixel for border if required)
	float endXTexCoord = 1.0f - startXTexCoord; // texture left edge coordinate (stepped in one pixel for border if required)
	float startYTexCoord = texOverlap / (textureHeight + 2.0f * texOverlap); // texture top edge coordinate (stepped in one pixel for border if required)
	float endYTexCoord = 1.0f - startYTexCoord; // texture bottom edge coordinate (stepped in one pixel for border if required)
	if (textureRectangle)
	{
		startXTexCoord = texOverlap; // texture right edge coordinate (stepped in one pixel for border if required)
		endXTexCoord = textureWidth + texOverlap; // texture left edge coordinate (stepped in one pixel for border if required)
		startYTexCoord = texOverlap; // texture top edge coordinate (stepped in one pixel for border if required)
		endYTexCoord = textureHeight + texOverlap; // texture bottom edge coordinate (stepped in one pixel for border if required)
	}
	if (endX > (imageWidth + 0.5)) // handle odd image sizes, (+0.5 is to ensure there is no fp resolution problem in comparing two fp numbers)
	{
		endXDraw = imageWidth; // end should never be past end of image, so set it there
		if (textureRectangle)
			endXTexCoord -= 1.0f;
		else
			endXTexCoord = 1.0f -  2.0f * startXTexCoord; // for the last texture in odd size images there are two texels of padding so step in 2
	}
	if (endY > (imageHeight + 0.5f)) // handle odd image sizes, (+0.5 is to ensure there is no fp resolution problem in comparing two fp numbers)
	{
		endYDraw = imageHeight; // end should never be past end of image, so set it there
		if (textureRectangle)
			endYTexCoord -= 1.0f;
		else
			endYTexCoord = 1.0f -  2.0f * startYTexCoord; // for the last texture in odd size images there are two texels of padding so step in 2
	}
	
	glBegin (drawType); // draw either tri strips of line strips (so this will drw either two tris or 3 lines)
		glTexCoord2f (startXTexCoord, startYTexCoord); // draw upper left in world coordinates
		glVertex3d (startXDraw, startYDraw, 0.0);

		glTexCoord2f (endXTexCoord, startYTexCoord); // draw lower left in world coordinates
		glVertex3d (endXDraw, startYDraw, 0.0);

		glTexCoord2f (startXTexCoord, endYTexCoord); // draw upper right in world coordinates
		glVertex3d (startXDraw, endYDraw, 0.0);

		glTexCoord2f (endXTexCoord, endYTexCoord); // draw lower right in world coordinates
		glVertex3d (endXDraw, endYDraw, 0.0);
	glEnd();
	
	// finish strips
/*	if (drawType == GL_LINE_STRIP) // draw top and bottom lines which were not draw with above
	{
		glBegin (GL_LINES);
			glVertex3d(startXDraw, endYDraw, 0.0); // top edge
			glVertex3d(startXDraw, startYDraw, 0.0);
	
			glVertex3d(endXDraw, startYDraw, 0.0); // bottom edge
			glVertex3d(endXDraw, endYDraw, 0.0);
		glEnd();
	}*/
}


static long GetNextTextureSize (long textureDimension, long maxTextureSize, Boolean textureRectangle)
{
	long targetTextureSize = maxTextureSize; // start at max texture size
	if (textureRectangle)
	{
		if (textureDimension >= targetTextureSize) // the texture dimension is greater than the target texture size (i.e., it fits)
			return targetTextureSize; // return corresponding texture size
		else
			return textureDimension; // jusr return the dimension
	}
	else
	{
		do // while we have txture sizes check for texture value being equal or greater
		{  
			if (textureDimension >= targetTextureSize) // the texture dimension is greater than the target texture size (i.e., it fits)
				return targetTextureSize; // return corresponding texture size
		}
		while (targetTextureSize >>= 1); // step down to next texture size smaller
	}
	return 0; // no textures fit so return zero
}

static long GetTextureNumFromTextureDim (long textureDimension, long maxTextureSize, Boolean texturesOverlap, Boolean textureRectangle) 
{
	// start at max texture size 
	// loop through each texture size, removing textures in turn which are less than the remaining texture dimension
	// each texture has 2 pixels of overlap (one on each side) thus effective texture removed is 2 less than texture size
	
	long i = 0; // initially no textures
	long bitValue = maxTextureSize; // start at max texture size
	long texOverlapx2 = texturesOverlap ? 2 : 0;
	textureDimension -= texOverlapx2; // ignore texture border since we are using effective texure size (by subtracting 2 from the initial size)
	if (textureRectangle)
	{
		// count number of full textures
		while (textureDimension > (bitValue - texOverlapx2)) // while our texture dimension is greater than effective texture size (i.e., minus the border)
		{
			i++; // count a texture
			textureDimension -= bitValue - texOverlapx2; // remove effective texture size
		}
		// add one partial texture
		i++; 
	}
	else
	{
		do
		{
			while (textureDimension >= (bitValue - texOverlapx2)) // while our texture dimension is greater than effective texture size (i.e., minus the border)
			{
				i++; // count a texture
				textureDimension -= bitValue - texOverlapx2; // remove effective texture size
			}
		}
		while ((bitValue >>= 1) > texOverlapx2); // step down to next texture while we are greater than two (less than 4 can't be used due to 2 pixel overlap)
	if (textureDimension > 0x0) // if any textureDimension is left there is an error, because we can't texture these small segments and in anycase should not have image pixels left
		NSLog (@"GetTextureNumFromTextureDim error: Texture to small to draw, should not ever get here, texture size remaining");
	}
	return i; // return textures counted
} 

@implementation AlignDCMView

- (id)initWithFrame:(NSRect)frame imageRows:(int)rows  imageColumns:(int)columns
{
	int i;
	float transMatrix[] = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
	self = [super initWithFrame:frame imageRows:rows imageColumns:columns];
	[self setTilingColorBuf:0L];
	[self setTileTextureName:0L];
	[self setTileBlendFactor:0.0];
	[self setTileTextureX:0L];
	[self setTileTextureY:0L];

	[self setBackgroundColorBuf:0L];
	[self setBackgroundTextureName:0L];
	[self setBackgroundTextureX:0L];
	[self setBackgroundTextureY:0L];
	[self setBackgroundTextureWidth:0L];
	[self setBackgroundTextureHeight:0L];
	[self setBackgroundPWidth:0L];
	[self setBackgroundPHeight:0L];

	for (i = 0; i < 5; i++)
		[self setControlPoint:i:NSMakePoint(0xFFFFFF, 0xFFFFFF)];
	
	[self setActiveControlPoints:0];
	[self setDraggingControlPoint:-1];
	
	[self setTransformationMatrix:transMatrix];
	[self setBackgroundTransformationMatrix:transMatrix];
	return self; 
}

- (void) dealloc {
	if (aligndcmview__instanceIDToIvars)
	{
		[aligndcmview__instanceIDToIvars removeObjectForKey:[self aligndcmview__instanceID]];
		if ([aligndcmview__instanceIDToIvars count] == 0)
		{
			[aligndcmview__instanceIDToIvars release];
			aligndcmview__instanceIDToIvars = nil;
		}
	}

	if([self tilingColorBuf]) free([self tilingColorBuf]);
	if([self backgroundColorBuf]) free([self backgroundColorBuf]);
	[self setTransformationMatrix:0L];
	[self setBackgroundTransformationMatrix:0L];
	[self setBackgroundTransMatrixStart:0L];
	
	if( [self tileTextureName])
	{
		glDeleteTextures ([self tileTextureX] * [self tileTextureY], [self tileTextureName]);
		free( [self tileTextureName]);
		[self setTileTextureName:0L];
	}
	if( [self backgroundTextureName])
	{
		glDeleteTextures ([self backgroundTextureX] * [self backgroundTextureY], [self backgroundTextureName]);
		free( [self backgroundTextureName]);
		[self setBackgroundTextureName:0L];
	}

	[super dealloc];
}

- (void) drawRect:(NSRect)aRect // AHH YUCKY YUCKY SCHIFO, but I can't see any other way to just sneak in some draw opperations -JS
{
	if ([self align_state] == AL_NORMAL)
	{
		[super drawRect:aRect];
		return;
	}
	[[self window] invalidateCursorRectsForView: self];

	long		clutBars	= [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long		annotations	= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
	
	if( noScale)
	{
		//scaleValue = 1;
		[self setScaleValue:1];
		origin.x = 0;
		origin.y = 0;
	}
	
	if ( [NSGraphicsContext currentContextDrawingToScreen] )
	{
		NSPoint offset;
		
		offset.y = offset.x = 0;
		
	//	if( QuartzExtreme)
	//	{
	//		NSRect bounds = [self bounds];
	//		[[NSColor clearColor] set];
	//		NSRectFill(bounds);
	//		
	//		NSRect ovalRect = NSMakeRect(0.0, 0.0, 50.0, 50.0);
	//		NSBezierPath *aPath = [NSBezierPath bezierPathWithOvalInRect:ovalRect];
	//		
	//		NSColor *color = [NSColor colorWithDeviceRed: 1.0 green: 0.0 blue: 0.0 alpha: 0.3];
	//		[color set];
	//		
	//		[aPath fill];
	//	}
		
		// Make this context current
		[[self openGLContext] makeCurrentContext];
//		[[self openGLContext] update];
		
		NSRect size = [self frame];
		
		glViewport (0, 0, size.size.width, size.size.height); // set the viewport to cover entire window
		
		glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
		glClear (GL_COLOR_BUFFER_BIT);
		
		if( dcmPixList && curImage > -1)
		{
			if( blendingView != 0L || [self tileView] != 0L || [self backgroundTextureName])
			{
				glBlendFunc(GL_ONE, GL_ZERO);
				glEnable( GL_BLEND);
			}
			else glDisable( GL_BLEND);
			
			[self drawRectIn:size :pTextureName :offset :textureX :textureY];
			
			if( [self tileView])
			{
				glPushMatrix();
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_DST_COLOR, GL_ZERO);
				
				if( [self tileTextureName])
				{
				//////// set up the transformation matrix
				float panzoom[] = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
				float hw = [curDCM pwidth]/2.0;
				float hh = [curDCM pheight]/2.0;				
				panzoom[1-1] = panzoom[6-1] = scaleValue;
				panzoom[13-1] = hw*scaleValue*-1.;
				panzoom[14-1] = hh*scaleValue*-1.;
				glMultMatrixf(panzoom);
				glMultMatrixf([self transformationMatrix]);
				////////	

					[[self tileView] drawTileIn:size :[self tileTextureName] :offset :[self tileTextureX] :[self tileTextureY]: scaleValue];
				}
				else
					NSLog( @"tileTextureName == 0L");
				glPopMatrix();
			}
			if([self backgroundTextureName])
			{
				glPushMatrix();
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_DST_COLOR, GL_ZERO);
				
				//////// set up the transformation matrix
				float panzoom[] = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
				float hw = [self backgroundPWidth]/2.0;
				float hh = [self backgroundPHeight]/2.0;				
				panzoom[1-1] = panzoom[6-1] = scaleValue;
				panzoom[13-1] = hw*scaleValue*-1.;
				panzoom[14-1] = hh*scaleValue*-1.;
				
				glMultMatrixf(panzoom);
				glMultMatrixf([self backgroundTransformationMatrix]);
				////////	

				[self  drawBackgroundIn:size :[self backgroundTextureName] :offset :[self backgroundTextureX] :[self backgroundTextureY]: scaleValue];
				glPopMatrix();
			}

			if( blendingView)
			{
				if( [curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingY] != 0 &&  [[NSUserDefaults standardUserDefaults] boolForKey:@"COPYSETTINGS"] == YES)
				{
					float vectorP[ 9], tempOrigin[ 3], tempOriginBlending[ 3];
					
					[curDCM orientation: vectorP];
					
					tempOrigin[ 0] = [curDCM originX] * vectorP[ 0] + [curDCM originY] * vectorP[ 1] + [curDCM originZ] * vectorP[ 2];
					tempOrigin[ 1] = [curDCM originX] * vectorP[ 3] + [curDCM originY] * vectorP[ 4] + [curDCM originZ] * vectorP[ 5];
					tempOrigin[ 2] = [curDCM originX] * vectorP[ 6] + [curDCM originY] * vectorP[ 7] + [curDCM originZ] * vectorP[ 8];
					
					tempOriginBlending[ 0] = [[blendingView curDCM] originX] * vectorP[ 0] + [[blendingView curDCM] originY] * vectorP[ 1] + [[blendingView curDCM] originZ] * vectorP[ 2];
					tempOriginBlending[ 1] = [[blendingView curDCM] originX] * vectorP[ 3] + [[blendingView curDCM] originY] * vectorP[ 4] + [[blendingView curDCM] originZ] * vectorP[ 5];
					tempOriginBlending[ 2] = [[blendingView curDCM] originX] * vectorP[ 6] + [[blendingView curDCM] originY] * vectorP[ 7] + [[blendingView curDCM] originZ] * vectorP[ 8];
					
					offset.x = (tempOrigin[0] + [curDCM pwidth]*[curDCM pixelSpacingX]/2. - (tempOriginBlending[ 0] + [[blendingView curDCM] pwidth]*[[blendingView curDCM] pixelSpacingX]/2.));
					offset.y = (tempOrigin[1] + [curDCM pheight]*[curDCM pixelSpacingY]/2. - (tempOriginBlending[ 1] + [[blendingView curDCM] pheight]*[[blendingView curDCM] pixelSpacingY]/2.));
					
					offset.x *= scaleValue;
					offset.x /= [curDCM pixelSpacingX];
					
					offset.y *= scaleValue;
					offset.y /= [curDCM pixelSpacingY];
				}
				else
				{
					offset.y = 0;
					offset.x = 0;
				}
				
				//NSLog(@"offset:%f - %f", offset.x, offset.y);
				
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_DST_COLOR, GL_ZERO);
				
				if( blendingTextureName)
					[blendingView drawRectIn:size :blendingTextureName :offset :blendingTextureX :blendingTextureY];
				else
					NSLog( @"blendingTextureName == 0L");
					
			}
			
			if( blendingView != 0L || [self tileView] != 0L)
				glDisable( GL_BLEND);

			
			// ***********************
			// DRAW CLUT BARS ********
			
			if( [(AlignController *)[[self window] windowController] is2DViewer] == YES && annotations != annotNone)
			{
				if( clutBars == barOrigin || clutBars == barBoth)
				{
					float			heighthalf = size.size.height/2 - 1;
					float			widthhalf = size.size.width/2 - 1;
					long			i;
					NSString		*tempString = 0L;
					
					#define BARPOSX1 50.f
					#define BARPOSX2 20.f
					
					heighthalf = 0;
					
					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
					glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f);
					
					glLineWidth(1.0);
					glBegin(GL_LINES);
					for( i = 0; i < 256; i++)
					{
						glColor3ub ( redTable[ i], greenTable[ i], blueTable[ i]);
						
						glVertex2f(  widthhalf - BARPOSX1, heighthalf - (-128.f + i));
						glVertex2f(  widthhalf - BARPOSX2, heighthalf - (-128.f + i));
					}
					glColor3ub ( 128, 128, 128);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX2 , heighthalf - -128.f);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);			glVertex2f(  widthhalf - BARPOSX2 , heighthalf - 127.f);
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);
					glVertex2f(  widthhalf - BARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  widthhalf - BARPOSX2, heighthalf - 127.f);
					glEnd();
					
					if( curWW < 50)
					{
						tempString = [NSString stringWithFormat: @"%0.4f", curWL - curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.4f", curWL];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.4f", curWL + curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
					}
					else
					{
						tempString = [NSString stringWithFormat: @"%0.0f", curWL - curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.0f", curWL];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
						
						tempString = [NSString stringWithFormat: @"%0.0f", curWL + curWW/2];
						[self DrawNSStringGL: tempString : labelFontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
					}
				} //clutBars == barOrigin || clutBars == barBoth
				
				if( blendingView)
				{
					if( clutBars == barFused || clutBars == barBoth)
					{
						unsigned char	*bred, *bgreen, *bblue;
						float			heighthalf = size.size.height/2 - 1;
						float			widthhalf = size.size.width/2 - 1;
//						long			yRaster = 1, xRaster, i;
						long			i;
						float			bwl, bww;
						NSString		*tempString = 0L;
						
						if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
						{
							bred = [DCMView PETredTable];
							bgreen = [DCMView PETgreenTable];
							bblue = [DCMView PETblueTable];
						}
						else [blendingView getCLUT:&bred :&bgreen :&bblue];
						
						#define BBARPOSX1 55.f
						#define BBARPOSX2 25.f
						
						heighthalf = 0;
						
						glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
						glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f);
						
						glLineWidth(1.0);
						glBegin(GL_LINES);
						for( i = 0; i < 256; i++)
						{
							glColor3ub ( bred[ i], bgreen[ i], bblue[ i]);
							
							glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - (-128.f + i));
							glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - (-128.f + i));
						}
						glColor3ub ( 128, 128, 128);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - -128.f);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - 127.f);
						glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);
						glVertex2f(  -widthhalf + BBARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - 127.f);
						glEnd();
						
						[blendingView getWLWW: &bwl :&bww];
						
						if( curWW < 50)
						{
							tempString = [NSString stringWithFormat: @"%0.4f", bwl - bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
							
							tempString = [NSString stringWithFormat: @"%0.4f", bwl];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
							
							tempString = [NSString stringWithFormat: @"%0.4f", bwl + bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
						}
						else
						{
							tempString = [NSString stringWithFormat: @"%0.0f", bwl - bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
							
							tempString = [NSString stringWithFormat: @"%0.0f", bwl];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
							
							tempString = [NSString stringWithFormat: @"%0.0f", bwl + bww/2];
							[self DrawNSStringGL: tempString : labelFontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
						}
					}
				} //blendingView
			} //[[[self window] windowController] is2DViewer] == YES
			
			
			//** SLICE CUT FOR 2D MPR
			if( cross.x != -9999 && cross.y != -9999 && [DCMView display2DMPRLines] == YES)
			{
				glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
				glEnable(GL_BLEND);
				glEnable(GL_POINT_SMOOTH);
				glEnable(GL_LINE_SMOOTH);
				glEnable(GL_POLYGON_SMOOTH);

				if(( mprVector[ 0] != 0 || mprVector[ 1] != 0))
				{
					float tvec[ 2];
						
					tvec[ 0] = cos((angle+90)*deg2rad);
					tvec[ 1] = sin((angle+90)*deg2rad);

					glColor3f (0.0f, 0.0f, 1.0f);
					
						// Thick Slab
						if( slab > 1)
						{
							float crossx, crossy;
							float slabx, slaby;

							glLineWidth(1.0);
							glBegin(GL_LINES);
							
							crossx = cross.x-[curDCM pwidth]/2.;
							crossy = cross.y-[curDCM pheight]/2.;
							
							slabx = (slab/2.)/[curDCM pixelSpacingX]*tvec[ 0];
							slaby = (slab/2.)/[curDCM pixelSpacingY]*tvec[ 1];
							
							glVertex2f( scaleValue * (crossx - 1000*mprVector[ 0] - slabx), scaleValue*(crossy - 1000*mprVector[ 1] - slaby));
							glVertex2f( scaleValue * (crossx + 1000*mprVector[ 0] - slabx), scaleValue*(crossy + 1000*mprVector[ 1] - slaby));

							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0]), scaleValue*(crossy - 1000*mprVector[ 1]));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0]), scaleValue*(crossy + 1000*mprVector[ 1]));

							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0] + slabx), scaleValue*(crossy - 1000*mprVector[ 1] + slaby));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0] + slabx), scaleValue*(crossy + 1000*mprVector[ 1] + slaby));
						}
						else
						{
							float crossx, crossy;
							
							glLineWidth(2.0);
							glBegin(GL_LINES);

							crossx = cross.x-[curDCM pwidth]/2.;
							crossy = cross.y-[curDCM pheight]/2.;
							
							glVertex2f( scaleValue*(crossx - 1000*mprVector[ 0]), scaleValue*(crossy - 1000*mprVector[ 1]));
							glVertex2f( scaleValue*(crossx + 1000*mprVector[ 0]), scaleValue*(crossy + 1000*mprVector[ 1]));
						}
					glEnd();
					
					if( [stringID isEqualToString:@"Original"])
					{
						glColor3f (1.0f, 0.0f, 0.0f);
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(cross.x-[curDCM pwidth]/2. - 1000*tvec[ 0]), scaleValue*(cross.y-[curDCM pheight]/2. - 1000*tvec[ 1]));
							glVertex2f( scaleValue*(cross.x-[curDCM pwidth]/2. + 1000*tvec[ 0]), scaleValue*(cross.y-[curDCM pheight]/2. + 1000*tvec[ 1]));
						glEnd();
					}
				}

				NSPoint crossB = cross;

				crossB.x -= [curDCM pwidth]/2.;
				crossB.y -= [curDCM pheight]/2.;
				
				crossB.x *=scaleValue;
				crossB.y *=scaleValue;
				
				glColor3f (1.0f, 0.0f, 0.0f);
				
		//		if( [stringID isEqualToString:@"Perpendicular"])
		//		{
		//			glLineWidth(2.0);
		//			glBegin(GL_LINES);
		//				glVertex2f( crossB.x-BS, crossB.y);
		//				glVertex2f(  crossB.x+BS, crossB.y);
		//				
		//				glVertex2f( crossB.x, crossB.y-BS);
		//				glVertex2f(  crossB.x, crossB.y+BS);
		//			glEnd();
		//		}
		//		else
				{
					glLineWidth(2.0);
//					glBegin(GL_LINE_LOOP);
//						glVertex2f( crossB.x-BS, crossB.y-BS);
//						glVertex2f( crossB.x+BS, crossB.y-BS);
//						glVertex2f( crossB.x+BS, crossB.y+BS);
//						glVertex2f( crossB.x-BS, crossB.y+BS);
//						glVertex2f( crossB.x-BS, crossB.y-BS);
//					glEnd();
					
					glBegin(GL_LINE_LOOP);
					
					long i;
					
					#define CIRCLERESOLUTION 20
					for(i = 0; i < CIRCLERESOLUTION ; i++)
					{
					  // M_PI defined in cmath.h
					  float alpha = i * 2 * M_PI /CIRCLERESOLUTION;
					  
					  glVertex2f( crossB.x + BS*cos(alpha), crossB.y + BS*sin(alpha));
					}
					glEnd();
				}
				glLineWidth(1.0);
				
				glColor3f (0.0f, 0.0f, 0.0f);
				
				glDisable(GL_LINE_SMOOTH);
				glDisable(GL_POLYGON_SMOOTH);
				glDisable(GL_POINT_SMOOTH);
				glDisable(GL_BLEND);
			}
			
			if (annotations != annotNone)
			{
//				long yRaster = 1, xRaster;
//				char cstr [400], *cptr;
			
				//    NSRect size = [self frame];
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f /(xFlipped ? -(size.size.width) : size.size.width), -2.0f / (yFlipped ? -(size.size.height) : size.size.height), 1.0f); // scale to port per pixel scale

				//FRAME RECT IF MORE THAN 1 WINDOW and IF THIS WINDOW IS THE FRONTMOST
				if(( [ViewerController numberOf2DViewer] > 1 && [[[self window] windowController] is2DViewer] == YES && stringID == 0L) || [stringID isEqualToString:@"OrthogonalMPRVIEW"])
				{
					if( [[self window] isMainWindow] && isKeyView)
					{
						float heighthalf = size.size.height/2 - 1;
						float widthhalf = size.size.width/2 - 1;
						
						glColor3f (1.0f, 0.0f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINE_LOOP);
							glVertex2f(  -widthhalf, -heighthalf);
							glVertex2f(  -widthhalf, heighthalf);
							glVertex2f(  widthhalf, heighthalf);
							glVertex2f(  widthhalf, -heighthalf);
						glEnd();
						glLineWidth(1.0);
					}
				}  //drawLines for ImageView Frames
				
				if ((_imageColumns > 1 || _imageRows > 1) && [[[self window] windowController] is2DViewer] == YES) {
					float heighthalf = size.size.height/2 - 1;
					float widthhalf = size.size.width/2 - 1;
					
					glColor3f (0.5f, 0.5f, 0.5f);
					glLineWidth(1.0);
					glBegin(GL_LINE_LOOP);
						glVertex2f(  -widthhalf, -heighthalf);
						glVertex2f(  -widthhalf, heighthalf);
						glVertex2f(  widthhalf, heighthalf);
						glVertex2f(  widthhalf, -heighthalf);
					glEnd();
					glLineWidth(1.0);
					if (isKeyView && [[self window] isMainWindow]) {
						float heighthalf = size.size.height/2 - 1;
						float widthhalf = size.size.width/2 - 1;
						
						glColor3f (1.0f, 0.0f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINE_LOOP);
							glVertex2f(  -widthhalf, -heighthalf);
							glVertex2f(  -widthhalf, heighthalf);
							glVertex2f(  widthhalf, heighthalf);
							glVertex2f(  widthhalf, -heighthalf);
						glEnd();
						glLineWidth(1.0);
					}
				}
				
				glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
				glTranslatef( origin.x + originOffset.x, -origin.y - originOffset.y, 0.0f);
				glScalef( 1.f, [curDCM pixelRatio], 1.f);
				
				// Draw ROIs
				BOOL drawROI = NO;
				
				if( [[[self window] windowController] is2DViewer] == YES) drawROI = [[[[self window] windowController] roiLock] tryLock];
				else drawROI = YES;
				
				if( drawROI)
				{
					rectArray = [[NSMutableArray alloc] initWithCapacity: [curRoiList count]];
					long i;
					for( i = 0; i < [curRoiList count]; i++)
					{
						[(ROI*)[curRoiList objectAtIndex:i] setRoiFont: labelFontListGL :labelFontListGLSize :self];
						[(ROI*)[curRoiList objectAtIndex:i] drawROI: scaleValue :[curDCM pwidth]/2. :[curDCM pheight]/2. :[curDCM pixelSpacingX] :[curDCM pixelSpacingY]];
					}
					
					if (!suppress_labels)
					{
						for( i = 0; i < [curRoiList count]; i++)
						{
							[(ROI*)[curRoiList objectAtIndex:i] drawTextualData];
						}
					}
					
					[rectArray release];
					rectArray = 0L;
				}
				
				if( drawROI && [[[self window] windowController] is2DViewer] == YES) [[[[self window] windowController] roiLock] unlock];
				
				// draw the controlPoints
				[self drawControlPoints: scaleValue :[curDCM pwidth]/2. :[curDCM pheight]/2. :[curDCM pixelSpacingX] :[curDCM pixelSpacingY]];
				
				// Draw 2D point cross (used when double-click in 3D panel)
				
				[self draw2DPointMarker];
				if( blendingView) [blendingView draw2DPointMarker];
				
				// Draw any Plugin objects
				
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat: scaleValue], @"scaleValue",
																						[NSNumber numberWithFloat: [curDCM pwidth]/2.], @"offsetx",
																						[NSNumber numberWithFloat: [curDCM pheight]/2.], @"offsety",
																						[NSNumber numberWithFloat: [curDCM pixelSpacingX]], @"spacingX",
																						[NSNumber numberWithFloat: [curDCM pixelSpacingY]], @"spacingY",
																						0L];
				
				[[NSNotificationCenter defaultCenter] postNotificationName: @"PLUGINdrawObjects" object: self userInfo: userInfo];
				
				//**SLICE CUR FOR 3D MPR
				if( stringID)
				{
					if( [stringID isEqualToString:@"OrthogonalMPRVIEW"])
					{
						[self subDrawRect: aRect];
						[self setScaleValue: scaleValue];
					}
					
					if( [stringID isEqualToString:@"MPR3D"])
					{
						long	xx, yy;
						
						[[[self window] windowController] getPlanes:&xx :&yy];
						
						glColor3f (0.0f, 0.0f, 1.0f);
			
						glLineWidth(2.0);
						glBegin(GL_LINES);
							glVertex2f( -origin.x -size.size.width/2.		, scaleValue * (yy-[curDCM pheight]/2.));
							glVertex2f( -origin.x -size.size.width/2 + 100   , scaleValue * (yy-[curDCM pheight]/2.));
							
							if( yFlipped)
							{
								glVertex2f( scaleValue * (xx-[curDCM pwidth]/2.), (origin.y -size.size.height/2.)/[curDCM pixelRatio]);
								glVertex2f( scaleValue * (xx-[curDCM pwidth]/2.), (origin.y -size.size.height/2. + 100)/[curDCM pixelRatio]);
							}
							else
							{
								glVertex2f( scaleValue * (xx-[curDCM pwidth]/2.), (origin.y +size.size.height/2.)/[curDCM pixelRatio]);
								glVertex2f( scaleValue * (xx-[curDCM pwidth]/2.), (origin.y +size.size.height/2. - 100)/[curDCM pixelRatio]);
							}
						glEnd();
					}
				}
				
				
				//** SLICE CUT BETWEEN SERIES
				
				if( stringID == 0L)
				{
					glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
					glEnable(GL_BLEND);
					glEnable(GL_POINT_SMOOTH);
					glEnable(GL_LINE_SMOOTH);
					glEnable(GL_POLYGON_SMOOTH);

					if( sliceVector[ 0] != 0 | sliceVector[ 1] != 0  | sliceVector[ 2] != 0 )
					{
				
						glColor3f (0.0f, 0.6f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePoint[ 0] - 1000*sliceVector[ 0]), scaleValue*(slicePoint[ 1] - 1000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePoint[ 0] + 1000*sliceVector[ 0]), scaleValue*(slicePoint[ 1] + 1000*sliceVector[ 1]));
						glEnd();
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointI[ 0] - 1000*sliceVector[ 0]), scaleValue*(slicePointI[ 1] - 1000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePointI[ 0] + 1000*sliceVector[ 0]), scaleValue*(slicePointI[ 1] + 1000*sliceVector[ 1]));
						glEnd();
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointO[ 0] - 1000*sliceVector[ 0]), scaleValue*(slicePointO[ 1] - 1000*sliceVector[ 1]));
							glVertex2f( scaleValue*(slicePointO[ 0] + 1000*sliceVector[ 0]), scaleValue*(slicePointO[ 1] + 1000*sliceVector[ 1]));
						glEnd();
						
						if( slicePoint3D[ 0] != 0 | slicePoint3D[ 1] != 0  | slicePoint3D[ 2] != 0 )
						{
							float vectorP[ 9], tempPoint3D[ 3], rotateVector[ 2];
							
						//	glColor3f (0.6f, 0.0f, 0.0f);
							
							[curDCM orientation: vectorP];
							
							glLineWidth(2.0);
							
						//	NSLog(@"Before: %2.2f / %2.2f / %2.2f", slicePoint3D[ 0], slicePoint3D[ 1], slicePoint3D[ 2]);
							
							slicePoint3D[ 0] -= [curDCM originX];
							slicePoint3D[ 1] -= [curDCM originY];
							slicePoint3D[ 2] -= [curDCM originZ];
							
							tempPoint3D[ 0] = slicePoint3D[ 0] * vectorP[ 0] + slicePoint3D[ 1] * vectorP[ 1] + slicePoint3D[ 2] * vectorP[ 2];
							tempPoint3D[ 1] = slicePoint3D[ 0] * vectorP[ 3] + slicePoint3D[ 1] * vectorP[ 4] + slicePoint3D[ 2] * vectorP[ 5];
							tempPoint3D[ 2] = slicePoint3D[ 0] * vectorP[ 6] + slicePoint3D[ 1] * vectorP[ 7] + slicePoint3D[ 2] * vectorP[ 8];
							
							slicePoint3D[ 0] += [curDCM originX];
							slicePoint3D[ 1] += [curDCM originY];
							slicePoint3D[ 2] += [curDCM originZ];
							
						//	NSLog(@"After: %2.2f / %2.2f / %2.2f", tempPoint3D[ 0], tempPoint3D[ 1], tempPoint3D[ 2]);
							
							tempPoint3D[0] /= [curDCM pixelSpacingX];
							tempPoint3D[1] /= [curDCM pixelSpacingY];
							
							tempPoint3D[0] -= [curDCM pwidth]/2.;
							tempPoint3D[1] -= [curDCM pheight]/2.;
							
							rotateVector[ 0] = sliceVector[ 1];
							rotateVector[ 1] = -sliceVector[ 0];
							
							glBegin(GL_LINES);
								glVertex2f( scaleValue*(tempPoint3D[ 0]-20/[curDCM pixelSpacingX] *(rotateVector[ 0])), scaleValue*(tempPoint3D[ 1]-20/[curDCM pixelSpacingY]*(rotateVector[ 1])));
								glVertex2f( scaleValue*(tempPoint3D[ 0]+20/[curDCM pixelSpacingX] *(rotateVector[ 0])), scaleValue*(tempPoint3D[ 1]+20/[curDCM pixelSpacingY]*(rotateVector[ 1])));
							glEnd();
							
							glLineWidth(1.0);
						}
					}
					
					if( sliceVector2[ 0] != 0 | sliceVector2[ 1] != 0  | sliceVector2[ 2] != 0 )
					{
						glColor3f (0.0f, 0.6f, 0.0f);
						glLineWidth(2.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePoint2[ 0] - 1000*sliceVector2[ 0]), scaleValue*(slicePoint2[ 1] - 1000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePoint2[ 0] + 1000*sliceVector2[ 0]), scaleValue*(slicePoint2[ 1] + 1000*sliceVector2[ 1]));
						glEnd();
						glLineWidth(1.0);
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointI2[ 0] - 1000*sliceVector2[ 0]), scaleValue*(slicePointI2[ 1] - 1000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePointI2[ 0] + 1000*sliceVector2[ 0]), scaleValue*(slicePointI2[ 1] + 1000*sliceVector2[ 1]));
						glEnd();
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(slicePointO2[ 0] - 1000*sliceVector2[ 0]), scaleValue*(slicePointO2[ 1] - 1000*sliceVector2[ 1]));
							glVertex2f( scaleValue*(slicePointO2[ 0] + 1000*sliceVector2[ 0]), scaleValue*(slicePointO2[ 1] + 1000*sliceVector2[ 1]));
						glEnd();
					}
					
					glDisable(GL_LINE_SMOOTH);
					glDisable(GL_POLYGON_SMOOTH);
					glDisable(GL_POINT_SMOOTH);
					glDisable(GL_BLEND);
				}
				
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f / size.size.width, -2.0f /  size.size.height, 1.0f); // scale to port per pixel scale
				
				glColor3f (0.0f, 1.0f, 0.0f);
				
				 if( annotations >= annotBase)
				 {
					//** PIXELSPACING LINES
					glBegin(GL_LINES);
					if ([curDCM pixelSpacingX] != 0 && [curDCM pixelSpacingX] * 1000.0 < 1)
					{
						glVertex2f(scaleValue  * (-0.02/[curDCM pixelSpacingX]), size.size.height/2 - 12); 
						glVertex2f(scaleValue  * (0.02/[curDCM pixelSpacingX]), size.size.height/2 - 12);

						glVertex2f(-size.size.width/2 + 10 , scaleValue  * (-0.02/[curDCM pixelSpacingY]*[curDCM pixelRatio])); 
						glVertex2f(-size.size.width/2 + 10 , scaleValue  * (0.02/[curDCM pixelSpacingY]*[curDCM pixelRatio]));

						short i, length;
						for (i = -20; i<=20; i++)
						{
							if (i % 10 == 0) length = 10;
							else  length = 5;
						
							glVertex2f(i*scaleValue *0.001/[curDCM pixelSpacingX], size.size.height/2 - 12);
							glVertex2f(i*scaleValue *0.001/[curDCM pixelSpacingX], size.size.height/2 - 12 - length);
							
							glVertex2f(-size.size.width/2 + 10 +  length,  i* scaleValue *0.001/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
							glVertex2f(-size.size.width/2 + 10,  i* scaleValue * 0.001/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
						}
					}
					else
					{
						glVertex2f(scaleValue  * (-50/[curDCM pixelSpacingX]), size.size.height/2 - 12); 
						glVertex2f(scaleValue  * (50/[curDCM pixelSpacingX]), size.size.height/2 - 12);
						
						glVertex2f(-size.size.width/2 + 10 , scaleValue  * (-50/[curDCM pixelSpacingY]*[curDCM pixelRatio])); 
						glVertex2f(-size.size.width/2 + 10 , scaleValue  * (50/[curDCM pixelSpacingY]*[curDCM pixelRatio]));

						short i, length;
						for (i = -5; i<=5; i++)
						{
							if (i % 5 == 0) length = 10;
							else  length = 5;
						
							glVertex2f(i*scaleValue *10/[curDCM pixelSpacingX], size.size.height/2 - 12);
							glVertex2f(i*scaleValue *10/[curDCM pixelSpacingX], size.size.height/2 - 12 - length);
							
							glVertex2f(-size.size.width/2 + 10 +  length,  i* scaleValue *10/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
							glVertex2f(-size.size.width/2 + 10,  i* scaleValue * 10/[curDCM pixelSpacingY]*[curDCM pixelRatio]);
						}
					}
					glEnd();
					
					[self drawTextualData: size :annotations];
					
				} //annotations >= annotBase
				} //Annotation  != None
			}  
		
		else {  //no valid image  ie curImage = -1
			//NSLog(@"no IMage");
			glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
			glClear (GL_COLOR_BUFFER_BIT);
		}
		
	// Swap buffer to screen
		[[self openGLContext] flushBuffer];
		
//		GLenum err = glGetError();
//		if (GL_NO_ERROR != err)
//		{
//			NSString * errString = [NSString stringWithFormat:@"Error: %d.", err];
//			NSLog (@"%@\n", errString);
//		}
		
	}  //[NSGraphicsContext currentContextDrawingToScreen] 
	else  //not drawing to screen
	{
//        long		width, height;
//		NSRect		dstRect;
//		float		scale;
//		
//		NSLog(@"size: %f, %f", aRect.size.width, aRect.size.height);
//		
//		NSImage *im = [self nsimage:YES];
//		
//		[im setScalesWhenResized:YES];
//        
//		[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
//		
//		if( [im size].width / aRect.size.width > [im size].height / aRect.size.height)
//		{
//			scale = [im size].width / aRect.size.width;
//		}
//		else
//		{
//			scale = [im size].height / aRect.size.height;
//		}
//		
//		dstRect = NSMakeRect( 0, 0, [im size].width / scale, [im size].height / scale);
//		
//		[im drawRepresentation:[im bestRepresentationForDevice:nil] inRect:dstRect]; 
	}
}

- (void) drawBackgroundIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY: (float) scale;
{	
	long effectiveTextureMod = 0; // texture size modification (inset) to account for borders
	long x, y, k = 0, offsetY, offsetX = 0, currTextureWidth, currTextureHeight;

	
//	if( [curDCM pixelRatio] != 1.0)
//	{
//		glScalef( 1.f, [curDCM pixelRatio], 1.f);
//	}
	
	effectiveTextureMod = 0;	//2;	//OVERLAP
	
	glEnable (TEXTRECTMODE); // enable texturing
	glColor4f (1.0f, 1.0f, 1.0f, 1.0f); 
	
	for (x = 0; x < tX; x++) // for all horizontal textures
	{
			// use remaining to determine next texture size
			currTextureWidth = GetNextTextureSize ([self backgroundTextureWidth] - offsetX, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // current effective texture width for drawing
			offsetY = 0; // start at top
			for (y = 0; y < tY; y++) // for a complete column
			{
					// use remaining to determine next texture size
					currTextureHeight = GetNextTextureSize ([self backgroundTextureHeight] - offsetY, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // effective texture height for drawing
					glBindTexture(TEXTRECTMODE, texture[k++]); // work through textures in same order as stored, setting each texture name as current in turn
					DrawGLImageTile (GL_TRIANGLE_STRIP, [self backgroundPWidth], [self backgroundPHeight],		//
										currTextureWidth, currTextureHeight, // draw this single texture on two tris 
										offsetX,  offsetY, 
										currTextureWidth + offsetX, 
										currTextureHeight + offsetY, 
										false, f_ext_texture_rectangle);		// OVERLAP
//					DrawGLImageTile (GL_TRIANGLE_STRIP, [curDCM pwidth], [curDCM pheight], (scaleValue),		//
//										currTextureWidth, currTextureHeight, // draw this single texture on two tris 
//										offsetX,  offsetY, 
//										currTextureWidth + offsetX, 
//										currTextureHeight + offsetY, 
//										false, f_ext_texture_rectangle);		// OVERLAP
					offsetY += currTextureHeight; // offset drawing position for next texture vertically
			}
			offsetX += currTextureWidth; // offset drawing position for next texture horizontally
	}
	
    glDisable (TEXTRECTMODE); // done with texturing
}

- (void) drawTileIn:(NSRect) size :(GLuint *) texture :(NSPoint) offset :(long) tX :(long) tY: (float) scale;
{	
	long effectiveTextureMod = 0; // texture size modification (inset) to account for borders
	long x, y, k = 0, offsetY, offsetX = 0, currTextureWidth, currTextureHeight;

	
//	if( [curDCM pixelRatio] != 1.0)
//	{
//		glScalef( 1.f, [curDCM pixelRatio], 1.f);
//	}
	
	effectiveTextureMod = 0;	//2;	//OVERLAP
	
	glEnable (TEXTRECTMODE); // enable texturing
	glColor4f (1.0f, 1.0f, 1.0f, 1.0f); 
	
	for (x = 0; x < tX; x++) // for all horizontal textures
	{
			// use remaining to determine next texture size
			currTextureWidth = GetNextTextureSize (textureWidth - offsetX, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // current effective texture width for drawing
			offsetY = 0; // start at top
			for (y = 0; y < tY; y++) // for a complete column
			{
					// use remaining to determine next texture size
					currTextureHeight = GetNextTextureSize (textureHeight - offsetY, maxTextureSize, f_ext_texture_rectangle) - effectiveTextureMod; // effective texture height for drawing
					glBindTexture(TEXTRECTMODE, texture[k++]); // work through textures in same order as stored, setting each texture name as current in turn
					DrawGLImageTile (GL_TRIANGLE_STRIP, [curDCM pwidth], [curDCM pheight],		//
										currTextureWidth, currTextureHeight, // draw this single texture on two tris 
										offsetX,  offsetY, 
										currTextureWidth + offsetX, 
										currTextureHeight + offsetY, 
										false, f_ext_texture_rectangle);		// OVERLAP
//					DrawGLImageTile (GL_TRIANGLE_STRIP, [curDCM pwidth], [curDCM pheight], (scaleValue),		//
//										currTextureWidth, currTextureHeight, // draw this single texture on two tris 
//										offsetX,  offsetY, 
//										currTextureWidth + offsetX, 
//										currTextureHeight + offsetY, 
//										false, f_ext_texture_rectangle);		// OVERLAP
					offsetY += currTextureHeight; // offset drawing position for next texture vertically
			}
			offsetX += currTextureWidth; // offset drawing position for next texture horizontally
	}
	
    glDisable (TEXTRECTMODE); // done with texturing
}

-(void) becomeMainWindow
{
	AppController *appController = 0L;
	appController = [AppController sharedAppController];
//	[self setFusion: thickSlabMode :-1]; // this is the only difference from the superclass's method, but I don;t want this called, it forces a reload of textures

	NSLog(@"BecomeMainWindow");
	[[NSNotificationCenter defaultCenter] postNotificationName: @"DCMNewImageViewResponder" object: self userInfo: 0L];
	
	sliceVector[ 0] = sliceVector[ 1] = sliceVector[ 2] = 0;
	sliceVector2[ 0] = sliceVector2[ 1] = sliceVector2[ 2] = 0;
	[self sendSyncMessage:0];
	
	[appController setXFlipped: xFlipped];
	[appController setYFlipped: yFlipped];
	
	[self setNeedsDisplay:YES];
}


- (GLuint *) loadTextureIn:(GLuint *) texture blending:(BOOL) blending colorBuf: (unsigned char**) colorBufPtr textureX:(long*) tX textureY:(long*) tY redTable:(unsigned char*) rT greenTable:(unsigned char*) gT blueTable:(unsigned char*) bT 
{
// joel
    maxTextureSize = 1024;
//    maxNPOTDTextureSize = 2048;
// endjoel
	if(  rT == 0L)
	{
		rT = redTable;
		gT = greenTable;
		bT = blueTable;
	}

	if( curDCM == 0L) NSLog( @"err curDCM == 0L");
	
	if( noScale == YES)
	{
		[curDCM changeWLWW :127 : 256];
	}
	
//	if( mainThread != [NSThread currentThread])
//	{
//		NSLog(@"Warning! OpenGL activity NOT in the main thread???");
//	}
	
    if( texture)
	{
		glDeleteTextures( *tX * *tY, texture);
		free( (char*) texture);
		texture = 0L;
	}
	
	if( [curDCM isRGB] == YES)
	{
		if((colorTransfer == YES) || (blending == YES))
		{
			vImage_Buffer src, dest;
			
			[curDCM changeWLWW :curWL: curWW];
			
			src.height = [curDCM pheight];
			src.width = [curDCM pwidth];
			src.rowBytes = [curDCM rowBytes];
			src.data = [curDCM baseAddr];
			
			dest.height = [curDCM pheight];
			dest.width = [curDCM pwidth];
			dest.rowBytes = [curDCM rowBytes];
			dest.data = [curDCM baseAddr];
			
			if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
			{
				unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
				long i;
				
				for( i = 0; i < 256; i++)
				{
					credTable[ i] = rT[ i] * redFactor;
					cgreenTable[ i] = gT[ i] * greenFactor;
					cblueTable[ i] = bT[ i] * blueFactor;
				}
				#if __BIG_ENDIAN__
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
				#else
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) &alphaTable, 0);
				#endif
			}
			else
			{
				#if __BIG_ENDIAN__
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
				#else
				vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) bT, (Pixel_8*) gT, (Pixel_8*) rT, (Pixel_8*) &alphaTable, 0);
				#endif
			}
		}
		else if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
		{
			unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
			long i;
			
			vImage_Buffer src, dest;
			
			[curDCM changeWLWW :curWL: curWW];
			
			src.height = [curDCM pheight];
			src.width = [curDCM pwidth];
			src.rowBytes = [curDCM rowBytes];
			src.data = [curDCM baseAddr];
			
			dest.height = [curDCM pheight];
			dest.width = [curDCM pwidth];
			dest.rowBytes = [curDCM rowBytes];
			dest.data = [curDCM baseAddr];
			
			for( i = 0; i < 256; i++)
			{
				credTable[ i] = rT[ i] * redFactor;
				cgreenTable[ i] = gT[ i] * greenFactor;
				cblueTable[ i] = bT[ i] * blueFactor;
			}
			#if __BIG_ENDIAN__
			vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
			#else
			vImageTableLookUp_ARGB8888( &dest, &dest, (Pixel_8*) &cblueTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &credTable, (Pixel_8*) &alphaTable, 0);
			#endif

		}
	}
	else if( (colorTransfer == YES) || (blending == YES))
	{
		if( *colorBufPtr)
		{
			free( *colorBufPtr);
		}
// joel block comment
/*		*colorBufPtr = malloc( [curDCM rowBytes] * [curDCM pheight] * 4);
		
		vImage_Buffer src8, dest8;
		
		src8.height = [curDCM pheight];
		src8.width = [curDCM pwidth];
		src8.rowBytes = [curDCM rowBytes];
		src8.data = [curDCM baseAddr];
		
		dest8.height = [curDCM pheight];
		dest8.width = [curDCM pwidth];
		dest8.rowBytes = [curDCM rowBytes]*4;
		dest8.data = *colorBufPtr;
*/		

// joel start
		*tX = GetTextureNumFromTextureDim (textureWidth, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
		*tY = GetTextureNumFromTextureDim (textureHeight, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
//		int temp_textureSize = GetNextTextureSize (textureWidth, maxTextureSize, f_ext_texture_rectangle);
//		int temp_textureSize = GetNextTextureSize (textureWidth, maxTextureSize, NO);
		int temp_textureSize = GetNextTextureSize (textureWidth, maxTextureSize, f_ext_texture_rectangle);
	//	int textureSize = GetNextTextureSize (textureWidth, maxTextureSize, NO);
		if (temp_textureSize < GetNextTextureSize(textureHeight, maxTextureSize, f_ext_texture_rectangle))
		temp_textureSize = GetNextTextureSize(textureHeight, maxTextureSize, f_ext_texture_rectangle);
		
		*colorBufPtr = malloc(*tX * *tY * temp_textureSize * temp_textureSize * 4);

		vImage_Buffer src8, dest8;
		
		src8.height = *tY * temp_textureSize;
		src8.width = *tX * temp_textureSize;
		src8.rowBytes = *tX * temp_textureSize;
		src8.data = [curDCM baseAddr];
		
		dest8.height = *tY * temp_textureSize;
		dest8.width = *tX * temp_textureSize;
		dest8.rowBytes = *tX * temp_textureSize *4;
		dest8.data = *colorBufPtr;
// joel end
		vImageConvert_Planar8toARGB8888(&src8, &src8, &src8, &src8, &dest8, 0);
		
		if( redFactor != 1.0 || greenFactor != 1.0 || blueFactor != 1.0)
		{
			unsigned char  credTable[256], cgreenTable[256], cblueTable[256];
			long i;
			
			for( i = 0; i < 256; i++)
			{
				credTable[ i] = rT[ i] * redFactor;
				cgreenTable[ i] = gT[ i] * greenFactor;
				cblueTable[ i] = bT[ i] * blueFactor;
			}
			vImageTableLookUp_ARGB8888( &dest8, &dest8, (Pixel_8*) &alphaTable, (Pixel_8*) &credTable, (Pixel_8*) &cgreenTable, (Pixel_8*) &cblueTable, 0);
		}
		else vImageTableLookUp_ARGB8888( &dest8, &dest8,
		 (Pixel_8*) &alphaTable, (Pixel_8*) rT, (Pixel_8*) gT, (Pixel_8*) bT, 0);
	}

// joel	
//	[curDCM setBaseAddr:[self texturetiledImage:[curDCM baseAddr]: [curDCM pwidth]:[curDCM pheight]: [curDCM rowBytes]: 2048]];
// end joel	
	
//	glDisable(GL_TEXTURE_2D);
    glEnable(TEXTRECTMODE);
	
	if( [curDCM isRGB] == YES || [curDCM thickSlabMode] == YES) textureWidth = [curDCM rowBytes]/4;
    else textureWidth = [curDCM rowBytes];
	
	textureHeight = [curDCM pheight];
	
// joel comment
//    glPixelStorei (GL_UNPACK_ROW_LENGTH, textureWidth); // set image width in groups (pixels), accounts for border this ensures proper image alignment row to row
// endjoel

    // get number of textures x and y
    // extract the number of horiz. textures needed to tile image
    *tX = GetTextureNumFromTextureDim (textureWidth, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
    // extract the number of horiz. textures needed to tile image
    *tY = GetTextureNumFromTextureDim (textureHeight, maxTextureSize, false, f_ext_texture_rectangle); //OVERLAP
	
	texture = (GLuint *) malloc ((long) sizeof (GLuint) * *tX * *tY);

	
//	NSLog( @"%d %d - No Of Textures: %d", textureWidth, textureHeight, *tX * *tY);
	if( *tX * *tY > 1) NSLog(@"NoOfTextures: %d", *tX * *tY);
//joel comment
//	glTextureRangeAPPLE(TEXTRECTMODE, textureWidth * textureHeight * 4, [curDCM baseAddr]);
// end joel
// joel
	int textureSize = GetNextTextureSize (textureWidth, maxTextureSize, f_ext_texture_rectangle);
//	int textureSize = GetNextTextureSize (textureWidth, maxTextureSize, NO);
	if (textureSize < GetNextTextureSize(textureHeight, maxTextureSize, f_ext_texture_rectangle))
		textureSize = GetNextTextureSize(textureHeight, maxTextureSize, f_ext_texture_rectangle);
// endjoel

	glGenTextures (*tX * *tY, texture); // generate textures names need to support tiling
    {
            long x, y, k = 0, offsetY, offsetX = 0, currWidth, currHeight; // texture iterators, texture name iterator, image offsets for tiling, current texture width and height
            for (x = 0; x < *tX; x++) // for all horizontal textures
            {
				currWidth = GetNextTextureSize (textureWidth - offsetX, maxTextureSize, f_ext_texture_rectangle); // use remaining to determine next texture size 
				
				offsetY = 0; // reset vertical offest for every column
				for (y = 0; y < *tY; y++) // for all vertical textures
				{
					unsigned char * pBuffer;
					
					if( [curDCM isRGB] == YES || [curDCM thickSlabMode] == YES)
					{
//joel				
//						pBuffer =   (unsigned char*) [curDCM baseAddr] +			//baseAddr // I'm not sure how this could work... -JS
//									offsetY * [curDCM rowBytes] +      //depth
//									offsetX * 4;							//depth
						pBuffer =  (unsigned char*)[curDCM baseAddr] + (((x * *tY) + y) * textureSize * textureSize * 4);							//depth
					}
//					else if( (colorTransfer == YES) || (blending == YES))
//						pBuffer =  *colorBufPtr +			//baseAddr
//									offsetY * [curDCM rowBytes] * 4 +      //depth
//									offsetX * 4;							//depth
					else if( (colorTransfer == YES) || (blending == YES))
						pBuffer =  *colorBufPtr + (((x * *tY) + y) * textureSize * textureSize * 4);							//depth
//					else pBuffer =  (unsigned char*) [curDCM baseAddr] +			
//									offsetY * [curDCM rowBytes] +      
//									offsetX;							
					else pBuffer = (unsigned char*)[curDCM baseAddr] + (((x * *tY) + y) * textureSize * textureSize);
// endjoel
					
					currHeight = GetNextTextureSize (textureHeight - offsetY, maxTextureSize, f_ext_texture_rectangle); // use remaining to determine next texture size
					glBindTexture (TEXTRECTMODE, texture[k++]);
					
					glTexParameterf (TEXTRECTMODE, GL_TEXTURE_PRIORITY, 1.0f);
					
					if (f_ext_client_storage) glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 1);	// Incompatible with GL_TEXTURE_STORAGE_HINT_APPLE
					else  glPixelStorei (GL_UNPACK_CLIENT_STORAGE_APPLE, 0);
					
					if (f_arb_texture_rectangle && f_ext_texture_rectangle)
					{
						if( textureWidth > 2048 && textureHeight > 2048 || [self class] == [OrthogonalMPRPETCTView class] || [self class] == [OrthogonalMPRView class])
						{
							glTexParameteri (TEXTRECTMODE, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);		//<- this produce 'artefacts' when changing WL&WW for small matrix in RGB images... if	GL_UNPACK_CLIENT_STORAGE_APPLE is set to 1
						}
					}
// joel
					glPixelStorei (GL_UNPACK_ROW_LENGTH, textureSize); // set image width in groups (pixels), accounts for border this ensures proper image alignment row to row
// endjoel						
					if( [[NSUserDefaults standardUserDefaults] boolForKey:@"NOINTERPOLATION"])
					{
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
					}
					else
					{
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
						glTexParameteri (TEXTRECTMODE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
					}
					glTexParameteri (TEXTRECTMODE, GL_TEXTURE_WRAP_S, edgeClampParam);
					glTexParameteri (TEXTRECTMODE, GL_TEXTURE_WRAP_T, edgeClampParam);
					
					#if __BIG_ENDIAN__
					if( [curDCM isRGB] == YES || [curDCM thickSlabMode] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
					else if( (colorTransfer == YES) | (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
					else glTexImage2D (TEXTRECTMODE, 0, GL_INTENSITY8, currWidth, currHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pBuffer);
					#else
					if( [curDCM isRGB] == YES || [curDCM thickSlabMode] == YES) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, pBuffer);
					else if( (colorTransfer == YES) | (blending == YES)) glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, currWidth, currHeight, 0, GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8_REV, pBuffer);
					else glTexImage2D (TEXTRECTMODE, 0, GL_INTENSITY8, currWidth, currHeight, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, pBuffer);
					#endif
					
					offsetY += currHeight;// - 2 * 1; // OVERLAP, offset in for the amount of texture used, 
					//  since we are overlapping the effective texture used is 2 texels less than texture width
				}
				offsetX += currWidth;// - 2 * 1; // OVERLAP, offset in for the amount of texture used, 
				//  since we are overlapping the effective texture used is 2 texels less than texture width
            }
    }
    glDisable (TEXTRECTMODE);
	
	return texture;
}

-(unsigned char*) getRawPixels:(long*) width :(long*) height :(long*) spp :(long*) bpp :(BOOL) screenCapture :(BOOL) force8bits :(BOOL) removeGraphical
{
	unsigned char* return_value;
	[self setCLUT:0:0:0];
	[curDCM changeWLWW :127 : 256];

	[curDCM setBaseAddr:[curDCM deTexturetiledImage:[curDCM baseAddr]: 1024]];
	return_value = [super getRawPixelsWidth:width height:height spp:spp bpp:bpp screenCapture:screenCapture force8bits:force8bits removeGraphical:removeGraphical squarePixels: NO allTiles: NO allowSmartCropping: NO origin: 0L spacing: 0L];
	[curDCM setBaseAddr:[curDCM texturetiledImage:[curDCM baseAddr]: 1024]];
	[self loadTextures];
	[self setNeedsDisplay:YES];
	return return_value;
}

- (void) drawControlPoints :(float) scale :(float) offsetx :(float) offsety :(float) spacingX :(float) spacingY
{
	int i;
	float the_angle;
	
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_LINE_SMOOTH);
	glEnable(GL_POLYGON_SMOOTH);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
	glPointSize(3);
	
	// draw X
	if ([self controlPoint0].x != 0xFFFFFF &&  [self controlPoint0].y != 0xFFFFFF)
	{
		glColor4f (1.0f, 0.0f, 0.0f, 1.0f);
		glBegin( GL_LINES);
			glVertex2f(([self controlPoint0].x  - offsetx)*scale - 4, ([self controlPoint0].y  - offsety)*scale - 4);
			glVertex2f(([self controlPoint0].x  - offsetx)*scale + 4, ([self controlPoint0].y  - offsety)*scale + 4);
			glVertex2f(([self controlPoint0].x  - offsetx)*scale - 4, ([self controlPoint0].y  - offsety)*scale + 4);
			glVertex2f(([self controlPoint0].x  - offsetx)*scale + 4, ([self controlPoint0].y  - offsety)*scale - 4);
		glEnd();
	}
			
	// draw O
	if ([self controlPoint1].x != 0xFFFFFF &&  [self controlPoint1].y != 0xFFFFFF)
	{
		glColor4f (0.0f, 1.0f, 0.0f, 1.0f);
		glBegin(GL_LINE_LOOP);
		for(i = 0; i < 10 ; i++)
		{
			the_angle = i * 2. * M_PI / 10.;
			glVertex2f( ([self controlPoint1].x - offsetx)*scaleValue + 4*cos(the_angle), ([self controlPoint1].y - offsety)*scaleValue + 4*sin(the_angle));
		}
		glEnd();
	}
			
	// draw tri
	if ([self controlPoint2].x != 0xFFFFFF &&  [self controlPoint2].y != 0xFFFFFF)
	{
		glColor4f (0.0f, 0.0f, 1.0f, 1.0f);
		glBegin(GL_LINE_LOOP);
		for(i = 0; i < 3 ; i++)
		{
		  // M_PI defined in cmath.h
			the_angle = ((i * 2. * M_PI) / 3.) + M_PI/2.;
			glVertex2f( ([self controlPoint2].x - offsetx)*scaleValue + 4*cos(the_angle), ([self controlPoint2].y - offsety)*scaleValue + 4*sin(the_angle));
		}
		glEnd();
	}
			
	// draw +
	if ([self controlPoint3].x != 0xFFFFFF &&  [self controlPoint3].y != 0xFFFFFF)
	{
		glColor4f (1.0f, 1.0f, 0.0f, 1.0f);
		glBegin( GL_LINES);
			glVertex2f(([self controlPoint3].x  - offsetx)*scale, ([self controlPoint3].y  - offsety)*scale - 4);
			glVertex2f(([self controlPoint3].x  - offsetx)*scale, ([self controlPoint3].y  - offsety)*scale + 4);
			glVertex2f(([self controlPoint3].x  - offsetx)*scale - 4, ([self controlPoint3].y  - offsety)*scale);
			glVertex2f(([self controlPoint3].x  - offsetx)*scale + 4, ([self controlPoint3].y  - offsety)*scale);
		glEnd();
	}

	// draw square
	if ([self controlPoint4].x != 0xFFFFFF &&  [self controlPoint3].y != 0xFFFFFF)
	{
		glColor4f (1.0f, 0.0f, 1.0f, 1.0f);
		glBegin(GL_LINE_LOOP);
			glVertex2f(([self controlPoint4].x  - offsetx)*scale - 4, ([self controlPoint4].y  - offsety)*scale - 4);
			glVertex2f(([self controlPoint4].x  - offsetx)*scale - 4, ([self controlPoint4].y  - offsety)*scale + 4);
			glVertex2f(([self controlPoint4].x  - offsetx)*scale + 4, ([self controlPoint4].y  - offsety)*scale + 4);
			glVertex2f(([self controlPoint4].x  - offsetx)*scale + 4, ([self controlPoint4].y  - offsety)*scale - 4);
		glEnd();
	}
}

- (void) mergeImages
{
	float* newfImage;
	int i;
	float newOrigin[3];
	float *background_trans_matrix = [self backgroundTransformationMatrix];
	
	if ([self align_state] != AL_MOSAIC || [self tileView] == 0)
		return;
	
	// find the size of the image that needs to be created
	NSRect mergedBounds = NSMakeRect(0, 0, [curDCM pwidth], [curDCM pheight]);
	NSRect transformedTileBounds = NSMakeRect(0, 0, 0.1, 0.1);
	NSRect transformedPoint = NSMakeRect(0, 0, 0.1, 0.1);
	
	transformedTileBounds.origin = [self transformPoint:NSMakePoint(0, 0)];
	transformedPoint.origin = [self transformPoint:NSMakePoint([[[self tileView] curDCM] pwidth], 0)];
	transformedTileBounds = NSUnionRect(transformedTileBounds, transformedPoint);
	transformedPoint.origin = [self transformPoint:NSMakePoint(0, [[[self tileView] curDCM] pheight])];
	transformedTileBounds = NSUnionRect(transformedTileBounds, transformedPoint);
	transformedPoint.origin = [self transformPoint:NSMakePoint([[[self tileView] curDCM] pwidth], [[[self tileView] curDCM] pheight])];
	transformedTileBounds = NSUnionRect(transformedTileBounds, transformedPoint);
	
	mergedBounds = NSUnionRect(transformedTileBounds, mergedBounds);
	mergedBounds.size.height++;
	mergedBounds.size.width++;

	mergedBounds.size.width /= 2;
	mergedBounds.size.height /= 2;
	mergedBounds = NSIntegralRect(mergedBounds);
	mergedBounds.size.height *= 2;
	mergedBounds.size.width *= 2;
	
	
	unsigned char* temp8888Planar = malloc(mergedBounds.size.width*mergedBounds.size.height*4);
	bzero(temp8888Planar, mergedBounds.size.width*mergedBounds.size.height*4);
//	unsigned char* temp8Planar = malloc(mergedBounds.size.width*mergedBounds.size.height);
	
	[self renderToMemory: mergedBounds: temp8888Planar];
	newfImage = malloc(mergedBounds.size.width*mergedBounds.size.height*sizeof(float) + 100);
//	bzero(newfImage, mergedBounds.size.width*mergedBounds.size.height*sizeof(float) + 100);
	for (i = 0; i < mergedBounds.size.width*mergedBounds.size.height; i++) // should do this with one of the vImageConvert calls,
		newfImage[i] = temp8888Planar[i*4];
	free(temp8888Planar);

	NSPoint oldOrigin = [self origin];
	[self setOrigin:NSMakePoint([self origin].x + (mergedBounds.origin.x + (mergedBounds.size.width/2.0) - [curDCM pwidth]/2.0)*scaleValue,
										[self origin].y - (mergedBounds.origin.y + mergedBounds.size.height/2.0 - [curDCM pheight]/2.0)*scaleValue)];
	background_trans_matrix[13-1] += (oldOrigin.x - [self origin].x)/scaleValue;
	background_trans_matrix[14-1] -= (oldOrigin.y - [self origin].y)/scaleValue;
	
	[curDCM setfImage:newfImage];
	[curDCM setBaseAddr: malloc(mergedBounds.size.width*mergedBounds.size.height)];
	[curDCM setRowBytes:mergedBounds.size.width];
	[curDCM setPwidth:mergedBounds.size.width];
	[curDCM setPheight:mergedBounds.size.height];

	[curDCM setRGB: NO];
	
	[curDCM changeWLWW:[curDCM wl] :[curDCM ww]];

	
	newOrigin[0] = [curDCM originX] + mergedBounds.origin.x;
	newOrigin[1] = [curDCM originY] + mergedBounds.origin.y;
	newOrigin[2] = [curDCM originZ];
//	[curDCM setOrigin:newOrigin];
	
//	[[[self tileView] curDCM] pwidth]
//	[self setOrigin:NSMakePoint([self origin].x + 1000,
//										[self origin].y + 1000)];
//	[self setOriginOffset:NSMakePoint([self originOffset].x + 1000,
//										[self originOffset].y + 1000)];
	[self setTiling:0L];
	for (i = 0; i < 5; i++)
		[self setControlPoint:i:NSMakePoint(0xFFFFFF, 0xFFFFFF)];
	[self setActiveControlPoints:0];
	
	[self loadTextures];
	[self setNeedsDisplay:YES];
}

- (void) renderToMemory: (NSRect) bounds: (unsigned char*) memory // code ripped from myx_gc_view.cpp of mySQL
{
	[[self openGLContext] makeCurrentContext];

	GLenum glFormat = GL_RGBA;
	bool canUseFBOs = YES;
	int x, y;
//  if (format == GC_COLOR_FORMAT_BGRA)
//    glFormat = GL_BGRA;

//  bool canUseFBOs = canvas()->supportsExtension(GC_OE_FRAME_BUFFER_OBJECTS);
//  if (canUseFBOs)
//  {
	// Get current draw buffer for later restoration.
	GLint currentDrawBuffer = 0;
	glGetIntegerv(GL_DRAW_BUFFER, &currentDrawBuffer);

	// Make sure we do not allocate more buffer space than supported.
	GLint maxBufferSize = 0x7FFFFFFF;
	glGetIntegerv(GL_MAX_RENDERBUFFER_SIZE_EXT, &maxBufferSize);

	GLint maxViewport[2];
	glGetIntegerv(GL_MAX_VIEWPORT_DIMS, maxViewport);

	// Determine area to render.
	int width = bounds.size.width;
	int height =  bounds.size.height;

	int bufferWidth = 0;
	int bufferHeight = 0;

	GLuint frameBuffer = 0;
	GLuint renderBuffer = 0;

	GLenum status = GL_FRAMEBUFFER_UNSUPPORTED_EXT;
	if (maxBufferSize > 1024)
		maxBufferSize = 1024; // let's not trust any wild claims the graphics card might make
	while (maxBufferSize >= 128)
	{
		// Set maximum possible viewport here (restore old one on exit).
		bufferWidth = (maxViewport[0] < maxBufferSize) ? maxViewport[0] : maxBufferSize;
		bufferHeight = (maxViewport[1] < maxBufferSize) ? maxViewport[1] : maxBufferSize;

		if (width < bufferWidth)
			bufferWidth = width;
		if (height < bufferHeight)
			bufferHeight = height;

		// Frame buffer objects allow for hardware accelerated off-screen rendering.
		glGenFramebuffersEXT(1, &frameBuffer);
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, frameBuffer);
		glGenRenderbuffersEXT(1, &renderBuffer);
		glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, renderBuffer);
		glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_RENDERBUFFER_EXT, renderBuffer);

		glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_RGBA8, bufferWidth, bufferHeight); 

		// Check validity of the frame buffer and try other configs if possible. 
		// If all fails go back to traditional rendering, but don't expect good results then.
		status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);
		if (status != GL_FRAMEBUFFER_UNSUPPORTED_EXT)
			break;

		// The FBO configuration did not work, so free the buffers and try again with smaller size.
		glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);
		glDeleteRenderbuffersEXT(1, &renderBuffer);
		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
		glDeleteFramebuffersEXT(1, &frameBuffer);
		maxBufferSize = maxBufferSize / 2;
	}

	if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
		canUseFBOs = false;
    
// make the appropriate textures
	long tempMosTextureX = 0, tempMosTextureY = 0;
	long tempTileTextureX = 0, tempTileTextureY = 0;
	unsigned char* tempMosColorBuf = 0;
	unsigned char* tempTileColorBuf = 0;
	GLuint*	tempMosTextureName = 0;
	GLuint*	tempTileTextureName = 0;
	unsigned char ct[256];
	int i;
	for (i= 0; i < 256; i++)
		ct[i] = (float) i;
	
	float oldRedFactor = redFactor, oldGreenFactor = greenFactor, oldBlueFactor = blueFactor;
	redFactor = greenFactor = blueFactor = 1.0;
	
	[curDCM changeWLWW :127 : 256];
	tempMosTextureName = [self loadTextureIn:tempMosTextureName blending:YES colorBuf:&tempMosColorBuf textureX:&tempMosTextureX textureY:&tempMosTextureY redTable:ct greenTable:ct blueTable:ct];
	[[[self tileView] curDCM] changeWLWW :127 : 256];
	tempTileTextureName = [[self tileView] loadTextureIn:tempTileTextureName blending:YES colorBuf:&tempTileColorBuf textureX:&tempTileTextureX textureY:&tempTileTextureY redTable:ct greenTable:ct blueTable:ct];

	redFactor = oldRedFactor;
	greenFactor = oldGreenFactor;
	blueFactor = oldBlueFactor;

    // Now that we know the dimensions we can set the viewport.
	glViewport(0, 0, bufferWidth, bufferHeight);

	if (canUseFBOs)
	{
		glPixelStoref(GL_PACK_ROW_LENGTH, bufferWidth);
//		glPixelStoref(GL_PACK_ROW_LENGTH, width);
		unsigned char* drawingBuffer = malloc(bufferWidth * bufferHeight * 4);
		// Render the entire workspace by splitting it in pieces of the render buffer size.
		for (y = 0; y < height; y += (bufferHeight - 1))
		{
			for (x = 0; x < width; x += (bufferWidth - 1))
			{
				int currentWidth = (width - x < bufferWidth) ? (int) (width - x) : bufferWidth;
				int currentHeight = (height - y < bufferHeight) ? (int) (height - y) : bufferHeight;

//				float verticalOffset = height - y - currentHeight;
				int verticalOffset = y;
				int offset = (verticalOffset * width + x) * 4; // * 4 because we have 4 components per pixel.

				glMatrixMode(GL_PROJECTION);
				glLoadIdentity();
				glOrtho(bounds.origin.x + x, bounds.origin.x + x + bufferWidth, bounds.origin.y + y, bounds.origin.y + y + bufferHeight, -1, 1);
				
				glMatrixMode(GL_MODELVIEW);
				glLoadIdentity();

				glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
				glClear (GL_COLOR_BUFFER_BIT);
				
				
//				glBlendEquation(GL_FUNC_ADD);
//				glBlendFunc(GL_ONE, GL_ZERO);
//				glEnable( GL_BLEND);

				[self drawTileIn:bounds :tempMosTextureName :NSMakePoint(0,0) :tempMosTextureX :tempMosTextureY: 1];

				glMultMatrixf([self transformationMatrix]);
				[[self tileView] drawTileIn:bounds :tempTileTextureName :NSMakePoint(0,0) :tempTileTextureX :tempTileTextureY: 1];

				glFlush(); 
				glReadPixels(0, 0, currentWidth, currentHeight, glFormat, GL_UNSIGNED_BYTE, drawingBuffer);
				unsigned char* ptr = memory + offset;
				for (i = 0; i < currentHeight; i++)
				{
					memcpy(ptr, drawingBuffer + i*bufferWidth*4, currentWidth * 4);
					ptr += width*4;
				}
//				glReadPixels(0, 0, currentWidth, currentHeight, glFormat, GL_UNSIGNED_BYTE, memory + offset);
//				glReadPixels(0, bufferHeight - currentHeight, currentWidth, currentHeight, glFormat, GL_UNSIGNED_BYTE, memory + offset);
			}
		}
		free(drawingBuffer);
		glPixelStoref(GL_PACK_ROW_LENGTH, 0);
	}
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

// free up the textures
	glDeleteTextures( tempMosTextureX * tempMosTextureY, tempMosTextureName);
	if(tempMosTextureName)
		free(tempMosTextureName);
	if (tempMosColorBuf)
		free(tempMosColorBuf);

	glDeleteTextures( tempTileTextureX * tempTileTextureY, tempTileTextureName);
	if(tempTileTextureName)
		free(tempTileTextureName);
	if (tempTileColorBuf)
		free(tempTileColorBuf);
    // Release frame buffer binding to enable normal rendering again.
    glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);
    glDeleteRenderbuffersEXT(1, &renderBuffer);
    glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
    glDeleteFramebuffersEXT(1, &frameBuffer);

	if (!canUseFBOs)
	{
		NSLog(@"error creating FBO");
	}
}


-(void) setScaleValueCentered:(float) x
{
	[super setScaleValueCentered:x];
	
	if ([self align_state] == AL_MOSAIC)
		[self recalcTransMatrix];
}

-(void) setScaleValue:(float) x;
{
	[super setScaleValue:x];
	
	if ([self align_state] == AL_MOSAIC)
		[self recalcTransMatrix];
}

- (NSPoint) transformPoint:(NSPoint) pt;
{
	float* transMatrix = [self transformationMatrix];
	NSPoint newPoint;
	float w;
	
	if (transMatrix == 0L)
		return NSMakePoint(0, 0);
	
	w = pt.x * transMatrix[4-1] + pt.y * transMatrix[8-1] + transMatrix[12-1] + transMatrix[16-1];
	newPoint.x = pt.x * transMatrix[1-1] + pt.y * transMatrix[5-1] + transMatrix[9-1] + transMatrix[13-1];
	newPoint.y = pt.x * transMatrix[2-1] + pt.y * transMatrix[6-1] + transMatrix[10-1] + transMatrix[14-1];
	newPoint.x /= w;
	newPoint.y /= w;

	return newPoint;
}

- (void) recalcTransMatrix
{
	float transMatrix[] = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0};
	
	if ([self tileView])
	{
		switch ([self activeControlPoints])
		{
		case 1:
			// single point translation
			transMatrix[13 - 1] = [self controlPoint0].x - [[self tileView] controlPoint0].x;
			transMatrix[14 - 1] = [self controlPoint0].y - [[self tileView] controlPoint0].y;
			break;
		case 2:
		{
			// double point translate rotate and zoom
			NSPoint cb0 = [self controlPoint0];
			NSPoint cb1 = [self controlPoint1];
			NSPoint ca0 = [[self tileView] controlPoint0];
			NSPoint ca1 = [[self tileView] controlPoint1];

			float distance = (ca0.x - ca1.x) * (ca0.x - ca1.x) + (ca0.y - ca1.y) * (ca0.y - ca1.y);
			transMatrix[1 - 1] = ((ca0.x-ca1.x) * (cb0.x-cb1.x) + (ca0.y-ca1.y)*(cb0.y-cb1.y))/distance;
			transMatrix[5 - 1] = ((cb0.x-cb1.x) * (ca0.y-ca1.y) - (ca0.x-ca1.x)*(cb0.y-cb1.y))/distance;
			transMatrix[2 - 1] = ((cb1.x-cb0.x) * (ca0.y-ca1.y) + (ca0.x-ca1.x)*(cb0.y-cb1.y))/distance;
			transMatrix[6 - 1] = transMatrix[1 - 1];

			transMatrix[13 - 1] = (ca1.x*ca1.x*cb0.x + ca0.x*ca0.x*cb1.x + (ca0.y-ca1.y)*(cb1.x*ca0.y-cb0.x*ca1.y)+ca1.x*ca0.y*(cb1.y-cb0.y)-ca0.x*(ca1.x*(cb0.x+cb1.x)+ca1.y*(cb1.y-cb0.y)))/distance;
			transMatrix[14 - 1] = (ca0.x*(cb1.x-cb0.x)*ca1.y+ca1.x*ca1.x*cb0.y+ca0.x*ca0.x*cb1.y+(ca0.y-ca1.y)*(ca0.y*cb1.y-ca1.y*cb0.y)+ca1.x*(cb0.x*ca0.y-cb1.x*ca0.y-ca0.x*(cb0.y+cb1.y)))/distance;
			break;
		}
		case 3:
		{
			// three point transformation
	 		NSPoint C0 = [self controlPoint0];
			NSPoint C1 = [self controlPoint1];
			NSPoint C2 = [self controlPoint2];
		
			NSPoint c0 = [[self tileView] controlPoint0];
			NSPoint c1 = [[self tileView] controlPoint1];
			NSPoint c2 = [[self tileView] controlPoint2];
			
			double a_data[] = {	c0.x, c0.y, 1,    0,    0, 0,
								   0,    0, 0, c0.x, c0.y, 1,
								c1.x, c1.y, 1,    0,    0, 0,
								   0,    0, 0, c1.x, c1.y, 1,
								c2.x, c2.y, 1,    0,    0, 0,
								   0,    0, 0, c2.x, c2.y, 1};
		
			double b_data[] = {C0.x, C0.y, C1.x, C1.y, C2.x, C2.y};

			
			gsl_matrix_view m = gsl_matrix_view_array (a_data, 6, 6);
			gsl_vector_view b = gsl_vector_view_array (b_data, 6);
		   
			gsl_vector *x = gsl_vector_alloc (6);

			int s;
			gsl_permutation * p = gsl_permutation_alloc (6);
			gsl_linalg_LU_decomp (&m.matrix, p, &s);
			gsl_linalg_LU_solve (&m.matrix, p, &b.vector, x);

			transMatrix[1 - 1] = gsl_vector_get(x, 0);
			transMatrix[2 - 1] = gsl_vector_get(x, 3);
			transMatrix[5 - 1] = gsl_vector_get(x, 1);
			transMatrix[6 - 1] = gsl_vector_get(x, 4);
			transMatrix[13 - 1] = gsl_vector_get(x, 2);
			transMatrix[14 - 1] = gsl_vector_get(x, 5);

			/*printf ("x = \n");

			gsl_vector_fprintf (stdout, x, "%g");
			gsl_vector_free(x);
			gsl_permutation_free(p);*/
			break;
		}
		case 4:
		{
			// four point transformation
			// tile is small letters, local is caps
	 		NSPoint C0 = [self controlPoint0];
			NSPoint C1 = [self controlPoint1];
			NSPoint C2 = [self controlPoint2];
			NSPoint C3 = [self controlPoint3];

			NSPoint c0 = [[self tileView] controlPoint0];
			NSPoint c1 = [[self tileView] controlPoint1];
			NSPoint c2 = [[self tileView] controlPoint2];
			NSPoint c3 = [[self tileView] controlPoint3];

			double a_data[] = {	c0.x, c0.y, 1,    0,    0, 0, -1*C0.x*c0.x, -1*C0.x*c0.y,
								   0,    0, 0, c0.x, c0.y, 1, -1*C0.y*c0.x, -1*C0.y*c0.y,
								c1.x, c1.y, 1,    0,    0, 0, -1*C1.x*c1.x, -1*C1.x*c1.y,
								   0,    0, 0, c1.x, c1.y, 1, -1*C1.y*c1.x, -1*C1.y*c1.y,
								c2.x, c2.y, 1,    0,    0, 0, -1*C2.x*c2.x, -1*C2.x*c2.y,
								   0,    0, 0, c2.x, c2.y, 1, -1*C2.y*c2.x, -1*C2.y*c2.y,
								c3.x, c3.y, 1,    0,    0, 0, -1*C3.x*c3.x, -1*C3.x*c3.y,
								   0,    0, 0, c3.x, c3.y, 1, -1*C3.y*c3.x, -1*C3.y*c3.y };

			double b_data[] = {C0.x, C0.y, C1.x, C1.y, C2.x, C2.y, C3.x, C3.y};
			
			gsl_matrix_view m = gsl_matrix_view_array (a_data, 8, 8);
			gsl_vector_view b = gsl_vector_view_array (b_data, 8);
		   
			gsl_vector *x = gsl_vector_alloc (8);

			int s;
			gsl_permutation * p = gsl_permutation_alloc (8);
			gsl_linalg_LU_decomp (&m.matrix, p, &s);
			gsl_linalg_LU_solve (&m.matrix, p, &b.vector, x);
			
			transMatrix[1 - 1] = gsl_vector_get(x, 0);
			transMatrix[2 - 1] = gsl_vector_get(x, 3);
			transMatrix[3 - 1] = gsl_vector_get(x, 6);
			transMatrix[4 - 1] = gsl_vector_get(x, 6);
			transMatrix[5 - 1] = gsl_vector_get(x, 1);
			transMatrix[6 - 1] = gsl_vector_get(x, 4);
			transMatrix[7 - 1] = gsl_vector_get(x, 7);
			transMatrix[8 - 1] = gsl_vector_get(x, 7);
			transMatrix[9 - 1] = 0;
			transMatrix[10 - 1] = 0;
			transMatrix[11 - 1] = 0;
			transMatrix[12 - 1] = 0;
			transMatrix[13 - 1] = gsl_vector_get(x, 2);
			transMatrix[14 - 1] = gsl_vector_get(x, 5);
			transMatrix[15 - 1] = 1;
			transMatrix[16 - 1] = 1;
			
			/*printf ("x = \n");
			gsl_vector_fprintf (stdout, x, "%g");
			gsl_vector_free(x);
			gsl_permutation_free(p);*/
		}
		}
	}
	[self setTransformationMatrix:transMatrix];
}

- (void) setControlPointCount:(long) pointCount
{

	if ([self align_state] == AL_MOSAIC && [self tileView] != 0)
	{
		[[self tileView] setControlPointCount:pointCount];
		return;
	}
	
	
	if ([self align_state] == AL_TILE)
	{
		int i;
		[self setActiveControlPoints:pointCount];
		for (i = 0; i < pointCount; i++)
			if ([self controlPoint:i].x == 0xFFFFFF &&  [self controlPoint:i].y == 0xFFFFFF)
				[self setControlPoint:i:NSMakePoint([curDCM pwidth]/2.0 + (i%2)*50, [curDCM pheight]/2.0 + (i<2?0:1)*50)];

		for (i = pointCount; i < 5; i++)
			[self setControlPoint:i:NSMakePoint(0xFFFFFF, 0xFFFFFF)];
		
		[self propagateControlPoints];
		[self setNeedsDisplay:YES];
	}
}

- (void) controlPointMovedInTile:(long) pt_num: (NSPoint) pt
{
	float* transMatrix = [self transformationMatrix];
	if (transMatrix == 0L)
		return;
	
	if (pt.x == 0xFFFFFF &&  pt.y == 0xFFFFFF)
		[self setControlPoint:pt_num:NSMakePoint(0xFFFFFF, 0xFFFFFF)];
	else
		[self setControlPoint:pt_num:[self transformPoint:pt]];
	[self setNeedsDisplay:YES];
}


- (void)mouseDown:(NSEvent *)event
{
	if( [[self window] isVisible] == NO) return;
	if( [[[self window] windowController] is2DViewer] == YES)
	{
		if( [[[self window] windowController] windowWillClose]) return;
	}

	if ([self align_state] == AL_NORMAL || !dcmPixList)
	{
		[super mouseDown:event];
		return;
	}
	
	int i;
	NSRect size = [self frame];
	NSPoint eventLocation = [event locationInWindow];
	NSPoint viewPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
//	tempPt = [self ConvertFromNSView2GL:tempPt];

	for (i = 0; i < 5; i++)
	{
		NSPoint currentPt = [self controlPoint:i];
		
		currentPt = [self ConvertFromGL2View:currentPt];
		currentPt.x += size.size.width/2; // so that ConvertFromGL2View is the reverse trans of ConvertFromView2GL
		currentPt.y += size.size.height/2; // so that ConvertFromGL2View is the reverse trans of ConvertFromView2GL
		
		currentPt.y -= size.size.height;
		currentPt.y *= -1;
		
		if (viewPt.x + 4. > currentPt.x && viewPt.x - 4. < currentPt.x &&
			viewPt.y + 4. > currentPt.y && viewPt.y - 4. < currentPt.y)
		{
			[self setDraggingControlPoint:i];
			[NSCursor hide];
			return;
		}
/*		if (tempPt.x + 8 > currentPt.x && tempPt.x - 8 < currentPt.x &&
			tempPt.y + 8 > currentPt.y && tempPt.y - 8 < currentPt.y)
		{
			[self setDraggingControlPoint:i];
			[NSCursor hide];
			return;
		}*/
	}
	[self setDraggingControlPoint:-1];
	[self setBackgroundTransMatrixStart:[self backgroundTransformationMatrix]];
	[super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event
{
	if( [[self window] isVisible] == NO) return;
	if( [[[self window] windowController] is2DViewer] == YES)
	{
		if( [[[self window] windowController] windowWillClose]) return;
	}

    if(!dcmPixList)
	{
		[super mouseDragged:event];
		return;
	}

	if ([self align_state] == AL_NORMAL)
	{
		[super mouseDragged:event];
		return;
	}

	if ([self draggingControlPoint] == -1)
	{
        NSPoint     eventLocation = [event locationInWindow];
        NSPoint     current = [self convertPoint:eventLocation fromView:self];
        short       tool;
		tool = [self getTool: event];
		if (currentTool == tTranslate && tool == tTranslate && [event modifierFlags] & NSCommandKeyMask)
		{
			float xmove, ymove, xx, yy;
	   //     GLfloat deg2rad = 3.14159265358979/180.0; 
			
			xmove = (current.x - start.x);
			ymove = -(current.y - start.y);
			
			if( xFlipped) xmove = -xmove;
			if( yFlipped) ymove = -ymove;
			
			xx = xmove*cos((rotation)*deg2rad) + ymove*sin((rotation)*deg2rad);
			yy = xmove*sin((rotation)*deg2rad) - ymove*cos((rotation)*deg2rad);
			
			float* backgroundTransMatrix = [self backgroundTransformationMatrix];
			float* backgroundTransMatrixStart = [self backgroundTransMatrixStart];
			
			backgroundTransMatrix[13-1] = backgroundTransMatrixStart[13-1] + xx/scaleValue;
			backgroundTransMatrix[14-1] = backgroundTransMatrixStart[14-1] - yy/scaleValue;
//			origin.x = originStart.x + xx;
//			origin.y = originStart.y + yy;
			
			//set value for Series Object Presentation State
//			if ([[[self window] windowController] is2DViewer] == YES)
//			{
//				[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.x] forKey:@"xOffset"];
//				[[self seriesObj] setValue:[NSNumber numberWithFloat:origin.y] forKey:@"yOffset"];
//			}
			previous = current;
			[self setNeedsDisplay:YES];
			return;
		}
		else
		{
			[super mouseDragged:event];
			return;
		}
	}
		
	NSRect size = [self frame];
	NSPoint eventLocation = [event locationInWindow];
	NSPoint tempPt = [[[event window] contentView] convertPoint:eventLocation toView:self];
	tempPt = [self ConvertFromNSView2GL:tempPt];
	
	[self setControlPoint:[self draggingControlPoint]: tempPt];
	if ([self align_state] == AL_TILE)
		[self propagateControlPoints];
	else if ([self align_state] == AL_MOSAIC)
		[self recalcTransMatrix];
	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)event
{
	if ([self align_state] == AL_NORMAL)
	{
		[super mouseUp:event];
		return;
	}

	short       tool = [self getTool: event];
	if (currentTool == tTranslate && tool == tTranslate && [event modifierFlags] & NSCommandKeyMask && [self draggingControlPoint] == -1)
		return;

	if ([self draggingControlPoint] == -1)
	{
		[super mouseDragged:event];
		return;
	}

	[NSCursor unhide];
	[self setDraggingControlPoint:-1];
}

- (void) resetCursorRects
{
	[super resetCursorRects];
	if ([self align_state] == AL_NORMAL)
		return;

	int i;
	NSRect size = [self frame];

	for (i = 0; i < 5; i++)
	{
		NSPoint currentPt = [self controlPoint:i];
		
		currentPt = [self ConvertFromGL2View:currentPt];
		currentPt.x += size.size.width/2; // so that ConvertFromGL2View is the reverse trans of ConvertFromView2GL
		currentPt.y += size.size.height/2; // so that ConvertFromGL2View is the reverse trans of ConvertFromView2GL
		
		currentPt.y -= size.size.height;
		currentPt.y *= -1;
		
		[self addCursorRect:NSMakeRect(currentPt.x-4, currentPt.y-4, 8., 8.) cursor: [NSCursor pointingHandCursor]]; // BOGUS I don't feel like drawing a cursor right now
	}
}

- (char*) texturetiledImage:(char*) inputImage: (long) width:(long) height: (long) rowBytes: (long) texture_width
{

	int tX = GetTextureNumFromTextureDim (width, texture_width, false, YES); //OVERLAP
	// extract the number of horiz. textures needed to tile image
	int tY = GetTextureNumFromTextureDim (height, texture_width, false, YES); //OVERLAP

	int textureSize = GetNextTextureSize (width, texture_width, YES);
	unsigned char *friendlyTextures;
	friendlyTextures = malloc(tX * tY * textureSize * textureSize);
	unsigned char * friendlyBuffer = friendlyTextures;
	
	{
		long x, y, offsetY, offsetX = 0, currWidth, currHeight; // texture iterators, texture name iterator, image offsets for tiling, current texture width and height
		for (x = 0; x < tX; x++) // for all horizontal textures
		{
			currWidth = GetNextTextureSize (width - offsetX, texture_width, YES); // use remaining to determine next texture size 
			offsetY = 0; // reset vertical offest for every column
			
			for (y = 0; y < tY; y++) // for all vertical textures
			{
				int i;
				unsigned char * pBuffer;
				currHeight = GetNextTextureSize (height - offsetY, texture_width, YES); // use remaining to determine next texture size
				pBuffer = (unsigned char*) inputImage + (offsetY * rowBytes) + offsetX;							
				
				friendlyBuffer = friendlyTextures + (((x * tY) + y) * textureSize * textureSize);
				for (i = 0; i < currHeight; i++)
				{
					memcpy(friendlyBuffer, pBuffer, currWidth);
					friendlyBuffer += textureSize;
					pBuffer += rowBytes;
				}
				
				offsetY += currHeight;
			}
		offsetX += currWidth;
		}
	}
	return (char*) friendlyTextures;
}

- (void)loadTextures
{
	[super loadTextures];
	
	if([self tileView])
	{
		long tempTileTextureX = [self tileTextureX], tempTileTextureY = [self tileTextureY];
		unsigned char* tempTilingColorBuf = [self tilingColorBuf];
		GLuint*	tempTileTextureName;
//		unsigned char ct[256];
//		int i;
//		for (i= 0; i < 256; i++)
//			ct[i] = ((float) i)/2.0;
		
//		float oldRedFactor = redFactor, oldGreenFactor = greenFactor, oldBlueFactor = blueFactor;
//		redFactor = greenFactor = blueFactor = .5;
		tempTileTextureName = [[self tileView] loadTextureIn:[self tileTextureName] blending:YES colorBuf:&tempTilingColorBuf textureX:&tempTileTextureX textureY:&tempTileTextureY redTable:0L greenTable:0L blueTable:0L];
//		tempTileTextureName = [[self tileView] loadTextureIn:[self tileTextureName] blending:YES colorBuf:&tempTilingColorBuf textureX:&tempTileTextureX textureY:&tempTileTextureY redTable:ct greenTable:ct blueTable:ct];
//		redFactor = oldRedFactor;
//		greenFactor = oldGreenFactor;
//		blueFactor = oldBlueFactor;
		[self setTileTextureName:tempTileTextureName];
		[self setTileTextureX:tempTileTextureX];
		[self setTileTextureY:tempTileTextureY];
		[self setTilingColorBuf:tempTilingColorBuf];
	}
}


-(void) setTiling:(AlignDCMView*) tV
{
//	float orientA[9], orientB[9];
//	float result[3];
	int i;
	
	if( [self tileView] == tV) return;
	
	if( tV)
	{
		if( [tV curDCM])
		{
//			[curDCM orientation:orientA];
//			[[bV curDCM] orientation:orientB];
			
//			if( orientB[ 6] == 0 && orientB[ 7] == 0 && orientB[ 8] == 0) { blendingView = bV;	return;}
//			if( orientA[ 6] == 0 && orientA[ 7] == 0 && orientA[ 8] == 0) { blendingView = bV;	return;}
			
			// normal vector of planes
			
//			result[0] = fabs( orientB[ 6] - orientA[ 6]);
//			result[1] = fabs( orientB[ 7] - orientA[ 7]);
//			result[2] = fabs( orientB[ 8] - orientA[ 8]);
			
//			if( result[0] + result[1] + result[2] > 0.01)  // Planes are not paralel!
//			{
//				if( NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. The result in 2D will be distorted.",nil), NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Cancel",nil),nil) != NSAlertDefaultReturn)
//				{
//					blendingView = 0L;
//				}
//				else blendingView = bV;
//			}
//			else blendingView = bV;
			[self setTileView:tV];
			// find the point that is at the center of the screen
			for (i = 1; i < 5; i++)
				[self setControlPoint:i:NSMakePoint(0xFFFFFF, 0xFFFFFF)];

			[self setControlPointCount:1];
			float x, y;
			x = [curDCM pwidth]/2.0 - origin.x/scaleValue - originOffset.x/scaleValue;
			y = [curDCM pheight]/2.0 + origin.y/scaleValue + originOffset.y/scaleValue;
//			x = 0;
//			y = 0;
			[self setControlPoint0:NSMakePoint(x, y)];
			[self recalcTransMatrix];
		}
	}
	else [self setTileView:0L];
	
	[self loadTextures];
	[self recalcTransMatrix];
	[self setNeedsDisplay:YES];
}

-(void) setBackground:(AlignDCMView*) bV
{
	if(bV && [bV curDCM] && ![[bV curDCM] isRGB])
	{
		// find the point that is at the center of the screen
		float x, y;
		x = [curDCM pwidth]/2.0 - origin.x/scaleValue - originOffset.x/scaleValue;
		y = [curDCM pheight]/2.0 + origin.y/scaleValue + originOffset.y/scaleValue;

		[self setControlPoint4:NSMakePoint(x, y)];
		[self recalcTransMatrix];
		
		[self loadBackgroundTexture:bV];
	}
	
//	[self loadTextures];
//	[self recalcTransMatrix];
	[self setNeedsDisplay:YES];
}

-(void) loadBackgroundTexture:(AlignDCMView*) bV
{
	if(bV)
	{
		[[self openGLContext] makeCurrentContext];

		long tempBackgroundTextureX = [self backgroundTextureX], tempBackgroundTextureY = [self backgroundTextureY];
		unsigned char* tempBackgroundColorBuf = [self backgroundColorBuf];
		GLuint*	tempBackgroundTextureName;

		tempBackgroundTextureName = [bV loadTextureIn:[self backgroundTextureName] blending:YES colorBuf:&tempBackgroundColorBuf textureX:&tempBackgroundTextureX textureY:&tempBackgroundTextureY redTable:0L greenTable:0L blueTable:0L];

		[self setBackgroundTextureName:tempBackgroundTextureName];
		[self setBackgroundTextureX:tempBackgroundTextureX];
		[self setBackgroundTextureY:tempBackgroundTextureY];
		[self setBackgroundColorBuf:tempBackgroundColorBuf];
		
		
		[self setBackgroundTextureWidth:[[bV curDCM] rowBytes]];
		[self setBackgroundTextureHeight:[[bV curDCM] pheight]];
		[self setBackgroundPWidth:[[bV curDCM] pwidth]];
		[self setBackgroundPHeight:[[bV curDCM] pheight]];
	}
}


- (al_state) align_state
{
	if ([[[self window] windowController] respondsToSelector:@selector(align_state)])
		return [(AlignController *)[[self window] windowController] align_state];
	else 
		return AL_NORMAL;
}

- (void) propagateControlPoints
{
	if ([[[self window] windowController] respondsToSelector:@selector(propagateControlPoints)])
		[(AlignController *)[[self window] windowController] propagateControlPoints];
}


- (AlignDCMView*) tileView;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"tile_view"] pointerValue];
}

- (void) setTileView:(AlignDCMView*) view
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:view] forKey:@"tile_view"];
	[self setNeedsDisplay:YES];
}

- (float) tileBlendFactor
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"tile_blend_factor"] floatValue];
}

- (void) setTileBlendFactor: (float) factor
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithFloat:factor] forKey:@"tile_blend_factor"];
}

- (long) tileTextureX
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"tile_texture_x"] longValue];
}

- (void) setTileTextureX: (long) size
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"tile_texture_x"];
}

- (long) tileTextureY
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"tile_texture_y"] longValue];
}

- (void) setTileTextureY: (long) size
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"tile_texture_y"];
}


- (GLuint*) tileTextureName
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"tile_texture"] pointerValue];
}

- (void) setTileTextureName: (GLuint*) texture
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:texture] forKey:@"tile_texture"];
}

- (GLuint*) backgroundTextureName;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"background_texture"] pointerValue];
}

- (void) setBackgroundTextureName: (GLuint*) texture;
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:texture] forKey:@"background_texture"];
}

- (long) backgroundTextureX;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_x"] longValue];
}

- (void) setBackgroundTextureX: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_x"];
}

- (long) backgroundTextureY;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_y"] longValue];
}

- (void) setBackgroundTextureY: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_y"];
}

- (long) backgroundTextureWidth;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_width"] longValue];
}

- (void) setBackgroundTextureWidth: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_width"];
}

- (long) backgroundTextureHeight;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_height"] longValue];
}

- (void) setBackgroundTextureHeight: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_height"];
}

- (long) backgroundPWidth;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_p_width"] longValue];
}

- (void) setBackgroundPWidth: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_p_width"];
}

- (long) backgroundPHeight;
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"background_texture_p_height"] longValue];
}

- (void) setBackgroundPHeight: (long) size;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:size] forKey:@"background_texture_p_height"];
}

- (unsigned char*) backgroundColorBuf;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"background_color_buf"] pointerValue];
}

- (void) setBackgroundColorBuf: (unsigned char*) buf;
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:buf] forKey:@"background_color_buf"];
}

- (unsigned char*) tilingColorBuf
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"tile_color_buf"] pointerValue];
}

- (void) setTilingColorBuf: (unsigned char*) buf
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:buf] forKey:@"tile_color_buf"];
}


// maybe later I should make it so there can be an arbitrary number of points...
- (NSPoint) controlPoint0;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"control_point_0"] pointValue];
}

- (void) setControlPoint0: (NSPoint) pt
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPoint:pt] forKey:@"control_point_0"];
}

- (NSPoint) controlPoint1;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"control_point_1"] pointValue];
}

- (void) setControlPoint1: (NSPoint) pt
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPoint:pt] forKey:@"control_point_1"];
}

- (NSPoint) controlPoint2;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"control_point_2"] pointValue];
}

- (void) setControlPoint2: (NSPoint) pt
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPoint:pt] forKey:@"control_point_2"];
}

- (NSPoint) controlPoint3;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"control_point_3"] pointValue];
}

- (void) setControlPoint3: (NSPoint) pt
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPoint:pt] forKey:@"control_point_3"];
}

- (NSPoint) controlPoint4;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"control_point_4"] pointValue];
}

- (void) setControlPoint4: (NSPoint) pt
{
	[[self aligndcmview__ivars] setObject:[NSValue valueWithPoint:pt] forKey:@"control_point_4"];
}


- (NSPoint) controlPoint:(long) pt_num
{
	switch (pt_num)
	{
	case 0:
		return [self controlPoint0];
	case 1:
		return [self controlPoint1];
	case 2:
		return [self controlPoint2];
	case 3:
		return [self controlPoint3];
	case 4:
		return [self controlPoint4];
	}
	return NSMakePoint(0,0);
}

- (void) setControlPoint:(long) pt_num: (NSPoint) pt
{
	switch (pt_num)
	{
	case 0:
		return [self setControlPoint0:pt];
	case 1:
		return [self setControlPoint1:pt];
	case 2:
		return [self setControlPoint2:pt];
	case 3:
		return [self setControlPoint3:pt];
	case 4:
		return [self setControlPoint4:pt];
	}
}

- (long) activeControlPoints
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"active_control_points"] longValue];
}

- (void) setActiveControlPoints:(long) pt_num
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:pt_num] forKey:@"active_control_points"];
}

- (long) draggingControlPoint
{
	return [(NSNumber*)[[self aligndcmview__ivars] objectForKey:@"dragging_control_point"] longValue];
}

- (void) setDraggingControlPoint:(long) pt;
{
	[[self aligndcmview__ivars] setObject:[NSNumber numberWithLong:pt] forKey:@"dragging_control_point"];
}

- (float*) transformationMatrix
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"transformation_matrix"] pointerValue];	
}

- (void) setTransformationMatrix: (float*) trans_matrix
{
	if (trans_matrix == 0L)
	{
		if ([self transformationMatrix] != 0L)
		{
			free([self transformationMatrix]);
			[[self aligndcmview__ivars] setObject:0L forKey:@"transformation_matrix"];
		}
		return;
	}
	if ([self transformationMatrix] == 0L)
	{
		float* new_matrix;
		new_matrix = malloc(16 * sizeof(float));
		bzero(new_matrix, 16 * sizeof(float));
		[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:new_matrix] forKey:@"transformation_matrix"];
	}
	memcpy([self transformationMatrix], trans_matrix, 16 * sizeof(float));
}

- (float*) backgroundTransformationMatrix;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"background_transformation_matrix"] pointerValue];	
}

- (void) setBackgroundTransformationMatrix: (float*) trans_matrix;
{
	if (trans_matrix == 0L)
	{
		if ([self backgroundTransformationMatrix] != 0L)
		{
			free([self backgroundTransformationMatrix]);
			[[self aligndcmview__ivars] setObject:0L forKey:@"background_transformation_matrix"];
		}
		return;
	}
	if ([self backgroundTransformationMatrix] == 0L)
	{
		float* new_matrix;
		new_matrix = malloc(16 * sizeof(float));
		bzero(new_matrix, 16 * sizeof(float));
		[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:new_matrix] forKey:@"background_transformation_matrix"];
	}
	memcpy([self backgroundTransformationMatrix], trans_matrix, 16 * sizeof(float));
}

- (float*) backgroundTransMatrixStart;
{
	return [(NSValue*) [[self aligndcmview__ivars] objectForKey:@"background_transformation_matrix_start"] pointerValue];	
}

- (void) setBackgroundTransMatrixStart: (float*) trans_matrix;
{
	if (trans_matrix == 0L)
	{
		if ([self backgroundTransMatrixStart] != 0L)
		{
			free([self backgroundTransMatrixStart]);
			[[self aligndcmview__ivars] setObject:0L forKey:@"background_transformation_matrix_start"];
		}
		return;
	}
	if ([self backgroundTransMatrixStart] == 0L)
	{
		float* new_matrix;
		new_matrix = malloc(16 * sizeof(float));
		bzero(new_matrix, 16 * sizeof(float));
		[[self aligndcmview__ivars] setObject:[NSValue valueWithPointer:new_matrix] forKey:@"background_transformation_matrix_start"];
	}
	memcpy([self backgroundTransMatrixStart], trans_matrix, 16 * sizeof(float));
}


#pragma mark -

- (id)aligndcmview__instanceID
{
    return [NSValue valueWithPointer:self];
}

- (NSMutableDictionary *) aligndcmview__ivars
{
    NSMutableDictionary *ivars;
    
    if (aligndcmview__instanceIDToIvars == nil)
    {
        aligndcmview__instanceIDToIvars = [[NSMutableDictionary alloc] init];
    }
    
    ivars = [aligndcmview__instanceIDToIvars objectForKey:[self aligndcmview__instanceID]];
    if (ivars == nil)
    {
        ivars = [NSMutableDictionary dictionary];
        [aligndcmview__instanceIDToIvars setObject:ivars forKey:[self aligndcmview__instanceID]];
    }
    
    return ivars;
}

@end

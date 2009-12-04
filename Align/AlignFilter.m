//
//  AlignFilter.m
//  Align
//
//  Created by rossetantoine on Jul 24 2006.
//  Copyright (c) 2006 __MyCompanyName__. All rights reserved.
//

/* this version of Align filter is built around OsiriX SVN revision 838 */
#import "AppController.h"
#import "AppControllerFiltersMenu.h"

#import "AlignDCMView.h"
#import "AlignFilter.h"
#import "AlignController.h"

#import </usr/include/objc/objc-class.h>
@class DCMPix;

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

// code from www.cocoadev.com
void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
    Method orig_method = nil, alt_method = nil;

    // First, look for the methods
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);

    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil))
        {
        char *temp1;
        IMP temp2;

        temp1 = orig_method->method_types;
        orig_method->method_types = alt_method->method_types;
        alt_method->method_types = temp1;

        temp2 = orig_method->method_imp;
        orig_method->method_imp = alt_method->method_imp;
        alt_method->method_imp = temp2;
        }
}

@implementation AlignFilter

- (void) initPlugin
{
	[super initPlugin];
	
	[AlignDCMView poseAsClass:[DCMView class]];
	[AlignController poseAsClass:[ViewerController class]];
	
	MethodSwizzle([DCMPix class],
                  @selector(changeWLWW_swizzle::),
                  @selector(changeWLWW::));

}

- (long) filterImage:(NSString*) menuName
{

	if ([menuName isEqualToString:@"Make Align Tile"])
		[self makeAlignTile];
	else if ([menuName isEqualToString:@"Make Align Background"])
		[self makeAlignBackground];
	else if ([menuName isEqualToString:@"Make Align Mosaic"])
		[self makeAlignMosaic];
	else if ([menuName isEqualToString:@"Make Normal"])
		[self makeNormal];
	else if ([menuName isEqualToString:@"Merge Images"])
		[self mergeImages];
	else if ([menuName isEqualToString:@"One Control Point"])
		[self setControlPointCount:1];
	else if ([menuName isEqualToString:@"Two Control Points"])
		[self setControlPointCount:2];
	else if ([menuName isEqualToString:@"Three Control Points"])
		[self setControlPointCount:3];
	else if ([menuName isEqualToString:@"Four Control Points"])
		[self setControlPointCount:4];

	return 0;
}

- (void) setMenus
{
	AppController *appController = 0L;
	NSMenuItem *alignMenu = 0L;
	NSMenuItem *tileMenuItem = 0L;
	NSMenuItem *backgroundMenuItem = 0L;
	NSMenuItem *mosaicMenuItem = 0L;
	NSMenuItem *mergeMenuItem = 0L;
	NSMenuItem *onePointMenuItem = 0L;
	NSMenuItem *twoPointMenuItem = 0L;
	NSMenuItem *threePointMenuItem = 0L;
	NSMenuItem *fourPointMenuItem = 0L;
	
	appController = [AppController sharedAppController];
	
	alignMenu = [[appController filtersMenu] itemWithTitle:@"Align"];
	if (alignMenu && [alignMenu hasSubmenu])
	{
		NSMenu *AlignSubMenu = 0L;
		AlignSubMenu = [alignMenu submenu];
		
		tileMenuItem = [AlignSubMenu itemWithTitle:@"Make Align Tile"];
		backgroundMenuItem = [AlignSubMenu itemWithTitle:@"Make Align Background"];
		mosaicMenuItem = [AlignSubMenu itemWithTitle:@"Make Align Mosaic"];
		mergeMenuItem = [AlignSubMenu itemWithTitle:@"Merge Images"];
		onePointMenuItem = [AlignSubMenu itemWithTitle:@"One Control Point"];
		twoPointMenuItem = [AlignSubMenu itemWithTitle:@"Two Control Points"];
		threePointMenuItem = [AlignSubMenu itemWithTitle:@"Three Control Points"];
		fourPointMenuItem = [AlignSubMenu itemWithTitle:@"Four Control Points"];
		
		[tileMenuItem setKeyEquivalent:@"i"];
		[tileMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[backgroundMenuItem setKeyEquivalent:@"b"];
		[backgroundMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[mosaicMenuItem setKeyEquivalent:@"z"];
		[mosaicMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[mergeMenuItem setKeyEquivalent:@"m"];
		[mergeMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[onePointMenuItem setKeyEquivalent:@"1"];
		[onePointMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[twoPointMenuItem setKeyEquivalent:@"2"];
		[twoPointMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[threePointMenuItem setKeyEquivalent:@"3"];
		[threePointMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];

		[fourPointMenuItem setKeyEquivalent:@"4"];
		[fourPointMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask | NSCommandKeyMask];
	}
}


- (void) makeAlignTile
{
	AlignController* currentController = (AlignController*) viewerController;
	
	[currentController setAlign_state:AL_TILE];
}

- (void) makeAlignBackground
{
	AlignController* currentController = (AlignController*) viewerController;
	
	[currentController setAlign_state:AL_BACKGROUND];
}

- (void) makeAlignMosaic
{
	AlignController* currentController = (AlignController*) viewerController;
	
	[currentController setAlign_state:AL_MOSAIC];
}

- (void) makeNormal
{
	AlignController* currentController = (AlignController*) viewerController;
	
	[currentController setAlign_state:AL_NORMAL];
}

- (void) mergeImages
{
	AlignController* currentController = (AlignController*) viewerController;
	[(AlignDCMView*) [currentController imageView] mergeImages];	
}

- (void) setControlPointCount:(long) count;
{
	AlignController* currentController = (AlignController*) viewerController;
	[(AlignDCMView*) [currentController imageView] setControlPointCount:count];	
}

- (long) buildAlignController
{

	
	return 1;
}


- (AlignController*) duplicateCurrent2DViewerWindowToAlign
{
	long							i;
	AlignController					*new2DViewer;
	unsigned char					*fVolumePtr;
	
	// We will read our current series, and duplicate it by creating a new series!
	
	// First calculate the amount of memory needed for the new serie
	NSArray		*pixList = [viewerController pixList];		
	DCMPix		*curPix;
	long		mem = 0;
	
	for( i = 0; i < [pixList count]; i++)
	{
		curPix = [pixList objectAtIndex: i];
		mem += [curPix pheight] * [curPix pwidth] * 4;		// each pixel contains either a 32-bit float or a 32-bit ARGB value
	}
	
	fVolumePtr = malloc( mem);	// ALWAYS use malloc for allocating memory !
	if( fVolumePtr)
	{
		// Copy the source series in the new one !
		memcpy( fVolumePtr, [viewerController volumePtr], mem);
		
		// Create a NSData object to control the new pointer
		NSData		*volumeData = [[NSData alloc] initWithBytesNoCopy:fVolumePtr length:mem freeWhenDone:YES]; 
		
		// Now copy the DCMPix with the new fVolumePtr
		NSMutableArray *newPixList = [NSMutableArray arrayWithCapacity:0];
		for( i = 0; i < [pixList count]; i++)
		{
			curPix = [[[pixList objectAtIndex: i] copy] autorelease];
			[curPix setfImage: (float*) (fVolumePtr + [curPix pheight] * [curPix pwidth] * 4 * i)];
			[newPixList addObject: curPix];
		}
		
		// We don't need to duplicate the DicomFile array, because it is identical!
		
		// A 2D Viewer window needs 3 things:
		// A mutable array composed of DCMPix objects
		// A mutable array composed of DicomFile objects
		// Number of DCMPix and DicomFile has to be EQUAL !
		// NSData volumeData contains the images, represented in the DCMPix objects
		new2DViewer = [AlignController newAlignWindow:newPixList :[viewerController fileList] :volumeData];
		
		[new2DViewer roiDeleteAll:self];
		
		return new2DViewer;
	}
	
	return 0L;
}




@end


@implementation DCMPix (Align_Swizzle)
- (void) changeWLWW_swizzle:(float)newWL :(float)newWW
{
	[self changeWLWW_swizzle:newWL :newWW];
	[self setBaseAddr:[self texturetiledImage:[self baseAddr]: 1024]];
}

- (char*) texturetiledImage:(char*) inputImage: (long) texture_width
{

	int tX = GetTextureNumFromTextureDim ([self pwidth], texture_width, false, YES); //OVERLAP
	int tY = GetTextureNumFromTextureDim ([self pheight], texture_width, false, YES); //OVERLAP

//	int textureSize = GetNextTextureSize([self pwidth], texture_width, NO);
	int textureSize = GetNextTextureSize([self pwidth], texture_width, YES);
	if (textureSize < GetNextTextureSize([self pheight], texture_width, YES))
		textureSize = GetNextTextureSize([self pheight], texture_width, YES);
		
	unsigned char *friendlyTextures;
	if( [self isRGB] == YES || [self thickSlabMode] == YES)
		friendlyTextures = malloc(tX * tY * textureSize * textureSize * 4);
	else
		friendlyTextures = malloc(tX * tY * textureSize * textureSize);

	unsigned char * friendlyBuffer = friendlyTextures;
	
	{
		long x, y, offsetY, offsetX = 0, currWidth, currHeight; // texture iterators, texture name iterator, image offsets for tiling, current texture width and height
		for (x = 0; x < tX; x++) // for all horizontal textures
		{
			currWidth = GetNextTextureSize ([self pwidth] - offsetX, texture_width, YES); // use remaining to determine next texture size 
			
			offsetY = 0; // reset vertical offest for every column
			
			for (y = 0; y < tY; y++) // for all vertical textures
			{
				int i;
				unsigned char * pBuffer;
				currHeight = GetNextTextureSize ([self pheight] - offsetY, texture_width, YES); // use remaining to determine next texture size
				if( [self isRGB] == YES || [self thickSlabMode] == YES)
					pBuffer = (unsigned char*) inputImage + (offsetY * [self rowBytes]) + offsetX*4;
				else
					pBuffer = (unsigned char*) inputImage + (offsetY * [self rowBytes]) + offsetX;
					
				if( [self isRGB] == YES || [self thickSlabMode] == YES)
					friendlyBuffer = friendlyTextures + (((x * tY) + y) * textureSize * textureSize * 4);
				else
					friendlyBuffer = friendlyTextures + (((x * tY) + y) * textureSize * textureSize);
				for (i = 0; i < currHeight; i++)
				{
					if( [self isRGB] == YES || [self thickSlabMode] == YES)
					{
						memcpy(friendlyBuffer, pBuffer, currWidth*4);
						friendlyBuffer += textureSize*4;
					}
					else
					{
						memcpy(friendlyBuffer, pBuffer, currWidth);
						friendlyBuffer += textureSize;
					}
					pBuffer += [self rowBytes];
				}
				
				offsetY += currHeight;
			}
		offsetX += currWidth;
		}
	}
	return (char*) friendlyTextures;
}

- (char*) deTexturetiledImage:(char*) friendlyTextures: (long) texture_width
{
	int tX = GetTextureNumFromTextureDim ([self pwidth], texture_width, false, YES); //OVERLAP
	int tY = GetTextureNumFromTextureDim ([self pheight], texture_width, false, YES); //OVERLAP

//	int textureSize = GetNextTextureSize([self pwidth], texture_width, NO);
	int textureSize = GetNextTextureSize([self pwidth], texture_width, YES);
	if (textureSize < GetNextTextureSize([self pheight], texture_width, YES))
		textureSize = GetNextTextureSize([self pheight], texture_width, YES);
		
	unsigned char *unfriendlyTextures;
	unfriendlyTextures = malloc([self pheight] * [self rowBytes]);
	char * friendlyBuffer = friendlyTextures;
	
	{
		long x, y, offsetY, offsetX = 0, currWidth, currHeight; // texture iterators, texture name iterator, image offsets for tiling, current texture width and height
		for (x = 0; x < tX; x++) // for all horizontal textures
		{
			currWidth = GetNextTextureSize ([self pwidth] - offsetX, texture_width, YES); // use remaining to determine next texture size 
			offsetY = 0; // reset vertical offest for every column
			
			for (y = 0; y < tY; y++) // for all vertical textures
			{
				int i;
				unsigned char * pBuffer;
				currHeight = GetNextTextureSize ([self pheight] - offsetY, texture_width, YES); // use remaining to determine next texture size
				pBuffer = (unsigned char*) unfriendlyTextures + (offsetY * [self rowBytes]) + offsetX;							
				
				friendlyBuffer = friendlyTextures + (((x * tY) + y) * textureSize * textureSize);
				for (i = 0; i < currHeight; i++)
				{
					memcpy(pBuffer, friendlyBuffer, currWidth);
//					memcpy(friendlyBuffer, pBuffer, currWidth);
					friendlyBuffer += textureSize;
					pBuffer += [self rowBytes];
				}
				
				offsetY += currHeight;
			}
		offsetX += currWidth;
		}
	}
	return (char*) unfriendlyTextures;
}
@end


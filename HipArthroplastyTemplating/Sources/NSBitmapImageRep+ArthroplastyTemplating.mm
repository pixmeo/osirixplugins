//
//  NSBitmapImageRep+ArthroplastyTemplating.mm
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 2/1/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "NSBitmapImageRep+ArthroplastyTemplating.h"
#include <stack>


@implementation NSBitmapImageRep (ArthroplastyTemplating)

struct IntegerPoint {
	NSInteger x, y;
	IntegerPoint(NSInteger x, NSInteger y) : x(x), y(y) {}
};

-(void)detectAndApplyBorderTransparency:(uint8)alphaThreshold {
	NSSize size = [self size]; // TODO: pixelsHigh, pixelsWide
	NSInteger width = size.width, height = size.height;
	uint8* data = [self bitmapData];
	
	const size_t rowBytes = [self bytesPerRow], pixelBytes = [self bitsPerPixel]/8;
#define P(x,y) (y*rowBytes+x*pixelBytes)

	BOOL visited[width][height]; memset(visited, 0, sizeof(BOOL)*width*height);

	// stack contains list of places to start flooding from
	std::stack<IntegerPoint> ps;
	// top and bottom borders
	for (NSInteger x = 0; x < width; ++x) {
		ps.push(IntegerPoint(x, 0));
		ps.push(IntegerPoint(x, height-1));
	}
	// left and right borders
	for (NSInteger y = 1; y < height-1; ++y) {
		ps.push(IntegerPoint(0, y));
		ps.push(IntegerPoint(width-1, y));
	}
	
	// flood from every point in stack
	while (!ps.empty()) {
		IntegerPoint p = ps.top();
		ps.pop();
		
		if (visited[p.x][p.y]) continue;
		visited[p.x][p.y] = YES;
		
		if (data[P(p.x,p.y)+3] < alphaThreshold) { // if pixel is transparent, flood its neighbors
			data[P(p.x,p.y)+3] = 0;
			if (p.x > 0 && !visited[p.x-1][p.y]) ps.push(IntegerPoint(p.x-1, p.y));
			if (p.y > 0 && !visited[p.x][p.y-1]) ps.push(IntegerPoint(p.x, p.y-1));
			if (p.x < width-1 && !visited[p.x+1][p.y]) ps.push(IntegerPoint(p.x+1, p.y));
			if (p.y < height-1 && !visited[p.x][p.y+1]) ps.push(IntegerPoint(p.x, p.y+1));			
		}
	}
	
	// make unflooded pixels with alpha = 0 have alpha = 1
//#pragma omp parallel for default(shared)
	for (NSInteger x = 0; x < width; ++x)
		for (NSInteger y = 1; y < height-1; ++y)
			if (!visited[x][y] && !data[P(x,y)+3])
				data[P(x,y)+3] = 1;

#undef P
}

-(void)setColor:(NSColor*)color {
	NSSize size = [self size];
	NSInteger width = size.width, height = size.height;
	uint8* data = [self bitmapData];
	
	const size_t rowBytes = [self bytesPerRow], pixelBytes = [self bitsPerPixel]/8;
#define P(x,y) (y*rowBytes+x*pixelBytes)
	
	if ([color colorSpaceName] != NSCalibratedRGBColorSpace)
		color = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	NSInteger componentsCount = [color numberOfComponents];
	CGFloat components[componentsCount];
	[color getComponents:components];
	
	uint8 uint8components[componentsCount];
	for (NSInteger i = 0; i < componentsCount; ++i)
		uint8components[i] = components[i]*UINT8_MAX;
	
//#pragma omp parallel for default(shared)
	for (NSInteger x = 0; x < width; ++x)
		for (NSInteger y = 1; y < height-1; ++y) {
			NSUInteger p = P(x,y);
			CGFloat m = CGFloat(data[p+3])/UINT8_MAX; // NSBitmapImageRep has premultiplied RGB
			data[p] = uint8components[0]*m;
			data[p+1] = uint8components[1]*m;
			data[p+2] = uint8components[2]*m;
		}
}

@end

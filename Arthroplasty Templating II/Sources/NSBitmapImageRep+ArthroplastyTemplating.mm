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
	NSSize size = [self size];
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
	
	while (!ps.empty()) {
		IntegerPoint p = ps.top();
		ps.pop();
		
		if (visited[p.x][p.y]) continue;
		visited[p.x][p.y] = YES;
		
		if (data[P(p.x,p.y)+3] < alphaThreshold) {
			data[P(p.x,p.y)+3] = 0;
			if (p.x > 0 && !visited[p.x-1][p.y]) ps.push(IntegerPoint(p.x-1, p.y));
			if (p.y > 0 && !visited[p.x][p.y-1]) ps.push(IntegerPoint(p.x, p.y-1));
			if (p.x < width-1 && !visited[p.x+1][p.y]) ps.push(IntegerPoint(p.x+1, p.y));
			if (p.y < height-1 && !visited[p.x][p.y+1]) ps.push(IntegerPoint(p.x, p.y+1));			
		}
	}
	
#pragma omp parallel for default(shared)
	for (NSInteger x = 0; x < width; ++x)
		for (NSInteger y = 1; y < height-1; ++y)
			if (!visited[x][y] && !data[P(x,y)+3])
				data[P(x,y)+3] = 1;
				

#undef P
}

@end

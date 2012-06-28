//
//  HipAT2D.m
//  HipArthroplastyTemplating
//
//  Created by Alessandro Volz on 28.06.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HipAT2D.h"
#import <OsiriXAPI/DCMPix.h>
#include <cmath>

@implementation HipAT2DIntegerPoint

@synthesize x = _x, y = _y;

+(id)pointWith:(NSInteger)x :(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

+(id)pointWithX:(NSInteger)x y:(NSInteger)y {
    return [[[[self class] alloc] initWithX:x y:y] autorelease];
}

-(id)initWithX:(NSInteger)x y:(NSInteger)y {
    if ((self = [super init])) {
        _x = x; 
        _y = y;
    }
    
    return self;
}

-(BOOL)isEqual:(HipAT2DIntegerPoint*)other {
    return [other isKindOfClass:[HipAT2DIntegerPoint class]] && _x == other.x && _y == other.y;
}

-(NSArray*)neighbors {
    return [NSArray arrayWithObjects:
            [HipAT2DIntegerPoint pointWith:_x:_y-1],
            [HipAT2DIntegerPoint pointWith:_x+1:_y],
            [HipAT2DIntegerPoint pointWith:_x:_y+1],
            [HipAT2DIntegerPoint pointWith:_x-1:_y],
            nil];
}

/*-(CGFloat)distanceTo:(HipAT2DIntegerPoint*)p {
    return std::sqrt(std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2));
}*/

-(CGFloat)distanceToNoSqrt:(HipAT2DIntegerPoint*)p {
    return std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2);
}

-(NSString*)description {
    return [NSString stringWithFormat:@"[%d,%d]", (int)_x, (int)_y];
}

-(NSPoint)nsPoint {
    return NSMakePoint(_x, _y);
}

@end

@implementation HipAT2D

#define data(p) data[p.x+p.y*w]
#define mask(p) mask[p.x+p.y*w]

+ (void)growRegionFromPoint:(HipAT2DIntegerPoint*)p0 onDCMPix:(DCMPix*)pix outputPoints:(NSMutableArray*)points outputContour:(NSMutableArray*)contour {
    const NSInteger w = pix.pwidth, h = pix.pheight;
    float* data = pix.fImage;
    
    float threshold = data(p0);
    if (threshold < pix.fullwl)
        return;
    
    threshold /= 2;
    
    NSMutableArray* toBeVisited = [NSMutableArray arrayWithObject:p0];
    BOOL mask[w*h];
    memset(mask, 0, w*h*sizeof(BOOL));
    mask(p0) = YES;
    
    while (toBeVisited.count) {
        HipAT2DIntegerPoint* p = [toBeVisited lastObject];
        [toBeVisited removeLastObject];
        [points addObject:p];
        for (HipAT2DIntegerPoint* t in p.neighbors)
            if (t.x >= 0 && t.y >= 0 && t.x < w && t.y < h && !mask(t)) {
                mask(t) = YES;
                if (data(t) >= threshold)
                    [toBeVisited addObject:t];
                else [contour addObject:p];
            }
    }
}

+ (NSArray*)mostDistantPairOfPointsInSet:(NSArray*)points {
    if (points.count < 2)
        return nil;
    
    NSUInteger p1i, p2i;
    CGFloat rd = 0;
    
    NSUInteger ilimit = points.count-2, jlimit = points.count-1;
    for (NSUInteger i = 0; i < ilimit; ++i)
        for (NSUInteger j = i+1; j <= jlimit; ++j) {
            CGFloat ijd = [[points objectAtIndex:i] distanceToNoSqrt:[points objectAtIndex:j]];
            if (ijd > rd) {
                rd = ijd; p1i = i; p2i = j;
            }
        }
    
    return [NSArray arrayWithObjects: [points objectAtIndex:p1i], [points objectAtIndex:p2i], nil];
}

@end

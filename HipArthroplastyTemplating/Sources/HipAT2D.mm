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

-(BOOL)isEqual:(id)other {
    return [self x] == [other x] && [self y] == [other y];
}

-(NSArray*)neighbors {
    return [NSArray arrayWithObjects:
            [HipAT2DIntegerPoint pointWith:_x:_y-1],
            [HipAT2DIntegerPoint pointWith:_x+1:_y],
            [HipAT2DIntegerPoint pointWith:_x:_y+1],
            [HipAT2DIntegerPoint pointWith:_x-1:_y],
            nil];
}

-(CGFloat)distanceTo:(HipAT2DIntegerPoint*)p {
    return std::sqrt(std::pow((CGFloat)_x-p.x, 2)+std::pow((CGFloat)_y-p.y, 2));
}

@end

@implementation HipAT2D

#define data(p) data[p.x+p.y*w]

+ (void)growRegionFromPoint:(HipAT2DIntegerPoint*)p0 onDCMPix:(DCMPix*)pix outputPoints:(NSMutableSet*)points outputContour:(NSMutableSet*)contour {
    const NSInteger w = pix.pwidth, h = pix.pheight;
    float* data = pix.fImage;
    
    float threshold = data(p0)/2;
    
    NSMutableSet* toBeVisited = [NSMutableSet setWithObject:p0];
    NSMutableSet* alreadyVisited = [NSMutableSet set];
    
    while (toBeVisited.count) {
        HipAT2DIntegerPoint* p = [toBeVisited anyObject];
        [toBeVisited removeObject:p];
        [alreadyVisited addObject:p];
        [points addObject:p];
        for (HipAT2DIntegerPoint* t in p.neighbors)
            if (t.x >= 0 && t.y >= 0 && t.x < w && t.y < h && ![alreadyVisited containsObject:t])
                if (data(t) >= threshold)
                    [toBeVisited addObject:t];
                else [contour addObject:p];
    }
}

+ (NSSet*)mostDistantPairOfPointsInSet:(NSSet*)set {
    if (set.count < 2)
        return nil;
    
    NSUInteger p1i, p2i;
    CGFloat rd = 0;
    
    NSArray* points = [set allObjects];
    
    NSUInteger ilimit = points.count-1, jlimit = points.count;
    for (NSUInteger i = 0; i < ilimit; ++i)
        for (NSUInteger j = i+1; j <= jlimit; ++j) {
            CGFloat ijd = [[points objectAtIndex:i] distanceTo:[points objectAtIndex:j]];
            if (ijd > rd) {
                rd = ijd; p1i = i; p2i = j;
            }
        }
    
    return [NSSet setWithObjects: [points objectAtIndex:p1i], [points objectAtIndex:p2i], nil];
}

@end

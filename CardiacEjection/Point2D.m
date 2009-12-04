//
//  Point2D.m
//  EjectionFraction
//
//  Created by joris on 4/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "Point2D.h"


@implementation Point2D

+ (Point2D*) point: (NSPoint) a
{
	return [[[self alloc] initWithPoint: a] autorelease];
}

- (id) initWithPoint:(NSPoint) a
{
	pt = a;
	return self;
}

- (void) setPoint:(NSPoint) a
{
	pt = a;
}

- (float) y
{
	return pt.y;
}

- (float) x
{
	return pt.x;
}

- (NSPoint) point
{
	return pt;
}

@end

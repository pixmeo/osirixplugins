//
//  Point2D.h
//  EjectionFraction
//
//  Created by joris on 4/6/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface Point2D : NSObject
{
	NSPoint pt;
}

+ (Point2D*) point: (NSPoint) a;

- (id) initWithPoint:(NSPoint) a;
- (void) setPoint:(NSPoint) a;
- (float) y;
- (float) x;
- (NSPoint) point;
//- (Point2D) transformPoint: (float) scale: (float) rotation; ;


@end

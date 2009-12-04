//
//  CMIVBuketPirortyQueue.h
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 3/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMIVBuketPirortyQueue : NSObject {
	long* qBukets;
	long* biList;
	long buketNumber;
	long listSize;
	long curBuket;

}
- (id) initWithParameter: (long) costrange :(long) imageSize;
-(void)push:(long )item: (long )stepcost;
-(long)pop;
-(void)update:(long )item: (long )stepcost;
-(void)cleanQueue;
@end

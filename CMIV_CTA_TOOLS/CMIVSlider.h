//
//  CMIVSlider.h
//  CMIV_CTA_TOOLS
//
//  Created by chuwang on 2007-07-27.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMIVSlider : NSSlider {
	
	BOOL mouseLeftKeyDown;

}
-(BOOL) isMouseLeftKeyDown;

@end

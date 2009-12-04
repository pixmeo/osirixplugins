//
//  CMIVWindow.h
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CMIVWindow : NSWindow {
	

	NSSlider* horizontalSlider;
	NSSlider* verticalSlider;
	NSSlider* tranlateSlider;
	

}

-(void)setHorizontalSlider:(NSSlider*) aSlider;
-(void)setVerticalSlider:(NSSlider*) aSlider;
-(void)setTranlateSlider:(NSSlider*) aSlider;
@end

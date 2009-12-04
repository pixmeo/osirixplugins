//
//  CMIVWindow.m
//  CMIV_CTA_TOOLS
//
//  Created by chuwa on 12/13/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CMIVWindow.h"

@implementation CMIVWindow

-(void) dealloc
{
	NSLog(@"CMIVPluginWindow Dealloc.");
	[super dealloc];
	
}

-(void)setHorizontalSlider:(NSSlider*) aSlider
{
	horizontalSlider=aSlider;
}
-(void)setVerticalSlider:(NSSlider*) aSlider
{
	verticalSlider=aSlider;
}
-(void)setTranlateSlider:(NSSlider*) aSlider
{
	tranlateSlider=aSlider;
}

- (void)scrollWheel:(NSEvent *)theEvent
{
	CGFloat x,y,z=0;
	float loc;
	float acceleratefactor=0.1;

	x=[theEvent deltaX];
	y=[theEvent deltaY];
	if([theEvent modifierFlags] &  NSAlternateKeyMask)
	{
		x=0;
		y=0;
		z=[theEvent deltaY];
		if(z==0)
			z=[theEvent deltaX];
	}
	else if([theEvent modifierFlags] & NSCommandKeyMask )
	{
		x=[theEvent deltaY];
		y=[theEvent deltaX];
	}
		
	if(x!=0&&horizontalSlider!=nil)
	{
		if(x>0)
			x=(x-0.1)*acceleratefactor+0.1;
		else 
			x=(x+0.1)*acceleratefactor-0.1;
		loc=[horizontalSlider floatValue];
		loc-=x*10;
		while(loc>[horizontalSlider maxValue])
			loc-=([horizontalSlider maxValue]-[horizontalSlider minValue]);
		while(loc<[horizontalSlider minValue])
			loc+=([horizontalSlider maxValue]-[horizontalSlider minValue]);

		[horizontalSlider setFloatValue:loc];
		[horizontalSlider performClick:self];
	}
	if(y!=0&&tranlateSlider!=nil)
	{
		if(y>0)
			y=(y-0.1)*acceleratefactor+0.1;
		else 
			y=(y+0.1)*acceleratefactor-0.1;
		loc=[tranlateSlider floatValue];
		loc+=y*10;
		while(loc>[tranlateSlider maxValue])
			loc-=([tranlateSlider maxValue]-[tranlateSlider minValue]);
		while(loc<[tranlateSlider minValue])
			loc+=([tranlateSlider maxValue]-[tranlateSlider minValue]);
		[tranlateSlider setFloatValue:loc];
		[tranlateSlider performClick:self];
	}
	if(z!=0&&verticalSlider!=nil)
	{
		if(z>0)
			z=(z-0.1)*acceleratefactor+0.1;
		else 
			z=(z+0.1)*acceleratefactor-0.1;
		loc=[verticalSlider floatValue];
		loc+=z*10;
		while(loc>[verticalSlider maxValue])
			loc-=([verticalSlider maxValue]-[verticalSlider minValue]);
		while(loc<[verticalSlider minValue])
			loc+=([verticalSlider maxValue]-[verticalSlider minValue]);
		[verticalSlider setFloatValue:loc];
		[verticalSlider performClick:self];
	}
	
	[super scrollWheel:theEvent];

}
- (void)keyDown:(NSEvent *)event
{
	unsigned short i=[event keyCode];
	float loc;
	float x=0,y=0,z=0;
	float acceleratefactor=1.0;
	if([event modifierFlags] &  NSAlternateKeyMask)
		acceleratefactor=10.0;
	if(i==124)
	{
		x=1;
	}
	else if(i==123)
	{
		x=-1;
		
	}
	else if(i==121)
	{
		y=1;
		
	}
	else if(i==116)
	{
		y=-1;		
	}
	else if(i==126)
	{
		z=1;
		
	}
	else if(i==125)
	{
		z=-1;		
	}
	if(x!=0&&horizontalSlider!=nil)
	{

		loc=[horizontalSlider floatValue];
		loc+=x*acceleratefactor;
		while(loc>[horizontalSlider maxValue])
			loc-=([horizontalSlider maxValue]-[horizontalSlider minValue]);
		while(loc<[horizontalSlider minValue])
			loc+=([horizontalSlider maxValue]-[horizontalSlider minValue]);
		
		[horizontalSlider setFloatValue:loc];
		[horizontalSlider performClick:self];
	}
	if(y!=0&&tranlateSlider!=nil)
	{
	
		loc=[tranlateSlider floatValue];
		loc+=y*acceleratefactor;
		while(loc>[tranlateSlider maxValue])
			loc-=([tranlateSlider maxValue]-[tranlateSlider minValue]);
		while(loc<[tranlateSlider minValue])
			loc+=([tranlateSlider maxValue]-[tranlateSlider minValue]);
		[tranlateSlider setFloatValue:loc];
		[tranlateSlider performClick:self];
	}
	if(z!=0&&verticalSlider!=nil)
	{
		loc=[verticalSlider floatValue];
		loc+=z*acceleratefactor;
		while(loc>[verticalSlider maxValue])
			loc-=([verticalSlider maxValue]-[verticalSlider minValue]);
		while(loc<[verticalSlider minValue])
			loc+=([verticalSlider maxValue]-[verticalSlider minValue]);
		[verticalSlider setFloatValue:loc];
		[verticalSlider performClick:self];
	}
	
	//[super keyDown:event];
	
	
}

@end

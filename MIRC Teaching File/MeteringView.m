/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
			copyrights in this original Apple software (the "Apple Software"), to use,
			reproduce, modify and redistribute the Apple Software, with or without
			modifications, in source and/or binary forms; provided that if you redistribute
			the Apple Software in its entirety and without modifications, you must retain
			this notice and the following text and disclaimers in all such redistributions of
			the Apple Software.  Neither the name, trademarks, service marks or logos of
			Apple Computer, Inc. may be used to endorse or promote products derived from the
			Apple Software without specific prior written permission from Apple.  Except as
			expressly stated in this notice, no other rights or licenses, express or implied,
			are granted by Apple herein, including but not limited to any patent rights that
			may be infringed by your derivative works or by other works in which the Apple
			Software may be incorporated.

			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
			WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
			WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
			PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
			COMBINATION WITH YOUR PRODUCTS.

			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
			CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
			GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
			ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
			OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
			(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
			ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MeteringView.h"
#include <math.h>

double dbamp(double db) { return pow(10., 0.05 * db); }
double ampdb(double amp) { return 20. * log10(amp); }

#define kMinBarGap 			3
#define kBarWidth  			11
#define kBarInteriorWidth 	9
#define kClipBoxHeight		6

@implementation MeteringView

- (void)viewDidMoveToWindow
{
    if ([self window])
    {
        [self setNeedsDisplay:YES];
    }
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		mMeterValues = nil;
		mOldMeterValues = nil;
	
		drawsMetersOnly = NO;
		mHasClip = NO;
		mMinValue = 0.;
		mMinDB = ampdb(0.);
		mMaxValue = 1.;
		mMaxDB = ampdb(1.);
    }
    return self;
}

- (void) dealloc {
    //NSLog(@"[MeteringView dealloc] %p", self);
	if (mMeterValues)
		free(mMeterValues);
	if (mOldMeterValues)
		free(mOldMeterValues);
	[super dealloc];
}

- (void)drawRect:(NSRect)rect {
#pragma unused(rect)
    // Drawing code here.
	NSRect bounds = [self bounds];
	
	float xOffset = firstTrackOffset + .5;
	float yOffset = 0;
	float topGap  = mHasClip ? kClipBoxHeight + 2: 0;
	int i;
	
	// draw the frame
	for (i = 0; i < mNumChannels; i++) {
		NSRect  barRect = NSMakeRect(xOffset + .5, .5, kBarWidth-2, bounds.size.height-1.5 - topGap);
		
		if (!drawsMetersOnly) {
			NSPoint pt1 = NSMakePoint(xOffset, yOffset);
			NSPoint pt2 = NSMakePoint(xOffset, bounds.size.height-.5 - topGap);
			NSPoint pt3 = NSMakePoint(xOffset + kBarWidth-1, pt2.y);
			NSPoint pt4 = NSMakePoint(pt3.x, yOffset);
				
			[[NSColor colorWithCalibratedWhite: .37 alpha: 1] set];	// light color
			[NSBezierPath strokeLineFromPoint: pt1 toPoint: pt2];
			[NSBezierPath strokeLineFromPoint: pt2 toPoint: pt3];
			
			[[NSColor colorWithCalibratedWhite: .53 alpha: 1] set];	// shadow color
			[NSBezierPath strokeLineFromPoint: pt3 toPoint: pt4];
			[NSBezierPath strokeLineFromPoint: pt4 toPoint: pt1];
			
			if (mHasClip) {
				NSPoint pt5 = NSMakePoint(xOffset, bounds.size.height + 2.5 - topGap);
				NSPoint pt6 = NSMakePoint(xOffset, bounds.size.height-.5);
				NSPoint pt7 = NSMakePoint(xOffset + kBarWidth-1, pt6.y);
				NSPoint pt8 = NSMakePoint(pt7.x, pt5.y);
				
				[NSBezierPath strokeLineFromPoint: pt7 toPoint: pt8];
				[NSBezierPath strokeLineFromPoint: pt8 toPoint: pt5];

				[[NSColor colorWithCalibratedWhite: .37 alpha: 1] set];	// light color
				[NSBezierPath strokeLineFromPoint: pt5 toPoint: pt6];
				[NSBezierPath strokeLineFromPoint: pt6 toPoint: pt7];
			}
			
			// now draw the background above and including the current value
			[[NSColor colorWithCalibratedWhite: .4 alpha: 1] set];
			float value = roundf(mMeterValues[i * 2]);
			barRect.origin.y = value + 1;
			barRect.size.height   = bounds.size.height-2 - value - topGap;
			[NSBezierPath fillRect: barRect];
			
			if (mHasClip) {
				NSRect clipRect = NSMakeRect(barRect.origin.x, bounds.size.height + 3 - topGap, barRect.size.width, kClipBoxHeight -1.5);
				int clipVal = mClipValues[i];
				if (clipVal == 0) 
					[[NSColor colorWithCalibratedWhite: .4 alpha: 1] set];
				else if (clipVal >= 1 && clipVal < 10) {
					[[NSColor redColor] set];
					clipVal++;
				} else 
					[[NSColor colorWithCalibratedRed: 0.75 green: .18 blue: .18 alpha: 1] set];

				[NSBezierPath fillRect: clipRect];
			}
			
			[[NSColor greenColor] set];
			barRect.size.height   = barRect.origin.y;
			barRect.origin.y = 1;
			[NSBezierPath fillRect: barRect]; 
		} else {
			// only draw the difference area
			float old = roundf(mOldMeterValues[i * 2]);
			float curr= roundf(mMeterValues[i * 2]);
			
			// erase previous peak if it is different from the current
			float oldPeak = roundf(mOldMeterValues[(i*2) + 1]) + .5;
			float newPeak = roundf(mMeterValues[(i*2) + 1]) + .5;
			
			if (oldPeak != newPeak) {
				[[NSColor colorWithCalibratedWhite: .4 alpha: 1] set];
				[NSBezierPath strokeLineFromPoint: NSMakePoint(barRect.origin.x, oldPeak) 
					toPoint: NSMakePoint(barRect.origin.x+barRect.size.width, oldPeak)];
			}
			
			if (curr > old) {	// draw only green difference
				[[NSColor greenColor] set];
				barRect.origin.y = (old < 1)? 1 : old;
				barRect.size.height = curr - old;
				[NSBezierPath fillRect: barRect]; 			
			} else if (curr < old) {	// draw only gray difference
				[[NSColor colorWithCalibratedWhite: .4 alpha: 1] set];
				barRect.origin.y = curr + 1;
				barRect.size.height = old - curr;
				[NSBezierPath fillRect: barRect]; 
			} 
			
			// draw the peak
			if (oldPeak != newPeak || mClipValues[i] == 1) {
				if (mClipValues[i] == 1)
					[[NSColor redColor] set];
				else
					[[NSColor colorWithCalibratedWhite: .8 alpha: 1] set];
				[NSBezierPath strokeLineFromPoint: NSMakePoint(barRect.origin.x, newPeak) 
					toPoint: NSMakePoint(barRect.origin.x+barRect.size.width, newPeak)];
			}
			
			if (mHasClip) {
				NSRect clipRect = NSMakeRect(barRect.origin.x, bounds.size.height + 3 - topGap, 
												barRect.size.width, kClipBoxHeight -1.5);
				int clipVal = mClipValues[i];
				if (clipVal == 1) {
					[[NSColor redColor] set];
					[NSBezierPath fillRect: clipRect];
					clipVal++;
				} 
				else if (clipVal > 1 && clipVal < 10)
					clipVal++;
				else if (clipVal == 10) {
					[[NSColor colorWithCalibratedRed: 0.75 green: .18 blue: .18 alpha: 1] set];
					[NSBezierPath fillRect: clipRect];

					clipVal++;
				}
				mClipValues[i] = clipVal;
			}
		}
		
		xOffset += kMinBarGap + kBarWidth;
	}
	drawsMetersOnly = NO;
}

- (int)  numChannels
{
    return mNumChannels;
}

- (void) setNumChannels: (int) num {
	if (mNumChannels != num) {
		mNumChannels = num;
		if (mMeterValues != nil)
			free(mMeterValues);
		if (mOldMeterValues != nil)
			free(mOldMeterValues);
		if (mClipValues != nil)
			free(mClipValues);
		mMeterValues = (float *) calloc (2 * num, sizeof(float));
		mOldMeterValues = (float *) calloc (2 * num, sizeof(float));
		mClipValues = (int *) calloc (num, sizeof(int));
		drawsMetersOnly = NO;
		
		firstTrackOffset = floorf(([self bounds].size.width - (num * kBarWidth + (num-1) * kMinBarGap))/2);
		[self setNeedsDisplay: YES];
	}
}

- (void) setMinValue: (double) num { // lowest value possible slider (should be divisible by 2)
	if (num != mMinValue) {
		mMinValue = num;
		mMinDB = ampdb(num);
		drawsMetersOnly = NO;
		[self setNeedsDisplay: YES];
	}
}

- (void) setMaxValue: (double) num { // highest possible slider value (should be divisible by 2)
	if (num != mMaxValue) {
		mMaxValue = num;
		mMaxDB = ampdb(num);
		drawsMetersOnly = NO;
		[self setNeedsDisplay: YES];
	}
}

- (void) setMinDB: (double) num { 
	if (num != mMinDB) {
		mMinDB = num;
		mMinValue = dbamp(num);
		drawsMetersOnly = NO;
		[self setNeedsDisplay: YES];
	}
}

- (void) setMaxDB: (double) num { 
	if (num != mMaxDB) {
		mMaxDB = num;
		mMaxValue = dbamp(num);
		drawsMetersOnly = NO;
		[self setNeedsDisplay: YES];
	}
}

- (void) setHasClipIndicator: (BOOL) hasClip {
	if (hasClip != mHasClip) {
		mHasClip = hasClip;
		drawsMetersOnly = NO;
		[self setNeedsDisplay: YES];
	}
}

- (float)  pixelForValue: (double) value inSize: (int) size {
	return size * ((value - mMinValue) / (mMaxValue - mMinValue));		// figure out what percentage the value is of the entire range
}

- (void) updateMeters: (float *) meterValues {
	int i;
	
	if (![self inLiveResize]) {
		int numItems = mNumChannels * 2;
		for (i = 0; i < numItems; i++) {
			float tempValue = dbamp(meterValues[i]); 
			mOldMeterValues[i] = mMeterValues[i];
			float pixelValue = [self pixelForValue: tempValue inSize: (int) [self bounds].size.height];
			float top = [self bounds].size.height - (mHasClip ? kClipBoxHeight + 4: 2);
			if (pixelValue < 0)
				pixelValue = 0;
			else if (pixelValue > top)
				pixelValue = top;
				
			mMeterValues[i] = pixelValue;
			if (mHasClip) {
				if (tempValue > mMaxValue)
					mClipValues[i] = 1;
			}		
		}
		drawsMetersOnly = YES;
		[self setNeedsDisplay: YES];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (mHasClip) {
		int i;
		float xOffset = .5 + firstTrackOffset;
		float topGap  = mHasClip ? kClipBoxHeight + 3: 0;

		NSRect clipRect = NSMakeRect(0, [self bounds].size.height - topGap, kBarWidth-2, kClipBoxHeight);
		NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		for (i = 0; i < mNumChannels; i++) {
			clipRect.origin.x = xOffset + .5;
			if ([self mouse:mouseLoc inRect: clipRect]) {
				mClipValues[i] = 0;
				break;
			}
			xOffset += kMinBarGap + kBarWidth;
		}
	}
	drawsMetersOnly = NO;
	[self setNeedsDisplay: YES];
}

- (BOOL) acceptsFirstMouse: (NSEvent *) event {
#pragma unused(event)
    return YES;
}


- (BOOL) isOpaque {
	return YES;
}

- (void) setDirty: (BOOL)dirty
{
    drawsMetersOnly = !dirty;
}

@end

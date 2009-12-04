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

#import <Cocoa/Cocoa.h>
#import <QuickTime/QuickTime.h>
#import "SGChan.h"

@class SampleCIView;


extern NSString * SGVideoPreviewViewBoundsChangedNotification;


// this is a Cocoa wrapper for the VideoMediaType SGChannel.  It uses a SampleCIView
// (NSOpenGLView subclass) to preview images, after gathering them in the SGDataProc
// and pushing them through an ICMDecompressionSession.

@interface SGVideo : SGChan {
    GWorldPtr                   mOffscreen;
	ICMDecompressionSessionRef	mDecompS;
    TimeScale                   mTimeScale;
	TimeValue					mLastTime;
	UInt32						mFrameCount;
    long                        mFrameNumber;
	
// we intercept usage instead of passing it directly to the SGVideoChannel, 
// because we're overriding channel usage semantics by using the data proc
    long                        mUsage;
    NSRect                      mPreviewBounds;
	CodecQ						mPreviewQuality;
    SampleCIView *				mPreviewView;
    float						mDesiredPreviewFrameRate;
    TimeValue                   mMinPreviewFrameDuration;
}

- (id)initWithSeqGrab:(SeqGrab*)sg;

- (NSRect)srcVideoBounds;

- (NSRect)outputBounds;
- (void)setOutputBounds:(NSRect)bounds;

- (NSView*)previewView;
- (NSRect)previewBounds;


/*
	codecLowQuality               = 0x00000100,
	codecNormalQuality            = 0x00000200,
	codecHighQuality              = 0x00000300
*/
- (void)setPreviewQuality:(CodecQ)quality;
- (CodecQ)previewQuality;


- (void)setDesiredPreviewFrameRate:(float)fps;
- (float)desiredPreviewFrameRate;


- (OSType)channelType;
- (BOOL)isVideoChannel;
- (BOOL)isAudioChannel;


- (NSString*)summaryString;

-(OSErr)decompressData:(void*)data length:(long)length time:(TimeValue)timeValue;

- (void)displayData:(CVPixelBufferRef)pixelBuffer
            trackingFlags:(ICMDecompressionTrackingFlags)decompressionTrackingFlags
            displayTime:(TimeValue64)displayTime
            displayDuration:(TimeValue64)displayDuration
            validTimeFlags:(ICMValidTimeFlags)validTimeFlags;

@end

/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under AppleÕs
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

#import "SGVideo.h"
#import "WhackedDebugMacros.h"
#import "SampleCIView.h"


NSString * SGVideoPreviewViewBoundsChangedNotification = @"SGVideoPreviewViewBoundsChangedNotification";




static OSErr 
SGVideoDataProc(SGChannel c,  Ptr p,  long len,  long *offset,  long chRefCon, 
                TimeValue time,  short writeType, long refCon)
{
#pragma unused(offset)
#pragma unused(chRefCon)
#pragma unused(writeType)
#pragma unused(refCon)
	OSErr err = noErr;
    SGChan * chan = nil;
    
    SGGetChannelRefCon(c, (long*)&chan);
    
    if (chan && [chan isVideoChannel])
    {
        err = [(SGVideo*)chan decompressData:p length:len time:time];
    }

	return err;
}





// The tracking callback function for the decompression session.
// Used to display buffers into our view
static void 
SGVideoDecompTrackingCallback( 
		void *decompressionTrackingRefCon,
		OSStatus result,
		ICMDecompressionTrackingFlags decompressionTrackingFlags,
		CVPixelBufferRef pixelBuffer,
		TimeValue64 displayTime,
		TimeValue64 displayDuration,
		ICMValidTimeFlags validTimeFlags,
		void *reserved,
		void *sourceFrameRefCon )
{
#pragma unused(reserved)
#pragma unused(sourceFrameRefCon)
	if (result == noErr)
		[(SGVideo*)decompressionTrackingRefCon displayData:pixelBuffer
						trackingFlags:decompressionTrackingFlags
						displayTime:displayTime
						displayDuration:displayDuration
						validTimeFlags:validTimeFlags];
}







@implementation SGVideo

/*___________________________________________________________________________________________
*/

- (id)initWithSeqGrab:(SeqGrab*)sg
{
    OSStatus    err = noErr;
    NSRect      srcRect;
    
    self = [super initWithSeqGrab:sg];
    
	if (mChan == NULL)
		BAILSETERR( SGNewChannel([sg seqGrabComponent], VideoMediaType, &mChan) );
        
	BAILSETERR( SGSetChannelRefCon(mChan, (long)self) );

    srcRect = [self srcVideoBounds];
    [self setOutputBounds:srcRect];
    
    BAILSETERR( SGSetDataProc([sg seqGrabComponent], &SGVideoDataProc, 0) );
    
	[mSG addChannel:self];
	[super setUsage:seqGrabRecord];
    [self setUsage:seqGrabRecord + seqGrabPreview];
	
	mPreviewView = [[SampleCIView alloc] initWithFrame:srcRect];
	[self setPreviewQuality:codecNormalQuality];
    
bail:
    if (err)
    {
        [self release];
        return nil;
    }
    return self;
}

/*___________________________________________________________________________________________
*/

- (void)dealloc
{
    //NSLog(@"[SGVideo dealloc] %p", self);
    DisposeGWorld(mOffscreen);
    if (mDecompS)
        ICMDecompressionSessionRelease(mDecompS);
	[mPreviewView removeFromSuperview];
    [mPreviewView release];
    [super dealloc];
}

/*___________________________________________________________________________________________
*/

- (void)setUsage:(long)usage
{
    mUsage = usage;
}

/*___________________________________________________________________________________________
*/

- (long)usage
{
    return mUsage;
}

/*___________________________________________________________________________________________
*/

- (NSString*)selectedDevice;
{
	SGDeviceList list = NULL;
	SGDeviceInputList theSGInputList = NULL;
    NSString * currentDeviceAndInput = nil;
    OSStatus err = noErr;
	short deviceIndex, inputIndex;
	BOOL showInputsAsDevices = NO;

// get the list
    err = SGGetChannelDeviceList(mChan, sgDeviceListIncludeInputs, &list);

    if (!err && list)
    {
        // init
        deviceIndex = (*list)->selectedIndex;
        SGGetChannelDeviceAndInputNames(mChan, NULL, NULL, &inputIndex);
        showInputsAsDevices = ((*list)->entry[deviceIndex].flags) & sgDeviceNameFlagShowInputsAsDevices;
        theSGInputList = ((SGDeviceName *)(&((*list)->entry[deviceIndex])))->inputs;

        // get the combined device/input name
        if (showInputsAsDevices)
            currentDeviceAndInput = [NSString stringWithCString:(char*)((*theSGInputList)->entry[inputIndex].name + 1) 
										length:((*theSGInputList)->entry[inputIndex].name[0])];
    }

    if (list)
        SGDisposeDeviceList([mSG seqGrabComponent], list);

    return currentDeviceAndInput;
}

/*___________________________________________________________________________________________
*/

- (NSRect)srcVideoBounds
{
    Rect r;
    NSRect nsr = {0};
    
    if (noErr == SGGetSrcVideoBounds(mChan, &r))
    {
		if (r.bottom == 1200 && r.right == 1600)
		{
				// IIDC driver reports the largest bounds possible in the IIDC spec.  
				// At least if it's iSight, we can hack in a better value
			if ([[self selectedDevice] isEqualToString:@"iSight"])
			{
				nsr = NSMakeRect(0, 0, 640, 480);
				goto bail;
			}
		}

		nsr = NSMakeRect(r.left, r.top, r.right - r.left, r.bottom - r.top);
    }
bail:    
    return nsr;
}

/*___________________________________________________________________________________________
*/

- (NSRect)outputBounds
{
    Rect r;
    SGGetChannelBounds(mChan, &r);
    
    return NSMakeRect(r.left, r.top, r.right - r.left, r.bottom - r.top);
}

/*___________________________________________________________________________________________
*/

- (void)setOutputBounds:(NSRect)bounds
{
    OSStatus err = noErr;
    
    if (mOffscreen)
    {
        DisposeGWorld(mOffscreen);
        mOffscreen = NULL;
    }
    if (bounds.size.width && bounds.size.height)
    {
        Rect r;
        SetRect(&r, 0, 0, (short)bounds.size.width, (short)bounds.size.height);
        BAILSETERR( QTNewGWorld(&mOffscreen, 32, &r, NULL, NULL, 0) );
        LockPixels(GetGWorldPixMap(mOffscreen));
        
        BAILSETERR(SGSetGWorld(mChan, mOffscreen, GetGWorldDevice(mOffscreen)));
        
        BAILSETERR( SGSetChannelBounds(mChan, &r) );
    }
    
bail:
    return;
}

/*___________________________________________________________________________________________
*/

- (void)setPreviewQuality:(CodecQ)quality
{
	mPreviewQuality = quality;
}

/*___________________________________________________________________________________________
*/

- (CodecQ)previewQuality
{
	return mPreviewQuality;
}

/*___________________________________________________________________________________________
*/

- (NSRect)previewBounds
{
    return mPreviewBounds;
}

/*___________________________________________________________________________________________
*/
 
- (void)setPreviewBounds:(NSRect)newBounds
{
    if (newBounds.size.width != mPreviewBounds.size.width ||
        newBounds.size.height != mPreviewBounds.size.height)
    {
        mPreviewBounds = newBounds;
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:SGVideoPreviewViewBoundsChangedNotification object:self];
    }
}

/*___________________________________________________________________________________________
*/

- (OSType)channelType
{
    return VideoMediaType;
}

/*___________________________________________________________________________________________
*/

- (BOOL)isVideoChannel
{
    return YES;
}

/*___________________________________________________________________________________________
*/

- (BOOL)isAudioChannel
{
    return NO;
}

/*___________________________________________________________________________________________
*/

- (NSView*)previewView
{
	return mPreviewView;
}

/*___________________________________________________________________________________________
*/

- (NSString*)summaryString
{
    return [NSString stringWithFormat:@"[%p] SGVideo: %@", self, [self selectedDevice]];
}

/*___________________________________________________________________________________________
*/

- (void)setDesiredPreviewFrameRate:(float)fps
{
    mDesiredPreviewFrameRate = fps;
}

/*___________________________________________________________________________________________
*/

- (float)desiredPreviewFrameRate
{
    return mDesiredPreviewFrameRate;
}

/*___________________________________________________________________________________________
*/

-(OSErr)decompressData:(void*)data length:(long)length time:(TimeValue)timeValue
{
    OSStatus err = noErr;
    ICMFrameTimeRecord frameTime = {{0}};
    
        // don't bother doing any work if we're not supposed to be previewing
    if ( ([mSG isPreviewing] && !([self usage] & seqGrabPreview)) ||
         ([mSG isRecording] && !([self usage] & seqGrabPlayDuringRecord)) )
    {
        goto bail;
    }
	
        // don't bother doing any decompressing if our view is not in use
	if ([mPreviewView window] == nil)
	{
		goto bail; 
	}
	
	if (mLastTime > timeValue)
	{
        // this means there was a stop/start
		mLastTime = 0;
		mFrameCount = 0;
        mTimeScale = 0;
        mMinPreviewFrameDuration = 0;
		mPreviewBounds = NSMakeRect(0., 0., 0., 0.);
        
        if (mDecompS)
        {
            ICMDecompressionSessionRelease(mDecompS);
            mDecompS = NULL;
        }
	}
    
    if (mTimeScale == 0)
    {
        BAILSETERR( SGGetChannelTimeScale(mChan, &mTimeScale) );
    }
    
    
    
        // find out if we should drop this frame
    if (mDesiredPreviewFrameRate)
    {
        if (mMinPreviewFrameDuration == 0)
            mMinPreviewFrameDuration = (TimeValue)(mTimeScale/mDesiredPreviewFrameRate);
            
            // round times to a multiple of the frame rate
        int n = (int)floor( ( ((float)timeValue) * mDesiredPreviewFrameRate / mTimeScale ) + 0.5 );
        timeValue = (TimeValue)(n * mTimeScale / mDesiredPreviewFrameRate);
        
        if ( (mLastTime > 0) && (timeValue < mLastTime + mMinPreviewFrameDuration) )
        {
            // drop the frame
            goto bail;
        }
    }
    
    
    
        // Make a decompression session!!
    if (NULL == mDecompS)
    {
        ImageDescriptionHandle imageDesc = (ImageDescriptionHandle)NewHandle(0);
        NSRect srcRect = [self srcVideoBounds], imageRect = {0};
        NSMutableDictionary * pixelBufferAttribs = nil;
        ICMDecompressionTrackingCallbackRecord trackingCallbackRecord;
        ICMDecompressionSessionOptionsRef sessionOptions = NULL;
        SInt32 displayWidth, displayHeight;
        
        
        
        if ( noErr != (err = SGGetChannelSampleDescription(mChan, (Handle)imageDesc)) )
        {
            DisposeHandle((Handle)imageDesc);
            BAILERR(err);
        }
        
        
        
        // Get the display width and height (the clean aperture width and height
        // suitable for display on a square pixel display like a computer monitor)
        if (noErr != ICMImageDescriptionGetProperty(imageDesc, kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_DisplayWidth,
                                sizeof(displayWidth), &displayWidth, NULL) )
            displayWidth = (**imageDesc).width;
        
        if (noErr != ICMImageDescriptionGetProperty(imageDesc, kQTPropertyClass_ImageDescription,
                                kICMImageDescriptionPropertyID_DisplayHeight,
                                sizeof(displayHeight), &displayHeight, NULL) )
            displayHeight = (**imageDesc).height;
            
        imageRect = NSMakeRect(0., 0., (float)displayWidth, (float)displayHeight);
		[self setPreviewBounds:imageRect];
        
        
        
		// the view to which we will be drawing accepts CIImage's.  As of QuickTime 7.0,
        // the CIImage * class does not apply gamma correction information present in
        // the ImageDescription unless there is also NCLCColorInfo to go with it.
        // We'll check here for the presence of this extension, and add a default if
        // we don't find one (we'll restrict this slam to 2vuy pixel format).
        if ( (**imageDesc).cType == '2vuy' )
        {
            OSStatus tryErr;
            NCLCColorInfoImageDescriptionExtension nclc;
            
            tryErr = ICMImageDescriptionGetProperty(imageDesc, 
                    kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_NCLCColorInfo, 
                    sizeof(nclc), &nclc, NULL);
            if( noErr != tryErr ) {
                // Assume NTSC
                nclc.colorParamType = kVideoColorInfoImageDescriptionExtensionType;
                nclc.primaries = kQTPrimaries_SMPTE_C;
                nclc.transferFunction = kQTTransferFunction_ITU_R709_2;
                nclc.matrix = kQTMatrix_ITU_R_601_4;
                ICMImageDescriptionSetProperty(imageDesc, 
                    kQTPropertyClass_ImageDescription, kICMImageDescriptionPropertyID_NCLCColorInfo, 
                    sizeof(nclc), &nclc);
            }
        }

        
        
        
        
        // fill out a dictionary describing the attributes of the pixel buffers we want the session
        // to produce.  we're purposely not setting a pixel format, as we want the session to figure
        // out the best format.  This strategy gives us performance opportunities if we don't
        // want to draw onto the video.  If we _do_ want to draw, we should explicitly ask for
        // k32ARGBPixelFormat.
	
        pixelBufferAttribs = [[NSMutableDictionary alloc] init];
	/*	
		//don't pass width and height.  Let the codec make a best guess as to the appropriate
		//width and height for the given quality.  It might choose to do a quarter frame decode,
		//for instance
		
        [pixelBufferAttribs setObject:[NSNumber numberWithFloat:imageRect.size.width] 
                                forKey:(id)kCVPixelBufferWidthKey];
        [pixelBufferAttribs setObject:[NSNumber numberWithFloat:imageRect.size.height] 
                                forKey:(id)kCVPixelBufferHeightKey];
	*/
        [pixelBufferAttribs setObject:[NSNumber numberWithBool:YES]
                                forKey:(id)kCVPixelBufferOpenGLCompatibilityKey];
        
        // assign a tracking callback
        trackingCallbackRecord.decompressionTrackingCallback = SGVideoDecompTrackingCallback;
        trackingCallbackRecord.decompressionTrackingRefCon = self;
        
        
        // we also need to create a ICMDecompressionSessionOptionsRef to fill in codec quality
        err = ICMDecompressionSessionOptionsCreate(NULL, &sessionOptions);
        if (err == noErr)
        {
            ICMDecompressionSessionOptionsSetProperty(sessionOptions,
                    kQTPropertyClass_ICMDecompressionSessionOptions,
                    kICMDecompressionSessionOptionsPropertyID_Accuracy,
                    sizeof(CodecQ), &mPreviewQuality);
        }
        
        // now make a new decompression session to decode source video frames
        // to pixel buffers
        err = ICMDecompressionSessionCreate(NULL, imageDesc, sessionOptions, // no session options
                    (CFDictionaryRef)pixelBufferAttribs, &trackingCallbackRecord, &mDecompS);
        
        
        [pixelBufferAttribs release];
        ICMDecompressionSessionOptionsRelease(sessionOptions);
        DisposeHandle((Handle)imageDesc);

		BAILERR(err);
    }
    
    
    frameTime.recordSize = sizeof(ICMFrameTimeRecord);
    *(TimeValue64*)&frameTime.value = timeValue;
    frameTime.scale = mTimeScale;
    frameTime.rate = fixed1;
    frameTime.frameNumber = ++mFrameCount;
    frameTime.flags = icmFrameTimeIsNonScheduledDisplayTime;
    
    // push the frame into the session
    err = ICMDecompressionSessionDecodeFrame( mDecompS,
			(UInt8 *)data, length, NULL, &frameTime, self );
    
    // and suck it back out
    ICMDecompressionSessionSetNonScheduledDisplayTime( mDecompS, timeValue, mTimeScale, 0 );
    
    mLastTime = timeValue;
bail:
    return err;
}

/*___________________________________________________________________________________________
*/

- (void)displayData:(CVPixelBufferRef)pixelBuffer
                    trackingFlags:(ICMDecompressionTrackingFlags)decompressionTrackingFlags
                    displayTime:(TimeValue64)displayTime
                    displayDuration:(TimeValue64)displayDuration
                    validTimeFlags:(ICMValidTimeFlags)validTimeFlags
{
#pragma unused(displayTime)
#pragma unused(displayDuration)
#pragma unused(validTimeFlags)
    if ( (decompressionTrackingFlags & kICMDecompressionTracking_EmittingFrame) && pixelBuffer)
    {
			// only draw into the view if it's housed in a window
		if ([mPreviewView window] != nil)
		{
			CIImage * ciImage = [CIImage imageWithCVImageBuffer:pixelBuffer];
			[mPreviewView setImage:ciImage];
			[mPreviewView setCleanRect:CVImageBufferGetCleanRect(pixelBuffer)];
			//[mPreviewView setDisplaySize:CVImageBufferGetDisplaySize(pixelBuffer)];
			[mPreviewView setDisplaySize:*(CGSize *)&mPreviewBounds.size];
			[mPreviewView setNeedsDisplay:YES];
		}
    }
}

/*___________________________________________________________________________________________
*/

@end

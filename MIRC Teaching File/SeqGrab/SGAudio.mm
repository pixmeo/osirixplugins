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

#import "SGAudio.h"
#import "WhackedDebugMacros.h"
#import <CoreAudioKit/CoreAudioKit.h>
#import "SGAudioSettings.h"



NSString * SGAudioDeviceListChangedNotification                     = @"SGAudioDeviceListChangedNotification";
NSString * SGAudioRecordDeviceDiedNotification                      = @"SGAudioRecordDeviceDiedNotification";
NSString * SGAudioRecordDeviceHoggedChangedNotification             = @"SGAudioRecordDeviceHoggedChangedNotification";
NSString * SGAudioRecordDeviceInUseChangedNotification              = @"SGAudioRecordDeviceInUseChangedNotification";
NSString * SGAudioRecordDeviceStreamFormatChangedNotification       = @"SGAudioRecordDeviceStreamFormatChangedNotification";
NSString * SGAudioRecordDeviceStreamFormatListChangedNotification   = @"SGAudioRecordDeviceStreamFormatListChangedNotification";
NSString * SGAudioRecordDeviceInputSelectionNotification            = @"SGAudioRecordDeviceInputSelectionNotification";
NSString * SGAudioRecordDeviceInputListChangedNotification          = @"SGAudioRecordDeviceInputListChangedNotification";
NSString * SGAudioPreviewDeviceDiedNotification                     = @"SGAudioPreviewDeviceDiedNotification";
NSString * SGAudioPreviewDeviceHoggedChangedNotification            = @"SGAudioPreviewDeviceHoggedChangedNotification";
NSString * SGAudioPreviewDeviceInUseChangedNotification             = @"SGAudioPreviewDeviceInUseChangedNotification";
NSString * SGAudioPreviewDeviceStreamFormatChangedNotification      = @"SGAudioPreviewDeviceStreamFormatChangedNotification";
NSString * SGAudioPreviewDeviceStreamFormatListChangedNotification  = @"SGAudioPreviewDeviceStreamFormatListChangedNotification";
NSString * SGAudioPreviewDeviceOutputSelectionChangedNotification   = @"SGAudioPreviewDeviceOutputSelectionChangedNotification";
NSString * SGAudioPreviewDeviceOutputListChangedNotification        = @"SGAudioPreviewDeviceOutputListChangedNotification";
NSString * SGAudioOutputStreamFormatChangedNotification             = @"SGAudioOutputStreamFormatChangedNotification";

static OSStatus myPreMixSGAudioCallback(
    SGChannel		 	  				c,
    void *                  			inRefCon,
    SGAudioCallbackFlags *				ioFlags,
    const AudioTimeStamp *  			inTimeStamp,
    const UInt32 *          			inNumberPackets,
    const AudioBufferList * 			inData,
    const AudioStreamPacketDescription*	inPacketDescriptions);
    
    
static OSStatus
fxUnitInputProc(void *inRefCon, 
                AudioUnitRenderActionFlags *ioActionFlags, 
                const AudioTimeStamp *inTimeStamp, 
                UInt32 inBusNumber, 
                UInt32 inNumberFrames, 
                AudioBufferList *ioData);
    
static void 
sgAudioPropListenerCallback(ComponentInstance inComponent, 
                            ComponentPropertyClass inPropClass, 
                            ComponentPropertyID inPropID, 
                            void *inUserData);


@implementation SGAudio

/*___________________________________________________________________________________________
*/

- (id)initWithSeqGrab:(SeqGrab*)sg
{
    OSStatus err = noErr;
    NSData * data = nil;
    ComponentPropertyInfo * cpi = NULL;
	Boolean audiComponentAlreadyOpened = (mChan != NULL);
    self = [super initWithSeqGrab:sg];
    
	if (false == audiComponentAlreadyOpened)
		BAILSETERR( SGNewChannel([sg seqGrabComponent], SGAudioMediaType, &mChan) );
        
	BAILSETERR( SGSetChannelRefCon(mChan, (long)self) );
    
	[mSG addChannel:self];
    
	[self setUsage:seqGrabPreview + seqGrabRecord];
    
        // register self as a listener of all the SGAudio Listenable properties.
        // we will create notifications for all the listenable properties we recognize
    [self getPropertyWithClass:kComponentPropertyClassPropertyInfo
                                    id:kComponentPropertyInfoList
                                    size:sizeof(data)
                                    address:&data
                                    sizeUsed:NULL];

    cpi = (ComponentPropertyInfo*)[data bytes];
    
    if (cpi)
    {
        for (int i = 0; i < [data length]/sizeof(ComponentPropertyInfo); i++)
        {
            if (cpi[i].propFlags & kComponentPropertyFlagWillNotifyListeners)
            {
                QTAddComponentPropertyListener(mChan, 
                    cpi[i].propClass, cpi[i].propID,
                    (QTComponentPropertyListenerUPP)sgAudioPropListenerCallback,
                    self);
            }
        }
    }
    
    // set the channel map on the record device to expressly indicate our desire to
    // receive all channels from the record device (a reasonable default)
	if (false == audiComponentAlreadyOpened)
    {
        AudioStreamBasicDescription devFormat;
        
        if (noErr == [self getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
                        id: kQTSGAudioPropertyID_StreamFormat 
                        size:sizeof(devFormat) 
                        address:&devFormat 
                        sizeUsed:NULL])
        {
            SInt32 * map = (SInt32*)malloc(devFormat.mChannelsPerFrame * sizeof(SInt32));
            
            for (int i = 0; i < devFormat.mChannelsPerFrame; i++)
            {
                map[i] = i;
            }
            
            [self setPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
                    id: kQTSGAudioPropertyID_ChannelMap 
                    size: devFormat.mChannelsPerFrame * sizeof(SInt32) 
                    address: map];
            
            free(map);
        }
    }
    
    mDoInitFXUnits = YES;
bail:
    [data release];
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
    //NSLog(@"[SGAudio dealloc] %p", self);
    
    while (mFXUnitsCount--)
        CloseComponent(mFXUnits[mFXUnitsCount]);
    
	[super dealloc];
}

/*___________________________________________________________________________________________
*/

- (OSType)channelType
{
    return SGAudioMediaType;
};

/*___________________________________________________________________________________________
*/

- (OSStatus)getPropertyInfoWithClass:(ComponentPropertyClass)theClass
                                    id:(ComponentPropertyID)theID
                                    type:(ComponentValueType*)type
                                    size:(ByteCount*)sz
                                    flags:(UInt32*)flags
{ 
    return QTGetComponentPropertyInfo(mChan, theClass, theID, type, sz, flags); 
}

/*___________________________________________________________________________________________
*/

- (OSStatus)getPropertyWithClass:(ComponentPropertyClass)theClass
                                    id:(ComponentPropertyID)theID
                                    size:(ByteCount)sz
                                    address:(ComponentValuePtr)addr
                                    sizeUsed:(ByteCount*)szUsed
{ 
    return QTGetComponentProperty(mChan, theClass, theID, sz, addr, szUsed); 
}

/*___________________________________________________________________________________________
*/
            
- (OSStatus)setPropertyWithClass:(ComponentPropertyClass)theClass
                                id:(ComponentPropertyID)theID
                                size:(ByteCount)sz
                                address:(ConstComponentValuePtr)addr
{ 
    return QTSetComponentProperty(mChan, theClass, theID, sz, addr); 
}

/*___________________________________________________________________________________________
*/

// The following three functions are for convenience in getting common properties

- (NSArray*)deviceList
{
    NSArray * devList = nil;
    
    [self getPropertyWithClass: kQTPropertyClass_SGAudio 
                             id: kQTSGAudioPropertyID_DeviceListWithAttributes 
                           size: sizeof(NSArray*) 
                        address: &devList
                       sizeUsed: NULL];
    return [devList autorelease];
}

/*___________________________________________________________________________________________
*/

- (NSArray*)recordCapableDeviceList
{
    NSArray * devList = [self deviceList];
    NSMutableArray * myList = nil;
    
    if (devList)
    {
        myList = [NSMutableArray array];
        
        for (int i = 0; i < [devList count]; i++)
        {
            NSDictionary * devDict = [devList objectAtIndex:i];
            UInt32 key = kQTAudioDeviceAttribute_DeviceCanRecordKey;

            if (YES == [(NSNumber*)[devDict objectForKey:(id)key] boolValue])
                [myList addObject:devDict];
        }
    }
    
    return myList;
}

/*___________________________________________________________________________________________
*/

- (NSArray*)previewCapableDeviceList
{
    NSArray * devList = [self deviceList];
    NSMutableArray * myList = nil;
    
    if (devList)
    {
        myList = [NSMutableArray array];
        
        for (int i = 0; i < [devList count]; i++)
        {
            NSDictionary * devDict = [devList objectAtIndex:i];
            UInt32 key = kQTAudioDeviceAttribute_DeviceCanPreviewKey;

            if (YES == [(NSNumber*)[devDict objectForKey:(id)key] boolValue])
                [myList addObject:devDict];
        }
    }

    return myList;
}

/*________________________________________________________________________________________
*/

- (NSString*)summaryString
{
	NSString * device = nil;
	NSDictionary * attribs = nil;
	NSString * retval = nil;
	
	[self getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
                             id: kQTSGAudioPropertyID_DeviceAttributes 
                           size: sizeof(attribs) 
                        address: &attribs
                       sizeUsed: NULL];
					   
	device = [attribs objectForKey:(id)kQTAudioDeviceAttribute_DeviceNameKey];
	
	
	retval = [NSString stringWithFormat:@"[%p] SGAudio: %@", self, device];
	
	[attribs release];
	
	return retval;
}

/*________________________________________________________________________________________
*/

- (BOOL)isVideoChannel
{
	return NO;
}

/*________________________________________________________________________________________
*/

- (BOOL)isAudioChannel
{
	return YES;
}

/*________________________________________________________________________________________
*/

// we override the SGChan base class's showSettingsDialog implementation, as the 
// SGAudioMediaType channel that shipped in QT 7 does not implement SGSettingsDialog(),
// but our Cocoa wrapper does.

- (OSStatus)showSettingsDialog
{
	SGAudioSettings * settings = [[SGAudioSettings alloc] initWithSGChan:self];
	[settings showPanel:self];
	[settings release];
	return noErr;
}

/*________________________________________________________________________________________
*/

- (void)notifyOfChangeInPropClass:(ComponentPropertyClass)theClass 
            id:(ComponentPropertyID)theID
{
    NSString * notif = nil;
  
    switch (theClass) {
        case kQTPropertyClass_SGAudio:
            switch (theID) {
                case kQTSGAudioPropertyID_DeviceListWithAttributes:
                    notif = SGAudioDeviceListChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_StreamFormat:
                    notif = SGAudioOutputStreamFormatChangedNotification;
                    break;
                    
                default:
                    NSLog(@"Unknown SGAudio property (%.4s)", (char*)&theID);
                    break;
            };
            break;
            
        case kQTPropertyClass_SGAudioRecordDevice:
            switch (theID) {
                case kQTSGAudioPropertyID_DeviceAlive:
                    notif = SGAudioRecordDeviceDiedNotification;
                    mDoInitFXUnits = YES;
                    break;
                    
                case kQTSGAudioPropertyID_DeviceHogged:
                    notif = SGAudioRecordDeviceHoggedChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_DeviceInUse:
                    notif = SGAudioRecordDeviceInUseChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_StreamFormat:
                    notif = SGAudioRecordDeviceStreamFormatChangedNotification;
                    mDoInitFXUnits = YES;
                    break;
                    
                case kQTSGAudioPropertyID_StreamFormatList:
                    notif = SGAudioRecordDeviceStreamFormatListChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_InputSelection:
                    notif = SGAudioRecordDeviceInputSelectionNotification;
                    break;
                    
                case kQTSGAudioPropertyID_InputListWithAttributes:
                    notif = SGAudioRecordDeviceInputListChangedNotification;
                    break;
                    
                default:
                    NSLog(@"Unknown SGAudioRecordDevice property (%.4s)", (char*)&theID);
                    break;
            };
            break;
        
        case kQTPropertyClass_SGAudioPreviewDevice:
            switch (theID) {
                case kQTSGAudioPropertyID_DeviceAlive:
                    notif = SGAudioPreviewDeviceDiedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_DeviceHogged:
                    notif = SGAudioPreviewDeviceHoggedChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_DeviceInUse:
                    notif = SGAudioPreviewDeviceInUseChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_StreamFormat:
                    notif = SGAudioPreviewDeviceStreamFormatChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_StreamFormatList:
                    notif = SGAudioPreviewDeviceStreamFormatListChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_OutputSelection:
                    notif = SGAudioPreviewDeviceOutputSelectionChangedNotification;
                    break;
                    
                case kQTSGAudioPropertyID_OutputListWithAttributes:
                    notif = SGAudioPreviewDeviceOutputListChangedNotification;
                    break;
                    
                default:
                    NSLog(@"Unknown SGAudioPreviewDevice property (%.4s)", (char*)&theID);
                    break;
            };
            break;
            
        default:
            NSLog(@"[SGAudio] Unknown property class (%.4s), id (%.4s)", (char*)&theClass, (char*)&theID);
            break;
    };
    
    if (notif)
        [[NSNotificationCenter defaultCenter] postNotificationName:notif object:self];
}

/*________________________________________________________________________________________
*/

- (AudioUnit *)fxUnits
{
	return mFXUnits;
}

/*________________________________________________________________________________________
*/
- (UInt32)fxUnitsCount
{
	return mFXUnitsCount;
}

/*________________________________________________________________________________________
*/

// The SGAudioMediaType channel that shipped in QT 7 has no built in support for 
// AudioUnit fx, but our Cocoa wrapper does, using the SGAudioMediaType SGChannel's
// SGAudioCallback mechanism.

- (AudioUnit)insertAUFXUnit:(ComponentDescription *)fxUnitDesc;
{
    Component c;
    AudioUnit au;
    SGAudioCallbackStruct cbStruct;
    
    
    if (mFXUnitsCount == kMaxFXUnits)
        return NULL;
        
    if (fxUnitDesc->componentType != 'aufx')
        return NULL;
       
    c = FindNextComponent(NULL, fxUnitDesc);
    if (!c)
        return NULL;
        
    au = OpenComponent(c);
    if (!au)
        return NULL;
        
    // register our callback proc
    cbStruct.inputProc = myPreMixSGAudioCallback;
    cbStruct.inputProcRefCon = self;
    
    [self setPropertyWithClass:kQTPropertyClass_SGAudio 
                            id:kQTSGAudioPropertyID_PreMixCallback 
                            size:sizeof(cbStruct) 
                            address:&cbStruct];
    
    mFXUnits[mFXUnitsCount++] = au;
    
    mDoInitFXUnits = YES;
    
    return au;
}

/*________________________________________________________________________________________
*/

- (BOOL)removeAUFXUnit:(AudioUnit)doomedFXUnit
{
    for (int i = 0; i < mFXUnitsCount; i++)
    {
        if (mFXUnits[i] == doomedFXUnit)
        {
            CloseComponent(doomedFXUnit);
            memcpy(&mFXUnits[i], &mFXUnits[i+1], (--mFXUnitsCount - i) * sizeof(AudioUnit));
			
				// when we go down to zero, we should remove the callback from firing
			if (mFXUnitsCount == 0)
			{
				SGAudioCallbackStruct cbStruct;
				cbStruct.inputProc = NULL;
				cbStruct.inputProcRefCon = 0;
				
				[self setPropertyWithClass:kQTPropertyClass_SGAudio 
                            id:kQTSGAudioPropertyID_PreMixCallback 
                            size:sizeof(cbStruct) 
                            address:&cbStruct];
			}
            return YES;
        }
    }
    return NO;
}

/*________________________________________________________________________________________
*/

- (OSStatus)sgAudioCallbackRender:
                (SGAudioCallbackFlags *)ioFlags
                timestamp:(const AudioTimeStamp *)inTimeStamp
                numPackets:(const UInt32 *)inNumberPackets
                buffer:(const AudioBufferList *)inData
                packetDescs:(const AudioStreamPacketDescription*)inPacketDescriptions
{
#pragma unused (ioFlags)
#pragma unused (inPacketDescriptions)
        // sgAudioCallbackRender gets called when pre-mixed data is available.
    OSStatus err = noErr;
    UInt32      numFrames = *inNumberPackets;
    
        // we lazily initialize the units, so this code will execute the first time we
        // get a render callback
    if (mDoInitFXUnits)
    {
        AudioStreamBasicDescription asbd;
        UInt32 maxFrames = numFrames + 512; // extra 512 for safety
        
            // get the pre-mix callback format

        [self getPropertyWithClass:kQTPropertyClass_SGAudio 
                                id:kQTSGAudioPropertyID_PreMixCallbackFormat 
                                size:sizeof(asbd) 
                                address:&asbd 
                                sizeUsed:NULL];

        for (int i = 0; i < mFXUnitsCount; i++)
        {
                // set up fx units
            UInt32                  inPlace, size;
            Boolean                 writable;
            OSStatus                caErr = noErr, inPlaceErr = noErr;

            if (mFXUnits[i])
            {
                AudioUnitUninitialize(mFXUnits[i]);
                
                caErr = AudioUnitSetProperty(   
                            mFXUnits[i], 
                            kAudioUnitProperty_StreamFormat, 
                            kAudioUnitScope_Input,
                            0, &asbd, sizeof(asbd));
                                                
                if (caErr == noErr)
                    caErr = AudioUnitSetProperty(mFXUnits[i], 
                                                kAudioUnitProperty_StreamFormat, 
                                                kAudioUnitScope_Output,
                                                0, &asbd, sizeof(asbd));
                                                
                if (caErr == noErr)
                    caErr = AudioUnitSetProperty(
                                mFXUnits[i], 
                                kAudioUnitProperty_MaximumFramesPerSlice, 
                                kAudioUnitScope_Global,
                                0, &maxFrames, sizeof(maxFrames));
                         
                         
                    // prefer in place processing, if the fx unit can do it
                    
                if (caErr == noErr)
                    inPlaceErr = AudioUnitGetPropertyInfo(
                                    mFXUnits[i], 
                                    kAudioUnitProperty_InPlaceProcessing, 
                                    kAudioUnitScope_Global,
                                    0, &size, &writable);
                if (caErr == noErr && inPlaceErr == noErr)
                {
                    caErr = AudioUnitGetProperty(
                                mFXUnits[i], 
                                kAudioUnitProperty_InPlaceProcessing, 
                                kAudioUnitScope_Global,
                                0, &inPlace, &size);
                                    
                    if (caErr == noErr && writable)
                    {
                        inPlace = 1;
                        caErr = AudioUnitSetProperty(
                                    mFXUnits[i], 
                                    kAudioUnitProperty_InPlaceProcessing, 
                                    kAudioUnitScope_Global,
                                    0, &inPlace, sizeof(inPlace));
                    }
                }
                

                AURenderCallbackStruct cb;
                cb.inputProc = fxUnitInputProc;
                cb.inputProcRefCon = self;
                if (caErr == noErr)
                    caErr = AudioUnitSetProperty(
                                mFXUnits[i], 
                                kAudioUnitProperty_SetRenderCallback, 
                                kAudioUnitScope_Global, 0, 
                                &cb, sizeof(cb) );
                if (caErr == noErr)
                    caErr = AudioUnitInitialize(mFXUnits[i]);
                    
                if (caErr != noErr)
                {
                    [self removeAUFXUnit:mFXUnits[i]];
                    i = 0; // start over
                }
            }
        }
        mDoInitFXUnits = NO;
    }  
        
        
        // Here, we stow away the buffer, and begin 
        // the pull on our Audio Unit chain
    
        // we are treating the passed buffer list as
        // read/write, so we explicitly cast away the const
    mPullBuffer = (AudioBufferList*)inData;
    
    if (mFXUnitsCount)
    {
        mPullUnitIndex = mFXUnitsCount - 1;
        BAILSETERR( AudioUnitRender(  mFXUnits[mPullUnitIndex], 
                                NULL, 
                                inTimeStamp, 0, numFrames, mPullBuffer) );
    }
bail:
	return err;
}
                         
/*________________________________________________________________________________________
*/
                                               
- (OSStatus)fxUnitRender:(AudioUnitRenderActionFlags *)ioActionFlags
                            timestamp:(const AudioTimeStamp *)inTimeStamp
                            bus:(UInt32)inBusNumber 
                            numFrames:(UInt32)inNumberFrames
                            buffer:(AudioBufferList *)ioData
{
#pragma unused (ioActionFlags)
#pragma unused (inBusNumber)
        // fxUnitRender gets called to feed data to the AudioUnit
        // at location mFXUnits[mPullUnitIndex].  If mPullUnitIndex
        // is zero, it's already been pulled, and we need to
        // feed the buffer passed in the SGAudioCallbackProc
    OSStatus    err = noErr;
    
    if (mPullUnitIndex > 0)
    {
        BAILSETERR( AudioUnitRender(  mFXUnits[--mPullUnitIndex], 
                                NULL, 
                                inTimeStamp, 0, inNumberFrames, ioData) );
    }
    else {
        // we've pulled through every audio unit, now we need to feed 
        // the SGAudioCallback stashed buffer
        if (mPullBuffer && (mPullBuffer->mNumberBuffers == ioData->mNumberBuffers))
        {            
            for (int i = 0; i < ioData->mNumberBuffers; i++)
            {
                ioData->mBuffers[i].mData = mPullBuffer->mBuffers[i].mData;
                ioData->mBuffers[i].mDataByteSize = mPullBuffer->mBuffers[i].mDataByteSize;
            }
        }
    }
bail:    
    return err;
}

/*________________________________________________________________________________________
*/

@end











/*________________________________________________________________________________________
*/

static OSStatus
fxUnitInputProc(void *inRefCon, 
                AudioUnitRenderActionFlags *ioActionFlags, 
                const AudioTimeStamp *inTimeStamp, 
                UInt32 inBusNumber, 
                UInt32 inNumberFrames, 
                AudioBufferList *ioData)
{
    SGAudio * myself = (SGAudio*)inRefCon;
    return ([myself fxUnitRender:ioActionFlags 
                    timestamp:inTimeStamp 
                    bus:inBusNumber 
                    numFrames:inNumberFrames 
                    buffer:ioData]);
}  

/*________________________________________________________________________________________
*/

static OSStatus myPreMixSGAudioCallback(
    SGChannel		 	  				c,
    void *                  			inRefCon,
    SGAudioCallbackFlags *				ioFlags,
    const AudioTimeStamp *  			inTimeStamp,
    const UInt32 *          			inNumberPackets,
    const AudioBufferList * 			inData,
    const AudioStreamPacketDescription*	inPacketDescriptions)
{
#pragma unused (c)
    SGAudio * myself = (SGAudio*)inRefCon;
    return ([myself sgAudioCallbackRender:ioFlags 
                    timestamp:inTimeStamp 
                    numPackets:inNumberPackets 
                    buffer:inData
                    packetDescs:inPacketDescriptions]);
}

/*________________________________________________________________________________________
*/

static void 
sgAudioPropListenerCallback(ComponentInstance inComponent, 
                            ComponentPropertyClass inPropClass, 
                            ComponentPropertyID inPropID, 
                            void *inUserData)
{
#pragma unused (inComponent)
    SGAudio * myself = (SGAudio*)inUserData;
    
    [myself notifyOfChangeInPropClass:inPropClass id:inPropID];
}

/*________________________________________________________________________________________
*/


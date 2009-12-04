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

#import "DeviceChannelStrip.h"
#import "SGAudioSettings.h"
#import "SGAudio.h"
#import <AudioToolbox/AudioFormat.h>
#import "WhackedDebugMacros.h"

#ifndef fieldOffset
#define fieldOffset(type, field) ((size_t) &((type *) 0)->field)
#endif


static const AudioChannelLabel kDeviceChannelStripLabels[] = 
{
    kAudioChannelLabel_Unknown,

    kAudioChannelLabel_Left,
    kAudioChannelLabel_Right,
    kAudioChannelLabel_Center,
    kAudioChannelLabel_LFEScreen,
    kAudioChannelLabel_LeftSurround,
    kAudioChannelLabel_RightSurround,
    kAudioChannelLabel_LeftCenter,
    kAudioChannelLabel_RightCenter,
    kAudioChannelLabel_CenterSurround,
    kAudioChannelLabel_LeftSurroundDirect,
    kAudioChannelLabel_RightSurroundDirect,
    kAudioChannelLabel_TopCenterSurround,
    kAudioChannelLabel_VerticalHeightLeft,
    kAudioChannelLabel_VerticalHeightCenter,
    kAudioChannelLabel_VerticalHeightRight,

    kAudioChannelLabel_TopBackLeft,
    kAudioChannelLabel_TopBackCenter,
    kAudioChannelLabel_TopBackRight,

    kAudioChannelLabel_RearSurroundLeft,
    kAudioChannelLabel_RearSurroundRight,
    kAudioChannelLabel_LeftWide,
    kAudioChannelLabel_RightWide,
    kAudioChannelLabel_LFE2,
	
    kAudioChannelLabel_Mono,

    kAudioChannelLabel_CenterSurroundDirect,

    // numbered discrete channel
//    kAudioChannelLabel_Discrete_0               = (1L<<16) | 0,
};






@implementation DeviceChannelStrip

/*________________________________________________________________________________________
*/

- (id)initWithSGAudioSettings:(SGAudioSettings*)settings channelNumber:(UInt32)num;
{
	self = [super init];
	
	mParent = settings;
    mChannelNumber = num;
    mMutex = QTMLCreateMutex();
	
	[NSBundle loadNibNamed:@"DeviceChannelStrip" owner:self];
    
    [mEnableButton setTitle:[NSString stringWithFormat:@"Channel %0.2ld", mChannelNumber + 1]];
    [mMeteringView setNumChannels:1];
    [mMeteringView setHasClipIndicator:YES];

	return self;
}

/*________________________________________________________________________________________
*/

- (void)startMetering
{
    [self stopMetering];
		// update the level meters 20 times a second
    mUpdateMeterTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:.1] 
                            interval:1./20 target:self
                             selector:@selector(updateLevelMeterTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:mUpdateMeterTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:mUpdateMeterTimer forMode:NSEventTrackingRunLoopMode];
}


/*________________________________________________________________________________________
*/

- (void)stopMetering
{
    if (mUpdateMeterTimer)
    {
        [mUpdateMeterTimer invalidate];
        [mUpdateMeterTimer release];
        mUpdateMeterTimer = nil;
    }
	[mMeteringView setNeedsDisplay:YES];
}


/*________________________________________________________________________________________
*/

- (void)dealloc
{
    //NSLog(@"[DeviceChannelStrip dealloc] %p, channel %lu", self, mChannelNumber);
    [self stopMetering];
    [mStripView removeFromSuperviewWithoutNeedingDisplay];
    [self invalidateChannelMap];
    QTMLDestroyMutex(mMutex);
	[super dealloc];
}


/*________________________________________________________________________________________
*/



- (NSView*)deviceChannelStripView
{
	return mStripView;
}


/*________________________________________________________________________________________
*/



- (UInt32)channelNumber
{
	BOOL useHardwareGain = [mParent usingHardwareGainControls];

	return  ( (useHardwareGain) ? mChannelNumber : mMyIndex );	
}


/*________________________________________________________________________________________
*/


- (NSSlider*)gainSlider
{
	return mGainSlider;
}


/*________________________________________________________________________________________
*/

- (NSTextField*)gainText
{
	return mGainText;
}


/*________________________________________________________________________________________
*/

- (BOOL)isEnabled
{
    return ([mEnableButton state] == NSOnState);
}

/*________________________________________________________________________________________
*/

- (void)setEnabled:(BOOL)enabled
{
    BOOL previousEnabled = [mEnableButton state] == NSOnState;
    
    if (previousEnabled != enabled)
    {
        [mEnableButton setState:(enabled ? NSOnState : NSOffState)];
    }
}

/*________________________________________________________________________________________
*/

- (BOOL)isSoloed
{
    return ([mSoloButton state] == NSOnState);
}

/*________________________________________________________________________________________
*/

- (BOOL)isMuted
{
    return ([mMuteButton state] == NSOnState);
}

/*________________________________________________________________________________________
*/

- (IBAction)toggleChannelEnabled:(id)sender
{
#pragma unused(sender)
    // set the channel map.  Channel map is a tricky property, because it
    // changes the device's number of active channels, which affects the 
    // device's channel layout (which should always have the same number of 
    // channels as the channel map).  In order to keep Sequence Grabber from
    // hurting itself by having a mismatch between a user defined input layout and 
    // a user defined channel map with differing numbers of channels, we need
    // to stop the channel, then set BOTH properties, then start the channel up again.
    
    OSStatus err = noErr;
    UInt32 numTotalChans = [[mParent recDeviceChannelStrips] count];
    UInt32 numChansInMap = 0;
    SInt32 * map = (SInt32*)calloc(1, numTotalChans * sizeof(SInt32));
	UInt32 layoutSize = fieldOffset(AudioChannelLayout, mChannelDescriptions[numTotalChans]);
    AudioChannelLayout * layout = (AudioChannelLayout*)calloc(1, layoutSize);
    
    [mParent stopChannelPreview];
    
    // build up the map by querying each channel strip for enabled status
    for (UInt32 i = 0; i < numTotalChans; i++)
    {
        if ( [[[mParent recDeviceChannelStrips] objectAtIndex:i] isEnabled] )
        {
            map[numChansInMap] = (SInt32)i;
            layout->mChannelDescriptions[numChansInMap++].mChannelLabel = 
                [[[mParent recDeviceChannelStrips] objectAtIndex:i] channelLabel];
        }
    }
    
        // set the new channel map
    BAILSETERR( [mParent setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_ChannelMap 
                                size:numChansInMap * sizeof(SInt32) address:map] );
                                
        // set the new channel layout
    layout->mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions;
    layout->mNumberChannelDescriptions = numChansInMap;
    layoutSize = fieldOffset(AudioChannelLayout, mChannelDescriptions[numChansInMap]);
    
    BAILSETERR( [mParent setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_ChannelLayout 
                                size:layoutSize address:layout] );
	[mParent updateOutputFormat];
    [mParent startChannelPreview];
    
    [[mParent recDeviceChannelStrips] makeObjectsPerformSelector:@selector(updateAllUI)];
    [mParent updateOutputControls:self];
bail:
    free(map);
}

/*________________________________________________________________________________________
*/


- (IBAction)toggleChannelMuted:(id)sender
{
	[self setChannelGain:sender];
}

/*________________________________________________________________________________________
*/


- (IBAction)toggleChannelSoloed:(id)sender
{
	[self setChannelGain:sender];
}

/*________________________________________________________________________________________
*/

- (void)updateChannelLabelPopUp:(id)sender
{
#pragma unused(sender)
    // set up labels.  We need to know how many device channels there are to
    // formulate the number of numbered discrete tags to show
    
    if ([self isEnabled] == NO)
        return;  // nothing to do
    
    [mLabelPopUp removeAllItems];
    
    AudioStreamBasicDescription asbd;
    
    [[mParent sgchan] getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                        id:kQTSGAudioPropertyID_StreamFormat 
                        size:sizeof(asbd) 
                        address:&asbd sizeUsed:NULL];
                        
        // also need to get the record device layout, so we can find our current
        // selected label
    UInt32 layoutSize = 0;
    UInt32 flags = 0;
    AudioChannelLabel selectedTag = kAudioChannelLabel_Unknown;
    
    [[mParent sgchan] getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                            id:kQTSGAudioPropertyID_ChannelLayout 
                            type:NULL size:&layoutSize flags:&flags];
                            
    if (layoutSize && (flags & kComponentPropertyFlagCanGetNow))
    {
        AudioChannelLayout * pLayout = (AudioChannelLayout*)malloc(layoutSize);
        [[mParent sgchan] getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                        id:kQTSGAudioPropertyID_ChannelLayout 
                        size:layoutSize 
                        address:pLayout sizeUsed:&layoutSize];
        if (pLayout->mNumberChannelDescriptions == 0)
        {
            // try to expand it
            UInt32 prop, specifier;
            UInt32 expandedLayoutSize = 0;
            
            if (pLayout->mChannelLayoutTag == kAudioChannelLayoutTag_UseChannelBitmap)
            {
                prop = kAudioFormatProperty_ChannelLayoutForBitmap;
                specifier = pLayout->mChannelBitmap;
            }
            else {
                prop = kAudioFormatProperty_ChannelLayoutForTag;
                specifier = pLayout->mChannelLayoutTag;
            }
            if (noErr == AudioFormatGetPropertyInfo(prop, sizeof(UInt32), &specifier, &expandedLayoutSize))
            {
                AudioChannelLayout * pExpandedLayout = (AudioChannelLayout*)calloc(1, expandedLayoutSize);
                AudioFormatGetProperty(prop, sizeof(UInt32), &specifier, &expandedLayoutSize, pExpandedLayout);
                
                free(pLayout);
                pLayout = pExpandedLayout;
                layoutSize = expandedLayoutSize;
            }
        }
        
        
        // get the channel map and find where we are
        UInt32 mapSize;
        SInt32 * map = NULL;
        
        [[mParent sgchan] getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                            id:kQTSGAudioPropertyID_ChannelMap 
                            type:NULL size:&mapSize flags:NULL];
        
        if (mapSize)
        {
            map = (SInt32*)malloc(mapSize);
            [[mParent sgchan] getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                        id:kQTSGAudioPropertyID_ChannelMap
                        size:mapSize
                        address:map sizeUsed:&mapSize];
        
            for (int i = 0; i < mapSize/sizeof(SInt32); i++)
            {
                if (map[i] == mChannelNumber)
                {
                    selectedTag = pLayout->mChannelDescriptions[i].mChannelLabel;
                }
            }
        }
        
        if (map)
            free(map);
        free(pLayout);
    }
    
                        
    UInt32 numBuiltInLabels = sizeof(kDeviceChannelStripLabels)/sizeof(AudioChannelLabel);
    BOOL foundMatch = NO;
    
    
    // add the built ins followed by the numbered discretes
    for (int i = 0; i < numBuiltInLabels + asbd.mChannelsPerFrame; i++)
    {
        NSString * tempString = nil;
        UInt32 size = sizeof(tempString);
        AudioChannelDescription acd = {0};
        acd.mChannelLabel = (i < numBuiltInLabels) 
                                ? kDeviceChannelStripLabels[i]
                                : (kAudioChannelLabel_Discrete_0 | (i - numBuiltInLabels));
        
        AudioFormatGetProperty(kAudioFormatProperty_ChannelName, sizeof(acd), &acd, &size, &tempString);
        
        if (tempString)
        {
            [mLabelPopUp addItemWithTitle:tempString];
            [[mLabelPopUp lastItem] setTag:acd.mChannelLabel];
            if (NO == foundMatch)
            {
                if (acd.mChannelLabel == selectedTag)
                {
                    [mLabelPopUp selectItemWithTag:selectedTag];
                    foundMatch = YES;
                }
            }
            [tempString release];
        }
    }
    
    if (NO == foundMatch)
        [mLabelPopUp selectItemWithTag:kAudioChannelLabel_Unknown];
}

/*________________________________________________________________________________________
*/

- (IBAction)setChannelLabel:(id)sender
{
#pragma unused(sender)
    UInt32 numChannels = [[mParent recDeviceChannelStrips] count];
    UInt32 size = fieldOffset(AudioChannelLayout, mChannelDescriptions[numChannels]);
    AudioChannelLayout * pLayout = (AudioChannelLayout*)calloc(1, size);
    UInt32 numEnabledChannels = 0;
            
    pLayout->mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions;
    for (UInt32 i = 0; i < numChannels; i++)
    {
        if ( [[[mParent recDeviceChannelStrips] objectAtIndex:i] isEnabled] )
            pLayout->mChannelDescriptions[numEnabledChannels++].mChannelLabel = 
                [[[mParent recDeviceChannelStrips] objectAtIndex:i] channelLabel];
    }
    pLayout->mNumberChannelDescriptions = numEnabledChannels;
    size = fieldOffset(AudioChannelLayout, mChannelDescriptions[numEnabledChannels]);

    
    // set it!
    OSStatus err = noErr;
    
	[mParent stopChannelPreview];
    BAILSETERR([mParent setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                            id:kQTSGAudioPropertyID_ChannelLayout 
                            size:size 
                            address:pLayout]);
	[mParent updateOutputFormat];
	[mParent startChannelPreview];
	
	[mParent updateOutputControls:self];
bail:
    free(pLayout);
}

/*________________________________________________________________________________________
*/


- (AudioChannelLabel)channelLabel
{
	// the label selected in the ui
	return [mLabelPopUp selectedTag];
}

/*________________________________________________________________________________________
*/

- (BOOL)anotherChannelIsSoloed
{
	for (int i = 0; i < [[mParent recDeviceChannelStrips] count]; i++)
	{
		DeviceChannelStrip * cur = [[mParent recDeviceChannelStrips] objectAtIndex:i];

		if ((self != cur) && [cur isEnabled] && [cur isSoloed])
		{
			return YES;
		}
	}
	return NO;
}

/*________________________________________________________________________________________
*/


- (IBAction)setChannelGain:(id)sender
{
#pragma unused(sender)
	if ([self isEnabled] == NO)
		return;
		
	{
		BOOL useHardwareGain = [mParent usingHardwareGainControls];
		ComponentPropertyClass theClass = (useHardwareGain)
									? kQTPropertyClass_SGAudioRecordDevice
									: kQTPropertyClass_SGAudio;
									
			// be careful.  If we're using hardware gain, then the number of 
            // levels is equal to the number of channels on the device.
            // If !useHardwareGain, it's equal to the number of channels in the
            // the channel map (the number of channels being collected from the
            // device by the sgaudiochannel
		UInt32 size, flags;
											
		if (noErr == [[mParent sgchan] getPropertyInfoWithClass:theClass
                                        id:kQTSGAudioPropertyID_PerChannelGain 
                                        type:NULL 
                                        size:&size flags:&flags]
                            && size && (flags & kComponentPropertyFlagCanSetNow))
		{
			Float32 * chanGains = (Float32*)malloc(size * sizeof(Float32));
			UInt32 numChannelGains = size/sizeof(Float32);
			BOOL someoneIsSoloed = NO;
			
			// set all chanGains to -1, indicating that we wish to ignore them.
			// we will put non -1 values into the indeces we wish to set.
			for (int i = 0; i < size/sizeof(Float32); i++)
			{
				chanGains[i] = -1.;
			}
			
			
			// loop through the channel strip instances once, see if any of them
			// are solo'ed.
			for (int i = 0; i < [[mParent recDeviceChannelStrips] count]; i++)
			{
				DeviceChannelStrip * curstrip = [[mParent recDeviceChannelStrips] objectAtIndex:i];
				
				if ( [curstrip isEnabled] && [curstrip isSoloed] )
				{
					someoneIsSoloed = YES;
					break;
				}
			}
			
			
			// loop through the channel strip array again, this time getting the appropriate
			// volume levels to set on the SGAudioChannel.
			for (int i = 0; i < [[mParent recDeviceChannelStrips] count]; i++)
			{
				DeviceChannelStrip * curstrip = [[mParent recDeviceChannelStrips] objectAtIndex:i];
				if ( [curstrip isEnabled] )
				{
					BOOL iAmMuted = [curstrip isMuted];
					BOOL iAmSoloed = [curstrip isSoloed];
					UInt32 myIndex = [curstrip channelNumber];
					NSSlider * mySlider = [curstrip gainSlider];
					NSTextField * myText = [curstrip gainText];
					
					if (iAmMuted || (!iAmSoloed && someoneIsSoloed))
					{
						// mute this bad boy
						if (myIndex < numChannelGains)
						{
							chanGains[myIndex] = 0.;
						}
					}
					else {
						// use the gain specified by the slider
						if (myIndex < numChannelGains)
						{
							chanGains[myIndex] = [mySlider floatValue];
						}
					}
					
					if ([mySlider isEnabled])
					{
						[myText setStringValue:[NSString stringWithFormat:@"%.2f", [mySlider floatValue]]];
					}
				}
			}
			
			
			
			[mParent setSGAudioPropertyWithClass:theClass 
						id:kQTSGAudioPropertyID_PerChannelGain 
						size:size
						address:chanGains];
			
			if (chanGains)
				free(chanGains);
		}
	}
}

/*________________________________________________________________________________________
*/


- (IBAction)updateGain:(id)sender
{
#pragma unused(sender)
    BOOL useHardwareGain = [mParent usingHardwareGainControls];
    ComponentPropertyClass theClass = (useHardwareGain)
                                ? kQTPropertyClass_SGAudioRecordDevice
                                : kQTPropertyClass_SGAudio;
    UInt32 size = 0, flags = 0;
    Float32 * array = NULL;
    
    if (noErr == [[mParent sgchan] getPropertyInfoWithClass:theClass
                                        id:kQTSGAudioPropertyID_PerChannelGain 
                                        type:NULL 
                                        size:&size flags:&flags]
                            && size && (flags & kComponentPropertyFlagCanGetNow))
    {
            // be careful.  If we're using hardware gain, then the number of 
            // levels is equal to the number of channels on the device.
            // If !useHardwareGain, it's equal to the number of channels in the
            // the channel map (the number of channels being collected from the
            // device by the sgaudiochannel
        UInt32 myIndex = (useHardwareGain) ? mChannelNumber : mMyIndex;
		
		array = (Float32*)malloc(size);

        
        if ([mEnableButton state] == NSOnState)
        {  
			if (![self isMuted] && ![self anotherChannelIsSoloed])
			{
				[[mParent sgchan] getPropertyWithClass:theClass
											id:kQTSGAudioPropertyID_PerChannelGain 
											size:size 
											address:array sizeUsed:&size];
				if (myIndex < size/sizeof(Float32))
				{
					[mGainSlider setFloatValue:array[myIndex]];
					[mGainText setStringValue:[NSString stringWithFormat:@"%.2f", [mGainSlider floatValue]]];
				}
			}                         

        }
        else {
            // we are disabled
            [mGainSlider setEnabled:NO];
            [mGainText setStringValue:@"N/A"];
        }
    }
    else {
        // device doesn't support this operation
        [mGainSlider setEnabled:NO];
        [mGainText setStringValue:@"N/A"];
    }

    
    if (array)
        free(array);
}

/*________________________________________________________________________________________
*/


- (void)updateLevelMeterTimer:(NSTimer*)t
{
#pragma unused(t)
    [self updateChannelLevel];
}

/*________________________________________________________________________________________
*/

- (void)invalidateChannelMap
{
    QTMLGrabMutex(mMutex);
    
    if (mLevelsArray)
        free(mLevelsArray);
    mLevelsArray = NULL;
    
    QTMLReturnMutex(mMutex);
}

/*________________________________________________________________________________________
*/

- (void)updateChannelLevel
{
    Float32 amps[2] = { -FLT_MAX, -FLT_MAX };
    
    QTMLGrabMutex(mMutex);
    if ([mEnableButton state] == NSOnState)
    {
        SGAudio * myAudi = [mParent sgchan];
        
        if (mLevelsArray == NULL)
        {    
            UInt32 size;
            
            [myAudi getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                                id:kQTSGAudioPropertyID_ChannelMap 
                                                type:NULL size:&size flags:NULL];
            if (size > 0)
            {
                SInt32 * map = (SInt32 *)malloc(size);
                
                [myAudi getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                                id:kQTSGAudioPropertyID_ChannelMap 
                                                size:size
                                                address:map sizeUsed:&size];
                
                for (int i = 0; i < size/sizeof(SInt32); i++)
                {
                    if (mChannelNumber == map[i])
                    {
                        mMyIndex = i;
                        mLevelsArraySize = size; // SInt32 and Float32 are the same size
                        mLevelsArray = (Float32*)malloc(mLevelsArraySize); 
                        break;
                    }
                }
                free(map);
            }
        }
        
        
        if (mLevelsArray) // paranoia
        {
            // get the avg power level
            if (noErr == [myAudi getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                    id:kQTSGAudioPropertyID_AveragePowerLevels 
                                    size:mLevelsArraySize 
                                    address:mLevelsArray sizeUsed:NULL])
            {
                amps[0] = mLevelsArray[mMyIndex];
            }
            
            // get the peak-hold level
            if (noErr == [myAudi getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                    id:kQTSGAudioPropertyID_PeakHoldLevels 
                                    size:mLevelsArraySize 
                                    address:mLevelsArray sizeUsed:NULL])
            {
                amps[1] = mLevelsArray[mMyIndex];
            }
        }
    }
    
    QTMLReturnMutex(mMutex);
    [mMeteringView updateMeters:amps];
}

/*________________________________________________________________________________________
*/



- (void)updateAllUI
{
    BOOL enabledVal = ([mEnableButton state] == NSOnState);

	[self stopMetering];
	[self invalidateChannelMap];
    [self updateChannelLevel];
    [mMeteringView setDirty:YES];
	[self startMetering];
    [mMuteButton setEnabled:enabledVal];
    [mSoloButton setEnabled:enabledVal];
    [self updateChannelLabelPopUp:self];
    [mLabelPopUp setEnabled:enabledVal];
    [mGainSlider setEnabled:enabledVal];
    [self updateGain:mGainSlider];
}

/*________________________________________________________________________________________
*/

@end

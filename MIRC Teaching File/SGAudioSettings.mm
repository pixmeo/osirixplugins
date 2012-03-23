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

#import <QuickTime/QuickTime.h>
#import <AudioToolbox/AudioFormat.h>
#import "SGAudioSettings.h"
#import "SGAudio.h"
#import "WhackedDebugMacros.h"
#import "DeviceChannelStrip.h"
#import <unistd.h> // for getpid()
#import <CoreAudioKit/CoreAudioKit.h>
#import "NSOpaqueGrayRulerView.h"


@implementation SGAudioSettings

/*________________________________________________________________________________________
*/


/*
	The SGAudio * object registers itself as a listener for all Listenable SGAudioChannel
	component properties.  It captures the ones it understands and forwards them as
	NSNotification's to the defaultCenter.
	
	Our SGAudioSettings dialog registers itself as an interested observer of all notifications
	sent from its SGAudio * channel object, and here, in sgAudioPropListener, it interprets
	and acts on some important notifications (like device hotplugging).
*/

- (void)sgAudioPropListener:(NSNotification*)n
{
    NSString * name = [n name];
    NSArray * modes = [[NSArray alloc] initWithObjects:
                            NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil];

        // we want to ensure that ui is updated on the main thread only.
        // NSNotifications fire on the thread in which the notification was posted,
        // which may or may not be the main thread when the SGAudioChannel is concerned.
        // So we explicitly performSelectorOnMainThread: rather than calling the update
        // methods directly.
        
    if ([name isEqualToString:SGAudioDeviceListChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateRecordDevicesPopup:) withObject:self waitUntilDone:NO modes:modes];
        [self performSelectorOnMainThread:@selector(updatePreviewDevicesPopup:) withObject:self waitUntilDone:NO modes:modes];
    }
    
       
    else if ([name isEqualToString:SGAudioRecordDeviceDiedNotification])
    {
        [[mRecDevicesPopUp selectedItem] setEnabled:NO];
        NSRunAlertPanel(@"WhackedTV",
                        [NSString stringWithFormat:@"\"%@\" disappeared.  Please select a new record device.",
                            [mRecDevicesPopUp titleOfSelectedItem]],
                        nil, nil, nil);
    }
    
    
    else if ([name isEqualToString:SGAudioRecordDeviceHoggedChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateRecordDevicesPopup:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioRecordDeviceStreamFormatChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateRecordDeviceFormatPopUp:) withObject:self waitUntilDone:NO modes:modes];
        [self performSelectorOnMainThread:@selector(updateRecordDeviceChannelsBox:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioRecordDeviceStreamFormatListChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateRecordDeviceFormatPopUp:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioRecordDeviceInputSelectionNotification] ||
                [name isEqualToString:SGAudioRecordDeviceInputListChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateRecordDeviceInputPopUp:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioPreviewDeviceDiedNotification])
    {
        [[mPrevDevicesPopUp selectedItem] setEnabled:NO];
        NSRunAlertPanel(@"WhackedTV",
                        [NSString stringWithFormat:@"\"%@\" disappeared.  Please select a new preview device.",
                            [mPrevDevicesPopUp titleOfSelectedItem]],
                        nil, nil, nil);
    }
    
    
    else if ([name isEqualToString:SGAudioPreviewDeviceHoggedChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updatePreviewDevicesPopup:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioPreviewDeviceStreamFormatChangedNotification] ||
                [name isEqualToString:SGAudioPreviewDeviceStreamFormatListChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updatePreviewDeviceFormatPopUp:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioPreviewDeviceOutputSelectionChangedNotification] ||
                [name isEqualToString:SGAudioPreviewDeviceOutputListChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updatePreviewDeviceOutputPopUp:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    
    else if ([name isEqualToString:SGAudioOutputStreamFormatChangedNotification])
    {
        [self performSelectorOnMainThread:@selector(updateOutputFormatText:) withObject:self waitUntilDone:NO modes:modes];
    }
    
    [modes release];
}

/*________________________________________________________________________________________
*/

- (void)registerForNotifications:(BOOL)doRegister
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    if (doRegister)
    {
            // register for all notifications from our SGAudio instance
        [nc addObserver:self selector:@selector(sgAudioPropListener:) name:nil object:mChan];
    }
    else {
        [nc removeObserver:self];
    }
}

/*________________________________________________________________________________________
*/

- (id)initWithSGChan:(SGAudio *)wrapper
{
    self = [super init];
    
    if (!wrapper)
    {
        [self autorelease];
        self = nil;
    }
    else {
        mChan = wrapper;

        [NSBundle loadNibNamed:@"SGAudioSettings" owner:self];
        [mRecDevicesPopUp setAutoenablesItems:NO];
        [mPrevDevicesPopUp setAutoenablesItems:NO];
		
        [mRecDeviceChannelsScrollView setAutohidesScrollers:YES];
        [mRecDeviceChannelsScrollView setHasVerticalScroller:YES];
        [mRecDeviceChannelsScrollView setHasHorizontalScroller:NO];
        [mRecDeviceChannelsScrollView setScrollsDynamically:YES];
        [[mRecDeviceChannelsScrollView verticalScroller] setControlSize:NSSmallControlSize];
        
        NSRect rect = [mRecDeviceChannelsScrollView bounds];
        [mRecDeviceChannelsContainerView setFrameSize:rect.size];
        [mRecDeviceChannelsScrollView setDocumentView:mRecDeviceChannelsContainerView];
        
		mRecDeviceChannelStrips = [[NSMutableArray alloc] init];

        [mFXScrollView setAutohidesScrollers:YES];
        [mFXScrollView setHasVerticalScroller:YES];
        [mFXScrollView setHasHorizontalScroller:NO];
        [mFXScrollView setScrollsDynamically:YES];
        [[mFXScrollView verticalScroller] setControlSize:NSSmallControlSize];
        
        
            // We use CoreAudioKit to display AU FX views.  CoreAudioKit
            // requires Tiger.
        long sysVersion = 0;
        if (noErr != Gestalt(gestaltSystemVersion, &sysVersion))
            sysVersion = 0;
        
        if ( sysVersion < 0x00001040 )
        {
            [mFXPanelButton setEnabled:NO];
        }
        else {
            rect = [mFXScrollView bounds];
            [mFXContainerView setFrameSize:rect.size];
            [mFXContainerView setAutoresizingMask:
                NSViewWidthSizable | NSViewHeightSizable];
            [mFXScrollView setDocumentView:mFXContainerView];
        }
    }
    
    return self;
}

/*________________________________________________________________________________________
*/

- (void)dealloc
{
    //NSLog(@"[SGAudioSettings dealloc] %p", self);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopChannelPreview];
    [mRecDeviceChannelStrips makeObjectsPerformSelector:@selector(stopMetering)];
	[mRecDeviceChannelStrips release];
    
    DisposeUserData(mSavedSettings);
    
    [super dealloc];
}

/*________________________________________________________________________________________
*/

- (SGAudio *)sgchan
{
	return mChan;
}

/*________________________________________________________________________________________
*/

- (NSArray*)recDeviceChannelStrips
{
    return mRecDeviceChannelStrips;
}

/*________________________________________________________________________________________
*/

- (UInt32)enabledChannelsCount
{
	UInt32 count = 0;
	
	for (int i = 0; i < [mRecDeviceChannelStrips count]; i++)
	{
		if ( [[mRecDeviceChannelStrips objectAtIndex:i] isEnabled] )
			count++;
	}
	
	return count;
}

/*________________________________________________________________________________________
*/

// for the duration of the SGAudioSettings dialog, we want to preview.  But several
// properties can only be set when the channel is not in recording or previewing mode,
// so we'll call this method to stop/start the preview if we receive a -2200 error
// on the first try
- (OSStatus)setSGAudioPropertyWithClass:(ComponentPropertyClass)theClass
                                id:(ComponentPropertyID)theID
                                size:(ByteCount)sz
                                address:(ConstComponentValuePtr)addr
{
    OSStatus err = noErr;
    err = [mChan setPropertyWithClass: theClass 
								 id: theID 
							   size: sz 
						    address: addr];
                            
    if (err == kQTPropertyAskLaterErr)
    {
        [self stopChannelPreview];
        
        err = [mChan setPropertyWithClass: theClass 
								 id: theID 
							   size: sz 
						    address: addr];
        
        [self startChannelPreview];
    }
    
    return err;
}

/*________________________________________________________________________________________
*/

- (void)updateRecordDeviceControls:(id)sender
{
    [self updateRecordDevicesPopUp:sender];
    [self updateRecordDeviceInputPopUp:sender];
    [self updateRecordDeviceFormatPopUp:sender];
    [self updateUseHardwareGainControls:sender];
    [self updateRecordDeviceMasterGainSlider:self];
    [self updateRecordDeviceChannelsBox:self];
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewDeviceControls:(id)sender
{
#pragma unused(sender)
    [self updatePlayWhileRecordingButton:self];
    [self togglePlayWhileRecording:self];
    [self updatePreviewDevicesPopUp:self];
    [self updatePreviewDeviceOutputPopUp:self];
    [self updatePreviewDeviceFormatPopUp:self];
    [self updatePreviewDeviceMasterGainSlider:self];
    [self updateHardwarePlaythruButton:self];
    [self updatePreviewFlagsPopUp:self];
}

/*________________________________________________________________________________________
*/

- (void)updateOutputControls:(id)sender
{
#pragma unused(sender)
    [self updateOutputFormatText:self];
}

/*________________________________________________________________________________________
*/

- (void)updateAllControls:(id)sender
{
#pragma unused(sender)
    [self updateRecordDeviceControls:self];
    [self updatePreviewDeviceControls:self];
    [self updateOutputControls:self];
}

/*________________________________________________________________________________________
*/

- (IBAction)showPanel:(id)sender
{
#pragma unused(sender)
    BOOL recordMetersWereEnabled, outputMetersWereEnabled, doEnable = YES;
    
	// turn off the grabber and remember its state
	mGrabberWasRecording = [[mChan grabber] isRecording];
	mGrabberWasPreviewing = [[mChan grabber] isPreviewing];
	mGrabberWasPaused = [[mChan grabber] isPaused];
	
	[[mChan grabber] stop];
	
	// store the current SGAudio state, so we can go back to it in case the user cancels
		[mChan getPropertyWithClass: kQTPropertyClass_SGAudio 
								 id: kQTSGAudioPropertyID_Settings 
							   size: sizeof(UserData) 
							address: &mSavedSettings 
						   sizeUsed: NULL];
						   
    
        // enable level metering, and remember the previous state of
        // this property, so it can be restored after our dialog goes away
    [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                            id:kQTSGAudioPropertyID_LevelMetersEnabled 
                            size:sizeof(recordMetersWereEnabled) 
                            address:&recordMetersWereEnabled 
                            sizeUsed:NULL];
                            
    if (recordMetersWereEnabled != doEnable)
    {
        [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_LevelMetersEnabled 
                                size:sizeof(doEnable)
                                address:&doEnable];
    }
    
        // enable output metering as well
    [mChan getPropertyWithClass:kQTPropertyClass_SGAudio
                            id:kQTSGAudioPropertyID_LevelMetersEnabled 
                            size:sizeof(outputMetersWereEnabled) 
                            address:&outputMetersWereEnabled 
                            sizeUsed:NULL];
                            
    if (outputMetersWereEnabled != doEnable)
    {
        [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudio
                                id:kQTSGAudioPropertyID_LevelMetersEnabled 
                                size:sizeof(doEnable)
                                address:&doEnable];
    }
    
    
	[mSettingsPanel setTitle:[NSString stringWithFormat:
		@"Audio Settings (Channel %d)", [[[mChan grabber] channels] indexOfObject:mChan] + 1]];
        
    [self updateAllControls:self];
		
	[self startChannelPreview];
    [self registerForNotifications:YES];
    
    // The following call blocks until the dialog is dismissed
	[[NSApplication sharedApplication] runModalForWindow:mSettingsPanel];
	
	[mSettingsPanel orderOut:self];
    [self registerForNotifications:NO];
    
    if (recordMetersWereEnabled != doEnable)
    {
        [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_LevelMetersEnabled 
                                size:sizeof(recordMetersWereEnabled)
                                address:&recordMetersWereEnabled];
    }
    
    
    if (outputMetersWereEnabled != doEnable)
    {
        [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudio
                                id:kQTSGAudioPropertyID_LevelMetersEnabled 
                                size:sizeof(outputMetersWereEnabled)
                                address:&outputMetersWereEnabled];
    }
    
    if (mGrabberWasRecording)
        [[mChan grabber] record];
    else if (mGrabberWasPreviewing)
        [[mChan grabber] preview];
        
    if (mGrabberWasPaused)
        [[mChan grabber] pause];
}

/*________________________________________________________________________________________
*/

- (IBAction)closePanel:(id)sender
{
	[self stopChannelPreview];
	
    if ([[sender title] isEqualToString:@"Cancel"]  && mSavedSettings)
    {
			// undo any changes
		OSStatus err = [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudio 
								 id: kQTSGAudioPropertyID_Settings 
							   size: sizeof(UserData) 
						    address: &mSavedSettings];
        if (err)
            NSRunAlertPanel(@"WhackedTV",
                [NSString stringWithFormat:@"Trouble restoring settings after cancel (%ld)",
                err], nil, nil, nil);
    }
    
	DisposeUserData(mSavedSettings);
	mSavedSettings = NULL;
		
    [[NSApplication sharedApplication] stopModal];
}

/*________________________________________________________________________________________
*/

- (IBAction)selectRecordDevice:(id)sender
{
    NSArray *       deviceList = [mChan deviceList];
    NSDictionary *  devDict = nil;
    OSStatus        err = noErr;
    
    devDict = [deviceList objectAtIndex:[(NSMenuItem*)[sender selectedItem] tag]];
    
    if (devDict)
    {
        NSString * uid = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceUIDKey];
		NSString *		curDevUID = nil;
		
		BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
											 id: kQTSGAudioPropertyID_DeviceUID 
										   size: sizeof(curDevUID) 
										address: &curDevUID 
									   sizeUsed: NULL] );
		
		if ( NO == [curDevUID isEqualToString: uid] )
		{
			[self stopChannelPreview];
			
			BAILSETERR( [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice
												 id: kQTSGAudioPropertyID_DeviceUID
											   size: sizeof(uid)
											address: &uid] );
											
			// make sure we start off totally fresh, namely
			// 1. nuke record device layout
			// 2. nuke output layout
			// 3. nuke output magic cookie
			BAILSETERR( [mChan setPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
									id: kQTSGAudioPropertyID_ChannelLayout 
								  size: 0  address:NULL] );
			BAILSETERR( [mChan setPropertyWithClass: kQTPropertyClass_SGAudio 
									id: kQTSGAudioPropertyID_ChannelLayout
								  size: 0  address:NULL] );
			BAILSETERR( [mChan setPropertyWithClass: kQTPropertyClass_SGAudio 
									id: kQTSGAudioPropertyID_MagicCookie
								  size: 0  address:NULL] );
			
			
			[self startChannelPreview];
			[self updateRecordDeviceControls:self];
		}
		
		[curDevUID release];
    }
bail:
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectRecordInput:(id)sender
{
    OSStatus err = noErr;
    NSArray * list = nil;
    
    BAILSETERR([mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice
                             id: kQTSGAudioPropertyID_InputListWithAttributes
                           size: sizeof(list)
                        address: &list 
                       sizeUsed: NULL]);
                       
    if (list)
    {
        NSDictionary * selDict = [list objectAtIndex:[sender indexOfSelectedItem]];
        UInt32 newSel = 
            [(NSNumber*)[selDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceInputID] 
                unsignedIntValue];
        
        BAILSETERR( 
            [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice
                                         id: kQTSGAudioPropertyID_InputSelection
                                       size: sizeof(newSel)
                                    address: &newSel] );
    }
    
bail:
    [list release];
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectRecordDeviceFormat:(id)sender
{
    OSStatus err = noErr;
    AudioStreamBasicDescription * formats = NULL;
    UInt32 size = 0;
    
    BAILSETERR( [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                            id:kQTSGAudioPropertyID_StreamFormatList 
                                            type:NULL size:&size flags:NULL] );
    formats = (AudioStreamBasicDescription *)malloc(size);
    
    BAILSETERR( [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                        id:kQTSGAudioPropertyID_StreamFormatList 
                                        size:size 
                                        address:formats sizeUsed:NULL] );
    
    BAILSETERR( [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                        id:kQTSGAudioPropertyID_StreamFormat 
                                        size:sizeof(AudioStreamBasicDescription) 
                                        address:&formats[[sender indexOfSelectedItem]]] );
bail:
    if (formats)
        free(formats);
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectPreviewDevice:(id)sender
{
    NSArray *       deviceList = [mChan deviceList];
    NSDictionary *  devDict = nil;
    OSStatus        err = noErr;
    
    devDict = [deviceList objectAtIndex:[(NSMenuItem*)[sender selectedItem] tag]];
    
    if (devDict)
    {
        Float32 curMasterGain = [mPrevMasterGainSlider floatValue];
        NSString * uid = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceUIDKey];
        
        [self stopChannelPreview];
        BAILSETERR( [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice
                                             id: kQTSGAudioPropertyID_DeviceUID
                                           size: sizeof(uid)
                                        address: &uid] );
        
        // apply the volume level from the last preview device to the new one
        BAILSETERR( [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
                                id:kQTSGAudioPropertyID_MasterGain 
                                size:sizeof(curMasterGain) 
                                address:&curMasterGain] );
        [self startChannelPreview];
        [self updatePreviewDeviceControls:self];
    }
bail:
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectPreviewOutput:(id)sender
{
    OSStatus err = noErr;
    NSArray * list = nil;
    
    BAILSETERR([mChan getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice
                             id: kQTSGAudioPropertyID_OutputListWithAttributes
                           size: sizeof(list)
                        address: &list 
                       sizeUsed: NULL]);
                       
    if (list)
    {
        NSDictionary * selDict = [list objectAtIndex:[sender indexOfSelectedItem]];
        UInt32 newSel = 
            [(NSNumber*)[selDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceOutputID] 
            unsignedIntValue];
        
        BAILSETERR( 
            [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice
                                         id: kQTSGAudioPropertyID_OutputSelection
                                       size: sizeof(newSel)
                                    address: &newSel] );
    }
    
bail:
    [list release];
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectPreviewDeviceFormat:(id)sender
{
    OSStatus err = noErr;
    AudioStreamBasicDescription * formats = NULL;
    UInt32 size = 0;
    
    BAILSETERR( [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioPreviewDevice
                                            id:kQTSGAudioPropertyID_StreamFormatList 
                                            type:NULL size:&size flags:NULL] );
    formats = (AudioStreamBasicDescription *)malloc(size);
    
    BAILSETERR( [mChan getPropertyWithClass:kQTPropertyClass_SGAudioPreviewDevice 
                                        id:kQTSGAudioPropertyID_StreamFormatList 
                                        size:size 
                                        address:formats sizeUsed:NULL] );
    
    BAILSETERR( [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioPreviewDevice 
                                        id:kQTSGAudioPropertyID_StreamFormat 
                                        size:sizeof(AudioStreamBasicDescription) 
                                        address:&formats[[sender indexOfSelectedItem]]] );
bail:
    if (formats)
        free(formats);
    return;
}

/*________________________________________________________________________________________
*/

- (IBAction)toggleHardwarePlaythru:(id)sender
{
#pragma unused(sender)
	// this button won't be enabled unless the hardware supports it
    OSStatus        err = noErr;
	NSString *		recuid = nil; 
	NSString *		prevuid = nil;
    Boolean			isEnabled = [mHardPlaythruEnabledButton state] == NSOnState;
	
	if (isEnabled)
	{
		// if we're to turn this property on, we must ensure that the prev and rec
		// devices are one and the same (see QuickTimeComponent.h, search for _HardwarePlaythruEnabled)
		BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
											 id: kQTSGAudioPropertyID_DeviceUID 
										   size: sizeof(recuid) 
										address: &recuid
									   sizeUsed: NULL] );
		BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
											 id: kQTSGAudioPropertyID_DeviceUID 
										   size: sizeof(prevuid) 
										address: &prevuid
									   sizeUsed: NULL] );

		
		if ([recuid isEqualToString:prevuid] == NO)
		{
			BAILSETERR( [self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioPreviewDevice 
									id:kQTSGAudioPropertyID_DeviceUID 
									size:sizeof(recuid) 
									address:&recuid]);
		}
	}

	BAILSETERR([self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
					id:kQTSGAudioPropertyID_HardwarePlaythruEnabled 
					size:sizeof(isEnabled) 
					address:&isEnabled]);
					
	[self updateAllControls:self];

bail:
	[recuid release];
	[prevuid release];
}

/*________________________________________________________________________________________
*/

- (IBAction)togglePlayWhileRecording:(id)sender
{
#pragma unused(sender)
	BOOL playWhileRecording = [mPreviewWhileRecordingButton state] == NSOnState;
	
	long usage = [mChan usage];
	if (playWhileRecording)
		usage |= seqGrabPlayDuringRecord;
	else
		usage &= ~seqGrabPlayDuringRecord;
		
		// don't need to stop/start the channel, because it's only previewing 
		// right now, not recording, so this preference doesn't affect it either way
	[mChan setUsage:usage];
}

/*________________________________________________________________________________________
*/

- (BOOL)usingHardwareGainControls
{
	return ([mUseHardwareGainButton state] == NSOnState);
}

/*________________________________________________________________________________________
*/

- (void)updateUseHardwareGainControls:(id)sender
{
#pragma unused(sender)
    UInt32 flags = 0;
    BOOL useDeviceGain = [self usingHardwareGainControls];
    ComponentPropertyClass propClass = 
        (useDeviceGain) ? kQTPropertyClass_SGAudioRecordDevice : kQTPropertyClass_SGAudio;
    
        // Adjust max gain
	if (noErr == [mChan getPropertyInfoWithClass: propClass 
											  id: kQTSGAudioPropertyID_MasterGain 
											type: NULL size: NULL flags: &flags]
				&& (flags & kComponentPropertyFlagCanGetNow))
    {
        [mRecMasterGainSlider setEnabled:YES];
        [self setRecordMasterGain:mRecMasterGainSlider];
    }
    else {
        [mRecMasterGainSlider setEnabled:NO];
        [mRecMasterGainText setStringValue:@"N/A"];
    }
}

/*________________________________________________________________________________________
*/

- (IBAction)toggleUseHardwareGainControls:(id)sender
{
#pragma unused(sender)
    [self updateUseHardwareGainControls:self];
	[self updateRecordDeviceControls:self];

}


/*________________________________________________________________________________________
*/

- (void)makeASBDMovieSafe:(AudioStreamBasicDescription *)ioDesc
{
	// We shouldn't/can't write the following formats to a movie:
	// 1. Non-interleaved
	// 2. Floats that aren't 32-bit or 64-bit
	// 3. Non-packed Integers that aren't 8, 16, 24, or 32 (12 and 20 are common hardware formats)
	// 3. Any extraneous bit fields in mFormatFlags that aren't valid
	
	if ( !ioDesc || (ioDesc->mFormatID != kAudioFormatLinearPCM) )
		return;
	
	ioDesc->mFramesPerPacket = 1;
		
	// 1. Correct for Non-interleavedness
	if (ioDesc->mFormatFlags & kAudioFormatFlagIsNonInterleaved)
	{
		ioDesc->mFormatFlags &= ~kAudioFormatFlagIsNonInterleaved;
		ioDesc->mBytesPerPacket = ioDesc->mBytesPerFrame = 
			ioDesc->mBytesPerPacket * ioDesc->mChannelsPerFrame;
	}
	
	
	// 2. Correct floats that are wrong
	if (ioDesc->mFormatFlags & kAudioFormatFlagIsFloat)
	{
		if (ioDesc->mBitsPerChannel < 32)
		{
			ioDesc->mBitsPerChannel = 32;
			ioDesc->mFormatFlags |= kAudioFormatFlagIsPacked;
			ioDesc->mBytesPerPacket = ioDesc->mBytesPerFrame = 
				sizeof(Float32) * ioDesc->mChannelsPerFrame;
		}
		else if (ioDesc->mBitsPerChannel > 32)
		{
			ioDesc->mBitsPerChannel = 64;
			ioDesc->mFormatFlags |= kAudioFormatFlagIsPacked;
			ioDesc->mBytesPerPacket = ioDesc->mBytesPerFrame = 
				sizeof(Float64) * ioDesc->mChannelsPerFrame;
		}
			
		// take out extraneous flags
		ioDesc->mFormatFlags &= ~kAudioFormatFlagIsSignedInteger;
	}
	else {
		if (ioDesc->mBitsPerChannel != 8)
			ioDesc->mFormatFlags |= kAudioFormatFlagIsSignedInteger;
	}
	
	
		
		
	// 3. Correct for Non-packedness
	if (!(ioDesc->mFormatFlags & kAudioFormatFlagIsPacked))
	{
		// if it's not packed, it might not be a multiple-of-8 bits per channel
		ioDesc->mBitsPerChannel	= (ioDesc->mBitsPerChannel + 7) & ~7;
		
		// now take bytesPerFrame and bytesPerPacket down to the right numbers
		// for packed
		ioDesc->mBytesPerPacket = ioDesc->mBytesPerFrame = 
			((ioDesc->mBitsPerChannel/8) * ioDesc->mChannelsPerFrame);
		
		ioDesc->mFormatFlags |= kAudioFormatFlagIsPacked;
	}
	
	
	
	// 4. Take out any additional flags that shouldn't be set		
	ioDesc->mFormatFlags &= (	kAudioFormatFlagIsFloat | 
								kAudioFormatFlagIsBigEndian |
								kAudioFormatFlagIsSignedInteger |
								kAudioFormatFlagIsPacked |
								kAudioFormatFlagsAreAllClear);
}

/*________________________________________________________________________________________
*/

- (OSStatus)openAndConfigureStdAudio:(ComponentInstance*)outCI
{
    // use StdAudio dialog to let user set an output format
    OSStatus err = noErr;
    AudioStreamBasicDescription format;
    ComponentInstance ci;
    SoundDescriptionHandle sdh = NULL;
    UInt32  size = 0;
    AudioChannelLayout *pLayout = NULL;
    SCExtendedProcs xProcs;
	
		// we'll (arbitrarily) limit the format choices shown in the dialog to the below list.
		// (this is purely for pedagogical purposes)
    UInt32 limitedFormats[] = { 'lpcm', 'aac ', 'alac', 'samr', 'ima4' };
	
		// and we'll limit the audio channel layout tags shown in the dialog
		// to these.  If we don't limit the channel layouts to this restricted
		// list, StdAudio will show a laundry list of every channel layout tag
		// defined in CoreAudioTypes.h.
    AudioChannelLayoutTag limitedTagList[] =
    {
			// Prepending kAudioChannelLayoutTag_DiscreteInOrder to the
			// accepted list of channel layout tags lets StdAudio know
			// how many discrete channels are present in our input signal.
            // You need to OR in the real discrete number of channels (see below).
        kAudioChannelLayoutTag_DiscreteInOrder,
            // Prepending kAudioChannelLayoutTag_UseChannelDescriptions to the
			// accepted list of channel layout tags allows passthru of a custom 
			// input layout that would not otherwise be presented in the dialog (i.e. 3.0 surround)
        kAudioChannelLayoutTag_UseChannelDescriptions, 
        
        kAudioChannelLayoutTag_Mono,
        kAudioChannelLayoutTag_Stereo,
        kAudioChannelLayoutTag_Quadraphonic,
        kAudioChannelLayoutTag_MPEG_5_0_A,
        kAudioChannelLayoutTag_MPEG_5_0_B,
        kAudioChannelLayoutTag_MPEG_5_0_C,
        kAudioChannelLayoutTag_MPEG_5_0_D,
        kAudioChannelLayoutTag_MPEG_5_1_A,
        kAudioChannelLayoutTag_MPEG_5_1_B,
        kAudioChannelLayoutTag_MPEG_5_1_C,
        kAudioChannelLayoutTag_MPEG_5_1_D,
        kAudioChannelLayoutTag_AudioUnit_6_0,
        kAudioChannelLayoutTag_AAC_6_0,
        kAudioChannelLayoutTag_MPEG_6_1_A,
        kAudioChannelLayoutTag_AAC_6_1,
        kAudioChannelLayoutTag_AudioUnit_7_0,
        kAudioChannelLayoutTag_AAC_7_0,
        kAudioChannelLayoutTag_MPEG_7_1_A,
        kAudioChannelLayoutTag_MPEG_7_1_B,
        kAudioChannelLayoutTag_MPEG_7_1_C,
        kAudioChannelLayoutTag_Emagic_Default_7_1
     };
    
    
        // We configure StdAudio by telling it the starting input format and output formats,
        // plus any restrictions we want to set.
        
        // First we get the input format (asbd)
    BAILSETERR( [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice
                                    id:kQTSGAudioPropertyID_StreamFormat 
                                    size:sizeof(format) 
                                    address:&format sizeUsed:NULL] );
    
        // then we get the channel map property, since the record device StreamFormat
        // property does not take into account deactivated channels, always reporting
        // the full number of channels present on the device
    BAILSETERR( [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice
                                    id:kQTSGAudioPropertyID_ChannelMap 
                                    type: NULL
                                    size: &size
                                    flags:NULL] );
    
		// if the number of total channels on the record device differs from the number
		// of enabled channels, we need to adjust some of the fields in the AudioStreamBasicDescription
    if ( (size != 0) && (format.mChannelsPerFrame != size/sizeof(SInt32)) )
    {
        UInt32 oldNumChans = format.mChannelsPerFrame;
        format.mChannelsPerFrame = size/sizeof(SInt32); // channel map is an array of SInt32's.
        
        // adjust the fields of the asbd that need adjusting
        if (0 == (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved) )
        {
            UInt32 bytesPerFramePerChannel = format.mBytesPerFrame / oldNumChans;
            format.mBytesPerFrame = format.mBytesPerPacket = format.mChannelsPerFrame * bytesPerFramePerChannel;
        }
    }

    BAILSETERR( OpenADefaultComponent(StandardCompressionType, StandardCompressionSubTypeAudio, &ci) );
    
    
        // configure the dialog to only allow a subset of compression formats
    BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                        kQTSCAudioPropertyID_ClientRestrictedCompressionFormatList,
                                        sizeof(limitedFormats), limitedFormats) );

    
        // configure the dialog to only allow a subset of channel layouts
    limitedTagList[0] |= format.mChannelsPerFrame;
    BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio,
                                        kQTSCAudioPropertyID_ClientRestrictedChannelLayoutTagList,
                                        sizeof(limitedTagList), limitedTagList) );
                                                
                                        
    
        // set the input format of the StdAudio component to that of our recording input asbd
    BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                            kQTSCAudioPropertyID_InputBasicDescription, 
                                            sizeof(format), &format) );
                                            
        // set the input layout of the StdAudio component to that of our recording device
    if (noErr == [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                            id:kQTSGAudioPropertyID_ChannelLayout 
                                            type:NULL size:&size flags:NULL] && size)
    {
        pLayout = (AudioChannelLayout*)malloc(size);
        [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_ChannelLayout 
                                size:size address:pLayout sizeUsed:&size];
								
								
			// see if this layout can be made into a tag
		if (pLayout->mChannelLayoutTag == kAudioChannelLayoutTag_UseChannelDescriptions)
		{
			UInt32 tag;
			UInt32 propSize = sizeof(tag);
			if (noErr == AudioFormatGetProperty(
									kAudioFormatProperty_TagForChannelLayout,
									size, pLayout,
									&propSize, &tag))
				pLayout->mChannelLayoutTag = tag;
		}
		
        BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                        kQTSCAudioPropertyID_InputChannelLayout, 
                                        size, pLayout) );
    }     
    
                                            
        // set the output format of the StdAudio component to that of our SGAudio's output.
    BAILSETERR( [mChan getPropertyWithClass:kQTPropertyClass_SGAudio 
                                        id:kQTSGAudioPropertyID_SoundDescription 
                                        size:sizeof(sdh) address:&sdh sizeUsed:NULL] );
    
    BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                        kQTSCAudioPropertyID_SoundDescription, 
                                        sizeof(sdh), &sdh) );
    DisposeHandle((Handle)sdh);
    sdh = NULL;
    
        // display a custom title in the window
    memset(&xProcs, 0, sizeof(xProcs));
	
		// Icky. the SCExtendedProcs struct is a holdover from older Standard Compression
		// components, and as such, it takes a pascal string as its custom name.  Sigh.
    strcpy((char*)xProcs.customName + 1, "Output Format");
    xProcs.customName[0] = strlen((char*)xProcs.customName + 1);
    BAILSETERR( QTSetComponentProperty(ci, kQTPropertyClass_SCAudio, 
                                        kQTSCAudioPropertyID_ExtendedProcs, 
                                        sizeof(xProcs), &xProcs) );

	*outCI = ci;
bail:
	if (pLayout)
		free(pLayout);
	DisposeHandle((Handle)sdh);
	return err;
}

/*________________________________________________________________________________________
*/

- (void)updateOutputFormat
{
	OSStatus err = noErr;
	AudioStreamBasicDescription format;
	UInt32 size;
	
	
	BAILIFTRUE(YES == mOutputFormatWasSetByUser, noErr);
	
	// since the output format has not been explicitly set by the user, we
	// will update it to reflect changes in the RecordDevice config
	// (we'll make the asbd's and channel layouts match)
	
	     // First we get the input format (asbd)
    BAILSETERR( [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice
                                    id:kQTSGAudioPropertyID_StreamFormat 
                                    size:sizeof(format) 
                                    address:&format sizeUsed:NULL] );
    
        // then we get the channel map property, since the record device StreamFormat
        // property does not take into account deactivated channels, always reporting
        // the full number of channels present on the device
    BAILSETERR( [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice
                                    id:kQTSGAudioPropertyID_ChannelMap 
                                    type: NULL
                                    size: &size
                                    flags:NULL] );
    
		// if the number of total channels on the record device differs from the number
		// of enabled channels, we need to adjust some of the fields in the AudioStreamBasicDescription
    if ( (size != 0) && (format.mChannelsPerFrame != size/sizeof(SInt32)) )
    {
        UInt32 oldNumChans = format.mChannelsPerFrame;
        format.mChannelsPerFrame = size/sizeof(SInt32); // channel map is an array of SInt32's.
        
        // adjust the fields of the asbd that need adjusting
        if (0 == (format.mFormatFlags & kAudioFormatFlagIsNonInterleaved) )
        {
            UInt32 bytesPerFramePerChannel = format.mBytesPerFrame / oldNumChans;
            format.mBytesPerFrame = format.mBytesPerPacket = format.mChannelsPerFrame * bytesPerFramePerChannel;
        }
    }
	
		// now make sure the asbd is movie safe
	[self makeASBDMovieSafe:&format];
	
	[self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudio 
				id:kQTSGAudioPropertyID_StreamFormat 
				size:sizeof(format) 
				address:&format];
	
		// now get the audio channel layout from the record device, so we can pass it thru
		// as the output
	 if (noErr == [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                            id:kQTSGAudioPropertyID_ChannelLayout 
                                            type:NULL size:&size flags:NULL] && size)
    {
        AudioChannelLayout * pLayout = (AudioChannelLayout*)malloc(size);
        [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                id:kQTSGAudioPropertyID_ChannelLayout 
                                size:size address:pLayout sizeUsed:&size];
		
		[self setSGAudioPropertyWithClass:kQTPropertyClass_SGAudio 
				id:kQTSGAudioPropertyID_ChannelLayout size:size address:pLayout];
		
		free(pLayout);
    }
	
		// don't have to worry about magic cookie, since the record format is never
		// compressed, and hence won't have a magic cookie

bail:
	return;
}

/*________________________________________________________________________________________
*/

- (IBAction)selectOutputFormat:(id)sender
{
#pragma unused(sender)
    // use StdAudio dialog to let user set an output format
    OSStatus err = noErr;
    ComponentInstance ci;
    SoundDescriptionHandle sdh = NULL;
	AudioStreamBasicDescription asbd;
	AudioChannelLayout * pLayout = NULL;
	UInt32 layoutSize = 0;
	void * magicCookie = NULL;
	UInt32 magicCookieSize = 0;
	    
		
	BAILSETERR( [self openAndConfigureStdAudio:&ci] );
	
        // show the dialog (this call blocks until the dialog is finished)
    BAILSETERR( SCRequestImageSettings(ci) );
    
	
		// now we'll get the new output information:
		// 1. AudioStreamBasicDescription, 
		// 2. AudioChannelLayout, and
		// 3. MagicCookie.  
		// Then we'll set these properties onto the SGAudioChannel output	
	[self stopChannelPreview];
	
	BAILSETERR( QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
										kQTSCAudioPropertyID_BasicDescription,
										sizeof(asbd), &asbd, NULL) );
										
	if (noErr == QTGetComponentPropertyInfo(ci, kQTPropertyClass_SCAudio,
										kQTSCAudioPropertyID_ChannelLayout,
										NULL, &layoutSize, NULL) && layoutSize)
	{
		pLayout = (AudioChannelLayout*)malloc(layoutSize);
		BAILSETERR( QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
								kQTSCAudioPropertyID_ChannelLayout,
								layoutSize, pLayout, &layoutSize) );
	}
    
	if (noErr == QTGetComponentPropertyInfo(ci, kQTPropertyClass_SCAudio,
										kQTSCAudioPropertyID_MagicCookie,
										NULL, &magicCookieSize, NULL) && magicCookieSize)
	{
		magicCookie = malloc(magicCookieSize);
		BAILSETERR( QTGetComponentProperty(ci, kQTPropertyClass_SCAudio,
								kQTSCAudioPropertyID_MagicCookie,
								magicCookieSize, magicCookie, &magicCookieSize) );
	}
	
		// now set these properties on the SGAudioChannel
	BAILSETERR( [mChan setPropertyWithClass:kQTPropertyClass_SGAudio 
						id:kQTSGAudioPropertyID_StreamFormat 
						size:sizeof(asbd) address:&asbd] );
	
	BAILSETERR( [mChan setPropertyWithClass:kQTPropertyClass_SGAudio 
						id:kQTSGAudioPropertyID_ChannelLayout 
						size:layoutSize address:pLayout] );
						
	BAILSETERR( [mChan setPropertyWithClass:kQTPropertyClass_SGAudio 
						id:kQTSGAudioPropertyID_MagicCookie 
						size:magicCookieSize address:magicCookie] );

	[self startChannelPreview];
    mOutputFormatWasSetByUser = YES;
    [self updateOutputFormatText:self];
    [mRecDeviceChannelStrips makeObjectsPerformSelector:@selector(updateAllUI)];
bail:
	if (err == userCanceledErr)
		err = noErr; // canceling is ok.
		
    if (err)
		NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble setting output format (Error %ld)", err], 
			nil, nil, nil);

	if (pLayout)
		free(pLayout);
	if (magicCookie)
		free(magicCookie);
    DisposeHandle((Handle)sdh);
    CloseComponent(ci);
}

/*________________________________________________________________________________________
*/

// See QuickTimeComponents.h for additional information on setting gain.
// Setting it on the kQTPropertyClass_SGAudioRecordDevice class sets the 
// device's physical gain (and you can watch it change in AudioMidiSetup.app
// in real time).  Setting it on the kQTPropertyClass_SGAudio property
// sets the volume in software.  The two are equivalent in that they will
// both affect the volume of the audio going to the movie track.  
// The difference between the two is that the RecordDevice class property
// may fail, if the device does not support this property.  Setting it in
// software is always assured to succeed.

- (IBAction)setRecordMasterGain:(id)sender
{
#pragma unused(sender)
    Float32 level = [mRecMasterGainSlider floatValue];
    ComponentPropertyClass propClass = 
		([mUseHardwareGainButton state] == NSOnState) ? kQTPropertyClass_SGAudioRecordDevice 
													  : kQTPropertyClass_SGAudio;

	if (noErr == [self setSGAudioPropertyWithClass: propClass 
										  id: kQTSGAudioPropertyID_MasterGain 
										size: sizeof(level) 
									 address: &level])
	{
        [mRecMasterGainText setStringValue:[NSString stringWithFormat:@"%.2f", level]];
	}
}

/*________________________________________________________________________________________
*/

// Unlike the kQTPropertyClass_SGAudioRecordDevice/kQTSGAudioPropertyID_MasterGain 
// property, the kQTPropertyClass_SGAudioPreviewDevice/kQTSGAudioPropertyID_MasterGain
// property sets the gain on a mixer unit in software, and does not touch the physical
// output volume of the playback device.  Playback devices are often shared between
// apps, and it is a jarring experience to have the playback volume of one app effect
// the playback volume of all other apps sharing that common output device.

- (IBAction)setPreviewMasterGain:(id)sender
{
#pragma unused(sender)
    Float32 level = [mPrevMasterGainSlider floatValue];

	if (noErr == [self setSGAudioPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
										  id: kQTSGAudioPropertyID_MasterGain 
										size: sizeof(level) 
									 address: &level])
	{
        [mPrevMasterGainText setStringValue:[NSString stringWithFormat:@"%.2f", level]];
	}
}

/*________________________________________________________________________________________
*/

- (void)updateDevicesPopUp:(NSPopUpButton*)sender withClass:(ComponentPropertyClass)theClass
{
	OSStatus err = noErr;
	NSString * selectedDeviceUID = nil;
    NSArray * deviceList = nil;
	UInt32 i;
	
        // get the device list.  Note, device list contains _all_ devices, 
        // not just record-capable ones
    BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudio 
                                         id: kQTSGAudioPropertyID_DeviceListWithAttributes 
                                       size: sizeof(NSArray*) 
                                    address: &deviceList
                                   sizeUsed: NULL] );
									   
        // get the currently selected rec/prev device
	BAILSETERR( [mChan getPropertyWithClass: theClass 
										 id: kQTSGAudioPropertyID_DeviceUID 
									   size: sizeof(NSArray*) 
									address: &selectedDeviceUID
								   sizeUsed: NULL] );
		
		
	[sender removeAllItems];
	for (i = 0; i < [deviceList count]; i++)
	{
		NSNumber * number;
		BOOL disableIt = NO;
		NSDictionary * devDict = [deviceList objectAtIndex:i];
        UInt32 key = (theClass == kQTPropertyClass_SGAudioRecordDevice)
                      ? kQTAudioDeviceAttribute_DeviceCanRecordKey
                      : kQTAudioDeviceAttribute_DeviceCanPreviewKey;
		
		NSString * curUID = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceUIDKey];
		NSString * curName = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceNameKey];
		
			// skip it if it's not a recording device
		number = [devDict objectForKey:(id)key];
		if (number && [number boolValue] == false)
			continue;
		
			// if it's dead, add it, but disable it
		number = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceAliveKey];
		if (number && [number boolValue] == false)
		{
			disableIt = YES;
			goto addItem;
		}		

			// if it's hogged, add it, and don't disable it, but indicate that it's hogged
		number = [devDict objectForKey:(id)kQTAudioDeviceAttribute_DeviceHoggedKey];
		if (number && [number longValue] != -1 && [number longValue] != getpid())
		{
			curName = [NSString stringWithFormat:@"%@ [hogged by %ld]", curName, [number longValue]];
			goto addItem;
		}
		
addItem:		
		[sender addItemWithTitle:curName];
            // record the index of the device in the item tag
        [[sender lastItem] setTag:i];
		
		if (disableIt)
			[[sender lastItem] setEnabled:NO];
		if ([curUID isEqualToString:selectedDeviceUID])
			[sender selectItem:[sender lastItem]];		
	}

bail:
    if (err)
        NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble updating device list (Error %ld)", err], 
			nil, nil, nil);
	[selectedDeviceUID release];
    [deviceList release];
	return;
}

/*________________________________________________________________________________________
*/

- (void)updateRecordDevicesPopUp:(id)sender
{
#pragma unused(sender)
    [self updateDevicesPopUp:mRecDevicesPopUp withClass:kQTPropertyClass_SGAudioRecordDevice];
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewDevicesPopUp:(id)sender
{
#pragma unused(sender)
    [self updateDevicesPopUp:mPrevDevicesPopUp withClass:kQTPropertyClass_SGAudioPreviewDevice];
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewFlagsPopUp:(id)sender
{
#pragma unused(sender)
    [mPreviewFlagsPopUp selectItemWithTag:[mChan previewFlags]];
}

/*________________________________________________________________________________________
*/

- (IBAction)setPreviewFlags:(id)sender
{
    long newFlags = [[sender selectedItem] tag];
    
    if (newFlags != [mChan previewFlags])
    {
        [self stopChannelPreview];
        [mChan setPreviewFlags:newFlags];
        [self startChannelPreview];
    }
}

/*________________________________________________________________________________________
*/

- (void)updateRecordDeviceMasterGainSlider:(id)sender
{
#pragma unused(sender)
    Float32 level;
    ComponentPropertyClass propClass = 
		([mUseHardwareGainButton state] == NSOnState) ? kQTPropertyClass_SGAudioRecordDevice 
													  : kQTPropertyClass_SGAudio;

	if (noErr == [mChan getPropertyWithClass: propClass 
										  id: kQTSGAudioPropertyID_MasterGain 
										size: sizeof(level) 
									 address: &level sizeUsed:NULL])
	{
        [mRecMasterGainSlider setFloatValue:level];
        [mRecMasterGainText setStringValue:[NSString stringWithFormat:@"%.2f", level]];
	}
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewDeviceMasterGainSlider:(id)sender
{
#pragma unused(sender)
    Float32 level;

	if (noErr == [mChan getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
										  id: kQTSGAudioPropertyID_MasterGain 
										size: sizeof(level) 
									 address: &level sizeUsed:NULL])
	{
        [mPrevMasterGainSlider setFloatValue:level];
        [mPrevMasterGainText setStringValue:[NSString stringWithFormat:@"%.2f", level]];
	}
}

/*________________________________________________________________________________________
*/

- (void)updateInputOutputPopUp:(NSPopUpButton*)sender withClass:(ComponentPropertyClass)theClass
{
    OSType selected = 0;
    NSArray * theList = nil;
    OSStatus err = noErr;
    BOOL isInput = (theClass == kQTPropertyClass_SGAudioRecordDevice);
    ComponentPropertyID theID;
    
    [sender removeAllItems];
    
    theID = (isInput ? kQTSGAudioPropertyID_InputSelection : kQTSGAudioPropertyID_OutputSelection);
    
	if (noErr ==[mChan getPropertyWithClass: theClass 
										 id: theID
									   size: sizeof(selected) 
									address: &selected
								   sizeUsed: NULL] )
    {
        int i;
        theID = (isInput ? kQTSGAudioPropertyID_InputListWithAttributes 
                             : kQTSGAudioPropertyID_OutputListWithAttributes);
                             
		BAILSETERR( [mChan getPropertyWithClass: theClass 
										 id: theID 
									   size: sizeof(NSArray*) 
									address: &theList
								   sizeUsed: NULL] );
        [sender setEnabled:YES];
        
        for (i = 0; i < [theList count]; i++)
        {
            NSDictionary * d = [theList objectAtIndex:i];
			
            theID = (isInput ? kQTAudioDeviceAttribute_DeviceInputDescription 
                             : kQTAudioDeviceAttribute_DeviceOutputDescription);
            
            [sender addItemWithTitle:
				[d objectForKey:(id)theID]];
                
            theID = (isInput ? kQTAudioDeviceAttribute_DeviceInputID 
                             : kQTAudioDeviceAttribute_DeviceOutputID);
				
            if (selected == 
				 [(NSNumber*)[d objectForKey:(id)theID] unsignedLongValue])
			{
                [sender selectItemAtIndex:i];
			}
        }   
    }
    else {
        // this device doesn't support inputs/outputs.
        // disable the menu
        [sender addItemWithTitle:@"None"];
        [sender setEnabled:NO];
    }   
    
bail:
    if (err)
        NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble updating input list (Error %ld)", err], 
			nil, nil, nil);
    [theList release];
    return;
}


/*________________________________________________________________________________________
*/

- (void)updateRecordDeviceInputPopUp:(id)sender
{
#pragma unused(sender)
    [self updateInputOutputPopUp:mRecDeviceInputsPopUp 
        withClass:kQTPropertyClass_SGAudioRecordDevice];
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewDeviceOutputPopUp:(id)sender
{
#pragma unused(sender)
    [self updateInputOutputPopUp:mPrevDeviceOutputsPopUp 
        withClass:kQTPropertyClass_SGAudioPreviewDevice];
}

/*________________________________________________________________________________________
*/

- (void)updateFormatPopUp:(NSPopUpButton*)sender withClass:(ComponentPropertyClass)theClass
{
    AudioStreamBasicDescription * formats = NULL;
    AudioStreamBasicDescription curFormat;
    UInt32 i, size, flags;
    OSStatus err = noErr;
    
    [sender removeAllItems];
    
	BAILSETERR( [mChan getPropertyWithClass: theClass 
										 id: kQTSGAudioPropertyID_StreamFormat 
									   size: sizeof(curFormat) 
									address: &curFormat
								   sizeUsed: NULL] );
	
	BAILSETERR( [mChan getPropertyInfoWithClass: theClass 
										 id: kQTSGAudioPropertyID_StreamFormatList 
										 type:NULL size:&size flags:&flags] );
    assert(flags & kComponentPropertyFlagCanGetNow);

    formats = (AudioStreamBasicDescription*)malloc(size);
	BAILSETERR( [mChan getPropertyWithClass: theClass 
										 id: kQTSGAudioPropertyID_StreamFormatList 
									   size: size
									address: formats
								   sizeUsed: &size] );
    
    
    for (i = 0; i < size/sizeof(AudioStreamBasicDescription); i++)
    {
        NSString * name = nil;
        SoundDescriptionHandle sdh = NULL;
        
			// QTSoundDescriptionSet/GetProperty{Info} API's can help us by
			// giving us a nicely formatted CFString of the format in question
        BAILSETERR( QTSoundDescriptionCreate(&formats[i], NULL, 0, NULL, 0, 
                        kQTSoundDescriptionKind_Movie_AnyVersion, &sdh) );
                        
        BAILSETERR( QTSoundDescriptionGetProperty(sdh, kQTPropertyClass_SoundDescription,
                        kQTSoundDescriptionPropertyID_UserReadableText,
                        sizeof(name), &name, NULL) );
        
        DisposeHandle((Handle)sdh);    

        [sender addItemWithTitle:name];
        [name release];
        
        if (formats[i].mSampleRate == curFormat.mSampleRate &&
            formats[i].mFormatID == curFormat.mFormatID &&
            formats[i].mFormatFlags == curFormat.mFormatFlags &&
            formats[i].mChannelsPerFrame == curFormat.mChannelsPerFrame &&
            formats[i].mBitsPerChannel == curFormat.mBitsPerChannel &&
            formats[i].mFramesPerPacket == curFormat.mFramesPerPacket &&
            formats[i].mBytesPerFrame == curFormat.mBytesPerFrame &&
            formats[i].mBytesPerPacket == curFormat.mBytesPerPacket)
        {
            [sender selectItemAtIndex:i];
        }
    }
                                            
bail:
    if (err)
        NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble updating format list (Error %ld)", err], 
			nil, nil, nil);
    if (formats) 
		free(formats);
    return;
}

/*________________________________________________________________________________________
*/

- (void)updatePreviewDeviceFormatPopUp:(id)sender
{
#pragma unused(sender)
    [self updateFormatPopUp:mPrevDeviceFormatPopUp 
            withClass:kQTPropertyClass_SGAudioPreviewDevice];
}

/*________________________________________________________________________________________
*/

- (void)updateRecordDeviceFormatPopUp:(id)sender
{
#pragma unused(sender)
    [self updateFormatPopUp:mRecDeviceFormatPopUp 
            withClass:kQTPropertyClass_SGAudioRecordDevice];
}

/*________________________________________________________________________________________
*/

- (void)updatePlayWhileRecordingButton:(id)sender
{
#pragma unused(sender)
    BOOL playthruEnabled = ([mChan usage] & seqGrabPlayDuringRecord) != 0;
    [mPreviewWhileRecordingButton setState:(int)playthruEnabled];
}

/*________________________________________________________________________________________
*/

- (void)updateHardwarePlaythruButton:(id)sender
{
#pragma unused(sender)
    // find out if our current recording device supports hardware playthru
    NSDictionary *  deviceAttribs = nil;
    BOOL            isSupported;
    OSStatus        err = noErr;
    
    BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
										 id: kQTSGAudioPropertyID_DeviceAttributes 
									   size: sizeof(deviceAttribs) 
									address: &deviceAttribs
								   sizeUsed: NULL] );
    
    isSupported = [(NSNumber*)[deviceAttribs objectForKey:
                    (id)kQTAudioDeviceAttribute_DeviceSupportsHardwarePlaythruKey] boolValue];
    
    [mHardPlaythruEnabledButton setEnabled:isSupported];
    if (isSupported)
    {
        // see if hard playthru is turned on
        BOOL isEnabled;
        
        BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
										 id: kQTSGAudioPropertyID_HardwarePlaythruEnabled 
									   size: sizeof(isEnabled) 
									address: &isEnabled
								   sizeUsed: NULL] );
        [mHardPlaythruEnabledButton setState:(int)isEnabled];
    }
    else {
        [mHardPlaythruEnabledButton setState:(int)isSupported]; // can't be checked if disabled
    }
bail:
    [deviceAttribs release];
}

/*________________________________________________________________________________________
*/

- (void)updateOutputFormatText:(id)sender
{
#pragma unused(sender)
    OSStatus err = noErr;
    SoundDescriptionHandle sdh = NULL;
    NSString * name = nil;

    
	BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudio 
										 id: kQTSGAudioPropertyID_SoundDescription 
									   size: sizeof(sdh)
									address: &sdh
								   sizeUsed: NULL] );
    
    BAILSETERR( QTSoundDescriptionGetProperty(sdh,
                        kQTPropertyClass_SoundDescription,
                        kQTSoundDescriptionPropertyID_UserReadableText,
                        sizeof(name), &name, NULL) );
    
    [mOutputFormatText setStringValue:name];
bail:
    [name release];
	DisposeHandle((Handle)sdh);
    if (err)
        NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble updating output format (Error %ld)", err],
			 nil, nil, nil);
}

/*________________________________________________________________________________________
*/

- (void)recDeviceChannelsBoxWasScrolled:(NSNotification*)n
{
#pragma unused(n)
	[mRecDeviceChannelStrips makeObjectsPerformSelector:@selector(updateAllUI)];
}

/*________________________________________________________________________________________
*/

- (void)updateRecordDeviceChannelsBox:(id)sender
{
#pragma unused(sender)
	AudioStreamBasicDescription deviceFormat;
	OSStatus err = noErr;
	
	BAILSETERR( [mChan getPropertyWithClass: kQTPropertyClass_SGAudioRecordDevice 
										 id: kQTSGAudioPropertyID_StreamFormat 
									   size: sizeof(deviceFormat)
									address: &deviceFormat
								   sizeUsed: NULL] );

	if ([mRecDeviceChannelStrips count] != deviceFormat.mChannelsPerFrame)
	{
		const Float32 kDevChanBoxHeightBump = 4.;
        const Float32 kDevStripHeight = 25.;
		const Float32 kDevChanBoxMinHeight = 204.;
		int i;
		NSRect devChansContainerBounds = [mRecDeviceChannelsScrollView bounds];
		float chanStripsHeight = kDevStripHeight * deviceFormat.mChannelsPerFrame + kDevChanBoxHeightBump;
        float curStripYPos;
        
        // get the channel map
        UInt32 mapSize;
        SInt32 * map = NULL;
            
        [mChan getPropertyInfoWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                            id:kQTSGAudioPropertyID_ChannelMap 
                                            type:NULL size:&mapSize flags:NULL];
        if (mapSize > 0)
        {
            map = (SInt32 *)malloc(mapSize);
            
            [mChan getPropertyWithClass:kQTPropertyClass_SGAudioRecordDevice 
                                            id:kQTSGAudioPropertyID_ChannelMap 
                                            size:mapSize
                                            address:map sizeUsed:&mapSize];
        }
		
		[[NSNotificationCenter defaultCenter] removeObserver:self 
				name:NSViewBoundsDidChangeNotification 
				object:[mRecDeviceChannelsScrollView contentView]];
        
        [mRecDeviceChannelStrips makeObjectsPerformSelector:@selector(stopMetering)];
		[mRecDeviceChannelStrips removeAllObjects];

        // determine whether we need to resize the container view
        if (chanStripsHeight > kDevChanBoxMinHeight)
        {
            devChansContainerBounds.size.height = chanStripsHeight;
            [mRecDeviceChannelsContainerView setFrameSize:devChansContainerBounds.size];
        }
        else if (chanStripsHeight < kDevChanBoxMinHeight) {
			devChansContainerBounds.size.height = kDevChanBoxMinHeight;
			[mRecDeviceChannelsContainerView setFrameSize:devChansContainerBounds.size];
        }
		
			// scroll the NSClipView back to the top
		[[mRecDeviceChannelsScrollView contentView] scrollToPoint:
			NSMakePoint(0., 
				(chanStripsHeight > kDevChanBoxMinHeight) ? chanStripsHeight - kDevChanBoxMinHeight : 0.)];
		[mRecDeviceChannelsScrollView reflectScrolledClipView:
			[mRecDeviceChannelsScrollView contentView]];

        // add the channel strips in reverse order
		curStripYPos = devChansContainerBounds.size.height - chanStripsHeight;
        
		for (i = deviceFormat.mChannelsPerFrame - 1; i >= 0; i--)
		{
			DeviceChannelStrip * devStrip = 
				[[DeviceChannelStrip alloc] initWithSGAudioSettings:self channelNumber:i];
            
			[mRecDeviceChannelStrips insertObject:devStrip atIndex:0];
            
			[mRecDeviceChannelsContainerView addSubview:[devStrip deviceChannelStripView]];
			
				// position it			
			[[devStrip deviceChannelStripView] setFrameOrigin:
				NSMakePoint(0., curStripYPos)];
			curStripYPos += kDevStripHeight;
            
            if (map)
            {
                int j;
                for (j = 0; j < mapSize/sizeof(SInt32); j++)
                {
                    if (i == map[j])
                    {
                        break; // found it.  This channel should be enabled
                    }
                }
                if (j >= mapSize/sizeof(SInt32))
                    [devStrip setEnabled:NO];
            }
			
			[devStrip release];
		}
        
		[[NSNotificationCenter defaultCenter] addObserver:self 
				selector:@selector(recDeviceChannelsBoxWasScrolled:) 
				name:NSViewBoundsDidChangeNotification 
				object:[mRecDeviceChannelsScrollView contentView]];

        if (map)
            free(map);
	}
		
	[mRecDeviceChannelStrips makeObjectsPerformSelector:@selector(updateAllUI)];
	
bail:
	if (err)
		NSRunAlertPanel(@"WhackedTV", 
			[NSString stringWithFormat:@"Trouble creating channel UI (Error %ld)", err], 
			nil, nil, nil);
}

/*________________________________________________________________________________________
*/

- (void)idleTimer:(NSTimer*)timer
{
#pragma unused(timer)
	SGIdle([mChan chanComponent]);
}

/*________________________________________________________________________________________
*/

- (void)startChannelPreview
{
    if (mPreviewTimer == nil)
    {
        mPreviewTimer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                        interval:.05
                                        target:self 
                                        selector:@selector(idleTimer:)  
                                        userInfo:nil repeats:YES];
    }

	SGPrepare([mChan chanComponent], true, false);
	SGStartPreview([mChan chanComponent]);
	
	[[NSRunLoop currentRunLoop] addTimer:mPreviewTimer forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:mPreviewTimer forMode:NSEventTrackingRunLoopMode];
}

/*________________________________________________________________________________________
*/

- (void)stopChannelPreview
{
    [mPreviewTimer invalidate];
    [mPreviewTimer release];
    mPreviewTimer = nil;
	SGStop([mChan chanComponent]);
    SGRelease([mChan chanComponent]);
}


/*________________________________________________________________________________________
*/

- (void)addFXUnitView:(AudioUnit)au
{	
	AUGenericView * auview = nil;
	BOOL doResizeContainerView = NO;
	
	if (!au)
		return;

		// AUGenericView is part of the CoreAudioKit, new in Tiger.
		
	auview = [[AUGenericView alloc] initWithAudioUnit:au 
			displayFlags:AUViewTitleDisplayFlag /*| AUViewPropertiesDisplayFlag*/ 
							| AUViewParametersDisplayFlag];
			
	[auview setShowsExpertParameters:YES];
	[auview setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];

	NSRect newRect = [auview bounds];
	NSRect curRect = [mFXContainerView bounds];
	NSRect subViewsBoundsRect = NSMakeRect(0., 0., curRect.size.width, curRect.size.height);
	
	if (newRect.size.width > subViewsBoundsRect.size.width)
		subViewsBoundsRect.size.width = newRect.size.width;
		
	subViewsBoundsRect.size.height -= newRect.size.height;
	
	for (int i = 0; i < [[mFXContainerView subviews] count]; i++)
	{
		NSRect subviewRect = [[[mFXContainerView subviews] objectAtIndex:i] bounds];
		
		if (subviewRect.size.width > subViewsBoundsRect.size.width)
			subViewsBoundsRect.size.width = subviewRect.size.width;
		subViewsBoundsRect.size.height -= subviewRect.size.height;
	}
	
	
	if ( subViewsBoundsRect.size.width > curRect.size.width )
	{
		curRect.size.width = subViewsBoundsRect.size.width;
		doResizeContainerView = YES;
	}
	
	
	if (subViewsBoundsRect.size.height < 0.)
	{
		// add this negative height back into curRect to
		// increase the height of the container view to
		// fit our new auview
		curRect.size.height -= subViewsBoundsRect.size.height;
		doResizeContainerView = YES;
	}
	else {
		newRect.origin.y = subViewsBoundsRect.size.height;
	}
	
	if (doResizeContainerView)
	{
		[mFXContainerView setFrameSize:curRect.size];
		// scroll to the bottom
		[[mFXScrollView contentView] scrollToPoint:NSMakePoint(0., 0.)];
		
		// reposition all subviews
		if (subViewsBoundsRect.size.height < 0.)
		{
			NSRect originRect = curRect;
			
			for (int i = 0; i < [[mFXContainerView subviews] count]; i++)
			{
				AUGenericView* curview = [[mFXContainerView subviews] objectAtIndex:i];
				NSRect curViewRect = [curview frame];
				
				originRect.size.height -= curViewRect.size.height;
				curViewRect.origin.y = originRect.size.height;
				[curview setFrameOrigin:curViewRect.origin];
			}
		}
	}
	[mFXContainerView addSubview:auview];
	[auview setFrame:newRect];
	[mFXContainerView setNeedsDisplay:YES];
	
	[auview release];
}


/*________________________________________________________________________________________
*/


- (IBAction)showFXPanel:(id)sender
{
#pragma unused(sender)
        // build-up the pop-up
    [mAddFXButton removeAllItems];
    
    [mAddFXButton addItemWithTitle:@"(Select an effect)"];
    [mAddFXButton selectItemAtIndex:0];
    
    ComponentDescription cd = {0};
    Component c = NULL;
    Handle name = NewHandle(0);
    cd.componentType = 'aufx';
    
    while (NULL != (c = FindNextComponent(c, &cd)))
    {
        char cstr[256];
        ComponentDescription thisCD;
        if (noErr == GetComponentInfo(c, &thisCD, name, NULL, NULL))
        {
            strncpy(cstr, *name + 1, **name);
            cstr[**name] = '\0';
            [mAddFXButton addItemWithTitle:[NSString stringWithUTF8String:cstr]];
            [[mAddFXButton lastItem] setTag:thisCD.componentSubType];
        }
    }
    DisposeHandle(name);
    
    
	for (int i = 0; i < [mChan fxUnitsCount]; i++)
    {
		[self addFXUnitView:[mChan fxUnits][i]];
    }
	
	if ([mChan fxUnitsCount] == 0)
		[mRemoveFXButton setEnabled:NO];
    
	[[NSApplication sharedApplication] beginSheet:mFXPanel 
			modalForWindow:mSettingsPanel 
			modalDelegate:self 
			didEndSelector:@selector(fxSheetDidEnd:returnCode:contextInfo:)
			contextInfo:NULL];
}

/*________________________________________________________________________________________
*/

- (void)fxSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
#pragma unused(returnCode)
#pragma unused(contextInfo)
	[sheet orderOut:self];
}

/*________________________________________________________________________________________
*/

- (IBAction)closeFXPanel:(id)sender
{
#pragma unused(sender)
    [[NSApplication sharedApplication] endSheet:mFXPanel];
	
	[[mFXContainerView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

/*________________________________________________________________________________________
*/

- (IBAction)addFXUnit:(id)sender
{
	if (NO == [[[sender selectedItem] title] isEqualToString:@"(Select an effect)"])
	{
		ComponentDescription cd = {0};
		
		cd.componentType = 'aufx';
		cd.componentSubType = [[sender selectedItem] tag];
		
		[self stopChannelPreview];
		AudioUnit au = [mChan insertAUFXUnit:&cd];
		[self addFXUnitView:au];
		[self startChannelPreview];
		
		[sender selectItemAtIndex:0]; // snap back to "(select an effect)"
		
		if ( [mChan fxUnitsCount] == kMaxFXUnits )
			[sender setEnabled:NO];
			
		[mRemoveFXButton setEnabled:YES];
	}
}

/*________________________________________________________________________________________
*/

- (IBAction)removeFXUnit:(id)sender
{
#pragma unused(sender)
    // just remove the last one
    AUGenericView * auview = [[mFXContainerView subviews] lastObject];
    AudioUnit au = [auview audioUnit];
	[auview removeFromSuperview]; // retain count should go down to 0 on the view
	
	// shrink the container view if necessary
	NSRect scrollRect = [mFXScrollView bounds];
	NSRect newRect = NSMakeRect(0., 0., scrollRect.size.width, 0.);
	
	for (int i = 0; i < [[mFXContainerView subviews] count]; i++)
	{
		NSView * view = [[mFXContainerView subviews] objectAtIndex:i];
		NSRect curRect = [view bounds];
		
		newRect.size.height += curRect.size.height;
		if (curRect.size.width > newRect.size.width)
			newRect.size.width = curRect.size.width;
	}
	
	if (newRect.size.height < scrollRect.size.height)
		newRect.size.height = scrollRect.size.height;
		
	NSRect actualRect = [mFXContainerView bounds];
	
	if (actualRect.size.height != newRect.size.height ||
		actualRect.size.width != newRect.size.width)
	{
		[mFXContainerView setFrameSize:newRect.size];
		[mFXContainerView setNeedsDisplay:YES];
	}
	
    
    [self stopChannelPreview];
    [mChan removeAUFXUnit:au];
	[mAddFXButton setEnabled:YES];
	if ([mChan fxUnitsCount] == 0)
		[mRemoveFXButton setEnabled:NO];
    [self startChannelPreview];
}

/*________________________________________________________________________________________
*/

@end

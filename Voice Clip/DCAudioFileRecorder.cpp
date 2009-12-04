/*

File:DCAudioFileRecorder.cpp

Abstract: simple audio-in recorder

Version: 1.1

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Computer, Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Computer,
Inc. may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright © 2006 Apple Computer, Inc., All Rights Reserved

*/ 

#include "DCAudioFileRecorder.h"
#include <sys/param.h>

DCAudioFileRecorder::DCAudioFileRecorder()
{
	fInputDeviceID = 0;
	fAudioChannels = fAudioSamples = 0;
}

DCAudioFileRecorder::~DCAudioFileRecorder()
{
	// Stop pulling audio data
	Stop();
	
	// Dispose our audio file reference
	// Also responsible for flushing async data to disk
	ExtAudioFileDispose(fOutputAudioFile);
}

// Convenience function to dispose of our audio buffers
void DCAudioFileRecorder::DestroyAudioBufferList(AudioBufferList* list)
{
	UInt32						i;
	
	if(list) {
		for(i = 0; i < list->mNumberBuffers; i++) {
			if(list->mBuffers[i].mData)
			free(list->mBuffers[i].mData);
		}
		free(list);
	}
}
	
// Convenience function to allocate our audio buffers
AudioBufferList *DCAudioFileRecorder::AllocateAudioBufferList(UInt32 numChannels, UInt32 size)
{
	AudioBufferList*			list;
	UInt32						i;
	
	list = (AudioBufferList*)calloc(1, sizeof(AudioBufferList) + numChannels * sizeof(AudioBuffer));
	if(list == NULL)
	return NULL;
	
	list->mNumberBuffers = numChannels;
	for(i = 0; i < numChannels; ++i) {
		list->mBuffers[i].mNumberChannels = 1;
		list->mBuffers[i].mDataByteSize = size;
		list->mBuffers[i].mData = malloc(size);
		if(list->mBuffers[i].mData == NULL) {
			DestroyAudioBufferList(list);
			return NULL;
		}
	}
	return list;
}

OSStatus DCAudioFileRecorder::AudioInputProc(void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
	DCAudioFileRecorder *afr = (DCAudioFileRecorder*)inRefCon;
	OSStatus	err = noErr;

	// Render into audio buffer
	err = AudioUnitRender(afr->fAudioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, afr->fAudioBuffer);
	if(err)
		fprintf(stderr, "AudioUnitRender() failed with error %i\n", err);
	
	// Write to file, ExtAudioFile auto-magicly handles conversion/encoding
	// NOTE: Async writes may not be flushed to disk until a the file
	// reference is disposed using ExtAudioFileDispose
	err = ExtAudioFileWriteAsync(afr->fOutputAudioFile, inNumberFrames, afr->fAudioBuffer);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileWrite FAILED! %d '%-4.4s'\n",err, formatID);
		return err;
	}

	return err;
}

OSStatus DCAudioFileRecorder::ConfigureOutputFile(const FSRef inParentDirectory, const CFStringRef inFileName, AudioStreamBasicDescription *inASBD)
{
	OSStatus err = noErr;
	AudioConverterRef conv = NULL;

	// Create new MP4 file (kAudioFileM4AType)
	err = ExtAudioFileCreateNew(&inParentDirectory, inFileName, kAudioFileM4AType, inASBD, NULL, &fOutputAudioFile);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileCreateNew FAILED! %d '%-4.4s'\n",err, formatID);
		return err;
	}

	// Inform the file what format the data is we're going to give it, should be pcm
	// You must set this in order to encode or decode a non-PCM file data format.
	err = ExtAudioFileSetProperty(fOutputAudioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &fOutputFormat);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileSetProperty FAILED! '%-4.4s'\n", formatID);
		return err;
	}

	// If we're recording from a mono source, setup a simple channel map to split to stereo
	if (fDeviceFormat.mChannelsPerFrame == 1 && fOutputFormat.mChannelsPerFrame == 2)
	{
		// Get the underlying AudioConverterRef
		UInt32 size = sizeof(AudioConverterRef);
		err = ExtAudioFileGetProperty(fOutputAudioFile, kExtAudioFileProperty_AudioConverter, &size, &conv);
		if (conv)
		{
			// This should be as large as the number of output channels,
			// each element specifies which input channel's data is routed to that output channel
			SInt32 channelMap[] = { 0, 0 };
			err = AudioConverterSetProperty(conv, kAudioConverterChannelMap, 2*sizeof(SInt32), channelMap);
		}
	}

	// Initialize async writes thus preparing it for IO
	err = ExtAudioFileWriteAsync(fOutputAudioFile, 0, NULL);
	if(err != noErr)
	{
		char formatID[5];
		*(UInt32 *)formatID = CFSwapInt32HostToBig(err);
		formatID[4] = '\0';
		fprintf(stderr, "ExtAudioFileWriteAsync FAILED! '%-4.4s'\n", formatID);
		return err;
	}

	return err;
}

OSStatus DCAudioFileRecorder::ConfigureAU()
{
	Component					component;
	ComponentDescription		description;
	OSStatus	err = noErr;
	UInt32	param;
	AURenderCallbackStruct	callback;

	// Open the AudioOutputUnit
	// There are several different types of Audio Units.
	// Some audio units serve as Outputs, Mixers, or DSP
	// units. See AUComponent.h for listing
	description.componentType = kAudioUnitType_Output;
	description.componentSubType = kAudioUnitSubType_HALOutput;
	description.componentManufacturer = kAudioUnitManufacturer_Apple;
	description.componentFlags = 0;
	description.componentFlagsMask = 0;
	if(component = FindNextComponent(NULL, &description))
	{
		err = OpenAComponent(component, &fAudioUnit);
		if(err != noErr)
		{
			fAudioUnit = NULL;
			return err;
		}
	}

	// Configure the AudioOutputUnit
	// You must enable the Audio Unit (AUHAL) for input and output for the same  device.
	// When using AudioUnitSetProperty the 4th parameter in the method
	// refer to an AudioUnitElement.  When using an AudioOutputUnit
	// for input the element will be '1' and the output element will be '0'.	
	
	// Enable input on the AUHAL
	param = 1;
	err = AudioUnitSetProperty(fAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &param, sizeof(UInt32));
	if(err == noErr)
	{
		// Disable Output on the AUHAL
		param = 0;
		err = AudioUnitSetProperty(fAudioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &param, sizeof(UInt32));
	}

	// Select the default input device
	param = sizeof(AudioDeviceID);
	err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultInputDevice, &param, &fInputDeviceID);
	if(err != noErr)
	{
		fprintf(stderr, "failed to get default input device\n");
		return err;
	}

	// Set the current device to the default input unit.
	err = AudioUnitSetProperty(fAudioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &fInputDeviceID, sizeof(AudioDeviceID));
	if(err != noErr)
	{
		fprintf(stderr, "failed to set AU input device\n");
		return err;
	}
	
	// Setup render callback
	// This will be called when the AUHAL has input data
	callback.inputProc = DCAudioFileRecorder::AudioInputProc; // defined as static in the header file
	callback.inputProcRefCon = this;
	err = AudioUnitSetProperty(fAudioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, &callback, sizeof(AURenderCallbackStruct));

	// get hardware device format
	param = sizeof(AudioStreamBasicDescription);
	err = AudioUnitGetProperty(fAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &fDeviceFormat, &param);
	if(err != noErr)
	{
		fprintf(stderr, "failed to get input device ASBD\n");
		return err;
	}

	// Twiddle the format to our liking
	fAudioChannels = MAX(fDeviceFormat.mChannelsPerFrame, 2);
	fOutputFormat.mChannelsPerFrame = fAudioChannels;
	fOutputFormat.mSampleRate = fDeviceFormat.mSampleRate;
	fOutputFormat.mFormatID = kAudioFormatLinearPCM;
	fOutputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
	if (fOutputFormat.mFormatID == kAudioFormatLinearPCM && fAudioChannels == 1)
		fOutputFormat.mFormatFlags &= ~kLinearPCMFormatFlagIsNonInterleaved;
#if __BIG_ENDIAN__
	fOutputFormat.mFormatFlags |= kAudioFormatFlagIsBigEndian;
#endif
	fOutputFormat.mBitsPerChannel = sizeof(Float32) * 8;
	fOutputFormat.mBytesPerFrame = fOutputFormat.mBitsPerChannel / 8;
	fOutputFormat.mFramesPerPacket = 1;
	fOutputFormat.mBytesPerPacket = fOutputFormat.mBytesPerFrame;

	// Set the AudioOutputUnit output data format
	err = AudioUnitSetProperty(fAudioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &fOutputFormat, sizeof(AudioStreamBasicDescription));
	if(err != noErr)
	{
		fprintf(stderr, "failed to set input device ASBD\n");
		return err;
	}

	// Get the number of frames in the IO buffer(s)
	param = sizeof(UInt32);
	err = AudioUnitGetProperty(fAudioUnit, kAudioDevicePropertyBufferFrameSize, kAudioUnitScope_Global, 0, &fAudioSamples, &param);
	if(err != noErr)
	{
		fprintf(stderr, "failed to get audio sample size\n");
		return err;
	}

	// Initialize the AU
	err = AudioUnitInitialize(fAudioUnit);
	if(err != noErr)
	{
		fprintf(stderr, "failed to initialize AU\n");
		return err;
	}

	// Allocate our audio buffers
	fAudioBuffer = AllocateAudioBufferList(fOutputFormat.mChannelsPerFrame, fAudioSamples * fOutputFormat.mBytesPerFrame);
	if(fAudioBuffer == NULL)
	{
		fprintf(stderr, "failed to allocate buffers\n");
		return err;
	}

	return noErr;
}

// Configure and Initialize our AudioUnits, Audio Files, and Audio Buffers
OSStatus DCAudioFileRecorder::Configure(const FSRef inParentDirectory, const CFStringRef inFileName, AudioStreamBasicDescription *inASBD)
{
	OSStatus err = noErr;
	
	err = ConfigureAU();
	if(err == noErr)
		err = ConfigureOutputFile(inParentDirectory, inFileName, inASBD);
	return err;
}

OSStatus DCAudioFileRecorder::Start()
{
	// Start pulling for audio data
	OSStatus err = AudioOutputUnitStart(fAudioUnit);
	if(err != noErr)
	{
		fprintf(stderr, "failed to start AU\n");
		return err;
	}
	
	fprintf(stderr, "Recording started...\n");
	return err;
}

OSStatus DCAudioFileRecorder::Stop()
{
	// Stop pulling audio data
	OSStatus err = AudioOutputUnitStop(fAudioUnit);
	if(err != noErr)
	{
		fprintf(stderr, "failed to stop AU\n");
		return err;
	}
	
	fprintf(stderr, "Recording stoped.\n");
	return err;
}

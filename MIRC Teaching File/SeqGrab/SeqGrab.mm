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

#import "SeqGrab.h"
#import "WhackedDebugMacros.h"
#import "SGChan.h"
#import "SGVideo.h"
#import "SGAudio.h"


NSString * SeqGrabChannelRemovedNotification = @"SeqGrabChannelRemovedNotification";
NSString * SeqGrabChannelAddedNotification   = @"SeqGrabChannelAddedNotification";
NSString * SeqGrabChannelKey                 = @"SeqGrabChannelKey";


@implementation SeqGrab


/*________________________________________________________________________________________
*/

+ (void)initialize
{
	// initialize the QT toolbox
	EnterMovies();
}

/*________________________________________________________________________________________
*/

- (id)init
{
    OSStatus err = noErr;
    
    self = [super init];
    
    BAILSETERR( OpenADefaultComponent(SeqGrabComponentType, 0, &mSeqGrab) );
    BAILSETERR( SGInitialize(mSeqGrab) );
	
	mChans = [[NSMutableArray alloc] init];
	mSavedChannelUsages = [[NSMutableArray alloc] init];
bail:
    if (err)
    {
        [self release];
        return nil;
    }
    return self;
}

/*________________________________________________________________________________________
*/

- (void)dealloc
{
    //NSLog(@"[SeqGrab dealloc] %p", self);
	[mChans release];
    CloseComponent(mSeqGrab);
	
	[mCapturePath release];
	[mSavedCapturePath release];
	[mSavedChannelUsages release];
    
    [super dealloc];
}

/*________________________________________________________________________________________
*/

- (NSArray *)channels
{
	return mChans;
}

/*________________________________________________________________________________________
*/

- (SeqGrabComponent)seqGrabComponent
{
    return mSeqGrab;
}

/*________________________________________________________________________________________
*/

- (OSStatus)addChannel:(SGChan*)chan
{
	if (![mChans containsObject:chan])
		[mChans addObject:chan];
	return noErr;
}

/*________________________________________________________________________________________
*/

- (OSStatus)removeChannel:(SGChan*)chan
{
	[mChans removeObject:chan];
	return noErr;
}

/*________________________________________________________________________________________
*/

- (OSStatus)setCapturePath:(NSString*)filePath flags:(long)flags
{
	OSStatus err = noErr;
	Handle dataRef = NULL;
	OSType dataRefType = 0;
	
	if (filePath)
	{
		BAILSETERR( QTNewDataReferenceFromFullPathCFString(	
                        (CFStringRef)filePath, 
                        (UInt32)kQTNativeDefaultPathStyle, 
                        0, &dataRef, &dataRefType) );
	}
	
	[mCapturePath release];
	mCapturePath = [filePath retain];
	mCaptureFlags = flags;
	
	
	if ( !(flags & seqGrabDontMakeMovie) )
	{
		if ( (flags & seqGrabDontPreAllocateFileSize) &&
			!(flags & seqGrabAppendToFile) )
		{
			// Sequence Grabber will still preallocate the file on disk unless
			// seqGrabAppendToFile is also set.  So if you wish to keep
			// Sequence Grabber from preallocating a large file on disk, but
			// you don't want to append to an existing file, you need to open
			// up the desired file and truncate it first, then set the 
			// seqGrabAppendToFile flag.
			
			// truncate the file on disk first
			fclose(fopen([filePath cString], "w"));
			flags |= seqGrabAppendToFile;
		}
	}

	err = SGSetDataRef(mSeqGrab, dataRef, dataRefType, flags);

bail:
	DisposeHandle(dataRef);
	return err;
}

/*________________________________________________________________________________________
*/

- (OSStatus)setSettings:(NSData*)blob
{
	OSStatus	err = noErr;
	UserData	ud = NULL;
	Handle		hud = NULL;
	short		idx;
	SGChannel	c;
	OSType		type;
    UserData    savedUD = NULL;
    
    BAILSETERR( SGGetSettings(mSeqGrab, &savedUD, 0) );
	
	hud = NewHandle([blob length]);
	memcpy(*hud, [blob bytes], [blob length]);
	BAILSETERR( NewUserDataFromHandle(hud, &ud) );
	
	// before setting settings, remove all channel objects,
	// since the settings will have new channel objects.
    while ([mChans count])
    {
        SGChan * chan = [[mChans lastObject] retain];
        [mChans removeLastObject];
        
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:SeqGrabChannelRemovedNotification object:self
            userInfo:[NSDictionary dictionaryWithObject:chan forKey:SeqGrabChannelKey]];
        
        [chan release];
    }
	
	BAILSETERR( SGSetSettings(mSeqGrab, ud, 0) );
    
    // iterate through all the channels and set their refcons to 0 (clearing out any
    // SGChan * object associations they may have had from previous runs)
    idx = 0;
    while (noErr == SGGetIndChannel(mSeqGrab, ++idx, &c, &type) )
    {
        SGSetChannelRefCon(c, 0);
    }
	
	// now iterate through mSeqGrab's channel components and make
	// SGChan wrappers for each.  Our implementation uses the SGChannel 
	// RefCon as a pointer to SGChan * object pointer, so if the channel
	//  refcon is non NULL, we don't need to make a wrapper for it
startOver:
	idx = 0;
	while ( noErr == SGGetIndChannel(mSeqGrab, ++idx, &c, &type) )
	{
		long refCon;
        SGGetChannelRefCon(c, &refCon);
		
		switch (type)
		{
			case VideoMediaType:
				if (refCon == 0)
                {
                    SGVideo * vide = 
                        [[SGVideo alloc] initWithSeqGrab:self channelComponent:c];
					[self addChannel:vide];
                    [[NSNotificationCenter defaultCenter] 
                        postNotificationName:SeqGrabChannelAddedNotification object:self
                        userInfo:
                            [NSDictionary dictionaryWithObject:vide 
                            forKey:SeqGrabChannelKey]];
                    [vide release];
                }
				break;
				
			case SGAudioMediaType:
				if (refCon == 0)
                {
					SGAudio * audi = 
                        [[SGAudio alloc] initWithSeqGrab:self channelComponent:c];
					[self addChannel:audi];
                    [[NSNotificationCenter defaultCenter] 
                        postNotificationName:SeqGrabChannelAddedNotification object:self
                        userInfo:
                            [NSDictionary dictionaryWithObject:audi forKey:SeqGrabChannelKey]];
                    [audi release];
                }
				break;
				
			case SoundMediaType:
			{
				// replace the 'soun' channel with an 'audi' channel.
				UserData sounSettings;
				SGChannel newChan;
				
				SGGetChannelSettings(mSeqGrab, c, &sounSettings, 0);
				SGDisposeChannel(mSeqGrab, c);
				SGNewChannel(mSeqGrab, SGAudioMediaType, &newChan);
				SGSetChannelSettings(mSeqGrab, newChan, sounSettings, 0);
				goto startOver;
			}
				break;
				
			default:
				NSLog(@"[SeqGrab setSettings:] encountered an "
                        "unrecognized chan type - \"%.4s\"", (char*)&type);
		}
	}
	
bail:
    if (err)
    {
        SGSetSettings(mSeqGrab, savedUD, 0);
    }
    DisposeUserData(savedUD);
	DisposeHandle(hud);
	DisposeUserData(ud);
	return err;
}


/*________________________________________________________________________________________
*/

- (NSData *)settings
{
	OSStatus	err = noErr;
	UserData	ud = NULL;
	Handle		hud = NewHandle(0);
	NSData *	data = nil;
	
	BAILSETERR( SGGetSettings(mSeqGrab, &ud, 0) );
	BAILSETERR( PutUserDataIntoHandle(ud, hud) );

	data = [NSData dataWithBytes:*hud length:GetHandleSize(hud)];
bail:
	DisposeUserData(ud);
	DisposeHandle(hud);
	return data;
}

/*________________________________________________________________________________________
*/

- (void)setIdleFrequency:(UInt32)idlesPerSecond
{
    mIdlesPerSecond = idlesPerSecond;
}

/*________________________________________________________________________________________
*/

- (UInt32)idleFrequency
{
    return mIdlesPerSecond;
}

/*________________________________________________________________________________________
*/

- (OSStatus)setMaxRecordTime:(float)seconds
{
	return (SGSetMaximumRecordTime(mSeqGrab, (UInt32)((seconds * 60) + .5)) );
}

/*________________________________________________________________________________________
*/

- (void)idleTimer:(NSTimer*)timer
{
    OSStatus err = noErr;
    
    if (mStopRequested == YES)
    {
        [timer invalidate];
		[timer release];
    }
    else {
        err = SGIdle(mSeqGrab);
        if (err)
			[self stop];
    }
}

/*________________________________________________________________________________________
*/

- (void)startTimer
{                    
    UInt32 idlesPerSecond = mIdlesPerSecond;
    const UInt32 kDefaultAudioIdlesPerSecond = 10;
    const UInt32 kDefaultVideoIdlesPerSecond = 30;
    
        // don't forget to set a default idle frequency if none has been
        // specified by the app
    if (idlesPerSecond == 0)
    {
        idlesPerSecond = kDefaultAudioIdlesPerSecond;
        for (int i = 0; i < [mChans count]; i++)
        {
            if ( [[mChans objectAtIndex:i] isVideoChannel] )
            {
                idlesPerSecond = kDefaultVideoIdlesPerSecond;
                break;
            }
        }
    }
    
	NSTimer * t = [[NSTimer alloc] initWithFireDate:
                        [NSDate dateWithTimeIntervalSinceNow:1./(double)idlesPerSecond]
							interval:1./(double)idlesPerSecond 
							target:self 
							selector:@selector(idleTimer:) 
							userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSModalPanelRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSEventTrackingRunLoopMode];
    mStopRequested = NO;
}

/*________________________________________________________________________________________
*/

- (OSStatus)preview
{
	OSStatus err = noErr;
	
	if ([self isPreviewing])
		goto bail;
	else if ([self isRecording])
		[self stop];
    
	
	// save capture path and channel usage state, as we're going to temporarily change them
	// to fake SGStartPreview.  We're going to use SGStartRecord instead, because when
	// SGStartPreview is called, the SGDataProc does not fire, and we're using the data proc
	// for video preview
	[mSavedCapturePath release];
	mSavedCapturePath = [mCapturePath retain];
	mSavedCaptureFlags = mCaptureFlags;
	[mSavedChannelUsages removeAllObjects];
	
	for (int i = 0; i < [mChans count]; i++)
	{
		SGChan* curChan = [mChans objectAtIndex:i];
		long usage = [curChan usage];
		[mSavedChannelUsages addObject:[NSNumber numberWithLong:usage]];
		
        if ([curChan isAudioChannel])
		{
			if (usage & seqGrabPreview)
				usage |= seqGrabPlayDuringRecord;
			else
				usage &= ~seqGrabPlayDuringRecord;
		}
		[curChan setUsage:usage];
	}
	
        // setting the seqGrabDontMakeMovie flag will prevent the
        // sequence grabber from writing any data to disk
	[self setCapturePath:nil flags:seqGrabDontMakeMovie];
	
    [self startTimer];
	BAILSETERR( SGStartRecord(mSeqGrab) );
	mPreviewing = YES;
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (OSStatus)record
{
	OSStatus err = noErr;
	
	if ([self isRecording])
		goto bail;
		
	if ([self isPreviewing])
		[self stop];
	
    [self startTimer];
	BAILSETERR( SGStartRecord(mSeqGrab) );
	mRecording = YES;
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (OSStatus)stop
{
	OSStatus err = noErr;
	
	if ([self isStopped])
		goto bail;
    
	mStopRequested = YES;
	BAILSETERR( SGStop(mSeqGrab) );
	
	if (mPreviewing)
	{
		// put the channel usages back the way you found them
		for (int i = 0; i < [mChans count]; i++)
		{
			long savedUsage = [(NSNumber*)[mSavedChannelUsages objectAtIndex:i] longValue];
			[(SGChan*)[mChans objectAtIndex:i] setUsage:savedUsage];
		}
	}
	mRecording = NO;
	mPreviewing = NO;
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (OSStatus)pause
{
	OSStatus err = noErr;
	
	if ([self isPreviewing] || [self isRecording])
		BAILSETERR( SGPause(mSeqGrab, seqGrabPause) );
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (OSStatus)resume
{
	OSStatus err = noErr;
	if ([self isPreviewing] || [self isRecording])
		BAILSETERR( SGPause(mSeqGrab, seqGrabUnpause) );
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (BOOL)isStopped
{
	return ( ![self isPreviewing] && ![self isRecording] );
}

/*________________________________________________________________________________________
*/

- (BOOL)isRecording
{
	return mRecording;
}

/*________________________________________________________________________________________
*/

- (BOOL)isPreviewing
{
	return mPreviewing;
}

/*________________________________________________________________________________________
*/

- (BOOL)isPaused
{
	Byte paused = 0;
	
	if ([self isPreviewing] || [self isRecording])
		SGGetPause(mSeqGrab, &paused);
	return (paused & seqGrabPause);  
}

/*________________________________________________________________________________________
*/

@end

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

#import "WhackedTVController.h"
#import "WhackedDebugMacros.h"
#import "SGAudio.h"
#import "SGVideo.h"


#define kDefaultRecordPath		@"/Users/Shared/whacked.mov"

@implementation WhackedTVController

/*________________________________________________________________________________________
*/


/*________________________________________________________________________________________
*/

- (id)initWithPath:(NSString *)path
{
	long quickTimeVersion = 0;
	
	self = [super initWithWindowNibName:@"MIRCVideoRecord"];
	_captureDestination = [path retain];
		// WhackedTVController uses SGAudioChannel, which showed up in QT 7
    if (Gestalt(gestaltQuickTime, &quickTimeVersion) || 
        ((quickTimeVersion & 0xFFFFFF00) < 0x07008000))
    {
        NSRunAlertPanel(@"OsiriX", 
            @"Please upgrade to QuickTime 7 to capture Video", nil, nil, nil);
        [[NSApplication sharedApplication] terminate:nil];
    }
	
		// Make a Sequence Grabber
	mGrabber = [[SeqGrab alloc] init];
	[mGrabber setIdleFrequency:50];
    [[NSNotificationCenter defaultCenter] 
        addObserver:self selector:@selector(seqGrabChannelAdded:) 
        name:SeqGrabChannelAddedNotification object:mGrabber];
	[[NSNotificationCenter defaultCenter] 
        addObserver:self selector:@selector(seqGrabChannelRemoved:) 
        name:SeqGrabChannelRemovedNotification object:mGrabber];
	mVideoPreviewQuality = codecNormalQuality;
	mVideoPreviewFrameRate = 0.; // native
	return self;
}

- (void)windowDidLoad{
	[mCaptureToField setStringValue:[_captureDestination lastPathComponent]];
	[mCaptureToField setEditable:NO];
	//[self addVideoTrack:nil];
	//[self addAudioTrack:nil];
		
	NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.macrad.mircplugin"];
	NSString *path = [bundle pathForResource:@"MIRC Video Setting" ofType:@"data"];
	NSData *videoSettings = [NSData dataWithContentsOfFile:path];
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:videoSettings forKey:@"MIRCVideoSettings"]];
	NSData *blob = [[NSUserDefaults standardUserDefaults] dataForKey:@"MIRCVideoSettings"];
	[self restoreSettings:blob];
	[[[mTableView tableColumnWithIdentifier:@"Settings"] dataCell] 
					setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [[[mTableView tableColumnWithIdentifier:@"Remove"] dataCell] 
					setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
//	[mRecordPauseButton setEnabled:NO];
}

- (void)restoreSettings:(NSData *)settings{
	OSStatus err = [mGrabber setSettings:settings];
	
	if (err)
	{
		NSRunAlertPanel(@"OsiriX", 
			[NSString stringWithFormat:@"Trouble restoring settings (Error %ld)", err], 
			nil, nil, nil);
	}
	[mTableView reloadData];
	if ([[mGrabber channels] count])
		[mTableView selectRow:[[mGrabber channels] count] - 1 
			byExtendingSelection:NO];
	[mWhackedWindow makeFirstResponder:mTableView];
	
		[mGrabber preview];
	
	if ([[mGrabber channels] count] > 0)
		[mRecordPauseButton setEnabled:YES];
	else
		[mRecordPauseButton setEnabled:NO];
}

- (void)saveSettings{
	[[NSUserDefaults standardUserDefaults] setObject:[mGrabber settings] forKey:@"MIRCVideoSettings"];
}

- (BOOL)windowShouldClose:(id)sender{
	[previewWindow performClose:sender];
	//previewWindow = nil;
	return YES;
}

- (void)setPath:(NSString *)path{
	[_captureDestination release];
	_captureDestination = [path retain];
	[mCaptureToField setStringValue:[_captureDestination lastPathComponent]];
	[mCaptureToField setEditable:NO];
}

/*________________________________________________________________________________________
*/

- (void)dealloc
{
    //NSLog(@"[WhackedTVController dealloc] %p", self);
	[mGrabber release];
	[_captureDestination release];
	[previewWindow release];
	[super dealloc];
}



- (OSStatus)setCapturePath:(NSString *)path flags:(long)flags
{
	OSStatus err = noErr;
    BOOL isPreviewing = [mGrabber isPreviewing];
	
    if (isPreviewing)
        [mGrabber stop];
        
	BAILSETERR( [mGrabber setCapturePath:path flags:flags] );
    
    if (isPreviewing)
        [mGrabber preview];
    
bail:
	return err;
}

/*________________________________________________________________________________________
*/

- (IBAction)doChannelSettings:(id)sender
{
#pragma unused(sender)
	// this gets called when a settings button is pushed
	SGChan * sgchan = [[mGrabber channels] objectAtIndex:[mTableView clickedRow]];
   
	[mGrabber stop];
	[sgchan showSettingsDialog];
	[mGrabber preview];
	
	[self saveSettings];
	
}

/*________________________________________________________________________________________
*/

- (IBAction)removeChannel:(id)sender
{
#pragma unused(sender)
    int myIndex = [mTableView clickedRow];
    
	[mGrabber stop];
	SGChan* doomedChan = [[mGrabber channels] objectAtIndex:myIndex];
    if ([doomedChan isVideoChannel])
    {
        [[[(SGVideo*)doomedChan previewView] window] close];
    }
	[mGrabber removeChannel:doomedChan];
    if ([[mGrabber channels] count] > 0)
	{
		[mRecordPauseButton setEnabled:YES];
        [mGrabber preview];
	} 
	else {
		[mRecordPauseButton setEnabled:NO];
	}
		
	[mTableView reloadData];
}

/*________________________________________________________________________________________
*/

- (IBAction)setVideoPreviewFrameRate:(id)sender
{
    NSMenuItem * mi = (NSMenuItem*)sender;
    NSMenu * m = [mi menu];
    NSArray * items = [m itemArray];
	NSString * title = [mi title];
	int i;
	
	if ([title isEqualToString:@"Device Native"])
		mVideoPreviewFrameRate = 0.;
	else
		mVideoPreviewFrameRate = [title floatValue];
		
	// update all video channels
	for (i = 0; i < [[mGrabber channels] count]; i++)
	{
		SGChan * cur = [[mGrabber channels] objectAtIndex:i];
		if ([cur isVideoChannel])
			[(SGVideo*)cur setDesiredPreviewFrameRate:mVideoPreviewFrameRate];
	}
	
    for (i = 0; i < [items count]; i++)
    {
        NSMenuItem * curItem = [items objectAtIndex:i];
        if (mi == curItem)
            [curItem setState:NSOnState];
        else
            [curItem setState:NSOffState];
    }
}

/*________________________________________________________________________________________
*/

- (IBAction)setVideoPreviewQuality:(id)sender
{
    NSMenuItem * mi = (NSMenuItem*)sender;
    NSMenu * m = [mi menu];
    NSArray * items = [m itemArray];
	int i;
    CodecQ quality = [sender tag]; // tag is CodecQ

	[mGrabber stop];
	
	// update all video channels
	for (i = 0; i < [[mGrabber channels] count]; i++)
	{
		SGChan * cur = [[mGrabber channels] objectAtIndex:i];
		if ([cur isVideoChannel])
		{
			[(SGVideo*)cur setPreviewQuality:quality];
		}
	}
    
    for (i = 0; i < [items count]; i++)
    {
        NSMenuItem * curItem = [items objectAtIndex:i];
        if (mi == curItem)
            [curItem setState:NSOnState];
        else
            [curItem setState:NSOffState];
    }
	
    if ([[mGrabber channels] count] > 0)
        [mGrabber preview];
}

/*________________________________________________________________________________________
*/

- (int)numVideoChannels
{
	int i, count = 0;
	
	for (i = 0; i < [[mGrabber channels] count]; i++)
	{
		if ([[[mGrabber channels] objectAtIndex:i] isVideoChannel])
			count++;
	}
	
	return count;
}

/*________________________________________________________________________________________
*/

- (void)makePreviewWindowForSGVideo:(SGVideo*)vide
{
	// set up a preview window for the newly added video channel
	NSRect screenRect = [[mWhackedWindow screen] visibleFrame];
	NSRect windowRect = [vide previewBounds];
	int numVidChannels = [self numVideoChannels] - 1;

	
	if (windowRect.size.width == 0. || windowRect.size.height == 0.)
		windowRect = [vide srcVideoBounds];
	
	
	windowRect.origin.x = 
		screenRect.origin.x + (numVidChannels * 16);

	windowRect.origin.y = 
		screenRect.origin.y + screenRect.size.height 
		- windowRect.size.height - (numVidChannels * 22);

			
	// Here's where we create a window to hold 
	// the sgvideo object's preview view
	
	previewWindow = 
		[[NSWindow alloc] initWithContentRect:windowRect 
		styleMask:NSTitledWindowMask | NSClosableWindowMask | 
				  NSMiniaturizableWindowMask | NSResizableWindowMask
		backing:NSBackingStoreBuffered 
		defer:YES
		screen:[mWhackedWindow screen]];
		
		
	//[previewWindow setReleasedWhenClosed:YES];
	[previewWindow setReleasedWhenClosed:NO];

	
	[[previewWindow contentView] addSubview:[vide previewView]];
	
	[previewWindow setTitle:[vide summaryString]];
	
	[[vide previewView] setAutoresizingMask:
		NSViewWidthSizable | NSViewHeightSizable];

	[previewWindow makeKeyAndOrderFront:self];
}

/*________________________________________________________________________________________
*/

- (void)seqGrabChannelAdded:(NSNotification*)n
{
    SeqGrab * seqGrab = [n object];
    if ([seqGrab isEqualTo:mGrabber])
    {
        SGChan * chan = [[n userInfo] objectForKey:SeqGrabChannelKey];
        if (chan)
        {
			[mTableView reloadData];
			[mTableView selectRow:[[mGrabber channels] count] - 1 
				byExtendingSelection:NO];
				
            if ([chan isVideoChannel])
            {
				[self makePreviewWindowForSGVideo:(SGVideo*)chan];
            }
        }
    }
}

/*________________________________________________________________________________________
*/

- (void)seqGrabChannelRemoved:(NSNotification*)n
{
	SeqGrab * seqGrab = [n object];
    if ([seqGrab isEqualTo:mGrabber])
    {
        SGChan * chan = [[n userInfo] objectForKey:SeqGrabChannelKey];
        if (chan)
        {
			[mTableView reloadData];
			if ([[mGrabber channels] count] > 0)
				[mTableView selectRow:[[mGrabber channels] count] - 1 
					byExtendingSelection:NO];
				
            if ([chan isVideoChannel])
            {
				[[[(SGVideo*)chan previewView] window] close];
            }
        }
    }
}

/*________________________________________________________________________________________
*/

- (IBAction)addVideoTrack:(id)sender
{
#pragma unused(sender)
	if ([self numVideoChannels] < 1){
		[mGrabber stop];
		SGVideo * vide = [[SGVideo alloc] initWithSeqGrab:mGrabber];
		
		if (vide == nil)
		{
			NSRunAlertPanel(@"OsiriX ", 
				@"Couldn't create a video channel.  Check your video device connections and try again.",
				nil, nil, nil);
				
			if ( [[mGrabber channels] count] > 0)
				[mGrabber preview];
		}
		else {
			[vide setUsage:seqGrabPreview + seqGrabRecord + seqGrabPlayDuringRecord];
			
			[mGrabber preview];
			
			[mTableView reloadData];
			[mTableView selectRow:[[mGrabber channels] count] - 1 
				byExtendingSelection:NO];
			[mWhackedWindow makeFirstResponder:mTableView];
			
			[self makePreviewWindowForSGVideo:vide];
			
			[vide release]; // it was retained by its mGrabber
		}
		
		if ( [[mGrabber channels] count] > 0)
		{
			[mRecordPauseButton setEnabled:YES];
		}
	}
}

/*________________________________________________________________________________________
*/

- (IBAction)addAudioTrack:(id)sender
{
#pragma unused(sender)
	[mGrabber stop];
	SGAudio * audi = [[SGAudio alloc] initWithSeqGrab:mGrabber];
        // set the default preview volume very low to prevent 
        // feedback loop from microphone near speakers
    Float32 masterVolume = 0.05;
    NSString * prevDevice = nil;
    int i;
    
    if (audi != nil)
    {
			// Want to perform custom set-up on the audi channel?  Do it here.
		[audi setUsage:seqGrabPreview + seqGrabRecord + seqGrabPlayDuringRecord];

            // instead of just setting the master gain of the preview device very low,
            // first find out if there are any other audi channels using this
            // preview device.  If there are, retain their current volume
        [audi getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
                    id:kQTSGAudioPropertyID_DeviceUID 
                    size:sizeof(prevDevice) 
                    address:&prevDevice 
                    sizeUsed:NULL];
            
            
        for (i = 0; i < [[mGrabber channels] count]; i++)
        {
            SGChan * chan = [[mGrabber channels] objectAtIndex:i];
            if (chan != audi && [chan isAudioChannel])
            {
                NSString * tempDev = nil;
                [(SGAudio*)chan getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
                    id:kQTSGAudioPropertyID_DeviceUID 
                    size:sizeof(tempDev) 
                    address:&tempDev 
                    sizeUsed:NULL];
                    
                if ([prevDevice isEqualToString:tempDev])
                {
                    [(SGAudio*)chan getPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice 
                        id:kQTSGAudioPropertyID_MasterGain
                        size:sizeof(masterVolume) 
                        address:&masterVolume 
                        sizeUsed:NULL];
                        
                    [tempDev release];
                    break;
                }
                [tempDev release];
            }
        }
        
		[audi setPropertyWithClass: kQTPropertyClass_SGAudioPreviewDevice
								id: kQTSGAudioPropertyID_MasterGain
							  size: sizeof(Float32)
						   address: &masterVolume];
        
		
		[audi release]; // it was retained by its mGrabber

		[mTableView reloadData];
		[mTableView selectRow:[[mGrabber channels] count] - 1 
			byExtendingSelection:NO];
		[mWhackedWindow makeFirstResponder:mTableView];
	}
	else {
        NSRunAlertPanel(@"OsiriX", 
            @"Couldn't create an audio channel.  Check your audio device connections and try again.",
            nil, nil, nil);
    }
    
    if ( [[mGrabber channels] count] > 0)
	{
        [mGrabber preview];
		[mRecordPauseButton setEnabled:YES];
	}
    [prevDevice release];
}

/*________________________________________________________________________________________
*/

- (IBAction)recordPause:(id)sender
{
#pragma unused(sender)
	if ([mGrabber isRecording])
	{
		// pause/unpause
		
		if ([mGrabber isPaused])
		{
			[mGrabber resume];
			[mRecordPauseButton setTitle:@"Pause"];
		}
		else {
			[mGrabber pause];
			[mRecordPauseButton setTitle:@"Resume"];
		}
	}
	else {
		// record
	
		[mGrabber stop];
		
        // use the capture path set in mCaptureToField
        OSStatus err = [self setCapturePath:_captureDestination
                        flags:seqGrabToDisk | seqGrabDontPreAllocateFileSize];
                        
                        
        if (err == noErr)
        {
            // record!
            [mGrabber record];
            [mRecordPauseButton setTitle:@"Pause"];
            [mStopButton setEnabled:YES];
            
                // disable all ui that should not be touched during a record operation
            [mCaptureToField setEnabled:NO];
            [mBrowseButton setEnabled:NO];
            [mTableView setEnabled:NO];
            [mAddVideoButton setEnabled:NO];
            [mAddAudioButton setEnabled:NO];
        }
        else {
            NSRunAlertPanel(@"OsiriX", 
                [NSString stringWithFormat:@"Trouble setting capture path to \"%@\" (Error %ld)", 
                    _captureDestination, err], 
                nil, nil, nil);
			[mGrabber preview];
        }
	}
}

/*________________________________________________________________________________________
*/

- (IBAction)stop:(id)sender
{
#pragma unused(sender)
	if ([mGrabber isRecording])
	{
		OSStatus err = [mGrabber stop];
		[mRecordPauseButton setTitle:@"Record"];
		[mStopButton setEnabled:NO];
		
			// re-enable all the ui that we turned off when we started the record operation
		[mCaptureToField setEnabled:YES];
		[mBrowseButton setEnabled:YES];
		[mTableView setEnabled:YES];
		[mAddVideoButton setEnabled:YES];
		[mAddAudioButton setEnabled:YES];
		[mGrabber preview];
        
            // launch the movie in player if successful
        if (err == noErr)
        {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MIRCNewMovie" 
			object:self 
			userInfo:[NSDictionary dictionaryWithObject:_captureDestination forKey:@"moviePath"]];
  
        }
        else {
            NSRunAlertPanel(@"OsiriX Video", 
                [NSString stringWithFormat:@"Trouble ending record operation (Error %ld)", 
                    err], 
                nil, nil, nil);
        }
	}
	else
		NSBeep();
	
	return;
}

/*________________________________________________________________________________________
*/

// NSTableView data source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
#pragma unused(tableView)
	return [[mGrabber channels] count];
}

/*________________________________________________________________________________________
*/

- (id)tableView:(NSTableView *)tableView 
        objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
#pragma unused(tableView)
	SGChan	 * chan = [[mGrabber channels] objectAtIndex:row];
	NSString * identifier = [tableColumn identifier];
	
	if ([identifier isEqualToString:@"Type"])
	{
		if ([chan isAudioChannel])
			return @"Audio";
		else
			return @"Video";
	}
	else if ([identifier isEqualToString:@"Summary"])
	{	
		return [chan summaryString];
	}
		
	return nil;
}

/*________________________________________________________________________________________
*/

// we'll use the delegate table view method to show the video preview window (if it's been closed)

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
#pragma unused(tableView)
#pragma unused(tableColumn)
	
	SGChan * chan = [[mGrabber channels] objectAtIndex:row];
	
	if ([chan isVideoChannel])
	{
		NSView * previewView = [(SGVideo*)chan previewView];
		
		if ( [previewView window] )
		{
			// the previewView is already associated with a window, simply bring it to the front
			[[previewView window] makeKeyAndOrderFront:self];
		}
		else {
			// the previewView needs a window.
			[self makePreviewWindowForSGVideo:(SGVideo*)chan];
		}
	}
	return NO;
}

/*________________________________________________________________________________________
*/

- (void)saveSettingsPanelDidEnd:(NSSavePanel *)sheet 
        returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
#pragma unused(contextInfo)
    if (returnCode == NSOKButton)
    {
        NSString * file = [sheet filename];
        NSData * settings = [mGrabber settings];
        [settings writeToFile:file atomically:NO];
    }
}

/*________________________________________________________________________________________


- (IBAction)saveSettings:(id)sender
{
#pragma unused(sender)
    NSSavePanel * browsePanel = [NSSavePanel savePanel];
    [browsePanel setRequiredFileType:@"whacked"];
    [browsePanel setCanCreateDirectories:YES];
    [browsePanel setCanSelectHiddenExtension:YES];
    
    [browsePanel beginSheetForDirectory:
        [[mCaptureToField stringValue] stringByDeletingLastPathComponent]
        file:@"Saved Whacked Settings.whacked"
        modalForWindow:mWhackedWindow 
        modalDelegate:self 
        didEndSelector:
            @selector(saveSettingsPanelDidEnd:returnCode:contextInfo:)
        contextInfo:nil];
}

________________________________________________________________________________________


- (void)restoreSettingsPanelDidEnd:(NSSavePanel *)sheet 
        returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
#pragma unused(contextInfo)
    if (returnCode == NSOKButton)
    {
        NSString * file = [sheet filename];
        NSData * settings = [NSData dataWithContentsOfFile:file];
        OSStatus err = [mGrabber setSettings:settings];
        
        if (err)
        {
            NSRunAlertPanel(@"OsiriX Teaching File", 
                [NSString stringWithFormat:@"Trouble restoring settings (Error %ld)", err], 
                nil, nil, nil);
        }
        [mTableView reloadData];
		if ([[mGrabber channels] count])
			[mTableView selectRow:[[mGrabber channels] count] - 1 
				byExtendingSelection:NO];
        [mWhackedWindow makeFirstResponder:mTableView];
    }
    [mGrabber preview];
	
	if ([[mGrabber channels] count] > 0)
		[mRecordPauseButton setEnabled:YES];
	else
		[mRecordPauseButton setEnabled:NO];
}

*/





- (IBAction)close:(id)sender{
//	[NSApp endSheet:[self window]];
//	[[self window]  orderOut:self];
}

- (IBAction)showWindow:(id)sender{
	[super showWindow:sender];
	if (previewWindow)
		[previewWindow makeKeyAndOrderFront:self];
	[[self window] makeKeyAndOrderFront:self];	
}


@end

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import <Cocoa/Cocoa.h>

@class QTMovie;

@interface VoiceClipController : NSWindowController {
	BOOL _recording;
	BOOL _audioExists;
	NSImage *_recordImage; 
	NSString *_moviePath;
	QTMovie *_movie;

	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSButton *recordButton;
}


- (void)record;
- (void)reset;
- (void)stopRecording;
- (BOOL)path:(NSString *)path toFSRef:(FSRef *)ref;

- (BOOL)recording;
- (void)setRecording:(BOOL)recording;
- (BOOL)audioExists;
- (void)setAudioExists:(BOOL)audioExists;
- (NSImage *)recordImage;
- (void)setRecordImage:(NSImage *)recordImage;
- (QTMovie *)movie;
- (void)setMovie:(QTMovie *)movie;
- (BOOL)hidePlayerControls;
- (void)setHidePlayerControls:(BOOL)hide;

- (IBAction) recordAudio: (id)sender;



@end

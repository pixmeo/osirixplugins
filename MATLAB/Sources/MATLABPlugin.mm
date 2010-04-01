//
//  MATLABPlugin.mm
//  MATLAB Plugin
//
//  Created by Alessandro Volz on 12/21/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "MATLABPlugin.h"
#import "MATLAB.h"
#import <OsiriX Headers/NSPanel+N2.h>
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/DICOMExport.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/DicomImage.h>

@implementation MATLABPlugin

-(void)initPlugin {
	_lock = [[NSLock alloc] init];
	_series = [[NSMutableArray alloc] initWithCapacity:1];
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerTask:) userInfo:NULL repeats:YES];
}

-(void)dealloc {
	[_timer invalidate];
	[_lock release];
	[_series release];
	[super dealloc];
}

-(long)filterImage:(NSString*)menuName {
	BOOL isDirectory;
	if (![[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/MATLAB_R2008a/bin/maci" isDirectory:&isDirectory] || !isDirectory) {
		NSImage* icon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Icon" ofType:@"png"]];
		NSPanel* panel = [NSPanel alertWithTitle:@"MATLAB" message:@"This plugin expects MATLAB to be installed in /Applications/MATLAB_R2008a/ and no such installation was found." defaultButton:@"Ok" alternateButton:NULL icon:icon];
		[NSApp beginSheet:panel modalForWindow:[viewerController window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		[icon release];
		return 0;
	}
	
	DCMPix* dcm = [[viewerController imageView] curDCM];
	
	// matlab execution
	MATLAB* m = [[MATLAB alloc] init];
	[m putDCMPix:dcm name:@"dcm"];
	[m evalString:@"r = test(dcm)"];
	DCMPix* r = [m getDCMPix:@"r"];
	[NSThread sleepForTimeInterval:5];
	[m release];
	
	// import result to browser
	DICOMExport* de = [[DICOMExport alloc] init];
	[de setSourceFile:[dcm sourceFile]];
	[de setPixelData:(unsigned char*)[r fImage] samplesPerPixel:1 bitsPerSample:sizeof(float)*8 width:[r pwidth] height:[r pheight]];
	[de setSeriesDescription:[[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SeriesDescription"]];
	[de setSeriesNumber:35466];
	[de setSlope:[dcm slope]];
	[de setPixelSpacing:[dcm pixelSpacingX] :[dcm pixelSpacingY]];
	[de setSliceThickness:[dcm sliceThickness]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resultImported:) name:OsirixAddToDBNotification object:NULL];
	[de writeDCMFile:NULL];
	
	[de release];
	
	return 0;
}

-(void)resultImported:(NSNotification*)notification {
	NSArray* dicomImages = [[notification userInfo] objectForKey:@"OsiriXAddToDBArray"];
	for (DicomImage* di in dicomImages) {
		NSManagedObject* series = [di valueForKey:@"series"];
		if ([[series valueForKey:@"name"] isEqualToString:[[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:@"SeriesDescription"]]) {
			while (![_lock tryLock]) [NSThread sleepForTimeInterval:0.001];
			[_series addObject:series];
			[_lock unlock];
		}
	}
}

-(void)timerTask:(NSTimer*)timer {
	if ([_series count] && [_lock tryLock]) {
		for (NSManagedObject* series in _series) {
			BOOL shown = NO;
			for (NSManagedObject* s in [ViewerController getDisplayedSeries])
				if (s == series)
					shown = YES;
			if (!shown) {
				ViewerController* viewer = [[BrowserController currentBrowser] loadSeries:series :NULL :NO keyImagesOnly:NO];
				[viewer showWindow:self];
			}
		}
		
		[_series removeAllObjects];
		
		[_lock unlock];
	}
}

-(void)alertDidEnd:(NSWindow*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	[sheet close];
}

@end

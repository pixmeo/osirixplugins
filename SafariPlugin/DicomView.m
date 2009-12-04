//
//  DicomView.m
//  DICOMPlugIn
//
//  Created by Lance Pysher on 4/5/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "DicomView.h"
#import <OsiriX/DCM.h>
#import <WebKit/WebKit.h>
#import <QTKit/QTKit.h>

//#import "DCMPix.h"


@implementation DicomView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setPreservesAspectRatio:YES];
		[self setShowsResizeIndicator:YES];
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
   // NSLog(@"Draw Dicom image in Safari: %@", [[self image] description]);
}


+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments
{
    DicomView *dicomView = [[[self alloc] init] autorelease];
    [dicomView setArguments:arguments];
    return dicomView;
}

- (void)dealloc
{   
    [_arguments release];
    [super dealloc];
}

- (void)setArguments:(NSDictionary *)arguments
{
    [arguments copy];
    [_arguments release];
    _arguments = arguments;
}

- (void)webPlugInInitialize
{
 //   [self showController:YES adjustingSize:NO];
}

- (void)webPlugInStart
{
	if (!_loadedImage) {
		_loadedImage = YES;
		NSDictionary *webPluginAttributesObj = [_arguments objectForKey:WebPlugInAttributesKey];
		NSString *URLString = [webPluginAttributesObj objectForKey:@"src"];
		if (URLString != nil && [URLString length] != 0) {
			NSURL *baseURL = [_arguments objectForKey:WebPlugInBaseURLKey];
			NSURL *URL = [NSURL URLWithString:URLString relativeToURL:baseURL];
			NSData *data = [NSData dataWithContentsOfURL:URL];
			DCMObject *dcmObject = [DCMObject objectWithData:data decodingPixelData:NO];
			NSString *patient = [dcmObject attributeValueWithName:@"PatientsName"];
			if (!patient)
				patient = @"Unknown";
			
			NSString *studyDescription = [dcmObject attributeValueWithName:@"StudyDescription"];
			if (!studyDescription)
				studyDescription = @"";
			NSString *study = [NSString stringWithFormat:@"%@ - %@",  [dcmObject attributeValueWithName:@"StudyID"], studyDescription];
			NSString *seriesDescription = [dcmObject attributeValueWithName:@"SeriesDescription"];
			if (!seriesDescription)
				seriesDescription = @"";
			NSString *series = [NSString stringWithFormat:@"%@ - %@",  [dcmObject attributeValueWithName:@"SeriesNumber"], seriesDescription];
			NSString *path = [NSString stringWithFormat:@"%@/%@/%@", NSHomeDirectory(), @"Desktop", @"Safari DICOM"];
			BOOL isDir;
			// Need to remove "/" from strings first
			NSMutableString *mPatient = [[patient mutableCopy] autorelease];
			NSMutableString *mStudy = [[study mutableCopy] autorelease];
			NSMutableString *mSeries = [[series mutableCopy] autorelease];
			NSArray *array = [NSArray arrayWithObjects: mPatient, mSeries, mStudy, nil];
			NSEnumerator *enumerator = [array objectEnumerator];
			NSMutableString *string;
			while (string = [enumerator nextObject])
				[string replaceOccurrencesOfString:@"/" withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [string length])];
			
			
			if (!([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path isDirectory:&isDir] && isDir))
				[[NSFileManager defaultManager] createDirectoryAtPath:(NSString *)path attributes:nil];
				
			path = [NSString stringWithFormat:@"%@/%@", path, mPatient];
			if (!([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path isDirectory:&isDir] && isDir))
				[[NSFileManager defaultManager] createDirectoryAtPath:(NSString *)path attributes:nil];
				
			path = [NSString stringWithFormat:@"%@/%@", path, mStudy];
			if (!([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path isDirectory:&isDir] && isDir))
				[[NSFileManager defaultManager] createDirectoryAtPath:(NSString *)path attributes:nil];
				
			path = [NSString stringWithFormat:@"%@/%@", path, mSeries];
			if (!([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path isDirectory:&isDir] && isDir))
				[[NSFileManager defaultManager] createDirectoryAtPath:(NSString *)path attributes:nil];
				
			path = [NSString stringWithFormat:@"%@/%@", path, [URLString lastPathComponent]];
			
			NSString *basePath = [path stringByDeletingPathExtension];
			
			int frameNumber = [[dcmObject attributeValueWithName:@"NumberofFrames"] intValue];
			if (frameNumber == 0)
				frameNumber =1;
			int i = 0;
			
			NSSize size;
			long long timeValue = 30;
			long timeScale = 600;
			QTTime curTime = QTMakeTime(timeValue, timeScale);
			// when adding images we must provide a dictionary
			// specifying the codec attributes
			NSDictionary *myDict = [NSDictionary dictionaryWithObjectsAndKeys:@"mp4v",
									QTAddImageCodecType,
									[NSNumber numberWithLong:codecHighQuality],
									QTAddImageCodecQuality,
									nil];
			size.height = [[dcmObject attributeValueWithName:@"Rows"] floatValue];
			size.width = [[dcmObject attributeValueWithName:@"Columns"] floatValue];
			
			OSErr err;
			// create a QuickTime movie
			Movie qtMovie = [self quicktimeMovieFromTempFile:&mDataHandlerRef error:&err];
			//if (nil == qtMovie) goto bail;
	
			// instantiate a QTMovie from our QuickTime movie
			QTMovie *movie = [QTMovie movieWithQuickTimeMovie:qtMovie disposeWhenDone:YES error:nil];
						 
			[movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
			[movie setAttribute:[NSValue valueWithSize:size] forKey:QTMovieCurrentSizeAttribute];

			while ( i < frameNumber){
				NSImage *image = [(DCMPixelDataAttribute *)[dcmObject attributeWithName:@"PixelData"] imageAtIndex:i++ ww:0.0  wl:0.0];
				//[[image TIFFRepresentation] writeToFile:@"/dcm.tif" atomically:YES];
				
				[movie addImage:image 
				forDuration:curTime
				withAttributes:myDict];
				
			}
			
			NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
				forKey:QTMovieFlatten];
			[movie writeToFile:@"/dcm.mov" withAttributes:dict];

			[self setMovie:movie];
			
			while ([[NSFileManager defaultManager] fileExistsAtPath:(NSString *)path])
				path = [NSString stringWithFormat:@"%@.%d.dcm", basePath, i++];
			
			[data writeToFile:path atomically:YES];

			[[NSWorkspace sharedWorkspace] openFile:path withApplication:@"OsiriX"];
		}
	}	
	[self setNeedsDisplay:YES];
	//[self play:self];

}

//
// quicktimeMovieFromTempFile
//
// Creates a QuickTime movie file from a temporary file
//
//

-(Movie)quicktimeMovieFromTempFile:(DataHandler *)outDataHandler error:(OSErr *)outErr
{
	*outErr = -1;
	
	// generate a name for our movie file
	NSString *tempName = [NSString stringWithCString:tmpnam(nil) 
							encoding:[NSString defaultCStringEncoding]];
	if (nil == tempName) goto nostring;
	
	Handle	dataRefH		= nil;
	OSType	dataRefType;

	// create a file data reference for our movie
	*outErr = QTNewDataReferenceFromFullPathCFString((CFStringRef)tempName,
												  kQTNativeDefaultPathStyle,
												  0,
												  &dataRefH,
												  &dataRefType);
	if (*outErr != noErr) goto nodataref;
	
	// create a QuickTime movie from our file data reference
	Movie	qtMovie	= nil;
	CreateMovieStorage (dataRefH,
						dataRefType,
						'TVOD',
						smSystemScript,
						newMovieActive, 
						outDataHandler,
						&qtMovie);
	*outErr = GetMoviesError();
	if (*outErr != noErr) goto cantcreatemovstorage;

	return qtMovie;

// error handling
cantcreatemovstorage:
	DisposeHandle(dataRefH);
nodataref:
nostring:

	return nil;
}


- (void)webPlugInStop
{
    //[self pause:self];
}

- (void)webPlugInDestroy
{
}

- (void)webPlugInSetIsSelected:(BOOL)isSelected
{
}

// Scripting support

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{

    return YES;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property
{

    return YES;
}

- (id)objectForWebScript
{
    return self;
}


@end

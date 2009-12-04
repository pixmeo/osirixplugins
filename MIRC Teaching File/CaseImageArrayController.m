//
//  CaseImageArrayController.m
//  TeachingFile
//
//  Created by Lance Pysher on 2/14/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "CaseImageArrayController.h"
#import "DCMView.h"
#import "DCMPix.h"
#import <QuartzCore/QuartzCore.h>
#import "ViewerController.h"
#import "WindowLayoutManager.h"
#import <OsiriX/DCM.h>
NSString *pasteBoardOsiriX = @"OsiriX pasteboard";


@implementation CaseImageArrayController

- (id)initWithCoder:(NSCoder *)decoder {
	if (self = [super initWithCoder:decoder]) {
		_addOrginalFormatImage = YES;
		_addAnnotatedImage = YES;
		_addOriginalDimensionImage = YES;
		_addOriginalDimensionAsMovie = NO;
	}
	return self;
}

- (void)awakeFromNib{
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects: pasteBoardOsiriX, nil]];
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    // Add code here to validate the drop
  
	
    return NSDragOperationEvery;    
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation{
	[self insertImageAtRow:row fromView:[info draggingSource]];	
	return YES;
}

- (void)insertImageAtRow:(int)row fromView: (DCMView *)vi {
	id newImage = [self newObject];


		// JPEG Image		
	NSImage *originalSizeImage = [vi nsimage:YES];
	NSBitmapImageRep *rep = (NSBitmapImageRep *)[originalSizeImage bestRepresentationForDevice:nil];
	NSData *jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		
	if (_addOriginalDimensionImage) {
		NSLog(@"add original Dimension");
		[newImage setValue:jpegData forKey: @"originalDimension"];
		[newImage setValue:@"jpg" forKey:@"originalDimensionExtension"];
	}

	//NSImage *thumbnail;
	NSData *tiff = [originalSizeImage TIFFRepresentation];
	// Convert to a CIImage
	CIImage  *ciImage    = [[CIImage alloc] initWithData:tiff];
	float width = [originalSizeImage size].width;
	float scale = 256.0/width;
	
	//create filter
	CIFilter *myFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
	[myFilter setDefaults];
	[myFilter setValue: ciImage forKey: @"inputImage"];  
	[myFilter setValue: [NSNumber numberWithFloat: scale]  
					forKey: @"inputScale"];
					
	//get scaled image
	CIImage *result = [myFilter valueForKey:@"outputImage"];
	NSCIImageRep *ciRep = [NSCIImageRep imageRepWithCIImage:result];
	NSImage *image = [[[NSImage alloc] init] autorelease];
	[image addRepresentation:ciRep];
	//convert to Tiff to get Bipmap and convert to jpeg
	NSImage *tn = [[[NSImage alloc] initWithData:[image TIFFRepresentation]] autorelease];
	rep = (NSBitmapImageRep *)[tn bestRepresentationForDevice:nil];
	jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
	[newImage setValue:jpegData forKey: @"thumbnail"];
	[newImage setValue:jpegData forKey: @"primary"];

	// Original Format
	// need to anonymize
	if (_addOrginalFormatImage) {
		NSString *originalImagePath = [[vi imageObj] valueForKey:@"completePath"];	
		[newImage setValue:[originalImagePath pathExtension] forKey:@"originalFormatExtension"];
		if ([[originalImagePath pathExtension] isEqualToString:@"dcm"]) {
				
				NSMutableArray *tags = [NSMutableArray array];
				[tags addObject:[DCMAttributeTag tagWithName:@"PatientsName"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"PatientsBirthDate"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"InstitutionName"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"StudyDate"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"SeriesDate"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"InstanceDate"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"ContentDate"]];
				[tags addObject:[DCMAttributeTag tagWithName:@"AcquisitionDate"]];
				DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:originalImagePath decodingPixelData:NO];
				NSEnumerator *enumerator = [tags objectEnumerator];
				DCMAttributeTag *tag;
				while (tag = [enumerator nextObject]) {
					[dcmObject anonyimizeAttributeForTag:(DCMAttributeTag *)tag replacingWith:nil];
				}
				DCMDataContainer *container = [DCMDataContainer dataContainer];
				[dcmObject writeToDataContainer:(DCMDataContainer *)container 
				withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]
				quality:1.0 
				asDICOM3:YES
				strippingGroupLengthLength:YES];
				//[DCMObject anonymizeContentsOfFile:path  tags:(NSArray *)tags  writingToFile:newJpegPath];
				[newImage setValue:[container dicomData]  forKey: @"originalFormat"];	
				
			}
			else {	
				NSData *originalFormatData = [NSData dataWithContentsOfFile:originalImagePath];
				[newImage setValue:originalFormatData forKey: @"originalFormat"];
			}
		}

	//Annotation
	if (_addAnnotatedImage) {;
		NSImage *annotationImage = [vi nsimage:NO];
		rep = (NSBitmapImageRep *)[annotationImage bestRepresentationForDevice:nil];
		jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		[newImage setValue:jpegData forKey: @"annotation"];
	}
	
	//insert image into array
	if (row < 0)
		row = 0;
	[newImage setValue:[NSNumber numberWithInt:[[self arrangedObjects] count]] forKey:@"index"];
	[self insertObject:newImage atArrangedObjectIndex:row];
}

- (IBAction)endSheet: (id)sender
{
    [NSApp endSheet:_imageImportPanel returnCode:[sender tag]];
}


/*
- (void)insertImageAtRow:(int)row fromView:(DCMView *)vi{
	NSDictionary *info = [[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:row], @"row" , vi, @"viewer", nil] retain];
	[NSApp beginSheet: _imageImportPanel
            modalForWindow: _window
            modalDelegate: self
            didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
            contextInfo: info];
}




- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
	if (returnCode == 1) {
		id newImage = [self newObject];
		int row = [[(NSDictionary *)contextInfo objectForKey:@"row"] intValue];
		id vi = [(NSDictionary *)contextInfo objectForKey:@"viewer"];
		

		// JPEG Image		
		NSImage *originalSizeImage = [vi nsimage:YES];
		NSBitmapImageRep *rep = (NSBitmapImageRep *)[originalSizeImage bestRepresentationForDevice:nil];
		NSData *jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			
		if (_addOriginalDimensionImage) {
			NSLog(@"add original Dimension");
			if (_addOriginalDimensionAsMovie) {
				// make movie
				id viewer = [vi windowController];
				//sheet runs modal.  Need to be able to wait for QT Movie before loading.  Hard to do.
				[viewer  exportQuicktime:self];
				//Need to add movie once it is made.
				_imageWaitingForMovie = newImage;
				[newImage setValue:@"mov" forKey:@"originalDimensionExtension"];
				[[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(newMovie:) name:@"OsiriXNewMovieSaved" object:nil];
			}
			else {
				[newImage setValue:jpegData forKey: @"originalDimension"];
				[newImage setValue:@"jpg" forKey:@"originalDimensionExtension"];
			}
		}

		//NSImage *thumbnail;
		NSData *tiff = [originalSizeImage TIFFRepresentation];
		// Convert to a CIImage
		CIImage  *ciImage    = [[CIImage alloc] initWithData:tiff];
		float width = [originalSizeImage size].width;
		float scale = 256.0/width;
		
		//create filter
		CIFilter *myFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
		[myFilter setDefaults];
		[myFilter setValue: ciImage forKey: @"inputImage"];  
		[myFilter setValue: [NSNumber numberWithFloat: scale]  
						forKey: @"inputScale"];
						
		//get scaled image
		CIImage *result = [myFilter valueForKey:@"outputImage"];
		NSCIImageRep *ciRep = [NSCIImageRep imageRepWithCIImage:result];
		NSImage *image = [[[NSImage alloc] init] autorelease];
		[image addRepresentation:ciRep];
		//convert to Tiff to get Bipmap and convert to jpeg
		NSImage *tn = [[[NSImage alloc] initWithData:[image TIFFRepresentation]] autorelease];
		rep = (NSBitmapImageRep *)[tn bestRepresentationForDevice:nil];
		jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
		[newImage setValue:jpegData forKey: @"thumbnail"];
		[newImage setValue:jpegData forKey: @"primary"];

		// Original Format
		// need to anonymize
		if (_addOrginalFormatImage) {
			NSString *originalImagePath = [[vi imageObj] valueForKey:@"completePath"];	
			[newImage setValue:[originalImagePath pathExtension] forKey:@"originalFormatExtension"];
			if ([[originalImagePath pathExtension] isEqualToString:@"dcm"]) {
					
					NSMutableArray *tags = [NSMutableArray array];
					[tags addObject:[DCMAttributeTag tagWithName:@"PatientsName"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"PatientsBirthDate"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"InstitutionName"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"StudyDate"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"SeriesDate"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"InstanceDate"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"ContentDate"]];
					[tags addObject:[DCMAttributeTag tagWithName:@"AcquisitionDate"]];
					DCMObject *dcmObject = [DCMObject objectWithContentsOfFile:originalImagePath decodingPixelData:NO];
					NSEnumerator *enumerator = [tags objectEnumerator];
					DCMAttributeTag *tag;
					while (tag = [enumerator nextObject]) {
						[dcmObject anonyimizeAttributeForTag:(DCMAttributeTag *)tag replacingWith:nil];
					}
					DCMDataContainer *container = [DCMDataContainer dataContainer];
					[dcmObject writeToDataContainer:(DCMDataContainer *)container 
					withTransferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax]
					quality:1.0 
					asDICOM3:YES
					strippingGroupLengthLength:YES];
					//[DCMObject anonymizeContentsOfFile:path  tags:(NSArray *)tags  writingToFile:newJpegPath];
					[newImage setValue:[container dicomData]  forKey: @"originalFormat"];	
					
				}
				else {	
					NSData *originalFormatData = [NSData dataWithContentsOfFile:originalImagePath];
					[newImage setValue:originalFormatData forKey: @"originalFormat"];
				}
			}

		//Annotation
		if (_addAnnotatedImage) {;
			NSImage *annotationImage = [vi nsimage:NO];
			rep = (NSBitmapImageRep *)[annotationImage bestRepresentationForDevice:nil];
			jpegData = [rep representationUsingType:NSJPEGFileType properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.9] forKey:NSImageCompressionFactor]];
			[newImage setValue:jpegData forKey: @"annotation"];
		}
		
		//insert image into array
		if (row < 0)
			row = 0;
		[newImage setValue:[NSNumber numberWithInt:[[self arrangedObjects] count]] forKey:@"index"];
		[self insertObject:newImage atArrangedObjectIndex:row];
	}
	[(NSDictionary *)contextInfo release];
}
*/

- (void)newMovie:(NSNotification *)note{
	NSLog(@"added Movie: %@", note);
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"OsiriXNewMovieSaved" object:nil];
	[_imageWaitingForMovie setValue:[NSData dataWithContentsOfFile:[[note userInfo] objectForKey:@"path"]] forKey:@"originalDimension"];
	NSAlert *alert = [NSAlert alertWithError:nil];
	[alert setInformativeText:NSLocalizedString(@"Movie Added", nil)];
	[alert setMessageText:NSLocalizedString(@"MIRC", nil)];
	[alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:nil contextInfo:nil];
	_imageWaitingForMovie = nil;
}

	
- (IBAction)addOrDelete:(id)sender{
	if ([sender selectedSegment] == 0) 
		[self selectCurrentImage:sender];
	else
		[self remove:sender];

}

- (IBAction)selectCurrentImage:(id)sender{
	// need to get current DCMView;
	NSWindowController  *viewer = [[WindowLayoutManager sharedWindowLayoutManager] currentViewer];
	[self insertImageAtRow:[[self arrangedObjects] count] fromView:[(ViewerController *)viewer imageView]];
}

- (int)tag{
	return 0;
}





@end

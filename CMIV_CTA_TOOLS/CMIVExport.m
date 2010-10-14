/*=========================================================================
Modified by: Chunliang Wang (chunliang.wang@imv.liu.se)



Program:   OsiriX

Copyright (c) OsiriX Team
All rights reserved.
Distributed under GNU - GPL

See http://www.osirix-viewer.com/copyright.html for details.

This software is distributed WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE.

=========================================================================*/

#import "CMIVExport.h"
#import "BrowserController.h"
#import "SRAnnotation.h"

#define VERBOSEMODE

@implementation CMIVExport
- (void) setSeriesDescription: (NSString*) desc
{
	if( desc != exportSeriesDescription)
	{
		[exportSeriesDescription release];
		exportSeriesDescription = [desc retain];
	}
}

- (void) setSeriesNumber: (long) no
{
	//If no == -1, take the value of source dcm
	exportSeriesNumber = no;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		dcmSourcePath = 0L;

		
		data = 0L;
		width = height = spp = bpp = 0;
		
		image = 0L;
		imageData = 0L;
		freeImageData = NO;
		imageRepresentation = 0L;
		
		ww = wl = -1;
		
		exportInstanceNumber = 0;
		exportSeriesNumber = 5000;
		
		DCMObject *dcmObject = [[[DCMObject alloc] init] autorelease];
		[dcmObject newSeriesInstanceUID];
		
		exportSeriesUID = [[dcmObject attributeValueWithName:@"SeriesInstanceUID"] retain];
		exportSeriesDescription = @"CMIV CTA TOOLs for OsiriX";
		[exportSeriesDescription retain];
		
		
		spacingX = 0;
		spacingY = 0;
		sliceThickness = 0;
		sliceInterval = 0;
		orientation[ 6] = 0;
		position[ 3] = 0;
		slicePosition = 0;
	}
	
	return self;
}

- (void) dealloc
{
	NSLog(@"DICOMExport released");
	
	// NSImage support
	[image release];
	[imageRepresentation release];
	if( freeImageData) free( imageData);
	
	[exportSeriesUID release];
	[exportSeriesDescription release];
	
	[dcmSourcePath release];
//	[dcmDst release];
	
	[super dealloc];
}

- (void) setSourceFile:(NSString*) isource
{
	[dcmSourcePath release];
	dcmSourcePath = [isource retain];
}

- (long) setPixelData:		(unsigned char*) idata
	   samplePerPixel:		(long) ispp
		 bitsPerPixel:		(long) ibpp
				width:				(long) iwidth
			   height:				(long) iheight
{
	spp = ispp;
	bpp = ibpp;
	width = iwidth;
	height = iheight;
	data = idata;
	
	return 0;
}

- (void) setDefaultWWWL: (long) iww :(long) iwl
{
	wl = iwl;
	ww = iww;
}

- (void) setPixelSpacing: (float) x :(float) y;
{
	spacingX = x;
	spacingY = y;
}

- (void) setSliceThickness: (float) t
{
	sliceThickness = t;
}

- (void) setOrientation: (float*) o
{
	long i;
	
	for( i = 0; i < 6; i++) orientation[ i] = o[ i];
}

- (void) setPosition: (float*) p
{
	long i;
	
	for( i = 0; i < 3; i++) position[ i] = p[ i];
}

- (void) setSlicePosition: (float) p
{
	slicePosition = p;
}
- (long) writeDCMFile: (NSString*) dstPath
{
	DCMObject			*dcmDst=nil;

	if( dstPath == 0L)
	{
		BOOL			isDir = YES;
		long			index = 0;
		NSString		*OUTpath = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/INCOMING.noindex"] ;

		if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
		
		do
		{
			dstPath = [NSString stringWithFormat:@"%@/%d", OUTpath, index];
			index++;
		}
		while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
	}

	if( width != 0 && height != 0 && data != 0L)
	{

		DCMCalendarDate		*acquisitionDate = [DCMCalendarDate date], *studyDate = 0L, *studyTime = 0L;

		NSString			*patientName = 0L, *patientID = 0L, *studyDescription = 0L, *studyUID = 0L, *studyID = 0L, *charSet = 0L;
		NSNumber			*seriesNumber = 0L;
		unsigned char		*squaredata = 0L;
		
		seriesNumber = [NSNumber numberWithInt:exportSeriesNumber];
		
		if( dcmSourcePath && [DicomFile isDICOMFile:dcmSourcePath])
		{
	
				dcmDst = [[DCMObject alloc] initWithContentsOfFile:dcmSourcePath decodingPixelData:NO];
				
		}
		else
		{
			return 1;
		}
		
		[dcmDst newSeriesInstanceUID ];
		[dcmDst newSOPInstanceUID];
		sopInstanceUID=[dcmDst attributeValueWithName:@"SOPInstanceUID"];
		DCMCalendarDate *seriesDate = acquisitionDate;
		DCMCalendarDate *seriestime = acquisitionDate;
		NSNumber *rows = [NSNumber numberWithInt: height];
		NSNumber *columns  = [NSNumber numberWithInt: width];

#if __BIG_ENDIAN__
		if( bpp == 16)
		{
			uint16_t* bigEndian= (uint16_t*)data;
			long size,itemp;
			size=height*width;
			for(itemp=0;itemp<size;itemp++)
				*(bigEndian+itemp)=CFSwapInt16HostToLittle(*(bigEndian+itemp));
			// the rest is to correct the potiential error caused by InverseShorts fuction (if size is not 8 times)
			int errint=size%8;
			for(itemp=1;itemp<=errint;itemp++)
				*(bigEndian+size-itemp)=0x0000;

			
			
		}
#endif
		
		NSMutableData *imageNSData = [[NSMutableData alloc] initWithBytesNoCopy: data length:height*width*spp*bpp/8 freeWhenDone:NO];
		NSString *vr;
		int highBit;
		int bitsAllocated;
		float numberBytes;
		BOOL isSigned;
		
		switch( bpp)
		{
			case 8:			
				highBit = 7;
				bitsAllocated = 8;
				numberBytes = 1;
				isSigned = NO;
			break;
			
			case 16:			
				highBit = 15;
				bitsAllocated = 16;
				numberBytes = 2;
				isSigned = NO;
			break;
			
			default:
				NSLog(@"Unsupported bpp: %d", bpp);
				return -1;
			break;
		}
		
		NSString *photometricInterpretation = @"MONOCHROME2";
		if (spp == 3) photometricInterpretation = @"RGB";
		

		
		//change attributes
		if( charSet) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:charSet] forName:@"SpecificCharacterSet"];
		if( studyUID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyUID] forName:@"StudyInstanceUID"];
		if( exportSeriesUID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[exportSeriesUID stringByAppendingString: [seriesNumber stringValue]]] forName:@"SeriesInstanceUID"];
		if( exportSeriesDescription) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:exportSeriesDescription] forName:@"SeriesDescription"];
		
		if( patientName) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:patientName] forName:@"PatientsName"];
		if( patientID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:patientID] forName:@"PatientID"];
		if( studyDescription) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyDescription] forName:@"StudyDescription"];
		[dcmDst setAttributeValues:nil forName:@"InstanceNumber"];
		if( seriesNumber) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriesNumber] forName:@"SeriesNumber"];
		if( studyID) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyID] forName:@"StudyID"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:@"OsiriX"] forName:@"ManufacturersModelName"];
		
		if( studyDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyDate] forName:@"StudyDate"];
		if( studyTime) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:studyTime] forName:@"StudyTime"];
		if( seriesDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriesDate] forName:@"SeriesDate"];
		if( seriestime) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:seriestime] forName:@"SeriesTime"];
		if( acquisitionDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:acquisitionDate] forName:@"AcquisitionDate"];
		if( acquisitionDate) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:acquisitionDate] forName:@"AcquisitionTime"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:exportInstanceNumber++]] forName:@"InstanceNumber"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:rows] forName:@"Rows"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:columns] forName:@"Columns"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:spp]] forName:@"SamplesperPixel"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:photometricInterpretation] forName:@"PhotometricInterpretation"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithBool:isSigned]] forName:@"PixelRepresentation"];
		
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:highBit]] forName:@"HighBit"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsAllocated"];
		[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:bitsAllocated]] forName:@"BitsStored"];
		
		if( spacingX != 0 && spacingY != 0)
		{
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:spacingY], [NSNumber numberWithFloat:spacingX], nil] forName:@"PixelSpacing"];
		}
		if( sliceThickness != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:sliceThickness]] forName:@"SliceThickness"];
		if( orientation[ 0] != 0 || orientation[ 1] != 0 || orientation[ 2] != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:orientation[ 0]], [NSNumber numberWithFloat:orientation[ 1]], [NSNumber numberWithFloat:orientation[ 2]], [NSNumber numberWithFloat:orientation[ 3]], [NSNumber numberWithFloat:orientation[ 4]], [NSNumber numberWithFloat:orientation[ 5]], nil] forName:@"ImageOrientationPatient"];
		if( position[ 0] != 0 || position[ 1] != 0 || position[ 2] != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:position[ 0]], [NSNumber numberWithFloat:position[ 1]], [NSNumber numberWithFloat:position[ 2]], nil] forName:@"ImagePositionPatient"];
		if( slicePosition != 0) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:slicePosition]] forName:@"SliceLocation"];
		if( spp == 3) [dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:0]] forName:@"PlanarConfiguration"];
		
		if( bpp == 16)
		{
			vr = @"OW";
			
			//By default, we use a 1024 rescale intercept !!
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:-1024]] forName:@"RescaleIntercept"];
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:1]] forName:@"RescaleSlope"];
			
			if( ww != -1 && ww != -1)
			{
				[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:wl]] forName:@"WindowCenter"];
				[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithInt:ww]] forName:@"WindowWidth"];
			}
		}
		else
		{
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:0]] forName:@"RescaleIntercept"];
			[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:[NSNumber numberWithFloat:1]] forName:@"RescaleSlope"];
			
			vr = @"OB";
		}
		
		//[dcmDst setAttributeValues:[NSMutableArray arrayWithObject:@"US"] forName:@"RescaleType"];
		
		//add Pixel data
		

		DCMTransferSyntax *ts;
		ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
		
		DCMAttributeTag *tag = [DCMAttributeTag tagWithName:@"PixelData"];
		DCMPixelDataAttribute *attr = [[DCMPixelDataAttribute alloc] initWithAttributeTag:tag 
										vr:vr 
										length:numberBytes
										data:nil 
										specificCharacterSet:nil
										transferSyntax:ts 
										dcmObject:dcmDst
										decodeData:NO];
		[attr addFrame:imageNSData];
		[imageNSData release];
		[dcmDst setAttribute:attr];
		[attr release];
		//[dcmDst writeToFile:dstPath withTransferSyntax:[DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax] quality:DCMLosslessQuality atomically:YES];
		NSMutableData *ourDicomData = [[NSMutableData alloc] init];
		DCMDataContainer* dcmcontainer=[[DCMDataContainer alloc] initWithData:ourDicomData transferSyntax:[DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] ];
		[ourDicomData release];

		if([dcmDst writeToDataContainer: dcmcontainer  withTransferSyntax: [DCMTransferSyntax ExplicitVRLittleEndianTransferSyntax] asDICOM3:YES])
		{

			unsigned char* tempbytes;
			tlength=[[dcmcontainer dicomData] length];
			tempbytes =(unsigned char* )[[dcmcontainer dicomData] bytes];
			memcpy(dicomFileData,tempbytes,tlength);

		}
		else
			tlength=0;
		//[[dcmcontainer dicomData] release];
		[dcmcontainer release];

		[[dcmDst attributes] removeAllObjects];
		
		if( squaredata)
		{
			free( squaredata);
		}
		squaredata = 0L;
		//if(dcmDst)
		[dcmDst release];
		
		return 0;
	}
	else return -1;
}
- (void) exportCurrentSeries:(ViewerController *)originalViewController
{

	NSArray *fileList = [originalViewController fileList]; 
	NSArray	*pixList = [originalViewController pixList];
	NSArray *roiList = [originalViewController roiList];
	unsigned int ii;
	float* inputData=[originalViewController volumePtr:0];
	float o[ 9];
	DCMPix			*curPix = [[originalViewController imageView] curDCM];
	width=[curPix pwidth];
	height=[curPix pheight];
	int maxImgSize=width*height;
	for(ii=0;ii<[pixList count];ii++)
	{
		curPix=[pixList objectAtIndex:ii];
		if([curPix pwidth]*[curPix pheight]>maxImgSize)
		{
			maxImgSize=[curPix pwidth]*[curPix pheight];
		}
		
	}
	spp=1;
	bpp=16;	
	vImage_Buffer	srcf, dst8;
				
	data=(unsigned char	*)malloc(maxImgSize*spp*bpp/8);
	dicomFileData=(unsigned char	*)malloc(maxImgSize*spp*bpp/8+100000);

	tempuint= (unsigned int*) data;
	
	
	NSString		*temppath = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/TEMP"] ;
	NSString		*OUTpath = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/INCOMING.noindex"] ;
	NSString		*roifolderpath = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/ROIs"] ;
	BOOL			isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:temppath isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:temppath attributes:nil];
	isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:OUTpath isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:OUTpath attributes:nil];
	isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:roifolderpath isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:roifolderpath attributes:nil];
	NSManagedObject* fakeDicomImage=[fileList objectAtIndex:0];
	
	NSManagedObject* study = [fakeDicomImage valueForKeyPath:@"series.study"];
	
	NSString* backupSOPIns=[[fakeDicomImage valueForKey:@"sopInstanceUID"] retain];
	NSNumber* backupInsNum=[[fakeDicomImage valueForKey:@"instanceNumber"] retain];
	
	
	if(data&&fileList&&originalViewController)
	{
		id waitWindow = [originalViewController startWaitWindow:@"writing to disk..."];	
		NSMutableArray* addedROIFiles=[[NSMutableArray alloc] initWithCapacity:0];

		for(ii=0;ii<[fileList count];ii++)
		{	
			NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
						long	err;
			curPix=[pixList objectAtIndex: ii];
			
			width=[curPix pwidth];
			height=[curPix pheight];
			srcf.height = height;
			srcf.width = width;
			srcf.rowBytes = width * sizeof( float);
			srcf.data = [curPix fImage];
			
			dst8.height =  height;
			dst8.width = width;
			dst8.rowBytes = width * sizeof( short);
			dst8.data = data;
			

			
			
			vImageConvert_FTo16U( &srcf, &dst8, -1024,  1, 0);	//By default, we use a 1024 rescale intercept !!
			[self setSourceFile: [[fileList objectAtIndex:ii] valueForKey:@"completePath"]];
			
			

			[self setPixelSpacing: [curPix pixelSpacingX]:[curPix pixelSpacingY]];

			[self setSliceThickness: [curPix sliceThickness]];
			[self setSlicePosition: [curPix sliceLocation]];
			
			[curPix orientation: o];
			[self setOrientation: o];
			
			o[ 0] = [curPix originX];		o[ 1] = [curPix originY];		o[ 2] = [curPix originZ];
			[self setPosition: o];
			
			//[self setPixelData: data samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
			
			err = [self writeDCMFile: 0L];
			if( err)  NSRunCriticalAlertPanel( NSLocalizedString(@"Error", nil),  NSLocalizedString(@"Error during the creation of the DICOM File!", nil), NSLocalizedString(@"OK", nil), nil, nil);
			
			//[imageView setIndex:ii];
			//[imageView sendSyncMessage:1];
			//[imageView display];
			//[originalViewController adjustSlider];
			

			if(tlength)
			{
				long			index = 0;
				NSString *dstPath,*tempdstPath;
				do
				{
					tempdstPath = [NSString stringWithFormat:@"%@/%d", temppath, index];
					index++;
				}
				while( [[NSFileManager defaultManager] fileExistsAtPath:tempdstPath] == YES);
				
				index = 0;
				
				do
				{
					dstPath = [NSString stringWithFormat:@"%@/%d", OUTpath, index];
					index++;
				}
				while( [[NSFileManager defaultManager] fileExistsAtPath:dstPath] == YES);
					
				FILE* tempFile;
				tempFile= fopen([tempdstPath cString],"wb");
				fwrite(dicomFileData,sizeof(char),tlength,tempFile);
				fclose(tempFile);
				[[NSFileManager defaultManager] copyPath:tempdstPath  toPath:dstPath handler:nil];
				[[NSFileManager defaultManager] removeFileAtPath:tempdstPath handler:nil];
				if([[roiList objectAtIndex:ii] count])
				{
					tempdstPath=[NSString stringWithFormat:@"/%@ %d-%d.dcm",sopInstanceUID, [curPix ID], [curPix frameNo]];
					tempdstPath=[roifolderpath stringByAppendingPathComponent:tempdstPath];
					[fakeDicomImage setValue:sopInstanceUID forKey:@"sopInstanceUID"];
					[fakeDicomImage setValue:[NSNumber numberWithInt:[curPix ID]] forKey:@"instanceNumber"];
				
					NSString	*aROIpath = [SRAnnotation archiveROIsAsDICOM: [roiList objectAtIndex:ii]  toPath: tempdstPath forImage:fakeDicomImage ];
					if(aROIpath)
						[addedROIFiles addObject:aROIpath];
					else
						[addedROIFiles addObject:tempdstPath];//sometime aROIpath will be nil but the ROI is all right, donot know why
				}
				
			}
			[pool release];

		}

		[fakeDicomImage setValue:backupSOPIns forKey:@"sopInstanceUID"];
		[fakeDicomImage setValue:backupInsNum forKey:@"instanceNumber"];
		[backupSOPIns release];
		[backupInsNum release];
		free( data);
		free(dicomFileData);
		[[BrowserController currentBrowser] addFilesToDatabase: addedROIFiles];
		[addedROIFiles release];
		[[BrowserController currentBrowser] saveDatabase: 0L];
		[originalViewController endWaitWindow: waitWindow];
	}
}
-(NSString*)osirixDocumentPath
{
	char	s[1024];

	FSRef	ref;

	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASELOCATION"]==1)
	{
		NSString	*path;
		BOOL		isDir = YES;
		NSString* url=[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"];
		path = [url stringByAppendingPathComponent:@"/OsiriX Data"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
			return path;	
#ifdef VERBOSEMODE
		NSLog( @"incoming folder is url type");
#endif
	}


	if( FSFindFolder (kOnAppropriateDisk, kDocumentsFolderType, kCreateFolder, &ref) == noErr )
	{
		NSString	*path;
		BOOL		isDir = YES;
		
		FSRefMakePath(&ref, (UInt8 *)s, sizeof(s));

		path = [[NSString stringWithUTF8String:s] stringByAppendingPathComponent:@"/OsiriX Data"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
#ifdef VERBOSEMODE
		NSLog( @"incoming folder is default type");
#endif
		return path;// not sure if s is in UTF8 encoding:  What's opposite of -[NSString fileSystemRepresentation]?
	}

	else
		return nil;
	
}
- (NSString*)exportSeriesUID
{
	NSNumber			*seriesNumber = [NSNumber numberWithInt:exportSeriesNumber];
	return [exportSeriesUID stringByAppendingString: [seriesNumber stringValue]];
}
@end

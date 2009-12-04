//
// VolumeGeneratorFilter.m
// VolumeGenerator
//
// Created by Philippe Thevenaz on Tue May 6 2008.
//

#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMCalendarDate.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX/DCMPixelDataAttribute.h>
#import <OsiriX/DCMTransferSyntax.h>
#import <stdlib.h>
#import "BrowserController.h"
#import "DCMPix.h"
#import "DicomFile.h"
#import "DicomSeries.h"
#import "ViewerController.h"
#import "VolumeGeneratorController.h"
#import "VolumeGeneratorFilter.h"

/*==============================================================================
|	VolumeGeneratorFilter
\=============================================================================*/
@implementation VolumeGeneratorFilter

/*----------------------------------------------------------------------------*/
- (long int)filterImage
	: (NSString*) menuName
{ /* begin filterImage */

	/* variables */
	DCMAttributeTag
		*tag = nil;
	DCMObject
		*dcmDst = nil;
	DCMPixelDataAttribute
		*attr = nil;
	DCMTransferSyntax
		*ts = nil;
	NSArray
		*imagesDB = nil;
	NSAutoreleasePool
		*pool = [[NSAutoreleasePool alloc] init];
	NSDate
		*acquisitionDate = nil,
		*acquisitionTime = nil,
		*seriesDate = nil,
		*seriesTime = nil,
		*studyDate = nil,
		*studyTime = nil,
		*patientsBirthDate = nil;
	NSDateFormatter
		*dateFormatter = nil,
		*timeFormatter = nil;
	NSMutableArray
		*files = nil;
	NSString
		*accessionNumber = @"1",
		*dstPath = nil,
		*manufacturer = @"Osirix",
		*manufacturersModelName = @"v3.2",
		*patientsID = @"PTABvH",
		*patientsName = @"Paracelsus",
		*photometricInterpretation = @"MONOCHROME2",
		*referringPhysiciansName = @"Ἱπποκράτης (Hippocrates of Cos II)",
		*seriesDescription = @"Die große Wundarzney",
		*seriesInstanceUID = @"Ulm",
		*seriesNumber = @"4",
		*studyDescription = @"Opus paramirum",
		*studyID = @"Volumen Medicinæ Paramirum Theophrasti",
		*studyInstanceUID = @"de Medica Industria";
	VolumeGeneratorController
		*controller = nil;
	bool
		isMale = true;
	float
		orientation[] = {0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F},
		originX = 0.0F,
		originY = 0.0F,
		originZ = 0.0F,
		rescaleIntercept = 0.0F,
		rescaleSlope = 1.0F,
		voxelDimensionX = 0.5F,
		voxelDimensionY = 0.5F,
		voxelDimensionZ = 2.0F;
	int
		bitsAllocated = 16,
		bitsStored = 16,
		depth = 16,
		evenDepth = 0,
		evenHeight = 0,
		evenWidth = 0,
		height = 36,
		highBit = 15,
		orientationIndex = 2,
		samplesperPixel = 1,
		x = 0,
		y = 0,
		width = 64,
		z = 0;
	unsigned short
		*p = (unsigned short*)NULL,
		*volume = (unsigned short*)NULL;

	/* allocations */
	acquisitionDate = [NSDate date];
	if (acquisitionDate == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: acquisitionDate");
		return(-1L);
	}
	acquisitionTime = [NSDate date];
	if (acquisitionTime == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: acquisitionTime");
		return(-1L);
	}
	seriesDate = [NSDate dateWithString: @"1536-03-19 18:25:00 +0000"];
	if (seriesDate == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: seriesDate");
		return(-1L);
	}
	seriesTime = [NSDate dateWithString: @"1536-03-19 18:25:00 +0000"];
	if (seriesTime == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: seriesTime");
		return(-1L);
	}
	studyDate = [NSDate dateWithString: @"1531-06-14 13:47:00 +0000"];
	if (studyDate == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: studyDate");
		return(-1L);
	}
	studyTime = [NSDate dateWithString: @"1531-06-14 13:47:00 +0000"];
	if (studyTime == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: studyTime");
		return(-1L);
	}
	patientsBirthDate = [NSDate dateWithString: @"1493-12-17 00:00:00 +0000"];
	if (patientsBirthDate == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: patientsBirthDate");
		return(-1L);
	}
	dateFormatter = [
		[[NSDateFormatter alloc]
			initWithDateFormat: @"%Y%m%d"
			allowNaturalLanguage: NO
		]
		autorelease
	];
	if (dateFormatter == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: dateFormatter");
		return(-1L);
	}
	timeFormatter = [
		[[NSDateFormatter alloc]
			initWithDateFormat: @"%H%M%S.000000"
			allowNaturalLanguage: NO
		]
		autorelease
	];
	if (timeFormatter == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: timeFormatter");
		return(-1L);
	}
	controller = [
		[[VolumeGeneratorController alloc] init]
		autorelease
	];
	if (controller == nil) {
		[pool release];
		NSLog(@"Failed to allocate/initialize: controller");
		return(-1L);
	}

	/* settings */
	controller.width = width;
	controller.height = height;
	controller.depth = depth;
	controller.voxelDimensionX = voxelDimensionX;
	controller.voxelDimensionY = voxelDimensionY;
	controller.voxelDimensionZ = voxelDimensionZ;
	controller.originX = originX;
	controller.originY = originY;
	controller.originZ = originZ;
	[controller setMale: nil];
	controller.patientsName = patientsName;
	controller.patientsID = patientsID;
	controller.patientsBirthDate = patientsBirthDate;
	controller.accessionNumber = accessionNumber;
	controller.referringPhysiciansName = referringPhysiciansName;
	controller.studyDescription = studyDescription;
	controller.studyDate = studyDate;
	controller.studyTime = studyTime;
	controller.studyID = studyID;
	controller.studyInstanceUID = studyInstanceUID;
	controller.seriesDescription = seriesDescription;
	controller.seriesDate = seriesDate;
	controller.seriesTime = seriesTime;
	controller.seriesNumber = seriesNumber;
	controller.seriesInstanceUID = seriesInstanceUID;
	controller.acquisitionDate = acquisitionDate;
	controller.acquisitionTime = acquisitionTime;
	controller.manufacturer = manufacturer;
	controller.manufacturersModelName = manufacturersModelName;
	controller.orientationIndex = orientationIndex;
	controller.photometricInterpretation = photometricInterpretation;
	controller.samplesperPixel = samplesperPixel;
	controller.highBit = highBit;
	controller.bitsAllocated = bitsAllocated;
	controller.bitsStored = bitsStored;
	controller.rescaleIntercept = rescaleIntercept;
	controller.rescaleSlope = rescaleSlope;
	[NSApp runModalForWindow
		: [controller window]
	];
	if (controller.didCancel) {
		[pool release];
		return(0L);
	}
	width = controller.width;
	height = controller.height;
	depth = controller.depth;
	voxelDimensionX = controller.voxelDimensionX;
	voxelDimensionY = controller.voxelDimensionY;
	voxelDimensionZ = controller.voxelDimensionZ;
	originX = controller.originX;
	originY = controller.originY;
	originZ = controller.originZ;
	isMale = controller.isMale;
	patientsName = controller.patientsName;
	patientsID = controller.patientsID;
	patientsBirthDate = controller.patientsBirthDate;
	accessionNumber = controller.accessionNumber;
	referringPhysiciansName = controller.referringPhysiciansName;
	studyDescription = controller.studyDescription;
	studyDate = controller.studyDate;
	studyTime = controller.studyTime;
	studyID = controller.studyID;
	studyInstanceUID = controller.studyInstanceUID;
	seriesDescription = controller.seriesDescription;
	seriesDate = controller.seriesDate;
	seriesTime = controller.seriesTime;
	seriesNumber = controller.seriesNumber;
	seriesInstanceUID = controller.seriesInstanceUID;
	acquisitionDate = controller.acquisitionDate;
	acquisitionTime = controller.acquisitionTime;
	manufacturer = controller.manufacturer;
	manufacturersModelName = controller.manufacturersModelName;
	orientationIndex = controller.orientationIndex;
	photometricInterpretation = controller.photometricInterpretation;
	samplesperPixel = controller.samplesperPixel;
	highBit = controller.highBit;
	bitsAllocated = controller.bitsAllocated;
	bitsStored = controller.bitsStored;
	rescaleIntercept = controller.rescaleIntercept;
	rescaleSlope = controller.rescaleSlope;

	/* created volume MUST have even dimensions */
	evenWidth = ((width + 1) / 2) * 2;
	evenHeight = ((height + 1) / 2) * 2;
	evenDepth = ((depth + 1) / 2) * 2;
	/* conventions for orientation */
	switch (orientationIndex) {
		case 0: { //Axial
			orientation[0] = 1.0F;
			orientation[1] = 0.0F;
			orientation[2] = 0.0F;
			orientation[3] = 0.0F;
			orientation[4] = 1.0F;
			orientation[5] = 0.0F;
			break;
		}
		case 1: { //Coronal
			orientation[0] = 1.0F;
			orientation[1] = 0.0F;
			orientation[2] = 0.0F;
			orientation[3] = 0.0F;
			orientation[4] = 1.0F;
			orientation[5] = 0.0F;
			break;
		}
		case 2: { //Sagittal
			orientation[0] = 1.0F;
			orientation[1] = 0.0F;
			orientation[2] = 0.0F;
			orientation[3] = 0.0F;
			orientation[4] = 1.0F;
			orientation[5] = 0.0F;
			break;
		}
		default: {
			[pool release];
			NSLog(@"Invalid orientation Index");
			return(-1L);
		}
	}

	@try
	{
		volume = (unsigned short*)malloc(sizeof(unsigned short) * (size_t)(
			(long int)evenWidth * (long int)evenHeight * (long int)evenDepth));
		if (volume == (unsigned short*)NULL) {
			[pool release];
			NSLog(@"Unable to allocate: volume");
			return(-1L);
		}
		p = volume;
		for (z = 0; (z < evenDepth); z++) {
			for (y = 0; (y < evenHeight); y++) {
				for (x = 0; (x < evenWidth); x++) {
					*p++ = (unsigned short)((x + y + z) % 2);
				}
			}
		}
		p = (unsigned short)NULL;
		/* first we create some files for the DB */
		files = [NSMutableArray array];
		if (files == nil) {
			free(volume);
			volume = (unsigned short)NULL;
			[pool release];
			NSLog(@"Failed to allocate/initialize: files");
			return(-1L);
		}
		for (z = 0; (z < evenDepth); z++) {
			dcmDst = [DCMObject
				secondaryCaptureObjectWithBitDepth: 32
				samplesPerPixel: samplesperPixel
				numberOfFrames: depth
			];
			if (dcmDst == nil) {
				free(volume);
				volume = (unsigned short)NULL;
				[pool release];
				NSLog(@"Failed to allocate/initialize: dcmDst");
				return(-1L);
			}
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: (isMale) ? (@"M") : (@"F")
				]
				forName: @"PatientsSex"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: patientsName
				]
				forName: @"PatientsName"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: patientsID
				]
				forName: @"PatientID"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomDate: [dateFormatter stringFromDate: patientsBirthDate]
					]
				]
				forName: @"PatientsBirthDate"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: accessionNumber
				]
				forName: @"AccessionNumber"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: referringPhysiciansName
				]
				forName: @"ReferringPhysiciansName"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: studyDescription
				]
				forName: @"StudyDescription"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomDate: [dateFormatter stringFromDate: studyDate]
					]
				]
				forName: @"StudyDate"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomTime: [timeFormatter stringFromDate: studyTime]
					]
				]
				forName: @"StudyTime"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: studyID
				]
				forName: @"StudyID"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: studyInstanceUID
				]
				forName: @"StudyInstanceUID"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: seriesDescription
				]
				forName: @"SeriesDescription"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomDate: [dateFormatter stringFromDate: seriesDate]
					]
				]
				forName: @"SeriesDate"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomTime: [timeFormatter stringFromDate: seriesTime]
					]
				]
				forName: @"SeriesTime"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: seriesNumber
				]
				forName: @"SeriesNumber"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: seriesInstanceUID
				]
				forName: @"SeriesInstanceUID"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomDate: [dateFormatter stringFromDate: acquisitionDate]
					]
				]
				forName: @"AcquisitionDate"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [DCMCalendarDate
						dicomTime: [timeFormatter stringFromDate: acquisitionTime]
					]
				]
				forName: @"AcquisitionTime"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: manufacturer
				]
				forName: @"Manufacturer"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: manufacturersModelName
				]
				forName: @"ManufacturersModelName"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObjects: [NSNumber
						numberWithFloat: orientation[0]
					], [NSNumber
						numberWithFloat: orientation[1]
					], [NSNumber
						numberWithFloat: orientation[2]
					], [NSNumber
						numberWithFloat: orientation[3]
					], [NSNumber
						numberWithFloat: orientation[4]
					], [NSNumber
						numberWithFloat: orientation[5]
					], nil
				]
				forName: @"ImageOrientationPatient"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: photometricInterpretation
				]
				forName: @"PhotometricInterpretation"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: samplesperPixel
					]
				]
				forName: @"SamplesperPixel"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: highBit
					]
				]
				forName: @"HighBit"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: bitsAllocated
					]
				]
				forName: @"BitsAllocated"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: bitsStored
					]
				]
				forName: @"BitsStored"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithFloat: rescaleIntercept
					]
				]
				forName: @"RescaleIntercept"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithFloat: rescaleSlope
					]
				]
				forName: @"RescaleSlope"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: evenHeight
					]
				]
				forName: @"Rows"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: evenWidth
					]
				]
				forName: @"Columns"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObjects: [NSNumber
						numberWithFloat: voxelDimensionX
					], [NSNumber
						numberWithFloat: voxelDimensionY
					], nil
				]
				forName: @"PixelSpacing"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithFloat: voxelDimensionZ
					]
				]
				forName: @"SliceThickness"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithInt: z
					]
				]
				forName: @"InstanceNumber"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObjects: [NSNumber
						numberWithFloat: originX
					], [NSNumber
						numberWithFloat: originY
					], [NSNumber
						numberWithFloat: originZ + voxelDimensionZ * (float)z
					], nil
				]
				forName: @"ImagePositionPatient"
			];
			[dcmDst
				setAttributeValues: [NSMutableArray
					arrayWithObject: [NSNumber
						numberWithFloat: originZ + voxelDimensionZ * (float)z
					]
				]
				forName: @"SliceLocation"
			];
			ts = [DCMTransferSyntax ImplicitVRLittleEndianTransferSyntax];
			if (ts == nil) {
				free(volume);
				volume = (unsigned short)NULL;
				[pool release];
				NSLog(@"Failed to allocate/initialize: ts");
				return(-1L);
			}
			tag = [DCMAttributeTag
				tagWithName: @"PixelData"
			];
			if (tag == nil) {
				free(volume);
				volume = (unsigned short)NULL;
				[pool release];
				NSLog(@"Failed to allocate/initialize: tag");
				return(-1L);
			}
			attr = [
				[[DCMPixelDataAttribute alloc]
					initWithAttributeTag: tag
					vr: @"OW"
					length: (long int)evenHeight * (long int)evenWidth
					data: nil
					specificCharacterSet: nil
					transferSyntax: ts
					dcmObject: dcmDst
					decodeData: NO
				]
				autorelease
			];
			if (attr == nil) {
				free(volume);
				volume = (unsigned short)NULL;
				[pool release];
				NSLog(@"Failed to allocate/initialize: attr");
				return(-1L);
			}
			tag = nil;
			ts = nil;
			[attr
				addFrame: [NSMutableData
					dataWithBytes: volume + (ptrdiff_t)(
						(long int)evenHeight * (long int)evenWidth * (long int)z)
					length: (long int)evenHeight * (long int)evenWidth
						* (long int)sizeof(unsigned short)
				]
			];
			[dcmDst setAttribute: attr];
			dstPath = [NSString
				stringWithFormat: @"/tmp/%d.dcm", z
			];
			if (dstPath == nil) {
				free(volume);
				volume = (unsigned short)NULL;
				[pool release];
				NSLog(@"Failed to allocate/initialize: dstPath");
				return(-1L);
			}
			[[NSFileManager defaultManager]
				removeFileAtPath: dstPath
				handler: nil
			];
			[files addObject: dstPath];
			[dcmDst
				writeToFile: dstPath
				withTransferSyntax: [DCMTransferSyntax
					ImplicitVRLittleEndianTransferSyntax]
				quality: 0
				atomically: YES
			];
			dstPath = nil;
		}
		dcmDst = nil;
		free(volume);
		volume = (unsigned short)NULL;

		/* add this series to the db:
		files are copied or linked to the DB,
		depending on the Database Preferences*/
		imagesDB = [[BrowserController currentBrowser]
			addFilesAndFolderToDatabase: files
		];
		if (imagesDB == nil) {
			[pool release];
			NSLog(@"Failed to allocate/initialize: imagesDB");
			return(-1L);
		}
		files = nil;

		/* OPTIONAL: open this new series */
		[[BrowserController currentBrowser]
			findAndSelectFile: nil
			image: [imagesDB lastObject]
			shouldExpand: NO
		];
		imagesDB = nil;
		[[BrowserController currentBrowser]
			newViewerDICOM: self
		];
	}
	@catch (
		NSException *e
	) {
		if (volume != (unsigned short)NULL) {
			free(volume);
			volume = (unsigned short)NULL;
		}
		[pool release];
		NSLog(@"Exception in plugin VolumeGenerator: %@", e);
		return(-1L);
	}
	[pool release];
	return(0L);
} /* end filterImage */

/*----------------------------------------------------------------------------*/
- (void)initPlugin
{ /* begin initPlugin */
} /* end initPlugin */

@end
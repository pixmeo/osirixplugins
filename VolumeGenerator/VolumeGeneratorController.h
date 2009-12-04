#import <Cocoa/Cocoa.h>

@interface VolumeGeneratorController
	: NSWindowController
{
	NSDate
		*acquisitionDate,
		*acquisitionTime,
		*patientsBirthDate,
		*seriesDate,
		*seriesTime,
		*studyDate,
		*studyTime;
	NSString
		*accessionNumber,
		*manufacturer,
		*manufacturersModelName,
		*patientsID,
		*patientsName,
		*photometricInterpretation,
		*referringPhysiciansName,
		*seriesDescription,
		*seriesInstanceUID,
		*seriesNumber,
		*studyDescription,
		*studyID,
		*studyInstanceUID;
	bool
		didCancel,
		isMale;
	float
		originX,
		originY,
		originZ,
		rescaleIntercept,
		rescaleSlope,
		voxelDimensionX,
		voxelDimensionY,
		voxelDimensionZ;
	int
		bitsAllocated,
		bitsStored,
		depth,
		height,
		highBit,
		orientationIndex,
		samplesperPixel,
		width;
}

@property(copy, readwrite) IBOutlet NSDate
	*acquisitionDate,
	*acquisitionTime,
	*patientsBirthDate,
	*seriesDate,
	*seriesTime,
	*studyDate,
	*studyTime;
@property(copy, readwrite) IBOutlet NSString
	*accessionNumber,
	*manufacturer,
	*manufacturersModelName,
	*patientsID,
	*patientsName,
	*photometricInterpretation,
	*referringPhysiciansName,
	*seriesDescription,
	*seriesInstanceUID,
	*seriesNumber,
	*studyDescription,
	*studyID,
	*studyInstanceUID;
@property(readwrite) IBOutlet bool
	didCancel,
	isMale;
@property(readwrite) IBOutlet float
	originX,
	originY,
	originZ,
	rescaleIntercept,
	rescaleSlope,
	voxelDimensionX,
	voxelDimensionY,
	voxelDimensionZ;
@property(readwrite) IBOutlet int
	bitsAllocated,
	bitsStored,
	depth,
	height,
	highBit,
	orientationIndex,
	samplesperPixel,
	width;

- (IBAction)cancel
	: (id)sender;

- (IBAction)create
	: (id)sender;

- (id)init;

- (IBAction)setFemale
	: (id)sender;

- (IBAction)setMale
	: (id)sender;

@end

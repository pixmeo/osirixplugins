#import "VolumeGeneratorController.h"

/*==============================================================================
|	VolumeGeneratorController
\=============================================================================*/
@implementation VolumeGeneratorController

/*..............................................................................
	Methods
..............................................................................*/

@synthesize
	accessionNumber,
	acquisitionDate,
	acquisitionTime,
	bitsAllocated,
	bitsStored,
	depth,
	didCancel,
	height,
	highBit,
	isMale,
	manufacturer,
	manufacturersModelName,
	orientationIndex,
	originX,
	originY,
	originZ,
	patientsBirthDate,
	patientsID,
	patientsName,
	photometricInterpretation,
	referringPhysiciansName,
	rescaleIntercept,
	rescaleSlope,
	samplesperPixel,
	seriesDate,
	seriesDescription,
	seriesInstanceUID,
	seriesNumber,
	seriesTime,
	studyDate,
	studyDescription,
	studyID,
	studyInstanceUID,
	studyTime,
	voxelDimensionX,
	voxelDimensionY,
	voxelDimensionZ,
	width;

/*----------------------------------------------------------------------------*/
- (IBAction)cancel
	: (id)sender
{ /* begin cancel */
	didCancel = true;
	[NSApp stopModal];
	[self close];
} /* end cancel */

/*----------------------------------------------------------------------------*/
- (IBAction)create
	: (id)sender
{ /* begin create */
	didCancel = false;
	[NSApp stopModal];
	[self close];
} /* end create */

/*----------------------------------------------------------------------------*/
- (id)init
{ /* begin init */
	didCancel = true;
	self = [super initWithWindowNibName
		: @"VolumeGeneratorController"
	];
	return self;
} /* end init */

/*----------------------------------------------------------------------------*/
- (IBAction)setFemale
	: (id)sender
{ /* begin setFemale */
	isMale = false;
} /* end setFemale */

/*----------------------------------------------------------------------------*/
- (IBAction)setMale
	: (id)sender
{ /* begin setMale */
	isMale = true;
} /* end setMale */

@end

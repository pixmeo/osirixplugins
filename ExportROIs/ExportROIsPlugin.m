//
//  ExportROIsPlugin.m
//  ExportROIs
//
//  Copyright (c) 2005 Yuichi Matsuyama & Tatsuo Hiramatsu, Team Lampway.
//  All rights reserved.
//  Distributed under GNU - GPL
//

#import "ExportROIsPlugin.h"
#import <OsiriXAPI/Wait.h>
#import <OsiriXAPI/DCMPix.h>
#import "FileTypeSelector.h"

#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>

@implementation ExportROIsPlugin

#pragma mark -
#pragma mark Export ROIs

- (long) exportROIs
{
	FileTypeSelector *ftsel = [[FileTypeSelector alloc] init];
    
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"FileTypeSelector" bundle: thisBundle] autorelease];
    [nib instantiateWithOwner: ftsel topLevelObjects: nil];
    
	NSSavePanel *panel = [NSSavePanel savePanel];
	assert( panel != nil);
	
	[panel setAllowedFileTypes: nil];
	[panel setAccessoryView: ftsel.addPanel];
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    DicomSeries *series = viewerController.currentSeries;
    NSString *filename = [NSString stringWithFormat: @"%@-%@-%@", series.study.name, [dateFormatter stringFromDate: series.study.date], series.name];
    
	[panel beginSheetForDirectory:nil file:filename modalForWindow: [viewerController window] modalDelegate:self didEndSelector: @selector(endSavePanel:returnCode:contextInfo:) contextInfo: ftsel];
	
	return 0;
}

- (void) endSavePanel: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo
{
	EXPORT_FILE_TYPE fileType = FT_CSV;
	
	if(retCode != NSFileHandlingPanelOKButton)
        return;
	
	// get selected type
	FileTypeSelector *ftsel = (FileTypeSelector *) contextInfo;
    [ftsel autorelease];
    
	if([[ftsel csvRadio] state] == NSOnState)
    {
		fileType = FT_CSV;
	}
    else if ([[ftsel xmlRadio] state] == NSOnState)
    {
		fileType = FT_XML;
	}
    
	// prepare for final output
	NSMutableDictionary *seriesInfo = [[[NSMutableDictionary alloc] init] autorelease];
	NSMutableArray *imagesInSeries = [NSMutableArray arrayWithCapacity: 0];

	NSMutableString	*csvText = [NSMutableString stringWithCapacity: 100];
	[csvText appendFormat: @"ImageNo,RoiNo,RoiMean,RoiMin,RoiMax,RoiTotal,RoiDev,RoiName,RoiCenterX,RoiCenterY,RoiCenterZ,LengthCm,LengthPix,AreaPix2, AreaCm2,RoiType,NumOfPoints,mmX,mmY,mmZ,pxX,pxY,...%c", LF];
	
	NSMutableString *csvRoiPoints;
	
	// get array of arrray of ROI in current series
	NSArray *roiSeriesList = viewerController.roiList;
	
	// show progress
	Wait *splash = [[[Wait alloc] initWithString: @"Exporting ROIs..."] autorelease];
	[splash showWindow:viewerController];
	[[splash progress] setMaxValue: roiSeriesList.count];
    
    int copyIndex = viewerController.imageIndex;
	long ImageHeight = 0;
	long ImageWidth = 0;
    
	// walk through each array of ROI
	for( long i = 0; i < roiSeriesList.count; i++ )
    {
        [viewerController setImageIndex: i];
        
		// current DICOM pix
        DCMPix *pix = viewerController.imageView.curDCM;
		ImageHeight = pix.pheight;
		ImageWidth = pix.pwidth;
		
		// array of ROI in current pix
		NSArray *roiImageList = viewerController.imageView.curRoiList;

		NSMutableDictionary *imageInfo = [NSMutableDictionary dictionary];
		NSMutableArray *roisInImage = [NSMutableArray arrayWithCapacity: 0];

		// walk through each ROI in current pix
        long numROIs = roiImageList.count;
		for(long j = 0; j < numROIs; j++ )
        {
            for( int b = 0; b < 2; b++)
            {
                ROI *roi = [roiImageList objectAtIndex: j];
                
                if( b == 0)
                {
                    [roi setPix: pix];
                }
                else
                {
                    if( viewerController.imageView.blendingView)
                    {
                        DCMPix	*blendedPix = [[viewerController.imageView blendingView] curDCM];
                        
                        roi = [[roi copy] autorelease];
                        roi.pix = blendedPix;
                        roi.curView = viewerController.imageView.blendingView;
                        [roi setOriginAndSpacing: blendedPix.pixelSpacingX: blendedPix.pixelSpacingY :[DCMPix originCorrectedAccordingToOrientation: blendedPix]];
                    }
                    else roi = nil;
                }
                
                if( roi)
                {
                    NSString *roiName = [roi name];
                    
                    float mean = [roi mean], minv = [roi min], maxv = [roi max], total = [roi total], dev = [roi dev];
                    
                    // array of point in pix coordinate
                    NSMutableArray *roiPoints = [roi points];
                    
                    NSMutableDictionary *roiInfo = [NSMutableDictionary dictionary];
                    NSMutableArray *mmXYZ = [NSMutableArray array];
                    NSMutableArray *pixXY = [NSMutableArray array];
                    NSPoint roiCenterPoint;
                    
                    // calc center of the ROI
                    if([roi type] == t2DPoint)
                    {
                        // ROI has a bug which causes miss-calculating center of 2DPoint roi
                        roiCenterPoint = [[roiPoints objectAtIndex: 0] point];
                    } else {
                        roiCenterPoint = roi.centroid;
                    }
                    float clocs[3], locs[3];
                    [roi.pix convertPixX: roiCenterPoint.x pixY: roiCenterPoint.y toDICOMCoords: clocs];
                    NSString *roiCenter = [NSString stringWithFormat: @"(%f, %f, %f)", clocs[0], clocs[1], clocs[2]];
                    
                    float areaPix2 = 0, areaCm2 = 0, lengthCm = 0, lengthPix;
                    NSMutableDictionary	*dataString = [roi dataString];
                    NSMutableArray *dataValues = [roi dataValues];
                    
                    if( [dataString objectForKey:@"AreaPIX2"]) areaPix2 = [[dataString objectForKey:@"AreaPIX2"] floatValue];
                    if( [dataString objectForKey:@"AreaCM2"]) areaCm2 = [[dataString objectForKey:@"AreaCM2"] floatValue];
                    if( [dataString objectForKey:@"LengthCM"])
                        lengthCm = [[dataString objectForKey:@"LengthCM"] floatValue];
                    if( [dataString objectForKey:@"LengthPIX"])
                        lengthPix = [[dataString objectForKey:@"LengthPIX"] floatValue];
                        
                    long numCsvPoints = 0;
                    // walk through each point in the ROI
                    if(fileType == FT_CSV )
                        csvRoiPoints = [NSMutableString string];
                    
                    for(long k = 0; k < [roiPoints count]; k++ )
                    {
                        
                        MyPoint *mypt = [roiPoints objectAtIndex: k];
                        NSPoint pt = [mypt point];
                        
                        [roi.pix convertPixX: pt.x pixY: pt.y toDICOMCoords: locs];

                        [mmXYZ addObject: [NSString stringWithFormat: @"(%f, %f, %f)", locs[0], locs[1], locs[2]]];
        //				NSLog( @"ROI %d - %d (%@): %f, %f, %f", (int)i, (int)j, roiName, locs[0], locs[1], locs[2] );

                        //NSArray *pxXY = [NSArray arrayWithObjects: [NSNumber numberWithFloat: pt.x], [NSNumber numberWithFloat: pt.y]];
                        //[xyzInRoi addObject: xyz];
                        [pixXY addObject: [NSString stringWithFormat: @"(%f, %f)", pt.x, pt.y]];
                        
                        // add to csv
                        if(fileType == FT_CSV )
                        {
                            if(k > 0 ) [csvRoiPoints appendString: @","];
                            [csvRoiPoints appendFormat: @"%f,%f,%f,%f,%f", locs[0], locs[1], locs[2], pt.x, pt.y];
                            numCsvPoints++;
                        }
                    }
                    
                    if(fileType == FT_CSV )
                    {
                        [csvText appendFormat: @"%d,%d,%f,%f,%f,%f,%f,%c%@%c,%f,%f,%f,%f,%f,%f,%f,%d,%d,%@%c",
                         (int)i, (int)j, mean, minv, maxv, total, dev, DQUOTE, roiName, DQUOTE, clocs[0], clocs[1], clocs[2], lengthCm, lengthPix, areaPix2, areaCm2, (int)[roi type], (int)numCsvPoints, csvRoiPoints, LF];
                    }
                                
                    // roiInfo stands for a ROI
                    //   IndexInImage	: order in the pix (start by zero)
                    //   Name			: ROI name
                    //   Type			: ROI type (in integer)
                    //   Center			: center point of the ROI (in mm unit)
                    //   NumberOfPoints	: number of points
                    //   Point_mm		: array of point (x,y,z) in mm unit
                    //   Point_px		: array of point (x,y) in pixel unit
                    //   Point_value	: array of pixel values
                    [roiInfo setObject: [NSNumber numberWithLong: j] forKey: @"IndexInImage"];
                    [roiInfo setObject: [NSNumber numberWithFloat: mean] forKey: @"Mean"];
                    [roiInfo setObject: [NSNumber numberWithFloat: minv] forKey: @"Min"];
                    [roiInfo setObject: [NSNumber numberWithFloat: maxv] forKey: @"Max"];
                    [roiInfo setObject: [NSNumber numberWithFloat: total] forKey: @"Total"];
                    [roiInfo setObject: [NSNumber numberWithFloat: dev] forKey: @"Dev"];
                    [roiInfo setObject: roiName forKey: @"Name"];
                    [roiInfo setObject: [NSNumber numberWithFloat: lengthCm] forKey: @"LengthCm"];
                    [roiInfo setObject: [NSNumber numberWithFloat: lengthPix] forKey: @"LengthPix"];
                    [roiInfo setObject: [NSNumber numberWithFloat: areaPix2] forKey: @"AreaPix2"];
                    [roiInfo setObject: [NSNumber numberWithFloat: areaCm2] forKey: @"AreaCm2"];
                    [roiInfo setObject: [NSNumber numberWithLong: [roi type]] forKey: @"Type"];
                    [roiInfo setObject: roiCenter forKey: @"Center"];
                    [roiInfo setObject: [NSNumber numberWithLong: [roiPoints count]] forKey: @"NumberOfPoints"];
                    [roiInfo setObject: mmXYZ forKey: @"Point_mm"];
                    [roiInfo setObject: pixXY forKey: @"Point_px"];
                    [roiInfo setObject: dataValues forKey: @"Point_value"];
                    
                    [roisInImage addObject: roiInfo];
                }
            }
		}

		if (numROIs > 0) {
			// imageInfo stands for a DICOM pix
			//   ImageHeight    : height of the current DICOM Image
			//   ImageWidth     : width of the current DICOM Image
			//   ImageIndex		: order in the series (start by zero)
			//   ImageTotalNum  : total num of images in the series (start by 1)
			//   NumberOfROIs	: number of ROIs
			//   ROIs			: array of ROI

			[imageInfo setObject: [NSNumber numberWithLong: ImageHeight] forKey: @"ImageHeight"];
			[imageInfo setObject: [NSNumber numberWithLong: ImageWidth] forKey: @"ImageWidth"];
			[imageInfo setObject: [NSNumber numberWithLong: i] forKey: @"ImageIndex"];
			[imageInfo setObject: [NSNumber numberWithLong: roiSeriesList.count] forKey: @"ImageTotalNum"];
			[imageInfo setObject: [NSNumber numberWithLong: numROIs] forKey: @"NumberOfROIs"];
			[imageInfo setObject: roisInImage forKey: @"ROIs"];
		
			[imagesInSeries addObject: imageInfo];
		}
		
		[splash incrementBy: 1];
	}
	
	// seriesInfo stands for a series
	//   Images	: array of imageInfo, which contains array of ROI
	[seriesInfo setObject: imagesInSeries forKey: @"Images"];
	
	NSString *fname = sheet.URL.path;
    fname = [fname stringByDeletingPathExtension];
    
	if(fileType == FT_CSV)
    {
        fname = [fname stringByAppendingPathExtension: @"csv"];
        [[NSFileManager defaultManager] removeItemAtPath: fname error: nil];
        [csvText writeToFile: fname atomically: YES encoding: NSUTF8StringEncoding error: nil];

	}
    else
    {
        fname = [fname stringByAppendingPathExtension: @"xml"];
        [[NSFileManager defaultManager] removeItemAtPath: fname error: nil];
		[seriesInfo writeToFile: fname atomically: TRUE];
	}

	// hide progress
	[splash close];
    
    viewerController.imageIndex = copyIndex;
}

- (long) filterImage:(NSString*) menuName
{
	long ret = 0;
	
	if([menuName isEqualToString: @"Export ROIs"]) {

		ret = [self exportROIs];

	}
	
	return ret;
}

@end

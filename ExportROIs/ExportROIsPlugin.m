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
#import "FileTypeSelector.h"

@implementation ExportROIsPlugin

#pragma mark -
#pragma mark Export ROIs

- (long) exportROIs
{
	FileTypeSelector *ftsel = [ [ FileTypeSelector alloc ] init ];
	
	BOOL ret = [ NSBundle loadNibNamed: @"FileTypeSelector" owner: ftsel ];
	assert( ret );
	
	NSSavePanel *panel = [ NSSavePanel savePanel ];
	assert( panel != nil );
	
	[ panel setRequiredFileType: nil ];
	[ panel setAccessoryView: [ ftsel addPanel ] ];
	[ panel beginSheetForDirectory:nil file:nil modalForWindow: [ viewerController window ] modalDelegate:self didEndSelector: @selector(endSavePanel:returnCode:contextInfo:) contextInfo: ftsel ];
	
	return 0;
}

- (void) endSavePanel: (NSSavePanel *) sheet returnCode: (int) retCode contextInfo: (void *) contextInfo
{

	NSArray					*pixList = [viewerController pixList];
	long					i, j, k, numCsvPoints, numROIs;
	EXPORT_FILE_TYPE		fileType = FT_CSV;
	
	if ( retCode != NSFileHandlingPanelOKButton ) return;
	
	// get selected type
	FileTypeSelector *ftsel = (FileTypeSelector *) contextInfo;
	
	if ( [ [ ftsel csvRadio ] state ] == NSOnState ) {
		fileType = FT_CSV;
	} else if ( [ [ ftsel xmlRadio ] state ] == NSOnState ) {
		fileType = FT_XML;
	}
    
	// prepare for final output
	NSMutableDictionary		*seriesInfo = [ [ NSMutableDictionary alloc ] init ];
	NSMutableArray			*imagesInSeries = [ NSMutableArray arrayWithCapacity: 0 ];

	NSMutableString	*csvText = [ NSMutableString stringWithCapacity: 100 ];
	[ csvText appendFormat: @"ImageNo,RoiNo,RoiMean,RoiMin,RoiMax,RoiTotal,RoiDev,RoiName,RoiCenterX,RoiCenterY,RoiCenterZ,Length,Area,RoiType,NumOfPoints,mmX,mmY,mmZ,pxX,pxY,...%c", LF];
	
	NSMutableString *csvRoiPoints;
	
	// get array of arrray of ROI in current series
	NSArray *roiSeriesList = [ viewerController roiList ];
	
	// show progress
	Wait *splash = [ [ Wait alloc ] initWithString: @"Exporting ROIs..." ];
	[ splash showWindow:viewerController ];
	[ [ splash progress] setMaxValue: [ roiSeriesList count ] ];

	// walk through each array of ROI
	for ( i = 0; i < [ roiSeriesList count ]; i++ ) {
		
		// current DICOM pix
		DCMPix *pix = [pixList objectAtIndex: i];
		
		// array of ROI in current pix
		NSArray *roiImageList = [ roiSeriesList objectAtIndex: i ];

		NSMutableDictionary *imageInfo = [ [ NSMutableDictionary alloc ] init ];
		NSMutableArray		*roisInImage = [ NSMutableArray arrayWithCapacity: 0 ];

		// walk through each ROI in current pix
		numROIs = [ roiImageList count ];
		for ( j = 0; j < numROIs; j++ )
        {
			ROI *roi = [roiImageList objectAtIndex: j ];
			
            [roi setPix: pix];
            
			NSString *roiName = [ roi name ];
			
			float mean = 0, min = 0, max = 0, total = 0, dev = 0;
			
			[pix computeROI:roi :&mean :&total :&dev :&min :&max];
			
			// array of point in pix coordinate
			NSMutableArray *roiPoints = [ roi points ];
			
			NSMutableDictionary *roiInfo = [ [ NSMutableDictionary alloc ] init ];
			NSMutableArray *mmXYZ = [ NSMutableArray arrayWithCapacity: 0 ];
			NSMutableArray *pixXY = [ NSMutableArray arrayWithCapacity: 0 ];
			NSPoint roiCenterPoint;
			
			// calc center of the ROI
			if ( [ roi type ] == t2DPoint ) {
				// ROI has a bug which causes miss-calculating center of 2DPoint roi
				roiCenterPoint = [ [ roiPoints objectAtIndex: 0 ] point ];
			} else {
				roiCenterPoint = [ roi centroid ];
			}
			float clocs[3], locs[3];
			[ pix convertPixX: roiCenterPoint.x pixY: roiCenterPoint.y toDICOMCoords: clocs ];
			NSString *roiCenter = [ NSString stringWithFormat: @"(%f, %f, %f)", clocs[0], clocs[1], clocs[2] ];
			
			float area = 0, length = 0;
			NSMutableDictionary	*dataString = [roi dataString];
			NSMutableArray *dataValues = [roi dataValues];
			
			if( [dataString objectForKey:@"AreaCM2"]) area = [[dataString objectForKey:@"AreaCM2"] floatValue];
			if( [dataString objectForKey:@"AreaPIX2"]) area = [[dataString objectForKey:@"AreaPIX2"] floatValue];
			if( [dataString objectForKey:@"Length"]) length = [[dataString objectForKey:@"Length"] floatValue];
			
			// walk through each point in the ROI
			if ( fileType == FT_CSV ) {
				csvRoiPoints = [ NSMutableString stringWithCapacity: 100 ];
				numCsvPoints = 0;
			}
			for ( k = 0; k < [ roiPoints count ]; k++ ) {
				
				MyPoint *mypt = [ roiPoints objectAtIndex: k ];
				NSPoint pt = [ mypt point ];
				
				[ pix convertPixX: pt.x pixY: pt.y toDICOMCoords: locs ];

				[ mmXYZ addObject: [ NSString stringWithFormat: @"(%f, %f, %f)", locs[0], locs[1], locs[2] ] ];
//				NSLog( @"ROI %d - %d (%@): %f, %f, %f", (int)i, (int)j, roiName, locs[0], locs[1], locs[2] );

				//NSArray *pxXY = [ NSArray arrayWithObjects: [ NSNumber numberWithFloat: pt.x ], [ NSNumber numberWithFloat: pt.y ] ];
				//[ xyzInRoi addObject: xyz ];
				[ pixXY addObject: [ NSString stringWithFormat: @"(%f, %f)", pt.x, pt.y ] ];

				// add to csv
				if ( fileType == FT_CSV ) {
					if ( k > 0 ) [ csvRoiPoints appendString: @"," ];
					[ csvRoiPoints appendFormat: @"%f,%f,%f,%f,%f", locs[0], locs[1], locs[2], pt.x, pt.y ];
					numCsvPoints++;
				}
			}
			
			if ( fileType == FT_CSV ) {
				[ csvText appendFormat: @"%d,%d,%f,%f,%f,%f,%f,%c%@%c,%f,%f,%f,%f,%f,%d,%d,%@%c",
                 (int)i, (int)j, mean, min, max, total, dev, DQUOTE, roiName, DQUOTE, clocs[0], clocs[1], clocs[2], length, area, (int)[roi type], (int)numCsvPoints, csvRoiPoints, LF ];
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
			[ roiInfo setObject: [ NSNumber numberWithLong: j ] forKey: @"IndexInImage" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: mean ] forKey: @"Mean" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: min ] forKey: @"Min" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: max ] forKey: @"Max" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: total ] forKey: @"Total" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: dev ] forKey: @"Dev" ];
			[ roiInfo setObject: roiName forKey: @"Name" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: length ] forKey: @"Length" ];
			[ roiInfo setObject: [ NSNumber numberWithFloat: area ] forKey: @"Area" ];
			[ roiInfo setObject: [ NSNumber numberWithLong: [ roi type ] ] forKey: @"Type" ];
			[ roiInfo setObject: roiCenter forKey: @"Center" ];
			[ roiInfo setObject: [ NSNumber numberWithLong: [ roiPoints count ] ] forKey: @"NumberOfPoints" ];
			[ roiInfo setObject: mmXYZ forKey: @"Point_mm" ];
			[ roiInfo setObject: pixXY forKey: @"Point_px" ];
			[ roiInfo setObject: dataValues forKey: @"Point_value" ];
			
			[ roisInImage addObject: roiInfo ];
		}

		if (numROIs > 0) {
			// imageInfo stands for a DICOM pix
			//   ImageIndex		: order in the series (start by zero)
			//   NumberOfROIs	: number of ROIs
			//   ROIs			: array of ROI
			[ imageInfo setObject: [ NSNumber numberWithLong: i ] forKey: @"ImageIndex" ];
			[ imageInfo setObject: [ NSNumber numberWithLong: numROIs ] forKey: @"NumberOfROIs" ]; 
			[ imageInfo setObject: roisInImage forKey: @"ROIs" ];
		
			[ imagesInSeries addObject: imageInfo ];
		}
		
		[splash incrementBy: 1];
	}
	
	// seriesInfo stands for a series
	//   Images	: array of imageInfo, which contains array of ROI
	[ seriesInfo setObject: imagesInSeries forKey: @"Images" ];
	
	NSMutableString *fname = [ NSMutableString stringWithString: [ sheet filename ] ];
	if ( fileType == FT_CSV ) {

		[ fname appendString: @".csv" ];
		const char *str = [ csvText cStringUsingEncoding: NSASCIIStringEncoding ];
		NSData *data = [ NSData dataWithBytes: str length: strlen( str ) ];
		[ data writeToFile: fname atomically: YES ];

	} else {
	
		[ fname appendString: @".xml" ];
		[ seriesInfo writeToFile: fname atomically: TRUE ];
		[ seriesInfo release ];
	}

	// hide progress
	[splash close];
	[splash release];
}

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	long ret = 0;
	
	if ( [ menuName isEqualToString: @"Export ROIs" ] ) {

		ret = [ self exportROIs ];

	}
	
	return ret;
}

@end

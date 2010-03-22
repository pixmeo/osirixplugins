//
//  CardiacStatisticsFilter.m
//  CardiacStatistics
//
//  Copyright (c) 2010 StanislasRapacchi. All rights reserved.
//

#import "CardiacStatisticsFilter.h"

static		float					deg2rad = M_PI / 180.0f; 
//static name since I use them as markers for reference contours
static		NSString*				epiName = @"myEpiRoi";
static		NSString*				endoName = @"myEndoRoi";
static		NSString*				separatorName=@"mySeparator";
static		NSString*				sectorIDComments=@"CardiacStatistics";

@implementation CardiacStatisticsFilter

- (void) initPlugin
{
}

- (long) filterImage:(NSString*) menuName
{
	[NSBundle loadNibNamed:@"CardiacStatisticsPanel" owner:self];	
	
	//[NSApp beginSheet: mywindow modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	//init text info display
	[TextDisplayField setStringValue:(@"Click to init EPI and ENDO") ];
	
	//init number of segments and layers
	int nSegment = 6;
	
	[SectorNumberField setStringValue: [[NSNumber numberWithInt:nSegment] stringValue]];
	[LayersNumberField setStringValue: [[NSNumber numberWithInt: 1 ] stringValue]];
	
	clickCount=0;
	
	return 0;	
}

- (IBAction)endMyDialog:(id)sender
{
	[mywindow orderOut:sender];
    
    [NSApp endSheet:mywindow returnCode:[sender tag]];
    
	[mywindow close];
	
    if( [sender tag])   //User clicks Done Button
    {
		[self release];
		
		[[NSNotificationCenter defaultCenter] removeObserver:self];
	}
	
	return;
}

//-------
// Segment button action
//
// Makes sure Epi, Endo and RV-LV are defined
// Or else returns an error message
//
//-------

- (IBAction)SegmentInter:(id)sender
{
	
	RGBColor segColor;
	segColor.red = [[NSColor blueColor] redComponent] * 65535;
	segColor.blue =  [[NSColor blueColor] blueComponent] * 65535;
	segColor.green = [[NSColor blueColor] greenComponent] * 65535;
	
	//retrieve number of segments from input
	int nSegment = [[SectorNumberField stringValue] intValue] ;
	
	if (nSegment<4) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segment",nil),NSLocalizedString(@"Min segments number is 4.",nil), NSLocalizedString(@"OK",nil), nil,nil);
		nSegment = 4;
		[SectorNumberField setStringValue: [[NSNumber numberWithInt:nSegment] stringValue]];
		
	}
	
	NSMutableArray  *RoiSeriesList;
	NSMutableArray  *RoiImageList;
	
	ROI  *myEpiRoi, *myEndoRoi,*SegmentSep;
	
	NSPoint CenterPoint, RefPoint;
	float SegSepLength;
	float AngleIncrement = 360./nSegment;
	
	// All Rois contained in the current series
	RoiSeriesList = [viewerController roiList];
	
	// All Rois contained in the current image
	RoiImageList = [RoiSeriesList objectAtIndex: [[viewerController imageView] curImage]];
	
	NSMutableArray *tempRoiImageList = [self DeleteSectorsinRoiList:RoiImageList];
	[RoiImageList removeAllObjects];
	for(ROI* roi in tempRoiImageList)
	{
		[RoiImageList addObject:roi];
	}
	
	
	myEpiRoi = [self FindRoiByName:epiName];
	if(myEpiRoi == nil)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segment",nil),NSLocalizedString(@"Epi not found on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);
		return;
	}
	
	myEndoRoi = [self FindRoiByName:endoName];
	if(myEndoRoi == nil)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segment",nil),NSLocalizedString(@"Endo not found on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);
		return;
	}
	
	/// at this point both Rois found ///
	
	SegmentSep = [self FindRoiByName:separatorName];
	if(SegmentSep == nil)
	{
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segment",nil),NSLocalizedString(@"RV/LV not found on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);
		return;
	}
	
	NSMutableArray  *sepPoints = [SegmentSep points];
	
	CenterPoint =[[sepPoints objectAtIndex: 0] point];
	RefPoint =[[sepPoints objectAtIndex: 1] point];
	SegSepLength = sqrt( pow(CenterPoint.x-RefPoint.x,2)+ pow(CenterPoint.y-RefPoint.y,2) );
	
	//create layers between endo and epi
	int nLayers = [[LayersNumberField stringValue] intValue] ;
	if (nLayers<1 || nLayers>4) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Segment",nil),NSLocalizedString(@"From 1 to 4 layers authorized.",nil), NSLocalizedString(@"OK",nil), nil,nil);
		nLayers = 4;
		[SectorNumberField setStringValue: [[NSNumber numberWithInt:nLayers] stringValue]];
		
	}
	
	int lay ;	//layers counter
	NSMutableArray *ContourRois=[NSMutableArray array];
	float factor = 0.;
	
	for(lay=0;lay<(nLayers+1);lay++)
	{
		[ContourRois addObject: [self CreateROIbwnROI1andROI2: myEndoRoi : myEpiRoi: (1.-factor) : factor] ];
		
		//[RoiImageList addObject: [ContourRois objectAtIndex: lay]];
		
		factor += 1./nLayers;
	}
	//[RoiImageList addObject: [ContourRois objectAtIndex: nLayers+1]];
	
	//----------------//
	// create Segments
	//----------------//
	ROI* tempROI ;
	NSMutableArray *tempArray= [NSMutableArray array];
	
	int Segi=0;
	for(Segi=0; Segi < nSegment; Segi++)
	{
		for(lay=0;lay<(nLayers);lay++)
		{
			tempROI	= [self GetRoibtwRoiswithAngle: (ROI*)[ContourRois objectAtIndex: lay] : (ROI*)[ContourRois objectAtIndex: (lay+1)]: CenterPoint: RefPoint: AngleIncrement];
			
			[tempROI setColor:segColor];
			//set its name
			[tempROI setName: [NSString stringWithFormat:@"%@%d%@%d",
							   NSLocalizedString(@"Sector", nil),
							   Segi+1,
							   NSLocalizedString(@"_", nil),
							   lay+1]];
			// this is how I mark the sectors(so that their names are modifiable)
			tempROI.comments = sectorIDComments; 
			
			[tempArray addObject: tempROI];
			
			[RoiImageList addObject: tempROI];
			
		}
		//new ref point
		RefPoint = [self CreatePointfromPointandAngleandRadius: CenterPoint: RefPoint: -AngleIncrement : SegSepLength];
		
	}
	
	SectorArray = [tempArray copy];
	
	// We modified the view: OsiriX please update the display!
	[viewerController needsDisplayUpdate];
	[TextDisplayField setStringValue:[NSString stringWithFormat:@"%@ %d %@ ", NSLocalizedString(@"Created ", nil),nSegment,NSLocalizedString(@" sectors ", nil)]];
	
	SectorManagerController *manager = [[SectorManagerController alloc] initWithViewer: viewerController :SectorArray ];
	if( manager)
	{
		[manager showWindow:self];
		[[manager window] makeKeyAndOrderFront:self];
	}
	
	return;
	
}
//-------
// Function to delete sectors on current image
// 
//-------

-(IBAction) DeleteSectors:(id)sender
{
	
	NSMutableArray  *RoiSeriesList;
	NSMutableArray  *RoiImageList;
	
	// All Rois contained in the current series
	RoiSeriesList = [viewerController roiList];
	
	// All Rois contained in the current image
	RoiImageList = [RoiSeriesList objectAtIndex: [[viewerController imageView] curImage]];
	
	NSMutableArray *tempRoiImageList = [self DeleteSectorsinRoiList:RoiImageList];
	[RoiImageList removeAllObjects];
	for(ROI* roi in tempRoiImageList)
	{
		[RoiImageList addObject:roi];
	}
	
	[viewerController needsDisplayUpdate];
	
	return;
	
}
//-------
// Function to create a ROI between 2 ROIs within a given "cone"
//
//	!!this is the function used for creating each Sector	
//
// Returns a ROI (one Sector)
//-------

-(ROI*)GetRoibtwRoiswithAngle:(ROI*)myRoi1:(ROI*)myRoi2:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle
{
	//create output Roi
	ROI *outRoi = [viewerController newROI:tCPolygon];
	//get its points array
	NSMutableArray  *outPoints = [outRoi points];
	
	NSPoint tempPoint, prevPoint;
	long PointsInAngle = 15; //max num of points to add
	//angle resolution is gAngle/AngleResolution
	float tempAngle = 0;
	
	//initiate
	prevPoint = RefPoint;
	
	while(fabs(tempAngle) <= fabs(gAngle) )
	{
		tempPoint = [self GetPointfromRoiwithAngle: myRoi1: CenterPoint: RefPoint: tempAngle];
		tempAngle += gAngle/PointsInAngle;
		
		//if point found, x value > 0
		if( tempPoint.x	> 0 )
		{
			//add point
			[outPoints addObject: [viewerController newPoint: tempPoint.x : tempPoint.y]];
			prevPoint = tempPoint;
			
		}
	}
	
	prevPoint = [self GetPointfromRoiwithAngle: myRoi1: CenterPoint: RefPoint:gAngle];
	tempPoint = [self GetPointfromRoiwithAngle: myRoi2: CenterPoint: RefPoint:gAngle];
	
	//add point
	[outPoints addObject: [viewerController newPoint: 0.75*prevPoint.x+0.25*tempPoint.x : 0.75*prevPoint.y+0.25*tempPoint.y]];
	[outPoints addObject: [viewerController newPoint: 0.5*prevPoint.x+0.5*tempPoint.x : 0.5*prevPoint.y+0.5*tempPoint.y]];
	[outPoints addObject: [viewerController newPoint: 0.25*prevPoint.x+0.75*tempPoint.x : 0.25*prevPoint.y+0.75*tempPoint.y]];
	
	tempAngle -= gAngle/PointsInAngle;
	
	while(tempAngle >= 0)
	{
		tempPoint = [self GetPointfromRoiwithAngle: myRoi2: CenterPoint: RefPoint:tempAngle];
		tempAngle -= gAngle/PointsInAngle;
		
		//if point found
		if(tempPoint.x	> 0 )
		{
			//add point
			[outPoints addObject: [viewerController newPoint: tempPoint.x : tempPoint.y]];
			prevPoint = tempPoint;
		}
	}
	
	prevPoint = [self GetPointfromRoiwithAngle: myRoi1: CenterPoint: RefPoint:0];
	tempPoint = [self GetPointfromRoiwithAngle: myRoi2: CenterPoint: RefPoint:0];
	
	//add point
	[outPoints addObject: [viewerController newPoint: 0.25*prevPoint.x+0.75*tempPoint.x : 0.25*prevPoint.y+0.75*tempPoint.y]];
	[outPoints addObject: [viewerController newPoint: 0.5*prevPoint.x+0.5*tempPoint.x : 0.5*prevPoint.y+0.5*tempPoint.y]];
	[outPoints addObject: [viewerController newPoint: 0.75*prevPoint.x+0.25*tempPoint.x : 0.75*prevPoint.y+0.25*tempPoint.y]];
	
	return outRoi;
}
//-------
// Function to create an intermetiade ROI contour between 2 ROI contours
//	with relative factors
//	put simple : outputROI = factor1 * ROI1 + factor2 * ROI2
//
// Returns a ROI*
//-------

-(ROI*) CreateROIbwnROI1andROI2: (ROI*)ROI1: (ROI*)ROI2: (float)factor1: (float)factor2
{
	ROI *outputROI = [viewerController newROI:tCPolygon];
	NSMutableArray *outpoints = [outputROI points];
	
	NSPoint CenterPoint = [ROI1 centroid];
	NSPoint RefPoint = NSMakePoint(CenterPoint.x, CenterPoint.y + 10);
	float tx,ty;
	NSPoint epiPoint;
	NSPoint endoPoint;
	
	if(factor1==0 && factor2==0)
		return nil;
	
	float AngleStep = 2; //in degrees
	float Angle = -180;
	
	while( Angle < 180 )
	{
		
		endoPoint = [self GetPointfromRoiwithAngle: ROI1: CenterPoint: RefPoint: Angle];
		
		epiPoint = [self GetPointfromRoiwithAngle: ROI2: CenterPoint: RefPoint: Angle];
		
		tx = factor1 * endoPoint.x + factor2 * epiPoint.x;
		
		ty = factor1 * endoPoint.y + factor2 * epiPoint.y;
		
		[outpoints addObject:[viewerController newPoint: tx : ty]];		
		
		Angle += AngleStep;
		
		tx=0; ty=0;
		
	}
	
	return outputROI;
	
}
//-------
// Function to retrieve a point on a ROI given 
//	-a segment(2points: 1 center, 1 reference)
//	-and an angle to rotate from this segment
//
// Returns a NSPoint
//-------
-(NSPoint)GetPointfromRoiwithAngle:(ROI*)myRoi:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle
{
	
	NSPoint outPoint;
	
	NSMutableArray  *IRoiPoints = [myRoi splinePoints];
	
	long npt = [IRoiPoints count];
	long j=0;
	float oldMeasAngle=0;
	float newMeasAngle=0;
	NSPoint tempPoint;
	long minIndex = -1;
	
	//loop over all points
	for(j=0;j<npt;j++)
	{
		//get point
		tempPoint =	[[IRoiPoints objectAtIndex: j] point];
		
		//measure angle btwn ref, center and current point
		newMeasAngle=[self myAngle:RefPoint:CenterPoint:tempPoint];
		
		//if we are closer and close enough
		if( (fabs(newMeasAngle-gAngle) < fabs(oldMeasAngle-gAngle)) && fabs(newMeasAngle-gAngle) < 4 )
			minIndex= j;
		
		oldMeasAngle=newMeasAngle;
	}
	
	if(minIndex >= 0)
		outPoint = [[IRoiPoints objectAtIndex: minIndex] point];
	
	return outPoint;
}

-(NSPoint)CreatePointfromPointandAngleandRadius:(NSPoint)CenterPoint:(NSPoint)RefPoint:(float)gAngle:(float)gRadius
{
	NSPoint outPoint;
	
	float VectX = RefPoint.x-CenterPoint.x;
	float VectY = RefPoint.y-CenterPoint.y;
	float DistRefCent = sqrt(VectX*VectX+VectY*VectY);
	
	VectX /=DistRefCent;
	VectY /=DistRefCent;
	
	//convert angle from degree to radian
	gAngle *= deg2rad;
	
	outPoint.x = gRadius*(VectX*cos(gAngle)+VectY*sin(gAngle))+CenterPoint.x;
	
	outPoint.y = gRadius*(-VectX*sin(gAngle)+VectY*cos(gAngle))+CenterPoint.y;
	
	return outPoint;
	
}

- (NSMutableArray*)RetrieveSectorsinRoiList:(NSMutableArray*)RoiList
{
	//init output
	NSMutableArray *FoundSectorArray= [NSMutableArray array];
	
	for (ROI *roi in RoiList) {
		
		//try to find sectors ID in comments
		if([roi.comments rangeOfString:sectorIDComments].location != NSNotFound)
		{
			[FoundSectorArray addObject:roi];
			//This is a sector, we add it to the output
		}
	}
	
	if ([FoundSectorArray count]==0) {
		return nil;
	}
	
	return FoundSectorArray;
	
}
- (NSMutableArray*)DeleteSectorsinRoiList:(NSMutableArray*)RoiList
{
	//init output
	NSMutableArray *PurgedRoiImageList= [NSMutableArray array];
	
	for (ROI *roi in RoiList) {
		//try to find sectors ID in comments
		if([roi.comments rangeOfString:sectorIDComments].location == NSNotFound)
		{
			[PurgedRoiImageList addObject: roi];
		}
		//This is not a sector, we add it to the output
	}
	
	return PurgedRoiImageList;
	
}

/*-(void)CheckContoursModification: (NSNotification*) note
 {
 // could update the sectors from contour modification every x seconds?
 //
 // right now user has to click on Segment button again
 
 }*/

//----------------
// Generix functions : can find usefulness elsewhere
//----------------
-(ROI*) FindRoiByName:(NSString*) RoiName
{
	
	NSMutableArray  *RoiSeriesList;
	NSMutableArray  *RoiImageList;
	
	ROI *foundRoi = nil;
	
	// All Rois contained in the current series
	RoiSeriesList = [viewerController roiList];
	
	// All Rois contained in the current image
	RoiImageList = [RoiSeriesList objectAtIndex: [[viewerController imageView] curImage]];
	
	long i;
	for(i = 0; i < [RoiImageList count]; i++)
	{
		if( [[[RoiImageList objectAtIndex: i] name] isEqualToString: RoiName])
		{
			foundRoi = [RoiImageList objectAtIndex: i];
		}
	}
	
	return foundRoi;
	
}

-(ROI*) ResampleRoiSplinePoints:(ROI*)RoiIn
{
	return [self ResampleRoiSplinePoints: RoiIn :5];
}
-(ROI*) ResampleRoiSplinePoints:(ROI*)RoiIn:(long)PointsStep
{
	ROI *RoiOut = [RoiIn copy];
	
	NSMutableArray *splineInPoints = [RoiIn splinePoints];
	NSMutableArray *OutPoints = [RoiOut points];
	
	[OutPoints removeAllObjects];
	
	long i;
	for(i=0;i<[splineInPoints count];i=i+10)
	{
		[OutPoints addObject:[splineInPoints objectAtIndex:i]];
	}
	
	return RoiOut;
}

-(float)myAngle:(NSPoint) p2 :(NSPoint) p1 :(NSPoint) p3
{
	float 		ax,ay,bx,by;
	float		angle;
	float			px = 1, py = 1;
	
	// get viewer pixels
	DCMPix *curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
	
	if( [curPix pixelSpacingX] != 0 && [curPix pixelSpacingY] != 0)
	{
		px = [curPix pixelSpacingX];
		py = [curPix pixelSpacingY];
	}
	
	ax = p2.x*px - p1.x*px;
	ay = p2.y*py - p1.y*py;
	bx = p3.x*px - p1.x*px;
	by = p3.y*py - p1.y*py;
	
	//no necessary:
	//normalize 
	/*
	 float anorm = sqrt(ax*ax+ay*ay);
	 float bnorm = sqrt(bx*bx+by*by);
	 ax = ax/anorm;
	 ay = ay/anorm;
	 bx = bx/bnorm;
	 by = by/bnorm;
	 */
	
	if (ax == 0 && ay == 0) return 0;
	
	//get angle
	angle= (atan2(by,bx)-atan2(ay,ax))/ deg2rad;
	
	//make sure to output angle between -180 and 180¡
	if(fabs(angle)>180)
		angle =  ((angle < 0) ? 1 : -1)*(180-fmod(fabs(angle), 180));
	
	return angle;
}


//-------------
// MOUSE HANDLING
// Certainly not right
//
//-------------
- (IBAction)startTrackingMouse:(id)sender
{
	[NSCursor arrowCursor];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector: @selector(myMouseDown:)
			   name: @"mouseDown"
			 object: nil];

	clickCount = 0;
	
	[TextDisplayField setStringValue:(@"Click one EPI point") ];

	ROI *myEpiROI = [self FindRoiByName:epiName];
	if(myEpiROI != nil)
	{
		clickCount=1;
		
		ROI *myEndoROI = [self FindRoiByName:endoName];
		
		if(myEndoROI != nil)
		{
			clickCount=2;
			
			
			ROI *mySepROI = [self FindRoiByName:separatorName];
			
			if(mySepROI != nil)
			{
				NSRunCriticalAlertPanel(NSLocalizedString(@"Error",nil),NSLocalizedString(@"Epi, Endo and RVLV already on the image.",nil), NSLocalizedString(@"OK",nil), nil,nil);

				[self stopTrackingMouse];
				return;
				
			}
		}
		
	}
	
	return;
}

- (void)stopTrackingMouse
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[TextDisplayField setStringValue:(@"Now you can modify contours and segment") ];

	return;
	
}

-(void)myMouseDown:(NSNotification*)note
{
	float CIRCLERESOLUTION = 30;
	
	//retrieve clicked point
	NSPoint np; 
	np.x = [[[note userInfo] objectForKey:@"X"] intValue];
	np.y = [[[note userInfo] objectForKey:@"Y"] intValue];
	
	NSPoint pt= [[viewerController imageView] ConvertFromGL2GL:np toView:[viewerController imageView]];//	NSPoint _mousePoint = [[[theEvent window] contentView] convertPointFromBase:[[viewerController mouseDown:theEvent] locationInWindow]];
	
	NSPoint centerPoint;
	NSRect myRect;
	float radius;
	float			angle;
	int i ;
	// get viewer pixels
	DCMPix *curPix = [[viewerController pixList] objectAtIndex: [[viewerController imageView] curImage]];
	//create a circle
	ROI *myCircleROI = [[[ROI alloc] initWithType:tCPolygon:[curPix pixelSpacingX] :[curPix pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: curPix]] autorelease];
	// All Rois contained in the current series
	NSMutableArray* RoiSeriesList = [viewerController roiList];
	// All Rois contained in the current image
	NSMutableArray* RoiImageList = [RoiSeriesList objectAtIndex: [[viewerController imageView] curImage]];
	//get its points
	NSMutableArray *myCirclePoints=[myCircleROI points];
	RGBColor myRoiColor;
	
	switch (clickCount) {
		case 0:		// Epi point
			prevclickedPoint= pt;
			[TextDisplayField setStringValue:(@"Click the center of LV") ];
			clickCount ++;
			break;
		case 1:		// Center point
			centerPoint= NSMakePoint(pt.x, pt.y);
			//[InfoTextField setStringValue:@"Centerdefined"];
			
			//create a circle
			NSPoint EpiPoint = prevclickedPoint;
			myRect.origin.x=centerPoint.x;
			myRect.origin.y=centerPoint.y;
			radius = sqrt(pow(EpiPoint.x-centerPoint.x,2)+pow(EpiPoint.y-centerPoint.y,2));
			myRect.size.width=myRect.size.height=radius;
			
			[RoiImageList addObject:myCircleROI];
			
			for( i= 0; i < CIRCLERESOLUTION ; i++ )
			{
				angle = i * 2 * M_PI /CIRCLERESOLUTION;
				
				[myCirclePoints addObject: [viewerController newPoint: myRect.origin.x + myRect.size.width*cos(angle) : myRect.origin.y + myRect.size.height*sin(angle)]];
			}
			
			[myCircleROI setName:epiName];
			
			myRoiColor.red = [[NSColor redColor] redComponent] * 65535;
			myRoiColor.blue =  [[NSColor redColor] blueComponent] * 65535;
			myRoiColor.green = [[NSColor redColor] greenComponent] * 65535;
			
			[myCircleROI setColor: myRoiColor];
			
			// We modified the view: OsiriX please update the display!
			[viewerController needsDisplayUpdate];
			
			prevclickedPoint = np;
			clickCount ++;
			[TextDisplayField setStringValue:(@"Click one ENDO point") ];
			break;
			// Endo point
		case 2:
			centerPoint= prevclickedPoint;
			NSPoint EndoPoint = pt;
			//[InfoTextField setStringValue:@"Endo defined"];
			
			myRect.origin.x=centerPoint.x;
			myRect.origin.y=centerPoint.y;
			radius = sqrt(pow(EndoPoint.x-centerPoint.x,2)+pow(EndoPoint.y-centerPoint.y,2));
			myRect.size.width=myRect.size.height=radius;
			
			//create a circle
			[RoiImageList addObject:myCircleROI];
			
			for( i= 0; i < CIRCLERESOLUTION ; i++ )
			{
				angle = i * 2 * M_PI /CIRCLERESOLUTION;
				
				[myCirclePoints addObject: [viewerController newPoint: myRect.origin.x + myRect.size.width*cos(angle) : myRect.origin.y + myRect.size.height*sin(angle)]];
			}
			
			[myCircleROI setName:endoName];
			
			myRoiColor.red = [[NSColor greenColor] redComponent] * 65535;
			myRoiColor.blue =  [[NSColor greenColor] blueComponent] * 65535;
			myRoiColor.green = [[NSColor greenColor] greenComponent] * 65535;
			
			[myCircleROI setColor: myRoiColor];
			
			// We modified the view: OsiriX please update the display!
			[viewerController needsDisplayUpdate];
			
			clickCount ++;
			[TextDisplayField setStringValue:(@"Click RV-LV junction") ];

			break;
			//RV/LV junction
		case 3:
			centerPoint = prevclickedPoint;
			//init Segment		
			ROI *SegmentSep = [viewerController newROI:tMesure];
		
			NSPoint rvlvPoint = np;
			
			[SegmentSep setName: separatorName];
			
			myRoiColor.red = [[NSColor yellowColor] redComponent] * 65535;
			myRoiColor.blue =  [[NSColor yellowColor] blueComponent] * 65535;
			myRoiColor.green = [[NSColor yellowColor] greenComponent] * 65535;
			
			[SegmentSep setColor: myRoiColor];
			
			NSMutableArray  *sepPoints = [SegmentSep points];
			
			//add points
			[sepPoints addObject: [viewerController newPoint: centerPoint.x : centerPoint.y]];
			[sepPoints addObject: [viewerController newPoint: rvlvPoint.x : rvlvPoint.y]];
			
			// add it to the image Roi list
			[RoiImageList addObject: SegmentSep];
			
			clickCount = 0;
			[self stopTrackingMouse];
			break;
		default:
			break;
	}
	
	return;
}


@end

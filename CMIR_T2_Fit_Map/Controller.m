//
//  Controller.m
//  Mapping
//
//  Created by Antoine Rosset on Mon Aug 02 2004.
//  Copyright (c) 2004 OsiriX. All rights reserved.
//

//#include "math.h"

#import "PluginFilter.h"
#import "CMIR_T2_Fit_MapFilter.h"
#import "Controller.h"
#import "objc/runtime.h"

@implementation ControllerCMIRT2Fit

-(IBAction) endFill:(id) sender
{
    [fillWindow orderOut:sender];
    
    [NSApp endSheet:fillWindow returnCode:[sender tag]];
    
    if( [sender tag])   //User clicks OK Button
    {
		NSMutableArray		*pixList;
		long				i;
		
		pixList = [pixListArrays objectAtIndex: 0];
		
		if( [[fillMode selectedCell] tag] == TAG_FILL_INTERVAL)		// Interval
		{
			for( i = 0; i < [pixList count]; i++)
			{
				TEValues[ i] = ([startFill floatValue]+ i*[intervalFill floatValue]) / 1000.;
			}
		}
		else //Start - End
		{
			for( i = 0; i < [pixList count]; i++)
			{
				TEValues[ i] = ([startFill floatValue] + (i*([endFill floatValue] - [startFill floatValue]))/((float) ([pixList count]-1))) / 1000.;
			}
		}
		
		[TETable reloadData];
		
		[self refreshGraph: self];
    }
}

- (IBAction) startFill:(id) sender
{
    [NSApp beginSheet: fillWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

//10.08.2010 - (int)numberOfRowsInTableView:(NSTableView *)aTableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView //10.08.2010
{
	return [[pixListArrays objectAtIndex: 0] count];
//	return [[pixListArrays objectAtIndex: 0] count]*[pixListArrays count];
}

//10.08.2010 - (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if( [[aTableColumn identifier] isEqualToString:@"index"]) return [NSString stringWithFormat:@"%d", rowIndex+1];
	else return [NSString stringWithFormat:@"%2.2f", TEValues[ rowIndex] * 1000.];
}

-(void) computeLinearRegression:(long) n :(float*) xValues :(float*) yValues :(float*) b :(float*) m :(float*) rmean
{
	long	i;
	float	sumx, sumx2, sumxy, sumy, sumy2;
//	float   r;                                 // correlation coefficient
	float	nf;
	
	float	countExcludedSlices, excludeSlicesBelow;
	
	excludeSlicesBelow = [excludeSignal floatValue];
	if ([logScale state]) excludeSlicesBelow = exp(excludeSlicesBelow);
	countExcludedSlices = 0;

	sumx = sumx2 = sumxy = sumy = sumy2 = 0;
	
	for( i = 0; i < n; i++)
	{
		if (rmean[i] > excludeSlicesBelow) {
			sumx += xValues[i];
			sumx2 += xValues[i]*xValues[i];
			sumxy += xValues[i]*yValues[ i];
			sumy += yValues[ i];
			sumy2 += yValues[ i]*yValues[ i];
		} else {
			countExcludedSlices++;
		}
	}
	
//--------------------------------------------------------------------------
//  Compute least-squares best fit straight line.                            
//--------------------------------------------------------------------------

	nf = n - countExcludedSlices;
	
   *m = (nf * sumxy  -  sumx * sumy) /        // compute slope                 
       (nf * sumx2 - sumx*sumx);

   *b = (sumy * sumx2  -  sumx * sumxy) /    // compute y-intercept           
       (nf * sumx2  -  sumx*sumx);

//   r = (sumxy - sumx * sumy / nf) /          // compute correlation coeff     
//            sqrt((sumx2 - (sumx*sumx)/nf) *
//            (sumy2 - (sumy*sumy)/nf));

}

- (id) roiIdentifier: (ROI*) roi
{
	return [roi name];
}

- (BOOL) roiIdentifierCompare: (ROI*) roi :(id) roiFromList
{
	return [[roi name]	isEqualToString: roiFromList];
}

- (ROI*) selectedROI {
	
	if ([currentROI indexOfSelectedItem] == NSNotFound || [currentROI indexOfSelectedItem]==-1 || [currentROI indexOfSelectedItem]==nil) return 0L;
	else {
		int i, x;
		x = -1; // just to get rid of excessive warning about return
		
		for (i=0; i<[currentROIs count]; i++) {

			if ([self roiIdentifierCompare: [currentROIs objectAtIndex:i] :[currentROI objectValueOfSelectedItem]]) {
				x = i;
				break;
			}	
		}
		if (x == -1) return 0L;
		else return [currentROIs objectAtIndex:x];
	}
}	

- (IBAction) refreshGraph:(id) sender
{
	long				i;
	NSMutableArray		*pixList;
	float				*rmean, *rmin, *rmax, background;

//++
	float threshold, rsmean, rsmin, rsmax;
	int					number_of_echos, number_of_slides, current_slide_no;//, roi;
//++
	
	DCMPix				*curPix;
	background = [backgroundSignal floatValue];
	
	// Verify number of echos
	if ([sender isKindOfClass:[NSTextField class]] && [sender tag] == TAG_NUMBER_OF_ECHOS) // field "number of echos"
	{
		if ([numberOfEchos intValue] < 1 || [numberOfEchos intValue] > maxNumberOfEchos) [numberOfEchos setIntValue:maxNumberOfEchos];
	}

	number_of_echos = [numberOfEchos intValue];
	number_of_slides = [numberOfSlides intValue];
	
	// Verify current slide
	if ([sender isKindOfClass:[NSTextField class]] && [sender tag] == TAG_CURRENT_SLIDE_NUMBER) // field "current slide number"
	{
		if ([currentSlideNumber intValue] < 1 || [currentSlideNumber intValue] > number_of_slides) 	[currentSlideNumber setIntValue:number_of_slides];

		current_slide_no = [currentSlideNumber intValue];		
		[currentSlide setIntValue:current_slide_no];
	}
	else {
		current_slide_no = [currentSlide intValue];
		[currentSlideNumber setIntValue:current_slide_no];
	}
	

	// update ROIs for the current slide
	if (([sender isKindOfClass:[NSTextField class]] && [sender tag] == TAG_CURRENT_SLIDE_NUMBER) ||
		[sender isKindOfClass:[NSSlider class]] && [sender tag] == TAG_CURRENT_SLIDE) {

		[self getCurrentImageROIs: (current_slide_no - 1)*XYZ_shift];
		[self updateCurrentROIs];
	
		// move to the current image in ViewerController to show on screen
		[[filter viewerController] setImageIndex: (current_slide_no - 1)*XYZ_shift];
	}	
	
	if (current_slide_no<1 || current_slide_no>[pixListArrays count]) {
		NSLog(@"%d   !!!!!  111 wrong index=%d", random(), current_slide_no);		
	}	
	pixList = [pixListArrays objectAtIndex: current_slide_no-1];
	
	[currentSlide setNumberOfTickMarks:number_of_slides];
	[currentSlide setMaxValue:(double)number_of_slides];

	threshold = [excludeSignal floatValue];
	if (threshold > 0 && [sender isKindOfClass:[NSButton class]] && [sender tag] == TAG_LOG_SCALE) // scaleLog checkbox tag
	{
		if ([logScale state]) [excludeSignal setDoubleValue:log(threshold)];
		else [excludeSignal setDoubleValue:exp(threshold)];
		threshold = [excludeSignal floatValue];
	}
	if ([logScale state]) threshold = exp(threshold);

	// Update list of ROIs or current ROI 
	
	if (setROIFocus == YES) {
		
		if ([currentROI indexOfSelectedItem] == NSNotFound || [currentROI indexOfSelectedItem] == -1 || 
				[currentROI indexOfSelectedItem] == nil // nothing is selected
				)  //after deleting - when selected item is deleted, but event handler have not update ROI list yet
		{	
			curROI = [currentROIs objectAtIndex: 0];
		}
		else 
		{
			curROI = [self selectedROI];
		}
		
		[self showCurrentROI: curROI];
	}
	else  { // don't update ROI focus on viewer when user operates himself on viewer's ROIs; otherwise there will be an infinite chain of events
		setROIFocus = YES;
		
	}

	
	if( currentROIs == 0L)
	{
		[resultView setArrays: 0 :number_of_echos :0L :0L :0L :TEValues :[logScale state]];
		return;
	}


	rmean = (float*) malloc( sizeof(float) * number_of_echos);
	rmin = (float*) malloc( sizeof(float) * number_of_echos);
	rmax = (float*) malloc( sizeof(float) * number_of_echos);
 
//	float rssmean, rssmin, rssmax;
	
	// Find the first selected ROI of current image
	for( i = 0; i < number_of_echos; i++)
	{
		
		curPix = [pixList objectAtIndex: i];
		
//		rssmean = rssmin = rssmax = 0;
			
		[curPix computeROI: curROI :&rsmean :0L :0L : &rsmin :&rsmax];
		
//			rssmean += rsmean;
//			rssmin += rsmin;
//			rssmax += rsmax;
		
//		rmean[i] = (rssmean / [currentROIs count]) - background;
//		rmin[i] = (rssmin / [currentROIs count]) - background;
//		rmax[i] = (rssmax / [currentROIs count]) - background;

		rmean[i] = rsmean - background;
		rmin[i] = rsmin - background;
		rmax[i] = rsmax - background;

	}

	[resultView setArrays:0 :number_of_echos :rmean :rmin :rmax :TEValues :[logScale state]]; 

	// Compute slope and intercept
	{
		float	*rmeanLog;
		
		rmeanLog = (float*) malloc( sizeof(float) * number_of_echos);
		for( i = 0; i < number_of_echos; i++)
		{
			if( rmean[i] < 1.0) rmean[i] = 1.0;
			if( rmin[i] < 1.0) rmin[i] = 1.0;
			if( rmax[i] < 1.0) rmax[i] = 1.0;
			
			rmeanLog[ i] = log( rmean[i]);
		}
		
		[self computeLinearRegression: number_of_echos :TEValues :rmeanLog :&intercept :&slope :rmean];

		free( rmeanLog);
		[resultView setLinearRegression:intercept : slope];
		[resultView setThreshold :threshold];
	}
	
	[meanT2Value setStringValue: [NSString stringWithFormat:@"Mean T2: %2.2f ms, M0: %2.2f", 1000.0 / (-slope), exp( intercept)]];

}

-(IBAction) compute:(id) sender
{
	// Contains a list of DCMPix objects: they contain the pixels of current series
	NSArray				*pixListA;
	NSArray				*pixListC;
	DCMPix				*firstPix;
	long				i, x, y;
	unsigned char		*emptyData;
	float				*dstImage;
	float				factor, thresholdSet, minValue, background;
	BOOL				meanMode;
	
	int					number_of_slides, number_of_echos;
	long r, s;
	// get number of slides, echos
	number_of_echos = [numberOfEchos intValue];
	number_of_slides = [numberOfSlides intValue];
	
	pixListA = [pixListArrays objectAtIndex: 0];

	[self refreshGraph: self];

	firstPix = [pixListA objectAtIndex: 0];

	if (new2DViewer!=0L) {
		NSAlert	*myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Please, close the current map window to avoid an OsiriX order bug!"]
													   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
		[myAlert runModal];
		
		return;
	}	
	
	if( new2DViewer == 0L)
	{
		
		long imageSize = sizeof(float) * [firstPix pwidth] * [firstPix pheight];
		long size =  imageSize * number_of_slides;		

		emptyData = malloc( size);
		memset( emptyData, 0, size);

		NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
		NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
		
		// Prepare new series
		for(i=0; i<number_of_slides; i++)
		{
			[newPixList addObject: [[[pixListArrays objectAtIndex: i] objectAtIndex:0] copy]];			
			[[newPixList lastObject] setfImage: (float*) (emptyData + imageSize * i)];
			[[newPixList lastObject] setTot: number_of_slides];
			[[newPixList lastObject] setID: i];
			[[newPixList lastObject] setFrameNo: i]; 
			[newDcmList addObject: [[[filter viewerController] fileList] objectAtIndex: i*XYZ_shift] ]; 
		}

//--		NSData	*newData = [NSData dataWithBytes:emptyData length: size];
 
//++		
		NSData	*newData = [NSData dataWithBytesNoCopy:emptyData length: size freeWhenDone:YES];
//++		
		
		// create new series
		new2DViewer = [[filter viewerController] newWindow		: newPixList 	: newDcmList  : newData];

/*		
		// replace method with bug in OsiriX onto correct one 
		SEL osirixComputeIntervalSel = sel_registerName("computeInterval");
		SEL newComputeIntervalSel = sel_registerName("newComputeInterval");	

		method_setImplementation(class_getInstanceMethod([ViewerController class], osirixComputeIntervalSel), 
								 class_getMethodImplementation([CMIRViewerController class], newComputeIntervalSel));
*/		
		
		pixListC = [new2DViewer pixList];
		
//--		float* ptr = (float*) [newData bytes];
//--		for( DCMPix *pix in pixListC)
//--		{
//--			[pix setfImage: ptr];
//--			ptr += [firstPix pwidth] * [firstPix pheight];
//--		}
	}
	else 
	{
		pixListC = [new2DViewer pixList];
	}	
	
	factor = [factorText floatValue];
	background = [backgroundSignal floatValue];
	thresholdSet = 0;
	minValue = 99999;
	
	meanMode = [[mode selectedCell] tag];

	if (meanMode) {
		
		for (s=0; s<number_of_slides; s++) 
		{
			firstPix = [[pixListArrays objectAtIndex: s] objectAtIndex:0];
			
			[self getCurrentImageROIs: s*XYZ_shift];
			
			float *values, *rmean;
			int *points_number;
			
			values = malloc(sizeof(float) * number_of_echos * [currentROIs count]);
			rmean = malloc(sizeof(float) * number_of_echos * [currentROIs count]);
			points_number = malloc(sizeof(int) * [currentROIs count]);
			
			memset(values, 0, sizeof(float) * number_of_echos * [currentROIs count]);
			memset(rmean, 0, sizeof(float) * number_of_echos * [currentROIs count]);
			memset(points_number, 0, sizeof(int) * [currentROIs count]);

			// ^^^^^ N=[currentROIs count]*number_of_echos, 2D array
			
			for (x = 0; x < [firstPix pwidth]; x++)
			{
				for (y = 0; y < [firstPix pheight]; y++)
				{
					NSPoint xy = NSMakePoint(x, y);
					for (r=0; r<[currentROIs count]; r++) 
					{
						if( [firstPix isInROI: [currentROIs objectAtIndex: r] :xy])
						{
							points_number[r]++;
							
							long pos = x + y*[firstPix pwidth];
							long offset = r * number_of_echos;
							
							for( i = 0; i < number_of_echos; i++)
							{
								rmean[offset+i] += [[[pixListArrays objectAtIndex: s] objectAtIndex:i] fImage] [ pos] - background;
							}
							
						}
					}	
				}	
			}	
			
			// mean value for each ROI area
			for (r = 0; r < [currentROIs count]; r++) 
			{
				if (points_number[r] > 0) {
					int offset = r * number_of_echos;
					for (i=0; i<number_of_echos; i++) {
						rmean[offset+i] = rmean[offset+i] / points_number[r];
						values[offset+i] = log(rmean[offset+i]); 
					}	
				}	
			}		
			
			// fill destination image
			dstImage = [[pixListC objectAtIndex: s] fImage];
			memset(dstImage, 0, sizeof(float) * [firstPix pwidth] * [firstPix pheight]);
			
			for (x = 0; x < [firstPix pwidth]; x++)
			{
				for (y = 0; y < [firstPix pheight]; y++)
				{
					for (r = 0; r < [currentROIs count]; r++) 
					{
						if( [firstPix isInROI: [currentROIs objectAtIndex: r] :NSMakePoint(x, y)])
						{
							// compute regression from mean values
							[self computeLinearRegression: number_of_echos :TEValues :&values[r*number_of_echos] :&intercept :&slope :&rmean[r*number_of_echos]];
							if (isnan(factor / -slope)) dstImage[ x + y*[firstPix pwidth]] = -32000.0;	
							else 
							{
								dstImage[ x + y*[firstPix pwidth]] = factor / -slope;
							}	
						}
					}
				}	
			
			}
			
			// free arrays
			free(values);
			free(rmean);
			free(points_number);
			
		}	

	}	
	else {
		//--	int position = 0;
		//--	if( curROI.type == tPlain || curROI == nil)
		//--	{
		//--		for( NSArray *teSequence in pixListArrays)
		//--		{
		//--			dstImage = [[pixListC objectAtIndex: position] fImage];
		//--			position++;
		//++++++++++++++++++++++++++++++++++++++++
		
		// Process all slides
		for (s=0; s<number_of_slides; s++) 		
		{
			firstPix = [[pixListArrays objectAtIndex: s] objectAtIndex:0];
			
			dstImage = [[pixListC objectAtIndex: s] fImage];
			memset(dstImage, 0, sizeof(float) * [firstPix pwidth] * [firstPix pheight]);
	
			[self getCurrentImageROIs: s*XYZ_shift];
		
			//int s1=0, r1=-1;
			// Loop through all pixels in the current image
			for( x = 0; x < [firstPix pwidth]; x++)
			{
				for( y = 0; y < [firstPix pheight]; y++)
				{
					//--					if( curROI == nil || [firstPix isInROI: curROI :NSMakePoint( x,  y)])
					//++++++++
					
					
					for (r=0; r<[currentROIs count]; r++) 
					{
						if( [firstPix isInROI: [currentROIs objectAtIndex: r] :NSMakePoint(x, y)])
						{
								float values[ 1000];
								float rmean[ 1000];
					
								long pos = x + y*[firstPix pwidth];
							
								for( i = 0; i < number_of_echos; i++)
								{
									rmean[ i] = [[[pixListArrays objectAtIndex: s] objectAtIndex:i] fImage] [ pos] - background;
									values[i] = log(rmean[i]); 
								}
							
								[self computeLinearRegression: number_of_echos :TEValues :values :&intercept :&slope :rmean];

									if( slope < 0)
										dstImage[ x + y*[firstPix pwidth]] = factor / -slope;
									else
										dstImage[ x + y*[firstPix pwidth]] = 0;
							
									if( dstImage[ x + y*[firstPix pwidth]] > 2000)
										dstImage[ x + y*[firstPix pwidth]] = 2000;
									 
						}
					}
				}
			}
			
		}
		
	}	
	
//--	else
//--	{
//--		NSArray *ptsTemp = [curROI splinePoints];
		
//--		NSPoint *pts = (NSPoint*) malloc( [ptsTemp count] * sizeof(NSPoint));
//--		int no = [ptsTemp count];
//--		int i;
//--		for( i = 0; i < no; i++) pts[ i] = [[ptsTemp objectAtIndex: i] point];
		
//--		for( NSArray *teSequence in pixListArrays)
//--		{
//--			dstImage = [[pixListC objectAtIndex: position] fImage];
//--			position++;
			
//--			// Loop through all images contained in the current series
//--			for( x = 0; x < [firstPix pwidth]; x++)
//--			{
//--				for( y = 0; y < [firstPix pheight]; y++)
//--				{
//--					if( [DCMPix IsPoint:NSMakePoint(x, y) inPolygon: pts size: no])
//--					{
//--						if( meanMode)
//--						{
//--						//	minValue = slope * factor;
//--							if( slope < 0)
//--								dstImage[ x + y*[firstPix pwidth]] = factor /-slope;
//--							else
//--								dstImage[ x + y*[firstPix pwidth]] = 0;
		
//--							if( dstImage[ x + y*[firstPix pwidth]] > 2000)
//--								dstImage[ x + y*[firstPix pwidth]] = 2000;
//--						}
//--						else
//--						{
//--							float values[ 1000];
					
//--							long pos = x + y*[firstPix pwidth];
							
//--							for( i = 0; i < [teSequence count]; i++)
//--							{
//--								values[ i] = log( [[teSequence objectAtIndex: i] fImage] [ pos] - background);
//--							}
							
//--							[self computeLinearRegression: [teSequence count] :TEValues :values :&intercept :&slope];
							
//--							if( slope < 0)
//--								dstImage[ x + y*[firstPix pwidth]] = factor / -slope;
//--							else
//--								dstImage[ x + y*[firstPix pwidth]] = 0;
							
//--							if( dstImage[ x + y*[firstPix pwidth]] > 2000)
//--								dstImage[ x + y*[firstPix pwidth]] = 2000;
//--						}
//--					}
//--				}
//--			}
//--		}
		
//--		free( pts);
//--	}
	
	// We modified the pixels: OsiriX please update the display!

	[[new2DViewer imageView] setWLWW:0 :0];
	
	[new2DViewer needsDisplayUpdate];
	
}

- (void)awakeFromNib
{
//	NSLog( @"Nib loaded!");
	
	NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector(closeViewer:)
               name: @"CloseViewerNotification"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiChange:)
               name: @"roiChange"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiRemove:)
               name: @"removeROI"
             object: nil];
	
	[nc addObserver: self
           selector: @selector(roiSelect:)
               name: @"roiSelected"
             object: nil];

	
	TAG_FILL_INTERVAL = 1;
	TAG_CURRENT_SLIDE = 2;
	TAG_CURRENT_SLIDE_NUMBER = 6;
	TAG_NUMBER_OF_ECHOS = 4;
	TAG_CURRENT_ROI = 5;
	TAG_LOG_SCALE = 10;
	
			 
}


- (id) init:(CMIR_T2_Fit_MapFilter*) f 
{
	int i, 
		number_of_slides, // quantity of volume slices 
		number_of_echos;

	number_of_slides = 0;
	number_of_echos = 0;
	TE_shift = 0;
	XYZ_shift = 0;
	
	setROIFocus = YES;
	
//	roiSorter = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];

	self = [super initWithWindowNibName:@"ControllerCMIRT2Fit"];
		
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	new2DViewer = 0L;
	curROI = 0L;
	currentROIs = 0L;
	filter = f;

	blendedWindow = [[filter viewerController] blendedWindow];

	[pixListArrays release];
	pixListArrays = [[NSMutableArray array] retain];
	
	[pixListResult release];
	pixListResult = [[NSMutableArray array] retain];
	
	[fileListResult release];
	fileListResult = [[NSMutableArray array] retain];

	if( [[filter viewerController] maxMovieIndex] > 1)  //!!!!  NOT CHECKED HOW THIS BRUNCH WORKS
	{
		// Its a 4D series
		NSArray *pixListAll = [[filter viewerController] pixList];
		int x;
		for( x = 0 ; x < [pixListAll count] ; x++)
		{
			NSMutableArray *l = [NSMutableArray array];
			
			for( i = 0 ; i < [[filter viewerController] maxMovieIndex] ; i++) {
				[l addObject: [[[filter viewerController] pixList: i] objectAtIndex: x]];
			}
			[pixListArrays addObject: l];
			[pixListResult addObject: [[[l objectAtIndex:0] copy] autorelease]];
			[fileListResult addObject: [[[filter viewerController] fileList: i] objectAtIndex: 0]];
		}
		
		number_of_echos = [[pixListArrays objectAtIndex:0] count];
		number_of_slides = [pixListArrays count]; 
		TE_shift = number_of_echos;
		XYZ_shift = 1;
	}
	else
	{
		NSArray *pixListAll = [[filter viewerController] pixList];	//++ all the opened images
	
		// Try to identify if it is a volumic TE sequence: multiple volumes of TE sequence
		
		float coord_X0, coord_Y0, coord_Z0;
		
		coord_X0 = [[pixListAll objectAtIndex:0] originX];
		coord_Y0 = [[pixListAll objectAtIndex:0] originY];
		coord_Z0 = [[pixListAll objectAtIndex:0] originZ];
			
		number_of_echos = 1;
		number_of_slides = 1;
			for( i = 1; i < [pixListAll count]; i++)
			{
				if( abs([[pixListAll objectAtIndex: i] originX] - coord_X0)>0.000001 || abs([[pixListAll objectAtIndex: i] originY] - coord_Y0)>0.000001 || abs([[pixListAll objectAtIndex: i] originZ] - coord_Z0)>0.000001) break;

				number_of_echos++;
			}

			if (number_of_echos == 1) // ZZZT series
			{
				float echo0;
				echo0 = [[[pixListAll objectAtIndex: 0] echotime] floatValue];

				for (i=1; i<[pixListAll count]; i++) 
				{
					if (abs([[[pixListAll objectAtIndex: i] echotime] floatValue] - echo0)>0.000001) break;
					number_of_slides++;
				}	
				
				TE_shift = number_of_slides;
				XYZ_shift = 1;
				number_of_echos = [pixListAll count]/number_of_slides;
				
			}	
			else { // TTTZ series
				number_of_slides = [pixListAll count]/number_of_echos;
				TE_shift = 1;
				XYZ_shift = number_of_echos;
			}	
			

		if( number_of_slides != [pixListAll count] && number_of_slides>0)
		{
			int s;
			for( s = 0; s < number_of_slides; s++)
			{
				NSMutableArray *l = [NSMutableArray array];
				
				for( i = 0; i < number_of_echos; i++) {
				
					[l addObject: [pixListAll objectAtIndex: s*XYZ_shift + i*TE_shift]];
				}
				
				[pixListArrays addObject: l];
				
				[pixListResult addObject: [[[pixListAll objectAtIndex: s*XYZ_shift] copy] autorelease]];
				[fileListResult addObject: [[[filter viewerController] fileList] objectAtIndex: s*XYZ_shift]];
			}
 
			
		}
		else
		{
			[pixListArrays addObject: pixListAll];
			[pixListResult addObject: [[[pixListAll objectAtIndex:0] copy] autorelease]];
			[fileListResult addObject: [[[filter viewerController] fileList] objectAtIndex: 0]];
			number_of_echos = [pixListAll count];
		}
		
	
	}
	
	
	
	// Try to find the TEs...
	float max;
	max = -1.0;

	maxNumberOfEchos = number_of_echos;

	// scan one TE set for max, supposed all TE are the same in different sets by slides
	for( i = 0; i < [[pixListArrays objectAtIndex: 0] count]; i++)	
	{
		TEValues[i] = [[[[pixListArrays objectAtIndex: 0] objectAtIndex: i] echotime] floatValue] / 1000.;
		if (TEValues[i] > max)	max = TEValues[i];
	}
	
	
	[TETable reloadData];

	[numberOfEchos setIntValue:number_of_echos];
	[numberOfSlides setIntValue:number_of_slides];
//	[currentSlide setNumberOfTickMarks:1];

	int current_slide_no = [[[filter viewerController] imageView] curImage];
	
	current_slide_no = [self getSlideNumber: current_slide_no];
	
	[currentSlide setNumberOfTickMarks: number_of_slides];
	[currentSlide setMinValue:(double)1];
	[currentSlide setMaxValue:(double) current_slide_no];
//	[currentSlide setTickMarkPosition: current_slide_no];
	[currentSlideNumber setIntValue: current_slide_no];
	//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	
	NSMutableArray		*roiSeriesList, *roiImageList;
	// TRY TO FIND THE SELECTED ROI OF CURRENT IMAGE
	// All rois contained in the current series
	roiSeriesList = [[filter viewerController] roiList];
	
	// All rois contained in the current image
	roiImageList = [roiSeriesList objectAtIndex: [[[filter viewerController] imageView] curImage]];
	
	// Find the first selected ROI of current image
	for( i = 0; i < [roiImageList count]; i++)
	{
		if([[roiImageList objectAtIndex: i] ROImode] == ROI_selected || [[roiImageList objectAtIndex: i] ROImode] == ROI_selectedModify)
		{
			// We find it! What's his name?
			curROI = [roiImageList objectAtIndex: i];
			
			break; //++
		}
		
	}

	if ([roiImageList count]>0) 
	{
		[self getCurrentImageROIs: [[[filter viewerController] imageView] curImage]];
		[self updateCurrentROIs];
	}	

	[self refreshGraph: self];

	return self;
}

- (void) getCurrentImageROIs :(int) selectedImageNo
{
	// reset currentROIs
	currentROIs = 0L;
	
	// get all ROIs in selected image
	currentROIs = [[[filter viewerController] roiList] objectAtIndex:selectedImageNo];
	
}

- (void) updateCurrentROIs
{
	[currentROI removeAllItems];
	if (currentROIs == 0L) {
		curROI = 0L;
		return;
	}
	
	int i;
	for (i=0; i<[currentROIs count]; i++) {
		[currentROI addItemWithObjectValue: [self roiIdentifier:[currentROIs objectAtIndex:i]]];	
	}
	
	if (curROI!=0L && [currentROIs containsObject: curROI]) {
//		[currentROI selectItemAtIndex: [currentROIs indexOfObject: curROI]];
	}
	else {
		curROI = [currentROIs objectAtIndex: 0];
	}
	[currentROI selectItemWithObjectValue: [self roiIdentifier: curROI]];		

	
}

- (int) getSlideNumber: (int) imageNumber
{
	if (XYZ_shift > 1)  { // TTTZ series
		return ((int)(imageNumber/XYZ_shift)) + 1;
	}	
	else	{  // ZZZT series
		return imageNumber - (int)(imageNumber/TE_shift)*TE_shift + 1;
	}
}

- (void) roiChange :(NSNotification*) note
{
	if ([[note name] isEqualToString:@"roiChange"])  //ROI_selected || [[note object] ROImode] == ROI_selectedModify)
	{
		if ([[note object] ROImode] != ROI_sleep)
		{	
			
			if (curROI != [note object]) {
//				[[filter viewerController] deselectAllROIs];
				curROI = [note object];
				[self getCurrentImageROIs: [[[filter viewerController] imageView] curImage]];
				[[filter viewerController] selectROI:curROI deselectingOther:YES];
				setROIFocus = NO;
			
				// update slide number if user moved in viewer to another image without touching appropriative form fields
				int i;
				i = [[[filter viewerController] imageView] curImage];
				i = [self getSlideNumber: i];
				[currentSlideNumber setIntValue: i];
				[currentSlide setIntValue: i];

			}	
			else  {
				setROIFocus = NO; 
		
			}	
		}	

		[self refreshGraph:self];

	}

}


- (void) roiRemove :(NSNotification*) note
{
	if( [[note name] isEqualToString:@"removeROI"])
	{
		curROI = 0L;
		
		int i = [currentROI indexOfItemWithObjectValue: [self roiIdentifier: [note object]]];
		if (i >=0 && i < [currentROI numberOfItems]) {
			[currentROI removeItemAtIndex: i];
		}	

		[self refreshGraph:self];
		
	}

}

- (void) roiSelect :(NSNotification*) note
{
	
	if (([[note name] isEqualToString:@"roiSelected"]) && ([[note object] ROImode] == ROI_selected || [[note object] ROImode] == ROI_selectedModify)) 
	{
		curROI = [note object];
		[self getCurrentImageROIs: [[[filter viewerController] imageView] curImage]];
		[self updateCurrentROIs];
		[self refreshGraph:self];

	}
	
}

- (void) showCurrentROI :(ROI*) roi
{
	
	[[filter viewerController] deselectAllROIs];
	
	[roi setROIMode: ROI_selected];
	[[filter viewerController] needsDisplayUpdate];

}

- (void) closeViewer :(NSNotification*) note
{
	if( [note object] == [filter viewerController])
	{
		NSLog(@"Viewer Window will close.... We have to close!");
		
		[self autorelease];
	}
	
	if( [note object] == new2DViewer)
	{
		new2DViewer = 0L;
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"Window will close.... and release his memory...");
	
	[self autorelease];
}

- (void) dealloc
{
    NSLog(@"My window is deallocating a pointer");
	
	[pixListArrays release];
	[pixListResult release];
	[fileListResult release];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[super dealloc];

}

@end

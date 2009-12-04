//
//  NMRegionGrowingController.mm
//  NMSegmentation
//
//  Created by Brian Jensen on 5/1/08.
//  Copyright 2008 - 2009. All rights reserved.
//

#import "NMSegmentationFilter.h"
#import "NMRegionGrowingController.h"

#import "ITKRegionGrowing3D.h"

#import "ROI.h"
	
//Default ROI color
static char color_default[] = {0x04, 0x0b, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x74, 0x79, 0x70, 0x65,
								0x64, 0x81, 0xe8, 0x03, 0x84, 0x01, 0x40, 0x84, 0x84, 0x84, 0x07, 0x4e, 0x53, 0x43, 0x6f, 0x6c,
								0x6f, 0x72, 0x00, 0x84, 0x84, 0x08, 0x4e, 0x53, 0x4f, 0x62, 0x6a, 0x65, 0x63, 0x74, 0x00, 0x85,
								0x84, 0x01, 0x63, 0x01, 0x84, 0x04, 0x66, 0x66, 0x66, 0x66, 0x83, 0x4e, 0x5a, 0xda, 0x3d, 0x83,
								0x26, 0xeb, 0x36, 0x3e, 0x83, 0x6d, 0x0a, 0x63, 0x3f, 0x01, 0x86};

@implementation NMRegionGrowingController

@synthesize posX, posY, posZ;
@synthesize mmPosX, mmPosY, mmPosZ;
@synthesize intensityValue;
@synthesize mainViewer, registeredViewer;

- (id) initWithMainViewer:(ViewerController*) mViewer registeredViewer:(ViewerController*) rViewer
{
	//Set the defaults before loading the window (otherwise parameters will not be initialized)
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:[self getDefaults]];
	
	self = [super initWithWindowNibName:@"NMRegionGrowingWindow"];
	if(self != nil)
	{
		DebugLog(@"Nib loaded successfully!");
		mainViewer = mViewer;
		registeredViewer = rViewer;
		seedPointSelected = NO;
		
		[self showWindow:self];
		
		if(registeredViewer != nil)
			segmenter = [[ITKRegionGrowing3D alloc] initWithMainViewer:mainViewer regViewer:registeredViewer];
		else
			segmenter = [[ITKRegionGrowing3D alloc] initWithViewer:mainViewer];
		
		[mainViewerLabel setStringValue:[[mainViewer window] title]];
		
		if(registeredViewer != nil)
		{
			[regViewerLabel setStringValue:[[registeredViewer window] title]];
		}
		else
		{
			[enableRegViewerButton setState:NSOffState];
			[enableRegViewerButton setEnabled:NO];	
		}
		
		//remove any haning ROIs
		[self removeMaxRegionROI];
		[self removeSeedPointROI];
		
		//make sure we catch the necessary notifications
		NSNotificationCenter *nc;
		nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: self
			   selector: @selector(mouseViewerDown:)
				   name: @"mouseDown"
				 object: nil];
		
		[nc addObserver: self
			   selector: @selector(CloseViewerNotification:)
				   name: @"CloseViewerNotification"
				 object: nil];
				
		algorithms = [NSArray arrayWithObjects: @"Connected Threshold",
					  @"Neighborhood Connected",
					  @"Confidence Connected",
					  @"Gradient Thresholding",
					  nil];
		
		//initialize the rest of the interface (fill algorithm pop up, set correct tab)
		[self fillAlgorithmsPopUp];	
		[self updateAlgorithm:self];
		[self manualRadioSelChanged:self];
		
	}
	else
		NSLog(@"Error loading the region growing window nib!");
	
	return self;
}

- (NSMutableDictionary*) getDefaults
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setValue:@"Segmented Region" forKey:@"NMSegRoiLabel"];
	[defaults setValue:@"45.0"	forKey:@"NMSegCutOffPercent"];
	[defaults setValue:@"70.0"	forKey:@"NMSegSearchRegion"];
	[defaults setValue:@"1"		forKey:@"NMSegNHRadiusX"];
	[defaults setValue:@"1"		forKey:@"NMSegNHRadiusY"];
	[defaults setValue:@"1"		forKey:@"NMSegNHRadiusZ"];
	[defaults setValue:@"1"		forKey:@"NMSegManualSeg"];
	[defaults setValue:@"0"		forKey:@"NMSegAlgorithm"];
	[defaults setValue:@"2"		forKey:@"NMSegConfRadiusX"];
	[defaults setValue:@"2"		forKey:@"NMSegConfRadiusY"];
	[defaults setValue:@"2"		forKey:@"NMSegConfRadiusZ"];
	[defaults setValue:@"2.5"	forKey:@"NMSegConfMultiplier"];
	[defaults setValue:@"5"		forKey:@"NMSegConfIterations"];
	[defaults setValue:@"8.0"	forKey:@"NMSegGradient"];
	[defaults setValue:@"30"	forKey:@"NMSegMaxVolumeSize"];
	[defaults setValue:@"1"		forKey:@"NMSegShowSeed"];
	[defaults setValue:@"1"		forKey:@"NMSegShowMaxRegion"];
	[defaults setValue:@"1"		forKey:@"NMSegDisableClick"];
	[defaults setValue:[NSData dataWithBytes:color_default length:71] forKey:@"NMSegColor"];
		
	return defaults;
}

- (void) fillAlgorithmsPopUp
{
	unsigned int i;
	NSMenu *items = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
	for (i=0; i<[algorithms count]; i++)
	{
		NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];				
		[item setTitle: [algorithms objectAtIndex: i]];
		[item setTag:i];
		[items addItem:item];
	}
	
	[algorithmPopUp removeAllItems];
	[algorithmPopUp setMenu:items];
	[algorithmPopUp selectItemAtIndex:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"NMSegAlgorithm"] intValue]];

}

- (void) dealloc
{
	DebugLog(@"NMRegionGrowingController dealloc");
	[segmenter release];
	[super dealloc];
}

- (IBAction) manualRadioSelChanged:(id) sender
{	
	DebugLog(@"Manual / Cutoff mode changed");
		
	//deactivate certain options depending upon the user's selection
	if([manualRadioGroup selectedRow] == 0)
	{
		[lowerThresholdBox setEnabled:YES];
		[upperThresholdBox setEnabled:YES];
		[cutOffBox setEnabled:NO];
		[cutOffSlider setEnabled:NO];
		[searchRegionBox setEnabled:NO];
	}
	else
	{
		[lowerThresholdBox setEnabled:NO];
		[upperThresholdBox setEnabled:NO];
		[cutOffBox setEnabled:YES];
		[cutOffSlider setEnabled:YES];	
		[searchRegionBox setEnabled:YES];
	}
	
	[self updateThresholds:self];	//make sure the upper and lower thresholds get recalculated
}

- (void) CloseViewerNotification:(NSNotification*) note
{
	DebugLog(@"NMRegionGrowingController: CloseCiewerNotification received");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self close];
}

- (void) mouseViewerDown:(NSNotification*) note
{
	DebugLog(@"NMRegionGrowingController: Mouse down event received");
	int xpx, ypx, zpx; // coordinate in pixels
	float xmm, ymm, zmm; // coordinate in millimeters
		
	//Disable the source viewer controller from reacting to the click events
	if([disableClickButton state] == NSOnState){
		DebugLog(@"Disabling viewer from reacting to click event");
		[[note userInfo] setValue: [NSNumber numberWithBool: YES] forKey: @"stopMouseDown"];
	} 
	else
	{
		DebugLog(@"Ignoring mouse event, passing to viewerController object");
		return;
	}
	
	if([note object] == mainViewer)
	{
		[seedLabel setStringValue:@"selected (click to reselect)"];	//notify the user that the seed point was selected

		if([enableRegViewerButton state] == NSOnState)
		{
			DebugLog(@"Using values from the registered viewer for determining seed point location");
			NSPoint np;
			np.x = [[[note userInfo] objectForKey:@"X"] intValue];
			np.y = [[[note userInfo] objectForKey:@"Y"] intValue];
			zpx = [[registeredViewer imageView] curImage];
		
			np = [[mainViewer imageView] ConvertFromGL2GL:np toView:[registeredViewer imageView]];
			xpx = np.x;
			ypx = np.y;
			
			float location[3];
			[[[registeredViewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location pixelCenter: YES];
			xmm = location[0];
			ymm = location[1];
			zmm = location[2];
			[self setIntensityValue:[[[registeredViewer imageView] curDCM] getPixelValueX: xpx Y:ypx]];

		}
		else
		{
			DebugLog(@"Using values from the main viewer for determining seed point location");
			xpx = [[[note userInfo] objectForKey:@"X"] intValue];
			ypx = [[[note userInfo] objectForKey:@"Y"] intValue];
			zpx = [[mainViewer imageView] curImage];
			
			float location[3];
			[[[mainViewer imageView] curDCM] convertPixX: (float) xpx pixY: (float) ypx toDICOMCoords: (float*) location pixelCenter: YES];
			xmm = location[0];
			ymm = location[1];
			zmm = location[2];
			
			[self setIntensityValue:[[[mainViewer imageView] curDCM] getPixelValueX: xpx Y:ypx]];
			
		}
		
		[self setPosX:xpx];
		[self setPosY:ypx];
		[self setPosZ:zpx];
		
		[self setMmPosX:xmm];
		[self setMmPosY:ymm];
		[self setMmPosZ:zmm];
		
		seedPointSelected = YES;
		
		[self showSeedEnable:self];
		[self updateThresholds:self];
	}
}

- (IBAction) updateThresholds:(id) sender
{
	DebugLog(@"NMRegionGrowingController: updating the thresholds");
	
	if([[algorithmPopUp selectedItem] tag] < 2 && [manualRadioGroup selectedRow] == 1 && seedPointSelected)
	{
		int displayIndex[2], searchIndex[3];
		int displayRegion[3], searchRegion[3];
		float displaySpacing[3], searchSpacing[3];
			
		DCMPix* curPix;
		int count;
			
		if([enableRegViewerButton state] == NSOnState)
		{
			curPix = [[registeredViewer imageView] curDCM];
			count = [[registeredViewer pixList] count];
		}
		else
		{
			curPix = [[mainViewer imageView] curDCM];
			count = [[mainViewer pixList] count];
		}
		
		searchSpacing[0] = [curPix pixelSpacingX];
		searchSpacing[1] = [curPix pixelSpacingY];
		searchSpacing[2] = [curPix sliceInterval];
						
		searchRegion[0] = [searchRegionBox floatValue] / searchSpacing[0];
		searchRegion[1] = [searchRegionBox floatValue] / searchSpacing[1];
		searchRegion[2] = [searchRegionBox floatValue] / searchSpacing[2];
						
		searchIndex[0] = [self posX] - (searchRegion[0] / 2);
		searchIndex[1] = [self posY] - (searchRegion[1] / 2);
		searchIndex[2] = [self posZ] - (searchRegion[2] / 2);
						
		//Make sure we don't go out of the image's domain
		if(searchIndex[0] < 0)
		{
			searchRegion[0] += searchIndex[0];
			searchIndex[0] = 0;
		}
		else if(searchIndex[0] > [curPix pwidth])
		{
			searchRegion[0] = 0; 
			searchIndex[0] = [curPix pwidth];
		}
		
		if(searchIndex[1] < 0)
		{
			searchRegion[1] += searchIndex[1];
			searchIndex[1] = 0;
		}
		else if(searchIndex[1] > [curPix pheight])
		{
			searchRegion[1] = 0;
			searchIndex[1] = [curPix pheight];
		}
		
		if(searchIndex[2] < 0)
		{
			searchRegion[2] += searchIndex[2];
			searchIndex[2] = 0;
		}
		else if(searchIndex[2] > count )
		{
			searchRegion[2] = 0;
			searchIndex[2] = count;
		}
		
		if(searchIndex[0] + searchRegion[0] > [curPix pwidth])
			searchRegion[0] = [curPix pwidth] - searchIndex[0];
		else if(searchRegion[0] < 0)
			searchRegion[0] = 0;

		if(searchIndex[1] + searchRegion[1] > [curPix pheight])
			searchRegion[1] = [curPix pheight] - searchIndex[1];
		else if(searchRegion[1] < 0)
			searchRegion[1] = 0;
		
		if(searchIndex[2] + searchRegion[2] > count)
			searchRegion[2] = count - searchIndex[2];
		else if(searchRegion[2] < 0)
			searchRegion[2] = 0;
		
		DebugLog(@"max search region sizes: %d %d %d", searchRegion[0], searchRegion[1], searchRegion[2]);
		DebugLog(@"max search region index: %d %d %d", searchIndex[0], searchIndex[1], searchIndex[2]);
			
		if([enableRegViewerButton state] == NSOnState)
		{
			//convert the search indexes into the main viewer's parameter space
			NSPoint np = NSMakePoint(searchIndex[0], searchIndex[1]);				
			curPix = [[mainViewer imageView] curDCM];
			displaySpacing[0] = [curPix pixelSpacingX];
			displaySpacing[1] = [curPix pixelSpacingY];
			displaySpacing[2] = [curPix sliceInterval];

			displayRegion[2] = [searchRegionBox floatValue] / displaySpacing[2];
			
			np = [[registeredViewer imageView] ConvertFromGL2GL:np toView:[mainViewer imageView]];
			displayIndex[0] = np.x;
			displayIndex[1] = np.y;
			
			np.x = searchIndex[0] + searchRegion[0];
			np.y = searchIndex[1] + searchRegion[1];
			
			np = [[registeredViewer imageView] ConvertFromGL2GL:np toView:[mainViewer imageView]];

			displayRegion[0] = np.x - displayIndex[0];
			displayRegion[1] = np.y - displayIndex[1];
			

		}
		else
		{
			displayRegion[0] = searchRegion[0];
			displayRegion[1] = searchRegion[1];
			displayRegion[2] = searchRegion[2];
				
			displayIndex[0] = searchIndex[0];
			displayIndex[1] = searchIndex[1];
		}
		
		DebugLog(@"display search region sizes: %d %d %d", displayRegion[0], displayRegion[1], displayRegion[2]);
		DebugLog(@"display search region index: %d %d", displayIndex[0], displayIndex[1]);

		float maxVal = [segmenter findMaximum:searchIndex region:searchRegion];
		DebugLog(@"Max value in region %f", maxVal);
		[upperThresholdBox setFloatValue:maxVal];
				
		if([showMaxRegionButton state] == NSOnState)
		{
			//now add the ROI to the image slice
			NSMutableArray  *roiSeriesList;
			NSMutableArray  *roiImageList;
			roiSeriesList = [mainViewer roiList];
					
			[self removeMaxRegionROI];
					
			int sliceStart = [[mainViewer imageView] curImage] - (displayRegion[2] / 2);
			if(sliceStart < 0)
				sliceStart = 0;
				
			for(unsigned int sliceIndex = sliceStart; sliceIndex < (unsigned int) sliceStart + displayRegion[2]; sliceIndex++)
			{
				if(sliceIndex >= [[mainViewer pixList] count])
					break;
				
				roiImageList = [roiSeriesList objectAtIndex:sliceIndex]; 
				ROI *myROI = [mainViewer newROI:tROI];
				NSRect rect = NSMakeRect(displayIndex[0], displayIndex[1], displayRegion[0], displayRegion[1]);
				[myROI setName:@"Max Threshold Localization Region"];
				[myROI setROIRect:rect];
				[roiImageList addObject: myROI];
			}

			[[mainViewer imageView] roiSet];
		}
	
		float lowerThreshold = ([cutOffBox floatValue] * [upperThresholdBox floatValue] / 100);
		[lowerThresholdBox setFloatValue:lowerThreshold];
	}
}

- (IBAction) updateRegEnabled:(id) sender
{
	if([enableRegViewerButton state] == NSOnState && registeredViewer != nil)
		[segmenter setRegViewer:registeredViewer];
	else
		[segmenter removeRegViewer];
}

- (IBAction) calculate: (id) sender
{
	NSLog(@"Calculate segmentation trigerred");
	int seed[3], radius[3], iterations = 0;
	
	if([[algorithmPopUp selectedItem] tag] == 1)
	{
		radius[0] = [nhRadiusX intValue];
		radius[1] = [nhRadiusY intValue];
		radius[2] = [nhRadiusZ intValue];
	}
	else if([[algorithmPopUp selectedItem] tag] == 2)
	{
		radius[0] = [confNeighborhood intValue];
		iterations = [confIterationsBox intValue];
	}
	else if([[algorithmPopUp selectedItem] tag] == 3)
	{
		iterations = [gradientMaxSegmentationBox intValue];
	}
	
	seed[0] = [self posX];
	seed[1] = [self posY];
	seed[2] = [self posZ];
	
	[self removeMaxRegionROI];
	[self removeSeedPointROI];
	
	NSLog([roiNameBox stringValue]);
	[segmenter		regionGrowing:-1 
					seedPoint:seed 
					name:[roiNameBox stringValue]
					color:[colorBox color] 
					algorithmNumber:[[algorithmPopUp selectedItem] tag]
					lowerThreshold:[lowerThresholdBox floatValue] 
					upperThreshold:[upperThresholdBox floatValue]
					radius:radius
					confMultiplier:[confMultBox floatValue]
					iterations:iterations
					gradient:[gradientBox floatValue]
					];
}

- (void) removeMaxRegionROI
{
	DebugLog(@"Removing Max search region ROI");
	NSMutableArray *roiSeriesList = [mainViewer roiList];
	
	for(NSMutableArray* roiImageList in roiSeriesList)
	{
		for(unsigned int index = 0; index < [roiImageList count]; index++)
		{
			ROI *roi = [roiImageList objectAtIndex:index];
			if([[roi name] compare:@"Max Threshold Localization Region"] == NSOrderedSame)
			{
				[roiImageList removeObject:roi];
			}
		}
	}
	
	[[mainViewer imageView] roiSet];
}

- (IBAction) showMaxRegionEnable:(id) sender
{
	if([showMaxRegionButton state] == NSOnState)
		[self updateThresholds:sender];
	else
		[self removeMaxRegionROI];
	
	[mainViewer needsDisplayUpdate];	
}

- (void) removeSeedPointROI
{
	DebugLog(@"Removing Seed ROI");
	NSMutableArray *roiSeriesList = [mainViewer roiList];
	for(NSMutableArray* roiImageList in roiSeriesList)
	{
		for(unsigned int index = 0; index < [roiImageList count]; index++)
		{
			ROI *roi = [roiImageList objectAtIndex:index];
			if([[roi name] compare:@"Segmentation Seed Point"] == NSOrderedSame)
			{
				[roiImageList removeObject:roi];
			}
		}
	}
}


- (IBAction) showSeedEnable:(id) sender
{
	DebugLog(@"Setting seed point");
	[self removeSeedPointROI];
	
	if([showSeedButton state] == NSOnState)
	{
		DebugLog(@"Displaying seed point ROI");
		NSMutableArray *roiSeriesList = [mainViewer roiList];
		NSRect rect;
		
		if([enableRegViewerButton state] == NSOnState)
		{
			NSPoint np = NSMakePoint([self posX], [self posY]);
			np = [[registeredViewer imageView] ConvertFromGL2GL:np toView:[mainViewer imageView]];
			rect = NSMakeRect(np.x, np.y, 1, 1);
		}
		else
		{
			rect = NSMakeRect([self posX], [self posY], 1, 1);
		}
		
		NSMutableArray *roiImageList = [roiSeriesList objectAtIndex:[[mainViewer imageView] curImage]]; 
		ROI *myROI = [mainViewer newROI:t2DPoint];
		[myROI setName:@"Segmentation Seed Point"];
		[myROI setROIRect:rect];
		[roiImageList addObject: myROI];
	}

	[[mainViewer imageView] roiSet];
	[mainViewer needsDisplayUpdate];
}

- (IBAction) updateAlgorithm:(id) sender;
{
	DebugLog(@"NMRegionGrowingController: algorithm selection changed");
	NSMenuItem* item = [algorithmPopUp selectedItem];
	
	if([item tag] < 2)
	{
		DebugLog(@"Displaying Connected / neighbor parameters panel");
		//first resize the window, then switch the view
		NSRect r = [[self window] frame];
		r.size.height = 650; //Size in IB plus 16px title
		[[self window] setFrame:r display:YES animate:YES];
		r = [paramsBox frame];
		r.size.height = 238; //Size in IB plus 16px title
		[paramsBox setFrame:r];
		
		[parameterView selectTabViewItemAtIndex:0];
		
		if([item tag] == 1)
		{
			[nhRadiusX setEnabled:YES];
			[nhRadiusY setEnabled:YES];
			[nhRadiusZ setEnabled:YES];
		}
		else
		{
			[nhRadiusX setEnabled:NO];
			[nhRadiusY setEnabled:NO];
			[nhRadiusZ setEnabled:NO];
		}
			
		[showMaxRegionButton setEnabled:YES];
		[self manualRadioSelChanged:self];
		[self showMaxRegionEnable:self];
		[self showSeedEnable:self];		//redraw the max seed point
	}
	else if([item tag] == 2)
	{
		DebugLog(@"Displaying Confidence parameters panel");
		//first switch the view, then resize the window
		[parameterView selectTabViewItemAtIndex:1];
		
		NSRect r = [paramsBox frame];
		r.size.height = 138; //Size in IB plus title - 100
		[paramsBox setFrame:r];
		r = [[self window] frame];
		r.size.height = 550; //Size in IB plus titls - 100
		[[self window] setFrame:r display:YES animate:YES];
		
		[showMaxRegionButton setEnabled:NO];
		[self removeMaxRegionROI];
		
		[self showSeedEnable:self];		//redraw the max seed point
		[mainViewer needsDisplayUpdate];
	}
	else		//current only 4 items
	{
		DebugLog(@"Displaying gradient parameters panel");
		//first switch the view, then resize the window
		[parameterView selectTabViewItemAtIndex:2];
		
		NSRect r = [paramsBox frame];
		r.size.height = 108; //Size in IB plus title - 130
		[paramsBox setFrame:r];
		r = [[self window] frame];
		r.size.height = 520; //Size in IB plus titls - 130
		[[self window] setFrame:r display:YES animate:YES];
		
		[showMaxRegionButton setEnabled:NO];
		[self removeMaxRegionROI];
		
		[self showSeedEnable:self];		//redraw the max seed point
		[mainViewer needsDisplayUpdate];
	} 
	
}

- (IBAction) resetDefaults:(id) sender
{
	DebugLog(@"Revert to default parameters requested");
	int selection = NSRunAlertPanel(@"Revert to Defaults", @"Do you really want to revert to the default paramters?", @"Yes", @"No", NULL);
	
	if(selection == 1)	//first reset the defaults dictionary, then reset the interface
	{
		[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:[self getDefaults]];
		NSLog(@"NMRegionGrowingController: Reverting to factory defaults");
		[algorithmPopUp selectItemAtIndex:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"NMSegAlgorithm"] intValue]];
		[self updateAlgorithm:self];
		[self manualRadioSelChanged:self];
		[self updateThresholds:self];

	}
}


@end

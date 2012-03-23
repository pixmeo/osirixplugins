//
//  Controller.m
//  CMIR_Fusion3
//
//  Created by lfexon on 5/5/09.
//  Copyright 2009 CSB_MGH. All rights reserved.
//


#import "Controller.h"

// for 3.5 only, for 3.6 could be used Notifications.h for these extern strings
static NSString *OsirixUpdateCLUTMenuNotification = @"UpdateCLUTMenu";
static NSString *OsirixROIChangeNotification = @"roiChange";

@implementation ControllerCMIRFusion3

-(void) roiRestore: (int) ind fromSet: (int) fixed_i
{
	ViewerController *v = [listOfViewers objectAtIndex:ind];

	NSMutableArray *roiSeriesList = [v roiList];
	
	for (int i=0; i<[[listOfROIs objectAtIndex:fixed_i] count]; i++) 
	{
		NSMutableArray *roiImageList = [roiSeriesList objectAtIndex:i];
		
		for (int r=0; r<[ [[listOfROIs objectAtIndex:fixed_i] objectAtIndex:i] count]; r++) {
			ROI *rrr = [[[listOfROIs objectAtIndex:fixed_i] objectAtIndex:i] objectAtIndex: r];
			if (rrr == nil) 	continue;
			
			ROI *theNewROI = [[ROI alloc] initWithType: t2DPoint :[rrr pixelSpacingX] :[rrr pixelSpacingY] :[DCMPix originCorrectedAccordingToOrientation: [[v pixList] objectAtIndex:0]]];
			theNewROI.name = [NSString stringWithString:rrr.name];	

			NSRect irect;
			irect.origin.x = rrr.rect.origin.x;
			irect.origin.y = rrr.rect.origin.y;
			irect.size.width = irect.size.height = 0;
			[theNewROI setROIRect:irect];
			[[v imageView] roiSet:theNewROI];
			
			[roiImageList addObject:theNewROI];
 
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixROIChangeNotification object:theNewROI userInfo: nil];	
			[theNewROI release];

		}	

	}	
	
}


-(NSMutableArray*) get2DPoints: (NSMutableArray *) roiArray
{
//	NSLog(@"********* get2DPoints ROIs count =%d ",[roiArray count]);
	
	NSMutableArray *roi2dArray = [NSMutableArray arrayWithCapacity: [roiArray count]]; //[[NSMutableArray arrayWithArray: roiArray] retain];
	for (int i=0; i < [roiArray count]; i++) 
	{
		NSMutableArray *slideROIs = [NSMutableArray arrayWithCapacity:0];
		for (ROI* rrr in [roiArray objectAtIndex:i]) {
			if ( rrr.type ==  t2DPoint)  [slideROIs addObject:rrr];	
		}	

		[roi2dArray insertObject:slideROIs atIndex:i];
	}	
	
//	NSLog(@"********* get2DPoints ROIs count =%d ",[roi2dArray count]);
	return roi2dArray;			
}

-(IBAction) compute:(id) sender
{
	[startButton setEnabled:NO];
	[cancelButton setEnabled:NO];
	
	[[self window] miniaturize:self];
	
	int oper = [[operation selectedCell] tag];
	
	
	// replace method in OsiriX
	SEL osirixMethodSel0 = sel_registerName("loadTexturesCompute");//@selector(newWindow:pixList:fileList:volumeData:frame:); //sel_registerName("newWindow");
	SEL newMethodSel0 =sel_registerName("loadTexturesComputeFusion3"); // @selector(newWindowNew:f:d:v:frame:); //sel_registerName("newWindowNew");	
	method_setImplementation(class_getInstanceMethod([DCMView class], osirixMethodSel0), 
							 class_getMethodImplementation([DCMView class], newMethodSel0));
	
	SEL osirixMethodSel1 = sel_registerName("drawRect:withContext:");//@selector(newWindow:pixList:fileList:volumeData:frame:); //sel_registerName("newWindow");
	SEL newMethodSel1 =sel_registerName("drawRectFusion3:withContext:"); // @selector(newWindowNew:f:d:v:frame:); //sel_registerName("newWindowNew");	
	method_setImplementation(class_getInstanceMethod([DCMView class], osirixMethodSel1), 
							 class_getMethodImplementation([DCMView class], newMethodSel1));
	
	SEL osirixMethodSel2 = sel_registerName("ApplyCLUTString:");
	SEL newMethodSel2 =sel_registerName("CSB_ApplyCLUTString:");
	method_setImplementation(class_getInstanceMethod([ViewerController class], osirixMethodSel2), 
							 class_getMethodImplementation([ViewerController class], newMethodSel2));
	
	SEL osirixMethodSel3 = sel_registerName("ActivateBlending:");
	SEL newMethodSel3 =sel_registerName("CSB_ActivateBlending:");
	method_setImplementation(class_getInstanceMethod([ViewerController class], osirixMethodSel3), 
							 class_getMethodImplementation([ViewerController class], newMethodSel3	));

	if (oper == COPY_ONLY_TAG)  
	{
		[self close];
		return;
	}
	else {
		if ([ViewerController numberOf2DViewer]<3) {
			NSAlert	*myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"The plugin needs at least 3 series for fusion !"]
											   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
			[myAlert runModal];
			[self close];
			return;
		}	
	}
	
	int N_SOURCES = 3;
	int CT_index = 0, PET_index = 1, FMT_index = 2;

	if (listOfViewers != nil) [listOfViewers release];
	if (listOfROIs != nil) [listOfROIs release];
	
	listOfViewers = [NSMutableArray arrayWithCapacity:0];
	listOfROIs = [NSMutableArray arrayWithCapacity:0];
	
	ViewerController *fusedSeries[N_SOURCES];
	for (int i=0; i<N_SOURCES; i++) fusedSeries[i] = nil;

	int current_show;
	int current_ROI_number=0;
	
	for (int i=0; i<[ViewerController numberOf2DViewer]; i++)
	{	
		
		NSString *current_modality = [[[[[ViewerController getDisplayed2DViewers] objectAtIndex:i] fileList] objectAtIndex:0] valueForKey:@"modality"];


		if ([current_modality isEqualToString: @"CT"])		  current_show = CT_index; 
		else if ([current_modality isEqualToString: @"PT"])   current_show = PET_index; 
		else												  current_show = FMT_index;
		
		fusedSeries[current_show] = [[ViewerController getDisplayed2DViewers] objectAtIndex:i];
		[listOfViewers addObject:[[ViewerController getDisplayed2DViewers] objectAtIndex:i]];
		
		[listOfROIs addObject: [self get2DPoints: [[[ViewerController getDisplayed2DViewers] objectAtIndex:i] roiList]]];
		
		if (![current_modality isEqualToString:@"PT"]) {
			int roi_number=0;
			
			for (int j=0; j<[[listOfROIs lastObject] count]; j++) {
				if ([[listOfROIs lastObject] objectAtIndex:j]!=nil) roi_number += [[[listOfROIs lastObject] objectAtIndex:j] count];	
			}	
			
			if (roi_number < 3 || (current_ROI_number>0 && roi_number!=current_ROI_number)) {

				NSAlert	*myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"All series (excluding PT) should have the same number of 2D points and at least 3 points in a series !"]
												   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
				[myAlert runModal];
				[self close];
				return;
				
			}
			current_ROI_number = roi_number;
			
		}	
		
		
		
	}
	
		ViewerController *targetViewer = [filter viewerController];
		BOOL checkPET = NO;
		if (fusedSeries[CT_index] && fusedSeries[PET_index]) // && fusedSeries[FMT_index]) 
		{ 
			
			if (targetViewer!=fusedSeries[PET_index])
			{	
				NSAlert	*myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Plugin will fuse the current set into PET window !"]
											   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
				[myAlert runModal];
			}
			targetViewer = fusedSeries[CT_index];
			[listOfROIs removeObjectAtIndex: [listOfViewers indexOfObject: fusedSeries[PET_index]]];
			[listOfViewers removeObject:fusedSeries[PET_index]];
			checkPET = YES;
		}
		
		Wait *progress = [[Wait alloc] initWithString: NSLocalizedString(@"Point-based registration of the series", nil)];
		[progress showWindow:self];
		[[progress progress] setMaxValue: [listOfViewers count]];
		[progress incrementBy: 1];
		
		ViewerController *currentViewer = nil;

		@try {
			// co-registration
			int fixed_i=0;
			for (int i=0; i<[ listOfViewers count]; i++) {
				if (targetViewer == [listOfViewers objectAtIndex:i]) continue;

				NSString *currentCLUT = [[listOfViewers objectAtIndex:i] curCLUTMenu];
			
				if (currentViewer)  {
					NSLog(@"***** coregistering %d and %d", currentViewer, [listOfViewers objectAtIndex:i]);

					[listOfViewers replaceObjectAtIndex:i withObject: [currentViewer CSB_computeRegistrationWithMovingViewer: [listOfViewers objectAtIndex:i]]];
					NSLog(@"***** result of registering: %d", [listOfViewers objectAtIndex:i]);
					[self roiRestore: i fromSet: fixed_i];
					NSLog(@"***** ROI set %d restored from %d",i, fixed_i);
					[listOfROIs replaceObjectAtIndex:i withObject:[listOfROIs objectAtIndex:fixed_i]];

				}
				else {
					NSLog(@"***** coregistering %d and %d", targetViewer, [listOfViewers objectAtIndex:i]);
				
					[listOfViewers replaceObjectAtIndex:i withObject: [targetViewer CSB_computeRegistrationWithMovingViewer: [listOfViewers objectAtIndex:i]]];
					NSLog(@"***** result of registering: %d", [listOfViewers objectAtIndex:i]);
					fixed_i = [listOfViewers indexOfObject:targetViewer];
					[self roiRestore: i fromSet: fixed_i];
					NSLog(@"***** ROI set %d restored from %d",i, fixed_i);
					[listOfROIs replaceObjectAtIndex:i withObject:[listOfROIs objectAtIndex: fixed_i]];

				}	
				currentViewer = [listOfViewers objectAtIndex:i];
				fixed_i = i;
			
				[[listOfViewers objectAtIndex:i] ApplyCLUTString:currentCLUT];
			
				[progress incrementBy: 1];
			
			}
		
			for (int i=[listOfViewers count]-1; i>=0; i--) {
				if (targetViewer == [listOfViewers objectAtIndex:i]) continue;
					
				if (currentViewer)  {
					[[listOfViewers objectAtIndex:i] ActivateBlending: currentViewer];
				}	
				currentViewer = [listOfViewers objectAtIndex:i];
					
			}
			if (currentViewer != nil && targetViewer != currentViewer) {
				[targetViewer ActivateBlending: currentViewer];
			}	
		
			if (checkPET) [fusedSeries[PET_index] ActivateBlending:targetViewer];
		
		}
		@catch(NSException *e) 
		{
			NSLog(@"CSB_Multi_Fusion: exception %@", e);	
		}	
		[progress close];
		[progress release];

	
	[self close];

}



- (void)awakeFromNib
{
		
}

- (id) init:(CSB_Multi_FusionFilter*) f 
{

	self = [super initWithWindowNibName:@"ControllerCSBMultiFusion"];
	
	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	
	COPY_ONLY_TAG = 100;
	COPY_AND_FUSE_TAG = 101;
	
	filter = f;
	
	[self check_CSB_LUT];

	return self;
}

- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"CSB_Multi_Fusion: Window will close.... and release his memory...");
	
	[self autorelease];

}

- (void) dealloc
{
 //   NSLog(@"My window is deallocating a pointer");
	
	[super dealloc];
}

- (IBAction) fetch:(id) sender
{
	
}

-(void) check_CSB_LUT 
{
	BOOL clutUpdated = NO;
	NSMutableDictionary *clutDict		= [[[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] mutableCopy] autorelease];
	
	if ( [clutDict objectForKey:@"CSB_Red"] == nil)
	{	
		clutUpdated = YES;
		
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
		
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		
		for( int i = 0; i < 256; i++) {
			[rArray addObject: [NSNumber numberWithLong: i]];
			[gArray addObject: [NSNumber numberWithLong: 0]];
			[bArray addObject: [NSNumber numberWithLong: 0]];
		}	
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		
		[clutDict setObject: aCLUTFilter forKey: @"CSB_Red"];
		
		
	}	
	
	if ( [clutDict objectForKey:@"CSB_Green"] == nil)
	{
		clutUpdated = YES;
		
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
		
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		
		for( int i = 0; i < 256; i++) {
			[rArray addObject: [NSNumber numberWithLong: 0]];
			[gArray addObject: [NSNumber numberWithLong: i]];
			[bArray addObject: [NSNumber numberWithLong: 0]];
		}	
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		
		[clutDict setObject: aCLUTFilter forKey: @"CSB_Green"];
		
	}	
	
	if ([clutDict objectForKey:@"CSB_Blue"] == nil)
	{	
		clutUpdated = YES;
		
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
		
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		for( int i = 0; i < 256; i++) {
			[rArray addObject: [NSNumber numberWithLong: 0]];
			[gArray addObject: [NSNumber numberWithLong: 0]];
			[bArray addObject: [NSNumber numberWithLong: i]];
		}	
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 1], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		
		[clutDict setObject: aCLUTFilter forKey: @"CSB_Blue"];
		
		
	}	
	
	if ([clutDict objectForKey:@"CSB_Magenta"] == nil)
	{	
		clutUpdated = YES;
		
		NSMutableDictionary *aCLUTFilter	= [NSMutableDictionary dictionary];
		
		NSMutableArray		*rArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*gArray = [NSMutableArray arrayWithCapacity:0];
		NSMutableArray		*bArray = [NSMutableArray arrayWithCapacity:0];
		for( int i = 0; i < 256; i++) {
			[rArray addObject: [NSNumber numberWithLong: i]];
			[gArray addObject: [NSNumber numberWithLong: 0]];
			[bArray addObject: [NSNumber numberWithLong: i]];
		}	
		[aCLUTFilter setObject:rArray forKey:@"Red"];
		[aCLUTFilter setObject:gArray forKey:@"Green"];
		[aCLUTFilter setObject:bArray forKey:@"Blue"];
		
		// Points & Colors
		NSMutableArray *colors = [NSMutableArray arrayWithCapacity:0], *points = [NSMutableArray arrayWithCapacity:0];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 0], nil]];
		[points addObject:[NSNumber numberWithLong: 0]];
		
		[colors addObject:[NSArray arrayWithObjects: [NSNumber numberWithFloat: 1], [NSNumber numberWithFloat: 0], [NSNumber numberWithFloat: 1], nil]];
		[points addObject:[NSNumber numberWithLong: 256]];
		
		[aCLUTFilter setObject:colors forKey:@"Colors"];
		[aCLUTFilter setObject:points forKey:@"Points"];
		
		
		[clutDict setObject: aCLUTFilter forKey: @"CSB_Magenta"];
		
	}	

	if (clutUpdated) {
		[[NSUserDefaults standardUserDefaults] setObject: clutDict forKey: @"CLUT"];
		
		NSString *menuName = [[filter viewerController] curCLUTMenu];
		
		[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: menuName userInfo: nil];
	}
	
}


@end



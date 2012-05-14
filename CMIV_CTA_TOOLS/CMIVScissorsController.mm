/*=========================================================================
Author: Chunliang Wang (chunliang.wang@imv.liu.se)


Program:  CMIV CTA image processing Plugin for OsiriX

This file is part of CMIV CTA image processing Plugin for OsiriX.

Copyright (c) 2007,
Center for Medical Image Science and Visualization (CMIV),
Linkšping University, Sweden, http://www.cmiv.liu.se/

CMIV CTA image processing Plugin for OsiriX is free software;
you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software 
Foundation, either version 3 of the License, or (at your option)
any later version.

CMIV CTA image processing Plugin for OsiriX is distributed in
the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=========================================================================*/
#import "CMIVScissorsController.h"
#import "CMIV3DPoint.h"
#import "CMIVSegmentCore.h"
#import "QuicktimeExport.h"

#define id Id
//#include "itkConnectedThresholdImageFilter.h"
#include "itkImage.h"
//#include "itkCurvatureFlowImageFilter.h"
#include "itkImportImageFilter.h"
//#include "itkGeodesicActiveContourLevelSetImageFilter.h"
#include "itkCurvatureAnisotropicDiffusionImageFilter.h"
//#include "itkGradientMagnitudeRecursiveGaussianImageFilter.h"
//#include "itkSigmoidImageFilter.h"
#include "itkFastMarchingImageFilter.h"
//#include "itkRescaleIntensityImageFilter.h"
#include "itkBinaryThresholdImageFilter.h"
#include "itkThresholdSegmentationLevelSetImageFilter.h"
#include "itkDanielssonDistanceMapImageFilter.h"

#include "itkRelabelComponentImageFilter.h"
#include "itkConnectedComponentImageFilter.h"
#include "itkImageRegionIterator.h"
#include "itkLabelStatisticsImageFilter.h"
#undef id




//#define VERBOSEMODE
//print out some detail logs



static		float						deg2rad = 3.14159265358979/180.0; 

@implementation CMIVScissorsController

#pragma mark-
#pragma mark 1. show/close the window
- (BOOL)windowShouldClose:(id)window
{
	if([cpr3DPaths count]&&needSaveCenterlines)
	{
		id waitWindow = [originalViewController startWaitWindow:@"Saving Centerlines"];	
		[self saveCenterlinesInPatientsCoordination];
		[originalViewController endWaitWindow: waitWindow];
	}
	if(needSaveSeeds&&contrastVolumeData)
	{
		int nrespond=NSRunAlertPanel(NSLocalizedString  (@"Save Seeds?", nil), NSLocalizedString(@"Do you want to save current seeds?", nil), NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), NSLocalizedString(@"Cancel", nil));
		if(nrespond==1)
			[self saveCurrentSeeds];
		else if(nrespond==-1)
			return NO;
			
	}
	if([basketImageArray count])
		[self saveImagesInBasket:self];
	
	return YES;
}
- (void)windowWillClose:(NSNotification *)notification
{
	NSLog(@"cmiv 2d view will close");
	[originalView setDrawing: NO];
	[cPRView setDrawing: NO];
	[crossAxiasView setDrawing: NO];
	
	if([[seedToolTipsTabView tabViewItemAtIndex:0] identifier]&&[[NSString stringWithString:@"Basket"] isEqualToString:[[seedToolTipsTabView tabViewItemAtIndex:0] identifier]] )
	{
		[self emptyImageInBasket:self];
		[basketImageArray release];
		[basketImageROIArray release];
	}
	
	
	
	[[self window] setHorizontalSlider:nil];
	[[self window] setVerticalSlider:nil];
	[[self window] setTranlateSlider:nil];
	[cPRView setHorizontalSlider:nil];
	[cPRView setTranlateSlider:nil];	
	[crossAxiasView setTranlateSlider:nil];
	[originalView setDrawing: NO];
	[cPRView setDrawing: NO];
	[crossAxiasView setDrawing: NO];
	if(!isInWizardMode)
	{
		[centerlinesList setDataSource:nil];
		[seedsList setDataSource:nil];	
	}
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[NSUserDefaults standardUserDefaults] setInteger: annotations forKey: @"ANNOTATIONS"];
	if(!roiShowNameOnly)
		[[NSUserDefaults standardUserDefaults] setBool:roiShowNameOnly forKey: @"ROITEXTNAMEONLY"];
	if(!roiShowTextOnlyWhenSeleted)
		[[NSUserDefaults standardUserDefaults] setBool:roiShowTextOnlyWhenSeleted forKey:@"ROITEXTIFSELECTED"];
	[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	unsigned i;
	NSString* emptystr=[NSString stringWithString:@""];
	for(i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
		[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] setComments:emptystr];	
	[[oViewROIList objectAtIndex: 0] removeAllObjects];
//	[[oViewROIList objectAtIndex: 1] removeAllObjects];
	[oViewROIList removeAllObjects];
	[oViewROIList release];
	[oViewPixList removeAllObjects];
	[oViewPixList release];
	[cViewPixList removeAllObjects];
	[cViewPixList release];
	[[cViewROIList objectAtIndex: 0]  removeAllObjects];
	[cViewROIList removeAllObjects];
	[cViewROIList release];
	[axViewPixList removeAllObjects];
	[axViewPixList release];
	[[axViewROIList objectAtIndex: 0]  removeAllObjects];
	[axViewROIList removeAllObjects];
	[axViewROIList release];

	for(i=0;i<[contrastList count];i++)
		[[contrastList objectAtIndex: i] removeAllObjects];
	[contrastList removeAllObjects];
	[contrastList release];
	
	
	[totalROIList  removeAllObjects];
	[totalROIList release];
	
	[curvedMPR3DPath removeAllObjects];
	[curvedMPR3DPath release];
	[curvedMPRProjectedPaths removeAllObjects];
	[curvedMPRProjectedPaths release];
	
	[vesselAnalysisMeanHu release];
	[vesselAnalysisMaxHu release];
	[vesselAnalysisArea release];
	[vesselAnalysisLongDiameter release];
	[vesselAnalysisShortDiameter release];
	[vesselAnalysisCentersInLongtitudeSection release];
	
	if(curvedMPRReferenceLineOfAxis)
		[curvedMPRReferenceLineOfAxis release];
	[curvedMPR2DPath release];
	if(curvedMPREven3DPath)
		[curvedMPREven3DPath release];
	if(axViewNOResultROI)
		[axViewNOResultROI release];
	if(axViewMeasurePolygon)
		[axViewMeasurePolygon release];
	if(cViewMeasurePolygon)
		[cViewMeasurePolygon release];
	
	if(contrastVolumeData)
		free(contrastVolumeData);
	
	if(reader)
	{
		reader->Delete();
		
		oViewSlice->Delete();
		
		oViewBasicTransform->Delete();
		oViewUserTransform->Delete();
		cViewTransform->Delete();
		axViewTransform->Delete();
		cViewSlice->Delete();
		axViewSlice->Delete();

		roiReader->Delete();
		oViewROISlice->Delete();

		if(fuzzyConectednessMap)
		{
			axROIReader->Delete();
			axViewROISlice->Delete();
			
		}
		///////////////
		
	}
	if(axViewConnectednessCostMap)
		free(axViewConnectednessCostMap);
	if(connectednessROIBuffer)
		free(connectednessROIBuffer);

	if(howToContinueTip)
		[howToContinueTip release];
	
	[[self window] setDelegate:nil];
	[originalViewController release];
	[originalViewVolumeData release];
	[originalViewPixList release];
	if(parentVesselnessMap)
		[parentVesselnessMap release];
	if(parentFuzzyConectednessData)
		[parentFuzzyConectednessData release];
	if(cpr3DPaths)
		[cpr3DPaths release];
	if(centerlinesNameArrays)
		[centerlinesNameArrays release];
	if(centerlinesLengthArrays)
		[centerlinesLengthArrays release];
	[seedToolTipsTabView setDelegate:nil];

	[self autorelease];
	
}
-(void) dealloc
{
	
	[super dealloc];
	NSLog(@"cmiv 2d view dealloced");
}
- (IBAction)onCancel:(id)sender
{
	int tag=[sender tag];
	
	
	// must not be here otherwise windowwillclose will not be called[[NSNotificationCenter defaultCenter] removeObserver: self];
	if(isInitialWithCPRMode)
	{
		NSMutableDictionary* dic=[parent dataOfWizard];
		[dic setObject:[NSString stringWithString:@"finish"] forKey:@"Step"];
	}	

	CMIV_CTA_TOOLS* tempparent=parent;
	[[self window] performClose:self];
	if(tag)
	{
		[tempparent gotoStepNo:3];
	}
	
	
}

- (IBAction)onOK:(id)sender
{
	int err=0;
	if(autoSegmentTimer)
	{
		[autoSegmentTimer invalidate];
		[autoSegmentTimer release];
		autoSegmentTimer=nil;
	}
	if(uniIndex>=2)
	{
		int i;
		NSString* roiname;
		ROI* temproi=[totalROIList objectAtIndex: 0];
		roiname=[temproi name];
		err=1;
		for(i=1;i<uniIndex;i++)
		{
			temproi=[totalROIList objectAtIndex: i];
			if(![roiname isEqualToString:[temproi name]])
			{
				err=0;
				break;
			}
			   
		}
		

	}
	else 
		err=1;
	if(err)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough seeds found", nil), NSLocalizedString(@"We need at least two sets of seeds with different names to start the segmenation algorithm", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	[self runSegmentation];
	/* NSArray				*pixList = [originalViewController pixList];
	unsigned int i;
	id waitWindow = [originalViewController startWaitWindow:@"processing"];
	NSMutableArray      *roiList;
	short unsigned int* im;
	for(i=0;i<[pixList count];i++)
	{
		roiList= [[originalViewController roiList] objectAtIndex: i];
		im=contrastVolumeData+imageSize*i;
		[self creatROIListFromSlices: roiList  :imageWidth :imageHeight :im :xSpacing :ySpacing :  [curPix originX]: [curPix originY]];
		
		
	}
	roiList= [originalViewController roiList] ;
	[self checkRootSeeds:roiList];
	[originalViewController endWaitWindow: waitWindow];
	[[originalViewController window] setTitle:@"Seeds Planted"];
	[self onCancel:sender];
	 */
}

- (id) showScissorsPanel:(ViewerController *) vc : (CMIV_CTA_TOOLS*) owner
{
	//initialize the window
	self = [super initWithWindowNibName:@"Scissors_Panel"];
	[[self window] setDelegate:self];
	
	//prepare images 
	
	int err=0;
	originalViewController=vc;	
	parent = owner;	
	originalViewVolumeData=[vc volumeData];
	originalViewPixList=[vc pixList];
	
	[originalViewController retain];
	[originalViewVolumeData retain];
	[originalViewPixList retain];
	
	curPix = [[originalViewController pixList] objectAtIndex: [[originalViewController imageView] curImage]];
	
	if( [curPix isRGB])
	{
		NSRunAlertPanel(NSLocalizedString(@"no RGB Support", nil), NSLocalizedString(@"This plugin doesn't surpport RGB images, please convert this series into BW images first", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 0;
	}	
	//store annotation state
	annotations	= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
	if([[NSUserDefaults standardUserDefaults] integerForKey: @"CMIV2DViewANNOTATIONS"]!=-1)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: 2 forKey: @"ANNOTATIONS"];
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"CMIV2DViewANNOTATIONS"];
		[showAnnotationButton setState:NSOnState];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"ANNOTATIONS"];
		[showAnnotationButton setState:NSOffState];
	}
	defaultROIThickness=[[NSUserDefaults standardUserDefaults] floatForKey:@"ROIThickness"];
	[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	roiShowTextOnlyWhenSeleted=[[NSUserDefaults standardUserDefaults] boolForKey:@"ROITEXTIFSELECTED"];
	roiShowNameOnly=[[NSUserDefaults standardUserDefaults] boolForKey: @"ROITEXTNAMEONLY"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"ROITEXTNAMEONLY"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTIFSELECTED"];
	interpolationMode=1;
	NSArray				*pixList = [originalViewController pixList];
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [pixList count];	
	imageSize = imageWidth*imageHeight;
	fileList =[originalViewController fileList ];
	
	minValueInSeries = [curPix minValueOfSeries]; 
	

	
	
	//initilize original view CPRView and Axial View;
	err = [self initViews];
	if(err)
		return nil;
	[self resetSliders];
	needSaveSeeds=NO;
	err = [self initSeedsList];
	if(err)
		return nil;
	[seedsList setDataSource:self];	
	
	currentTool=0;
	currentPathMode=ROI_sleep;
	cViewMPRorCPRMode=0;
	[self initCenterList];
	[centerlinesList setDataSource:self];
	
	[self initVesselAnalysis];

	
	//registe the notificationcenter
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self selector: @selector(defaultToolModified:) name:@"defaultToolModified" object:nil];
	[nc addObserver: self selector: @selector(roiChanged:) name:@"roiChange" object:nil];
	[nc addObserver: self selector: @selector(roiAdded:) name:@"addROI" object:nil];
	[nc addObserver: self selector: @selector(roiRemoved:) name:@"removeROI" object:nil];
	[nc	addObserver: self selector: @selector(changeWLWW:) name: @"changeWLWW" object: nil];	
	[nc	addObserver: self selector: @selector(crossMove:) name: @"crossMove" object: nil];	
	[nc	addObserver: self selector: @selector(dcmViewMouseDown:) name: @"cmivCTAViewMouseDown" object: nil];
	[nc	addObserver: self selector: @selector(dcmViewMouseUp:) name: @"cmivCTAViewMouseUp" object: nil];
	
	[seedToolTipsTabView setDelegate:self];
	
	if(isInWizardMode)
	{
		[seedToolTipsTabView selectTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:2]];
		[plotView removeFromSuperviewWithoutNeedingDisplay];
		[vesselAnalysisPanel removeFromSuperviewWithoutNeedingDisplay];
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:4]];		//tabViewItemAtIndex:4->1 is necessary, otherwise index will change after remove
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:3]];
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:1]];
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:0]];

		
		[captureOViewButton setHidden:YES];
		[captureCViewButton setHidden:YES];
		[captureAxViewButton setHidden:YES];
		totalSteps=3;
		[self goSubStep:0:YES];
		[previousButton setEnabled: NO];
		howToContinueTip = [[NSString alloc] initWithString:@"You are using a general tools, to contiue seed planting, please click the button below."];
		[continuePlantingButton setHidden:YES];
	}
	else if([cpr3DPaths count])
	{
		[seedToolTipsTabView selectTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:3]];
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:2]];	
		//[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:1]];
		isInitialWithCPRMode=YES;

		[self changAmongMPRCPRAndAnalysis:1];
	}
	else
	{
		[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:2]];
		//	[seedToolTipsTabView removeTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:1]];
		//	[nextButton setHidden:YES];
		//	[previousButton setHidden:YES];
		[seedToolTipsTabView selectTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:0]];

		
	}
	
	if([[seedToolTipsTabView tabViewItemAtIndex:0] identifier]&&[[NSString stringWithString:@"Basket"] isEqualToString:[[seedToolTipsTabView tabViewItemAtIndex:0] identifier]] )
	{
		basketImageArray=[[NSMutableArray alloc] initWithCapacity:0];
		basketImageROIArray=[[NSMutableArray alloc] initWithCapacity:0];
		[basketMatrix setPrototype:[basketMatrix cellAtRow:0 column:0]];
		[basketScrollView setDocumentView:basketMatrix];
	}
	
	
	if(!isInitialWithCPRMode)
	{
		[[self window] setHorizontalSlider:oYRotateSlider];
		[[self window] setVerticalSlider:oXRotateSlider];
		[[self window] setTranlateSlider:oImageSlider];
		
		[cPRView setHorizontalSlider:cYRotateSlider];
		[cPRView setTranlateSlider:cImageSlider];
		
	}
	else
	{
		[[self window] setHorizontalSlider:oXRotateSlider];
		[[self window] setVerticalSlider:oImageSlider];
		[[self window] setTranlateSlider:oYRotateSlider];
		
		[cPRView setHorizontalSlider:cImageSlider];
		[cPRView setTranlateSlider:cYRotateSlider ];
	}
	[originalView setHorizontalSlider:nil];
	[originalView setTranlateSlider:nil];
	
	[crossAxiasView setTranlateSlider:axImageSlider];
	[crossAxiasView setHorizontalSlider:nil];
	
	// show the window
	screenrect=[[[originalViewController window] screen] visibleFrame];
	[[self window]setFrame:screenrect display:NO animate:NO];
	[super showWindow:parent];
	[[self window] makeKeyAndOrderFront:parent];
	[[self window] setLevel:NSFloatingWindowLevel];
	[[self window] display];
	
	
	
	if(!isInWizardMode)
	{
		[self changeCurrentTool:0];
		//NSRect arect=[exportView visibleRect];
		//arect.size.height=[exportView frame].size.height;
		//[exportView addTrackingRect:arect owner:self userData:[NSNumber numberWithInt:1] assumeInside:NO];
		//exportViewIsClosed=1;
		//[seedToolTipsTabView addTrackingRect:[seedToolTipsTabView visibleRect] owner:self userData:[NSNumber numberWithInt:2] assumeInside:NO];
	}		
		//[self selectAContrast:seedsList];
	NSMutableDictionary* dic=[parent dataOfWizard];

	if([dic objectForKey:@"SeedMap"])
	{

		
	
			[self loadSavedSeeds];
			[seedToolTipsTabView selectTabViewItem:[seedToolTipsTabView tabViewItemAtIndex:1]];
			[self changAmongMPRCPRAndAnalysis:0];
			if(!isInWizardMode)
			{
				[seedsList reloadData];
			}
			[self updateOView];
	}
	

		
	
#ifdef VERBOSEMODE
	NSLog( @"******************************CMIV_CTA_PLUGIN 2D View established!*************************************");
#endif
	//mistery bug happens when DCMView.h is not updated, scaleValue will be 0, without following code.
	NSGraphicsContext *context = [NSGraphicsContext currentContext];
	NSPoint apoint;
	apoint.x=1;
	apoint.y=1;
	NSEvent* virtualMouseDownEvent=[NSEvent mouseEventWithType:NSRightMouseDown location:apoint
										modifierFlags:nil timestamp:GetCurrentEventTime() windowNumber: 0 context:context eventNumber: nil clickCount:1 pressure:nil];
	NSEvent* virtualMouseUpEvent = [NSEvent mouseEventWithType:NSRightMouseUp location:apoint
										  modifierFlags:nil timestamp:GetCurrentEventTime() windowNumber: 0 context:context eventNumber: nil clickCount:1 pressure:nil];
	[originalView mouseDown:virtualMouseDownEvent];
	[originalView mouseUp:virtualMouseUpEvent];
	[cPRView mouseDown:virtualMouseDownEvent];
	[cPRView mouseUp:virtualMouseUpEvent];
	[crossAxiasView mouseDown:virtualMouseDownEvent];
	[crossAxiasView mouseUp:virtualMouseUpEvent];
	//mistery bug above
	
	return self;
	
}
- (id)showPanelAsWizard:(ViewerController *) vc:(	CMIV_CTA_TOOLS*) owner
{
	isInWizardMode=1;
	[self showScissorsPanel: vc:owner];
	NSMutableDictionary* dic=[parent dataOfWizard];	
	if([dic objectForKey:@"SeedMap"])
	{
		[self goSubStep:2:NO];
		//[self performSelector:@selector(goNextStep:) withObject:nil afterDelay:1];
		[parent cleanDataOfWizard];
	}
		
	return self;
	
}
- (id)showPanelAsAutomaticWizard:(ViewerController *) vc:(	CMIV_CTA_TOOLS*) owner
{
	[self showScissorsPanel:vc :owner];
	if(contrastVolumeData&&[cpr3DPaths count]==0)
	{
		timeCountDown=3;
		[saveButton setTitle:[NSString stringWithFormat:@"Seg. start in %d seconds",timeCountDown]];
		[cancelSegmentationButton setHidden:NO];
		NSColor *color = [NSColor redColor];
		
		NSMutableAttributedString *colorTitle =
		[[NSMutableAttributedString alloc] initWithAttributedString:[cancelSegmentationButton attributedTitle]];
		
		NSRange titleRange = NSMakeRange(0, [colorTitle length]);
		
		[colorTitle addAttribute:NSForegroundColorAttributeName
						   value:color
						   range:titleRange];
		
		[cancelSegmentationButton setAttributedTitle:colorTitle];
		
		autoSegmentTimer = [[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(changeSegmentButtonTitle:) userInfo:self repeats:YES] retain];
		
	}
	return self;
	
}
//{
//	isInWizardMode=2;
//	parent = owner;	
//	[self showScissorsPanel: vc:owner];
//	
//	//CMIV3DPoint* startPoint=nil;
//	//startPoint=[[parent dataOfWizard] objectForKey:@"AortaPoint"];
//	NSMutableDictionary* dic=[parent dataOfWizard];
//	
//	NSString* stepstr=[dic objectForKey:@"Step"];
//	 if([stepstr isEqualToString:@"Step3"])
//	{
//		NSNumber* lastUniIndex=[dic objectForKey:@"UniIndex"];
//		//NSNumber* startPointr=[dic objectForKey:@"AortaPointr"];
//		
//		[self loadVesselnessMap];	
//		if(lastUniIndex)
//		{
//			[self loadSavedSeeds];
//			[self goSubStep:2:NO];
//		}
//		
//		[self performSelector:@selector(goNextStep:) withObject:nil afterDelay:1];	
//		
//		//[self performSelector:@selector(loadSegmentationResult:) withObject:nil afterDelay:1];	
//	}
//	else if([stepstr isEqualToString:@"Step2"])
//	{
//		NSNumber* lastUniIndex=[dic objectForKey:@"UniIndex"];
//		//NSNumber* startPointr=[dic objectForKey:@"AortaPointr"];
//		
//		[self loadVesselnessMap];	
//		if(lastUniIndex)
//		{
//			[self loadSavedSeeds];
//			[self goSubStep:2:NO];
//		}
//		 
//		[self performSelector:@selector(goNextStep:) withObject:nil afterDelay:1];	
//	}
//	else if([stepstr isEqualToString:@"Step1"])
//	{
//		NSNumber* startPointx=[dic objectForKey:@"AortaPointx"];
//		NSNumber* startPointy=[dic objectForKey:@"AortaPointy"];
//		NSNumber* startPointz=[dic objectForKey:@"AortaPointz"];
//		[self loadVesselnessMap];
//		if(startPointx)
//		{
//			double position[3];
//			position[0]=[startPointx floatValue]+vtkOriginalX;
//			position[1]=[startPointy floatValue]+vtkOriginalY;
//			position[2]=[startPointz floatValue]+vtkOriginalZ;
//			
//			
//			
//			oViewBasicTransform->Identity();
//			oViewBasicTransform->Translate(position);
//			oViewBasicTransform->RotateX(-90);
//			oViewUserTransform->Identity ();
//			[self updateOView];
//			[self cAndAxViewReset];
//			[self resetSliders];	
//			
//			[axViewSigemaSlider setFloatValue:40];
//			[axViewAreaSlider setFloatValue:60];
//			[axViewLowerThresholdSlider setFloatValue:150];
//			[self setAxViewThreshold:axViewLowerThresholdSlider];
//			[self changLeveSetSigema:axViewSigemaSlider];
//			[self changAxViewROIArea:axViewAreaSlider];
//			//if(!startPointx)
//			//	return self;
//			axViewROIMode=1;
//			isNeedSmoothImgBeforeSegment=YES;
//			[self startCrossSectionRegionGrowing:autoSeedingButton];
//			[self saveCurrentSeeds];
//			
//			
//		}
//		
//		[self performSelector:@selector(goNextStep:) withObject:nil afterDelay:1];
//	}
//	
//	
//	return self;
//	
//}
- (id)showPanelAsCPROnly:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner
{
	isInitialWithCPRMode=YES;
	needSaveCenterlines=YES;
	parent = owner;	
	
	parentFuzzyConectednessData=[[parent dataOfWizard] objectForKey:@"OutputData"];
	
	cpr3DPaths=[[parent dataOfWizard] objectForKey:@"CenterlinesList"];
	centerlinesNameArrays=[[parent dataOfWizard] objectForKey:@"CenterlinesNameList"];
	if(parentFuzzyConectednessData)
	{
		[parentFuzzyConectednessData retain];
		fuzzyConectednessMap=(float *)[parentFuzzyConectednessData bytes];

	}
	
	if(cpr3DPaths&&centerlinesNameArrays)
	{
		[cpr3DPaths retain];
		[centerlinesNameArrays retain];
	}
	else
		return nil;
	[parent cleanSharedData];
	
	[self showScissorsPanel: vc:owner];
	[axViewAreaSlider setFloatValue:10];
	[self changAxViewROIArea:axViewAreaSlider];
	[resampleRatioSlider setFloatValue:2.5];
	[resampleRatioText setFloatValue:2.5];
	//[axViewROIMode selectCellAtRow:2 column:0];
	[self setAxViewThreshold:axViewLowerThresholdSlider];
	[self convertCenterlinesToVTKCoordinate:cpr3DPaths];
	[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex: 0]:[resampleRatioSlider floatValue]];
	[self recaculateAllCenterlinesLength];
	[centerlinesList reloadData];
	[cImageSlider setEnabled: NO];
	//[cYRotateSlider setEnabled: NO];

	return self;
	
	
}

- (id) showPanelAfterROIChecking:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner
{
	//int err=0;
	originalViewController=vc;	
	unsigned int i,j,k;
	int thereIsSameName ;
	NSMutableArray *curRoiList = [originalViewController roiList];
	ROI * tempROI;
	NSMutableArray *existedMaskList = [[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableArray *temppathlist = [[NSMutableArray alloc] initWithCapacity: 0];
	
	for(i=0;i<[curRoiList count];i++)
		for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
		{
			tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
			if([tempROI type]==tPlain)
			{
				thereIsSameName=0;
				for(k=0;k<[existedMaskList count];k++)
				{ 
					if ([[tempROI name] isEqualToString:[existedMaskList objectAtIndex: k] ]==YES)
						thereIsSameName=1;
				}
				if(!thereIsSameName)
				{
					[existedMaskList addObject:[tempROI name]];
					[pathListButton addItemWithTitle: [tempROI name]];
				}	
			}
			
		}
	if([existedMaskList count]>0)
	{
		for(i=0;i<[existedMaskList count];i++)
		{
			NSMutableArray *temp3DPath=[self create3DPathFromROIs:[existedMaskList objectAtIndex:i]];
			if(temp3DPath!=nil)
				[temppathlist addObject:temp3DPath];
			else
			{
				[existedMaskList removeObjectAtIndex:i];
				i--;
			}
			
			
		}
	}
	cpr3DPaths=temppathlist;
	centerlinesNameArrays=existedMaskList;
	if([temppathlist count]>0)
	{	
		isInitialWithCPRMode=YES;
		[self showScissorsPanel: vc:owner];
		[self convertCenterlinesToVTKCoordinate:cpr3DPaths];
		[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex: 0]:[resampleRatioSlider floatValue]];
		[cImageSlider setEnabled: NO];
		//[cYRotateSlider setEnabled: NO];
		[self recaculateAllCenterlinesLength];
		[centerlinesList reloadData];

	}
	else
	{
		[self showScissorsPanel: vc:owner];
		
	}
	
	
	
	return self;
}


#pragma mark-
#pragma mark 2.1 control MRP views and General Tools
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSString* tabidstr=[tabViewItem identifier];
	
	if(isDrawingACenterline)
	{
		NSRunAlertPanel(NSLocalizedString(@"Creating A Centerline", nil), NSLocalizedString(@"Please finish the Centerline first", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return NO;
	}
	else if(tabidstr)
	{
		if([[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
		{
			
		}
		else if([[NSString stringWithString:@"Centerlines"] isEqualToString:tabidstr])
		{
			
		}
		else if([[NSString stringWithString:@"VesselAnalysis"] isEqualToString:tabidstr])
		{
			if(!curvedMPREven3DPath||[curvedMPREven3DPath count]<2)
			{
				NSRunAlertPanel(NSLocalizedString(@"NO Centerline Selected", nil), NSLocalizedString(@"Please choose a centerline first", nil), NSLocalizedString(@"OK", nil), nil, nil);
				return NO;
			}
		}
	}
	return YES;
	
}
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	NSString* tabidstr=[tabViewItem identifier];
	int indextab=0;
	if(tabidstr)
	{
		if([[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
		{
			indextab=0;
			[self changAmongMPRCPRAndAnalysis:indextab];
		}
		else if([[NSString stringWithString:@"Centerlines"] isEqualToString:tabidstr])
		{
			indextab=1;
			[self changAmongMPRCPRAndAnalysis:indextab];
		}
		else if([[NSString stringWithString:@"VesselAnalysis"] isEqualToString:tabidstr])
		{
			indextab=2;
			
			[self changAmongMPRCPRAndAnalysis:indextab];
		}
	}
	
	
}
- (void)changAmongMPRCPRAndAnalysis:(int)modeindex
{
	if(currentViewMode==modeindex)
		return;
	currentViewMode=modeindex;
	
	[[self window] setHorizontalSlider:oXRotateSlider];
	[[self window] setVerticalSlider:oImageSlider];
	[[self window] setTranlateSlider:oYRotateSlider];
	[cPRView setHorizontalSlider:cImageSlider];
	[cPRView setTranlateSlider:cYRotateSlider];
	
	
	if(modeindex==0)
	{
		if(isStraightenedCPR)
			[self switchStraightenedCPR:self];
		axViewROIMode=0;
		cViewMPRorCPRMode=0;
		[[self window] setHorizontalSlider:oYRotateSlider];
		[[self window] setVerticalSlider:oXRotateSlider];
		[[self window] setTranlateSlider:oImageSlider];
		
		[cPRView setHorizontalSlider:cYRotateSlider];
		[cPRView setTranlateSlider:cImageSlider];
		[repulsorButton setEnabled:NO];
		int showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowAxViewCrossHair"];
		if(showcross==1)
		{
			[axViewCrossShowButton setState:NSOnState];
			[crossAxiasView showCrossHair];
			[self updateAxView];
		}
		showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowCViewCrossHair"];
		if(showcross==1)
		{
			[cViewCrossShowButton setState:NSOnState];
			[cPRView showCrossHair];
			[self updateCView];
		}
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTIFSELECTED"];
		
		
		
	}
	else if(modeindex==1)
	{
		axViewROIMode=0;
		cViewMPRorCPRMode=1;
		[cPRView setCrossCoordinates:-9999 :-9999 :YES];
		[cPRView hideCrossHair];
		[cViewCrossShowButton setState:NSOffState];
		[crossAxiasView setCrossCoordinates:-9999 :-9999 :YES];
		[crossAxiasView hideCrossHair];
		[axViewCrossShowButton setState:NSOffState];

		[repulsorButton setEnabled:NO];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTIFSELECTED"];
		if([curvedMPR3DPath count]==0&&[cpr3DPaths count]>0)
		{
			[centerlinesList selectRow:0 byExtendingSelection: YES];
			[self selectANewCenterline:[cpr3DPaths objectAtIndex:0]];
		}
		
	}
	else if(modeindex==2)
	{
		cViewMPRorCPRMode=1;
		if(fuzzyConectednessMap)
		{
			axViewROIMode=2;
		}
		else
			axViewROIMode=1;
		if(!isStraightenedCPR)
		{
			[vesselAnalysisLongDiameter removeAllObjects];
			[self switchStraightenedCPR:self];
		}
		[repulsorButton setEnabled:YES];
		[cPRView setCrossCoordinates:-9999 :-9999 :YES];
		[cPRView hideCrossHair];
		[cViewCrossShowButton setState:NSOffState];
		[crossAxiasView setCrossCoordinates:-9999 :-9999 :YES];
		[crossAxiasView hideCrossHair];
		[axViewCrossShowButton setState:NSOffState];
		
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ROITEXTIFSELECTED"];
		if([vesselAnalysisLongDiameter count]==0)
		{
			[vesselAnalysisPlotSourceButton selectItemAtIndex:0];
			[self vesselAnalysisStart:self];
			if(2*vesselAnalysisMaxLongitudeDiameter>10)
				[axViewAreathText setFloatValue: 2*vesselAnalysisMaxLongitudeDiameter];
			else
				[axViewAreathText setFloatValue: 10];
			if(vesselAnalysisMaxLongitudeDiameter/3<1.0)
			{
				[vesselAnalysisParaStepText setFloatValue:1.0];
				[vesselAnalysisParaStepSlider setFloatValue:1.0];
			}
			else
			{
				[vesselAnalysisParaStepText setFloatValue:vesselAnalysisMaxLongitudeDiameter/3];
				[vesselAnalysisParaStepSlider setFloatValue:vesselAnalysisMaxLongitudeDiameter/3];
			}
			
			[self changAxViewROIArea:axViewAreathText];
			[self changeCurrentTool:0];
			[self updateOView];
			[self updatePageSliders];
			return;
		}
		else
			[self vesselAnalysisSetNewSource:self];
		
	}
	lastOViewZAngle=0,lastCViewZAngle=0,lastAxViewZAngle=0;
	[self changeCurrentTool:0];
	[self updateOView];
	[self cAndAxViewReset];
	[self updatePageSliders];
}

- (int) initViews
{
	
	
	//long                size;
	NSArray				*pixList = [originalViewController pixList];
	
	volumeData=[originalViewController volumePtr:0];

	
	//size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
	//contrastVolumeData = (unsigned short int*) malloc( size);

	
	curPix = [pixList objectAtIndex: 0];
	
	float vectors[9];
	[curPix orientation:vectors];			
	vtkOriginalX = ([curPix originX] ) * vectors[0] + ([curPix originY]) * vectors[1] + ([curPix originZ] )*vectors[2];
	vtkOriginalY = ([curPix originX] ) * vectors[3] + ([curPix originY]) * vectors[4] + ([curPix originZ] )*vectors[5];
	vtkOriginalZ = ([curPix originX] ) * vectors[6] + ([curPix originY]) * vectors[7] + ([curPix originZ] )*vectors[8];
	sliceThickness = [curPix sliceInterval];   
	if( sliceThickness == 0)
	{
		NSLog(@"Slice interval = slice thickness!");
		sliceThickness = [curPix sliceThickness];
	}
	centerX=0;
	centerY=0;
	centerZ=0;
	
	xSpacing=[curPix pixelSpacingX];
	ySpacing=[curPix pixelSpacingY];
	zSpacing=sliceThickness;
	minSpacing=xSpacing;
	if(minSpacing>ySpacing)minSpacing=ySpacing;
	if(minSpacing>zSpacing)minSpacing=zSpacing;
	minSpacing/=2;
	
	oViewRotateAngleX=0;
	oViewRotateAngleY=0;
	cViewRotateAngleY=0;

	
	reader = vtkImageImport::New();
	reader->SetWholeExtent(0, imageWidth-1, 0, imageHeight-1, 0, imageAmount-1);
	reader->SetDataSpacing(xSpacing,ySpacing,zSpacing);
	reader->SetDataOrigin( vtkOriginalX,vtkOriginalY,vtkOriginalZ );
	reader->SetDataExtentToWholeExtent();
	reader->SetDataScalarTypeToFloat();
	reader->SetImportVoidPointer(volumeData);
	
	roiReader = vtkImageImport::New();
	roiReader->SetWholeExtent(0, imageWidth-1, 0, imageHeight-1, 0, imageAmount-1);
	roiReader->SetDataSpacing(xSpacing,ySpacing,zSpacing);
	roiReader->SetDataOrigin( vtkOriginalX,vtkOriginalY,vtkOriginalZ );
	roiReader->SetDataExtentToWholeExtent();
	roiReader->SetDataScalarTypeToUnsignedShort();
	roiReader->SetImportVoidPointer(contrastVolumeData);

	if( fuzzyConectednessMap )
	{
		
		axROIReader= vtkImageImport::New();
		axROIReader->SetWholeExtent(0, imageWidth-1, 0, imageHeight-1, 0, imageAmount-1);
		axROIReader->SetDataSpacing(xSpacing,ySpacing,zSpacing);
		axROIReader->SetDataOrigin( vtkOriginalX,vtkOriginalY,vtkOriginalZ );
		axROIReader->SetDataExtentToWholeExtent();
		axROIReader->SetDataScalarTypeToFloat();
		axROIReader->SetImportVoidPointer(fuzzyConectednessMap);
		
		
	}
	axViewCostMapWidth=100/xSpacing;
	axViewCostMapHeight=100/ySpacing;
	axViewConnectednessCostMapMaxSize=4*imageWidth*imageHeight*sizeof(float);
	axViewConnectednessCostMap=(float*)malloc(axViewConnectednessCostMapMaxSize);//maximum

	connectednessROIBufferMaxSize=2*imageWidth*imageHeight*sizeof(char);
	connectednessROIBuffer=(unsigned char*)malloc(connectednessROIBufferMaxSize);
	axLevelSetMapReader = vtkImageImport::New();
	axLevelSetMapReader->SetWholeExtent(0, axViewCostMapWidth-1, 0, axViewCostMapHeight-1, 0, 0);
	axLevelSetMapReader->SetDataSpacing(1.0,1.0,0);
	axLevelSetMapReader->SetDataOrigin( 0,0,0 );
	axLevelSetMapReader->SetDataExtentToWholeExtent();
	axLevelSetMapReader->SetDataScalarTypeToFloat();
	axLevelSetMapReader->SetImportVoidPointer(axViewConnectednessCostMap);
	
	axROIOutlineFilter = vtkContourFilter::New();
	axROIOutlineFilter->SetValue(0, 0);
	axROIOutlineFilter->SetInput (axLevelSetMapReader->GetOutput());
	
	axViewPolygonfilter = vtkPolyDataConnectivityFilter::New();
	axViewPolygonfilter->SetColorRegions( 1);
	axViewPolygonfilter->SetExtractionModeToLargestRegion();
	axViewPolygonfilter->SetInput( axROIOutlineFilter->GetOutput());
	
	axViewPolygonfilter2 = vtkPolyDataConnectivityFilter::New();
	axViewPolygonfilter2->SetColorRegions( 1);
	axViewPolygonfilter2->SetExtractionModeToLargestRegion();
	axViewPolygonfilter2->SetInput( axViewPolygonfilter->GetOutput());
	
	
	oViewBasicTransform = vtkTransform::New();
	oViewBasicTransform->Translate( vtkOriginalX+xSpacing*imageWidth/2, vtkOriginalY+ySpacing*imageHeight/2, vtkOriginalZ + sliceThickness*imageAmount/2 );
	
	oViewUserTransform = vtkTransform::New();
	oViewUserTransform->Identity ();
	oViewUserTransform->SetInput(oViewBasicTransform) ;

	oViewUserTransform->RotateX(-90);
	
	centerIsLocked=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVLockMPRCenter"];
	if(centerIsLocked)
	{
		[centerLock setState:NSOnState];
		NSString* path=[parent osirixDocumentPath];
		NSString	*str =  [path stringByAppendingString:@"/CMIVCTACache/VRT.sav"];
		
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
		NSArray* matrixarray=[dict objectForKey:@"MPRTranformMatrix"];
		if(matrixarray&&[matrixarray count]==16)
		{
			double matrix[16];
			int i;
			for(i=0;i<16;i++)
				matrix[i]=[[matrixarray objectAtIndex:i] doubleValue];
			oViewBasicTransform->Identity();
			oViewUserTransform->SetMatrix(matrix);
		}
		else
			[centerLock setState:NSOffState];
		
	}
	
	
	inverseTransform = (vtkTransform*)oViewUserTransform->GetLinearInverse();
	
	
	cViewTransform = vtkTransform::New();
	cViewTransform->SetInput(oViewUserTransform) ;
	cViewTransform->RotateY(-90);
	
	axViewTransform = vtkTransform::New();
	axViewTransform->SetInput(oViewUserTransform) ;
	axViewTransform->RotateX(90);
	
	axViewTransformForStraightenCPR = vtkTransform::New();
	avViewinverseTransform = (vtkTransform*)axViewTransformForStraightenCPR->GetLinearInverse();
	oViewSlice = vtkImageReslice::New();
	oViewSlice->SetAutoCropOutput( true);
	oViewSlice->SetInformationInput( reader->GetOutput());
	oViewSlice->SetInput( reader->GetOutput());
	oViewSlice->SetOptimization( true);
	oViewSlice->SetResliceTransform( oViewUserTransform);
	oViewSlice->SetResliceAxesOrigin( 0, 0, 0);
	oViewSlice->SetInterpolationModeToCubic();//    >SetInterpolationModeToNearestNeighbor();
	oViewSlice->SetOutputDimensionality( 2);
	oViewSlice->SetBackgroundLevel( -1024);

	oViewROISlice= vtkImageReslice::New();
	oViewROISlice->SetAutoCropOutput( true);
	oViewROISlice->SetInformationInput( roiReader->GetOutput());
	oViewROISlice->SetInput( roiReader->GetOutput());
	oViewROISlice->SetOptimization( true);
	oViewROISlice->SetResliceTransform(oViewUserTransform );
	oViewROISlice->SetResliceAxesOrigin( 0, 0, 0);
	oViewROISlice->SetInterpolationModeToNearestNeighbor();
	oViewROISlice->SetOutputDimensionality( 2);
	oViewROISlice->SetBackgroundLevel( -1024);	


	vtkImageData	*tempIm;
	int				imExtent[ 6];
	double		space[ 3], origin[ 3];
	tempIm = oViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( oViewSpace);
	tempIm->GetOrigin( oViewOrigin);
	tempIm->GetSpacing( space);
	tempIm->GetOrigin( origin);	
	
	float *im = (float*) tempIm->GetScalarPointer();
	DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
	[mypix copySUVfrom: curPix];	
	float iwl, iww;
	iww = [[originalViewController imageView] curWW] ;
	iwl = [[originalViewController imageView] curWL] ;
	[mypix changeWLWW:iwl :iww];
	oViewPixList = [[NSMutableArray alloc] initWithCapacity:0];
	[oViewPixList addObject: mypix];
	[mypix release];	
	
	oViewROIList = [[NSMutableArray alloc] initWithCapacity:0];
	[oViewROIList addObject:[NSMutableArray arrayWithCapacity:0]];
//	[oViewROIList addObject:[NSMutableArray arrayWithCapacity:0]];
	[originalView setDCM:oViewPixList :fileList :oViewROIList :0 :'i' :YES];
	NSString *viewName = [NSString stringWithString:@"Original"];
	[originalView setStringID: viewName];
	[originalView setMPRAngle: 0.0];
	[originalView showCrossHair];
	
	[originalView setIndexWithReset: 0 :YES];
	[originalView setOrigin: NSMakePoint(0,0)];
	[originalView setCurrentTool:tWL];
	[originalView  scaleToFit];
	
	//[originalView discretelySetWLWW:iwl :iww];
	float crossX,crossY;
	crossX=-origin[0]/space[0];
	crossY=origin[1]/space[1];
	
	if(crossX<0)
		crossX=0;
	else if(crossX>imExtent[ 1]-imExtent[ 0])
		crossX=imExtent[ 1]-imExtent[ 0];
	if(crossY>0)
		crossY=0;
	else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
		crossY=-(imExtent[ 3]-imExtent[ 2] );
	[originalView setCrossCoordinates:crossX:crossY :YES];
	
	
	
	cViewSlice = vtkImageReslice::New();
	cViewSlice->SetAutoCropOutput( true);
	cViewSlice->SetInformationInput( reader->GetOutput());
	cViewSlice->SetInput( reader->GetOutput());
	cViewSlice->SetOptimization( true);
	cViewSlice->SetResliceTransform( cViewTransform);
	cViewSlice->SetResliceAxesOrigin( 0, 0, 0);
	cViewSlice->SetInterpolationModeToCubic();
	cViewSlice->SetOutputDimensionality( 2);
	cViewSlice->SetBackgroundLevel( -1024);
	
	maxWidthofCPR=40;//used by straighten CPR
	
	tempIm = cViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( space);
	tempIm->GetOrigin( origin);	
	tempIm->GetSpacing( cViewSpace);
	tempIm->GetOrigin( cViewOrigin);
	
	im = (float*) tempIm->GetScalarPointer();
	mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
	[mypix copySUVfrom: curPix];	
	[mypix changeWLWW:iwl :iww];
	
	cViewPixList = [[NSMutableArray alloc] initWithCapacity:0];
	[cViewPixList addObject: mypix];
	[mypix release];	
	
	cViewROIList = [[NSMutableArray alloc] initWithCapacity:0];
	[cViewROIList addObject:[NSMutableArray arrayWithCapacity:0]];
	
	viewName = [NSString stringWithString:@"Original"];
	
	[cPRView setDCM:cViewPixList :fileList :cViewROIList :0 :'i' :YES];
	//	viewName = [NSString stringWithString:@"Original"];
	[cPRView setStringID: viewName];
	[cPRView setMPRAngle: 0.0];
	[cPRView showCrossHair];
	
	[cPRView setIndexWithReset: 0 :YES];
	[cPRView setOrigin: NSMakePoint(0,0)];
	[cPRView setCurrentTool:tWL];
	[cPRView  scaleToFit];
	//[cPRView discretelySetWLWW:iwl :iww];	
	crossX=-origin[0]/space[0];
	crossY=origin[1]/space[1];
	
	if(crossX<0)
		crossX=0;
	else if(crossX>imExtent[ 1]-imExtent[ 0])
		crossX=imExtent[ 1]-imExtent[ 0];
	if(crossY>0)
		crossY=0;
	else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
		crossY=-(imExtent[ 3]-imExtent[ 2] );
	[cPRView setCrossCoordinates:crossX:crossY :YES];

	
	axViewSlice = vtkImageReslice::New();
	axViewSlice->SetAutoCropOutput( true);
	axViewSlice->SetInformationInput( reader->GetOutput());
	axViewSlice->SetInput( reader->GetOutput());
	axViewSlice->SetOptimization( true);
	axViewSlice->SetResliceTransform( axViewTransform);
	axViewSlice->SetResliceAxesOrigin( 0, 0, 0);
	axViewSlice->SetInterpolationModeToCubic();
	axViewSlice->SetOutputDimensionality( 2);
	//axViewSlice->SetOutputSpacing(1,1,0);
	axViewSlice->SetBackgroundLevel( -1024);
	
	
	tempIm = axViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( axViewSpace);
	tempIm->GetOrigin( axViewOrigin);
	tempIm->GetSpacing( space);
	tempIm->GetOrigin( origin);	
	
	if( fuzzyConectednessMap )
	{
		axViewROISlice= vtkImageReslice::New();
		axViewROISlice->SetAutoCropOutput( true);
		axViewROISlice->SetInformationInput( axROIReader->GetOutput());
		axViewROISlice->SetInput( axROIReader->GetOutput());
		axViewROISlice->SetOptimization( true);
		axViewROISlice->SetResliceTransform( axViewTransform);
		axViewROISlice->SetResliceAxesOrigin( 0, 0, 0);
		axViewROISlice->SetInterpolationModeToCubic();
		axViewROISlice->SetOutputDimensionality( 2);
		axViewROISlice->SetBackgroundLevel( -3000);	
		
	}
	
	
	im = (float*) tempIm->GetScalarPointer();
	mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :space[0] :space[1] :origin[0] :origin[1] :origin[2]];
	[mypix copySUVfrom: curPix];	
	[mypix changeWLWW:iwl :iww];
	
	axViewPixList = [[NSMutableArray alloc] initWithCapacity:0];
	[axViewPixList addObject: mypix];
	[mypix release];	
	
	axViewROIList = [[NSMutableArray alloc] initWithCapacity:0];
	[axViewROIList addObject:[NSMutableArray arrayWithCapacity:0]];
	
	[crossAxiasView setDCM:axViewPixList :fileList :axViewROIList :0 :'i' :YES];
	viewName = [NSString stringWithString:@"Original"];
	[crossAxiasView setStringID: viewName];
	[crossAxiasView setMPRAngle: 0.0];
	[crossAxiasView showCrossHair];
	
	[crossAxiasView setIndexWithReset: 0 :YES];
	[crossAxiasView setOrigin: NSMakePoint(0,0)];
	[crossAxiasView setCurrentTool:tWL];
	[crossAxiasView setScaleValue: 1.5*[originalView scaleValue]];
	//[crossAxiasView discretelySetWLWW:iwl :iww];	
	
	cprImageBuffer=0L;
	crossX=-origin[0]/space[0];
	crossY=origin[1]/space[1];
	
	if(crossX<0)
		crossX=0;
	else if(crossX>imExtent[ 1]-imExtent[ 0])
		crossX=imExtent[ 1]-imExtent[ 0];
	if(crossY>0)
		crossY=0;
	else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
		crossY=-(imExtent[ 3]-imExtent[ 2] );
	[crossAxiasView setCrossCoordinates:crossX:crossY :YES];

	{
	
		int showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowAxViewCrossHair"];
		if(showcross==0)
		{
			showcross=1;
			[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowAxViewCrossHair"];
		}
		if(showcross!=1)
		{
			[crossAxiasView setCrossCoordinates:-9999 :-9999 :YES];
			[crossAxiasView hideCrossHair];
			[axViewCrossShowButton setState:NSOffState];
		}
		showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowCViewCrossHair"];
		if(showcross==0)
		{
			showcross=1;
			[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowCViewCrossHair"];
		}
		if(showcross!=1)
		{
			[cPRView setCrossCoordinates:-9999 :-9999 :YES];
			[cPRView hideCrossHair];
			[cViewCrossShowButton setState:NSOffState];
		}
		showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowOViewCrossHair"];
		if(showcross==0)
		{
			showcross=1;
			[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowOViewCrossHair"];
		}
		if(showcross!=1)
		{
			[originalView setCrossCoordinates:-9999 :-9999 :YES];
			[originalView hideCrossHair];
			[oViewCrossShowButton setState:NSOffState];
		}
	}

	
	return 0;
	
	
}

- (void) updateOView
{
#ifdef VERBOSEMODE
	NSLog( @"updating Oview");
#endif
	vtkImageData	*tempIm,*tempROIIm;
	int				imExtent[ 6];
	
	if(interpolationMode)
		oViewSlice->SetInterpolationModeToCubic();
	else
		oViewSlice->SetInterpolationModeToNearestNeighbor();
	tempIm = oViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( oViewSpace);
	tempIm->GetOrigin( oViewOrigin);	
	
	float *im = (float*) tempIm->GetScalarPointer();
	DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :oViewSpace[0] :oViewSpace[1] :oViewOrigin[0] :oViewOrigin[1] :oViewOrigin[2]];
	[mypix copySUVfrom: curPix];	
	
	isRemoveROIBySelf=1;
	//to avoid ROIs release seeds when autoreleased

	unsigned i;
	NSString* emptystr=[NSString stringWithString:@""];
	for(i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
		[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] setComments:emptystr];

	[[oViewROIList objectAtIndex: 0] removeAllObjects];
//	if(curvedMPR2DPath)
//	{
//		
//		[[oViewROIList objectAtIndex: 1] removeAllObjects];
//		[[oViewROIList objectAtIndex: 1] addObject:curvedMPR2DPath ];
//	}
	isRemoveROIBySelf=0;
	//creat roi list
	if(currentViewMode==0)//if MPR mode
	{
		if(contrastVolumeData)
		{
			tempROIIm = oViewROISlice->GetOutput();
			tempROIIm->Update();
			tempROIIm->GetWholeExtent( imExtent);
			tempROIIm->GetSpacing( oViewSpace);
			tempROIIm->GetOrigin( oViewOrigin);	
			short unsigned int *imROI = (short unsigned int*) tempROIIm->GetScalarPointer();
			[self creatROIListFromSlices:[oViewROIList objectAtIndex: 0] :imExtent[ 1]-imExtent[ 0]+1  :imExtent[ 3]-imExtent[ 2]+1 :imROI : oViewSpace[0]:oViewSpace[1]:oViewOrigin[0]:oViewOrigin[1]];
		}
	}
	else // else is CPR mode
	{
		if(curvedMPR2DPath)
			[self reCaculateCPRPath:[oViewROIList objectAtIndex: 0] :imExtent[ 1]-imExtent[ 0]+1  :imExtent[ 3]-imExtent[ 2]+1 :oViewSpace[0]:oViewSpace[1]:oViewSpace[2]:oViewOrigin[0]:oViewOrigin[1]:oViewOrigin[3]];
	}
	
	[oViewPixList removeAllObjects];
	[oViewPixList addObject: mypix];
	[mypix release];
	//to cheat DCMView not reset current roi;
	
	[originalView setIndex: 0 ];
	
	if([oViewCrossShowButton state]== NSOnState)
	{
		float crossX,crossY;
		crossX=-oViewOrigin[0]/oViewSpace[0];
		crossY=oViewOrigin[1]/oViewSpace[1];
		if(crossX<0)
			crossX=0;
		else if(crossX>imExtent[ 1]-imExtent[ 0])
			crossX=imExtent[ 1]-imExtent[ 0];
		if(crossY>0)
			crossY=0;
		else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
			crossY=-(imExtent[ 3]-imExtent[ 2] );
		[originalView setCrossCoordinates:crossX:crossY :YES];
	}
	else
	{
		[originalView setCrossCoordinates:-9999 :-9999 :YES];
	}
	if(curvedMPR2DPath)
		[curvedMPR2DPath setROIMode:currentPathMode];
	if(referenceCurvedMPR2DPath)
		[referenceCurvedMPR2DPath setROIMode:currentPathMode];
	tempIm->GetSpacing( oViewSpace);
	tempIm->GetOrigin( oViewOrigin);	
#ifdef VERBOSEMODE
	NSLog( @"Oview Updated");
#endif
}
- (void) updatePageSliders
{
	float point[8][3];
	point[0][0] = vtkOriginalX;
	point[0][1] = vtkOriginalY;
	point[0][2] = vtkOriginalZ;
	
	point[1][0] = vtkOriginalX+imageWidth*xSpacing;
	point[1][1] = vtkOriginalY+imageHeight*ySpacing;
	point[1][2] = vtkOriginalZ;	
	
	point[2][0] = vtkOriginalX+imageWidth*xSpacing;
	point[2][1] = vtkOriginalY;
	point[2][2] = vtkOriginalZ;
	
	point[3][0] = vtkOriginalX;
	point[3][1] = vtkOriginalY+imageHeight*ySpacing;
	point[3][2] = vtkOriginalZ;
	
	point[4][0] = vtkOriginalX;
	point[4][1] = vtkOriginalY;
	point[4][2] = vtkOriginalZ+imageAmount*zSpacing;
	
	point[5][0] = vtkOriginalX+imageWidth*xSpacing;
	point[5][1] = vtkOriginalY;
	point[5][2] = vtkOriginalZ+imageAmount*zSpacing;
	
	point[6][0] = vtkOriginalX;
	point[6][1] = vtkOriginalY+imageHeight*ySpacing;
	point[6][2] = vtkOriginalZ+imageAmount*zSpacing;
	
	point[7][0] = vtkOriginalX+imageWidth*xSpacing;
	point[7][1] = vtkOriginalY+imageHeight*ySpacing;
	point[7][2] = vtkOriginalZ+imageAmount*zSpacing;
	
	float min[3],max[3];
	float pointout[3];
	int i,j;
	
	for(j=0;j<3;j++)
	{
		inverseTransform->TransformPoint(point[0],pointout);
		min[j]=max[j]=pointout[j];
		
		for(i=1;i<8;i++)
		{
			inverseTransform->TransformPoint(point[i],pointout);
			if(pointout[j]<min[j])
				min[j]=pointout[j];
			if(pointout[j]>max[j])
				max[j]=pointout[j];
			
		}
	}	
	if(!cViewMPRorCPRMode)
	{
		
		[cImageSlider setMaxValue: max[0]];
		[cImageSlider setMinValue: min[0]];
		[cImageSlider setFloatValue: 0];
		lastCViewTranslate=0;
		
		[axImageSlider setMaxValue:-min[1]];
		[axImageSlider setMinValue:-max[1]];
		[axImageSlider setFloatValue: 0];
		lastAxViewTranslate=0;
		
		[cImageSlider setEnabled: YES];
		//[cYRotateSlider setEnabled: YES];

	}
	else {

		float cprheight=[[cViewPixList objectAtIndex:0] pheight]*cViewSpace[1];
		[axImageSlider setMaxValue:cprheight];
		[axImageSlider setMinValue:0];
		if([axImageSlider floatValue]>cprheight)
			[axImageSlider setFloatValue: cprheight];
		else if([axImageSlider floatValue]<0)
			[axImageSlider setFloatValue: 0];
		if(isStraightenedCPR)
		{
			[cImageSlider setEnabled: NO];
			//[cYRotateSlider setEnabled: YES];
		}
		else
		{
			[cImageSlider setEnabled: NO];
			//[cYRotateSlider setEnabled: NO];
		}
		
		
	}

	
	[oImageSlider setMaxValue: max[2]];
	[oImageSlider setMinValue: min[2]];
	[oImageSlider setIntValue:0];
	lastOViewTranslate=0;
	
	
	
	
}
- (void) updateCView
{
#ifdef VERBOSEMODE
	NSLog( @"updating Cview");
#endif
	if(cViewMPRorCPRMode)
		[self updateCViewAsCurvedMPR];
	else 
		[self updateCViewAsMPR];
	
#ifdef VERBOSEMODE
	NSLog( @"Cview Updated");
#endif
}

- (void) updateAxView
{
#ifdef VERBOSEMODE
	NSLog( @"updating Axview");
#endif
	if(cViewMPRorCPRMode)
	{
		if(!isStraightenedCPR)
			[self recaculateAxViewForCPR];
		else
			[self recaculateAxViewForStraightenedCPR];
	}
	vtkImageData	*tempIm,*tempROIIm;
	int				imExtent[ 6];
	if(interpolationMode)
		axViewSlice->SetInterpolationModeToCubic();
	else
		axViewSlice->SetInterpolationModeToNearestNeighbor();
	tempIm = axViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( axViewSpace);
	tempIm->GetOrigin( axViewOrigin);	
	
	float *im = (float*) tempIm->GetScalarPointer();
	DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :axViewSpace[0] :axViewSpace[1] :axViewOrigin[0] :axViewOrigin[1] :axViewOrigin[2]];
	[mypix copySUVfrom: curPix];	
	
	[axViewPixList removeAllObjects];
	[axViewPixList addObject: mypix];
	[mypix release];
	float scale=[crossAxiasView scaleValue];
	NSPoint newOrigin;
	newOrigin.x = scale*round(axViewOrigin[0]/axViewSpace[0]+(imExtent[ 1]-imExtent[ 0]+1)/2);
	newOrigin.y = scale*(-(round(axViewOrigin[1]/axViewSpace[1]+(imExtent[ 3]-imExtent[ 2]+1)/2)));
	
	[crossAxiasView setOrigin: newOrigin];
	
	if([[axViewROIList objectAtIndex: 0] count])
	{
		
		ROI* roi=[[axViewROIList objectAtIndex: 0] objectAtIndex:0];
		
		if([roi type]==tOval)
		{
			float crossX,crossY;
			crossX=-axViewOrigin[0]/axViewSpace[0];
			crossY=-axViewOrigin[1]/axViewSpace[1];
			if(crossX<0)
				crossX=0;
			else if(crossX>imExtent[ 1]-imExtent[ 0])
				crossX=imExtent[ 1]-imExtent[ 0];
			if(crossY<0)
				crossY=0;
			else if(crossY>(imExtent[ 3]-imExtent[ 2] ))
				crossY=-(imExtent[ 3]-imExtent[ 2] );
			
			axCircleRect.origin.x = crossX;
			axCircleRect.origin.y = crossY;
			[roi setROIRect: axCircleRect];
		}
		else
			[[axViewROIList objectAtIndex: 0] removeAllObjects];
	}
	

	if(axViewROIMode==2) //use fuzzy connectedness segment results
	{
		if(interpolationMode)
			axViewROISlice->SetInterpolationModeToCubic();
		else
			axViewROISlice->SetInterpolationModeToNearestNeighbor();
		int				axROIExtent[ 6];
		double axROISpacing[3],axROIOrigin[3];
		tempROIIm = axViewROISlice->GetOutput();
		tempROIIm->Update();
		tempROIIm->GetWholeExtent( axROIExtent);
		tempROIIm->GetSpacing( axROISpacing);
		tempROIIm->GetOrigin( axROIOrigin);	
		float *imAxROI = (float*) tempROIIm->GetScalarPointer();
		[self creatAxROIListFromFuzzyConnectedness:[axViewROIList objectAtIndex: 0] :axROIExtent[ 1]-axROIExtent[ 0]+1  :axROIExtent[ 3]-axROIExtent[ 2]+1 :imAxROI : axROISpacing[0]:axROISpacing[1]:axROIOrigin[0]:axROIOrigin[1]];
	}	
	else if(axViewROIMode==1) //use only intensity
	{
		[self creatAxROIListFromFuzzyConnectedness:[axViewROIList objectAtIndex: 0] :imExtent[ 1]-imExtent[ 0]+1  :imExtent[ 3]-imExtent[ 2]+1 :im : axViewSpace[0]:axViewSpace[1]:axViewOrigin[0]:axViewOrigin[1]];
	}
	[axViewMeasurePolygon setROIMode:ROI_sleep];
	if([axViewCrossShowButton state]== NSOnState&&currentViewMode==0)
	{
		float crossX,crossY;
		crossX=-axViewOrigin[0]/axViewSpace[0];
		crossY=axViewOrigin[1]/axViewSpace[1];
		if(crossX<0)
			crossX=0;
		else if(crossX>imExtent[ 1]-imExtent[ 0])
			crossX=imExtent[ 1]-imExtent[ 0];
		if(crossY>0)
			crossY=0;
		else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
			crossY=-(imExtent[ 3]-imExtent[ 2] );
		[crossAxiasView setCrossCoordinates:crossX:crossY :YES];
	}
	else
	{
		[crossAxiasView setCrossCoordinates:-9999 :-9999 :YES];
	}
	
	[crossAxiasView setIndex: 0 ];
#ifdef VERBOSEMODE
	NSLog( @"AXview Updated");
#endif
	
}
- (void) resetSliders
{
	[oXRotateSlider setIntValue:0];
	[oViewRotateXText setFloatValue: 0];
	[oYRotateSlider setIntValue:0];
	[oViewRotateYText setFloatValue: 0];
	
	lastOViewXAngle=0;
	lastOViewYAngle=0;
	
	[cYRotateSlider setFloatValue: 0];	
	lastCViewYAngle=0;
	[cViewRotateYText setFloatValue: 0];
	
	[self updatePageSliders];		
}
- (void) changeCurrentTool:(int) tag
{
	if(currentTool==4)
	{
		unsigned int i;
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"ROITEXTNAMEONLY"];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ROITEXTIFSELECTED"];
		for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
		{
			ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
			if([temproi type] == tMesure)
			{
				
					[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
					i--;
			}
		}
		for ( i=0;i<[[cViewROIList objectAtIndex: 0] count];i++)
		{
			ROI* temproi=[[cViewROIList objectAtIndex: 0] objectAtIndex: i] ;
			if([temproi type] == tMesure)
			{
				
				[[cViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
				i--;
			}
		}
		for ( i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
		{
			ROI* temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex: i] ;
			if([temproi type] == tMesure)
			{
				
				[[axViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
				i--;
			}
		}
		
	}
	else 	if(currentTool>=6&&currentTool<=8)
	{
		if(!isInWizardMode)
		{
			NSString* tabidstr=[[seedToolTipsTabView tabViewItemAtIndex:1] identifier];
			if(tabidstr&&[[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
			{
				[convertToSeedButton setHidden:YES];
				[brushStatSegment setHidden:YES];
				[brushWidthSlider setHidden:YES];
				[brushWidthText setHidden:YES];
			}

		}
		if(!contrastVolumeData)
		{
			int size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
			contrastVolumeData = (unsigned short int*) malloc( size);
			roiReader->SetImportVoidPointer(contrastVolumeData);
		}

	}

	if(tag>=6&&tag<=8)
	{
		if([axViewCrossShowButton state]==NSOnState)
		{
			[axViewCrossShowButton setState:NSOffState];
			[crossAxiasView hideCrossHair];
			[self updateAxView];
		}
		if(!contrastVolumeData)
		{
			int size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
			contrastVolumeData = (unsigned short int*) malloc( size);
			roiReader->SetImportVoidPointer(contrastVolumeData);
		}
		needSaveSeeds=YES;
	}
	else
	{
		int showcross=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIV2DViewShowAxViewCrossHair"];
		if(showcross==1)
		{
			[axViewCrossShowButton setState:NSOnState];
			[crossAxiasView showCrossHair];
			[self updateAxView];
		}

	}
	if(tag>=0&&tag<4)
	{
		[originalView setCurrentTool: tag];
		[cPRView setCurrentTool: tag];
		[crossAxiasView setCurrentTool:tag];
		
		
	}
	else if(tag==4)
	{
		[originalView setCurrentTool: tMesure];
		[cPRView setCurrentTool: tMesure];
		[crossAxiasView setCurrentTool:tMesure];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"ROITEXTNAMEONLY"];
		[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ROITEXTIFSELECTED"];
	}
	else if(tag==5)
	{
		[originalView setCurrentTool: tOPolygon];
		[cPRView setCurrentTool: tTranslate];
		[crossAxiasView setCurrentTool: tWL];
		currentTool=tag;
		[self updateOView];
		[self cAndAxViewReset];
		[self updatePageSliders];
	}
	else if(tag==6)
	{
		[originalView setCurrentTool: tMesure];
		[cPRView setCurrentTool: tROI];
		[crossAxiasView setCurrentTool: tWL];
		if(!isInWizardMode)
		{
			NSString* tabidstr=[[seedToolTipsTabView tabViewItemAtIndex:1] identifier];
			if(tabidstr&&[[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
			{
				[convertToSeedButton setHidden:NO];
				[brushStatSegment setHidden:YES];
				[brushWidthSlider setHidden:YES];
				[brushWidthText setHidden:YES];
			}
			unsigned int row = currentStep;
			if(row>=0&&row<[contrastList count])
			{
				[[contrastList objectAtIndex: row] setObject: [NSNumber numberWithInt:6] forKey:@"CurrentTool"];
			}		
		}
		if(currentTool==7||currentTool==5)
		{
			currentTool=tag;
			[self updateOView];
			[self cAndAxViewReset];
			[self updatePageSliders];
		}
	}
	else if(tag==7)
	{
		[originalView setCurrentTool: tArrow];
		[cPRView setCurrentTool: tArrow];
		[crossAxiasView setCurrentTool: tOval];	
		if(!isInWizardMode)
		{
			NSString* tabidstr=[[seedToolTipsTabView tabViewItemAtIndex:1] identifier];
			if(tabidstr&&[[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
			{
				[convertToSeedButton setHidden:NO];
				[brushStatSegment setHidden:YES];
				[brushWidthSlider setHidden:YES];
				[brushWidthText setHidden:YES];
			}
			
			unsigned int row = currentStep;
			if(row>=0&&row<[contrastList count])
			{
				[[contrastList objectAtIndex: row] setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
			}
		}
			if(currentTool==6||currentTool==5)
		{	
			currentTool=tag;
			[self updateOView];
			[self cAndAxViewReset];
			[self updatePageSliders];
			
		}		
		
	}
	else if(tag==8)
	{

		
		[originalView setCurrentTool: tPlain];
		[originalView setEraserFlag:0];
		if(!isInWizardMode)
		{
			NSString* tabidstr=[[seedToolTipsTabView tabViewItemAtIndex:1] identifier];
			if(tabidstr&&[[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
			{
				[convertToSeedButton setHidden:YES];
				[brushStatSegment setHidden:NO];
				[brushWidthSlider setHidden:NO];
				[brushWidthText setHidden:NO];
			}
			[brushStatSegment setSelectedSegment: 0];
			unsigned int row = currentStep;
			if(row>=0&&row<[contrastList count])
			{
				[[contrastList objectAtIndex: row] setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
			}
			[[NSUserDefaults standardUserDefaults] setFloat:[brushWidthSlider floatValue] forKey:@"ROIRegionThickness"];
		}
			
		
			
		[cPRView setCurrentTool: tWL];
		[crossAxiasView setCurrentTool: tWL];
		if(currentTool==6||currentTool==7||currentTool==5)
		{	
			currentTool=tag;
			[self updateOView];
			[self cAndAxViewReset];
			[self updatePageSliders];
			
		}
		
	}
	else if(tag==9)
	{
		[originalView setCurrentTool: tWL];
		[cPRView setCurrentTool: tRepulsor];
		[crossAxiasView setCurrentTool: tRepulsor];	
		
		
	}
	else
		return;
	
	if(isInWizardMode)
	{
		if(tag!=6&&tag!=7&&tag!=8)
		{
			[currentTips setStringValue: howToContinueTip];
			[continuePlantingButton setHidden:NO];
			[nextButton setEnabled: NO];
			[previousButton setEnabled: NO];
		}
		else
			[continuePlantingButton setHidden:YES];
	}
		
	currentTool=tag;
	
}
- (IBAction)changeDefaultTool:(id)sender
{
	int tag=[sender tag];
	[self changeCurrentTool:tag];
}
- (IBAction)resetOriginalView:(id)sender
{
	oViewBasicTransform->Identity();
	oViewBasicTransform->Translate( vtkOriginalX+xSpacing*imageWidth/2, vtkOriginalY+ySpacing*imageHeight/2, vtkOriginalZ + sliceThickness*imageAmount/2 );
	oViewBasicTransform->RotateX(-90);
	oViewUserTransform->Identity ();
	[self updateOView];
	[self cAndAxViewReset];
	[self resetSliders];	
}
- (IBAction)lockCenter:(id)sender
{
	
	if([centerLock state]== NSOnState)
	{
		NSMutableArray* matrixArray=[NSMutableArray arrayWithCapacity:16];
		vtkMatrix4x4 * aMatrix = oViewUserTransform->GetMatrix();
		int i,j;
		for(i=0;i<4;i++)
			for(j=0;j<4;j++)
			{
				double tempdouble=aMatrix->GetElement(i, j);
				[matrixArray addObject:[NSNumber numberWithDouble:tempdouble]];
			}
		NSString* path=[parent osirixDocumentPath];
		NSString	*str =  [path stringByAppendingString:@"/CMIVCTACache/VRT.sav"];
		
		NSMutableDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
		
		if(!dict)
			dict=[NSMutableDictionary dictionary];
		[dict setObject:matrixArray forKey:@"MPRTranformMatrix"];
		
		
		
		[dict writeToFile:str atomically:YES];
		centerIsLocked=1;

		[[NSUserDefaults standardUserDefaults] setInteger:centerIsLocked forKey:@"CMIVLockMPRCenter"];
	
		
	}
	else
	{
		centerIsLocked=0;
		
		[[NSUserDefaults standardUserDefaults] setInteger:centerIsLocked forKey:@"CMIVLockMPRCenter"];
		[self resetOriginalView:self];
		
	}
	
	[self updateOView];
	[self cAndAxViewReset];
	[self resetSliders];
	
}
- (IBAction)changOriginalViewDirection:(id)sender
{

	float origin[3]={0,0,0};
	oViewUserTransform->TransformPoint(origin,origin);
	oViewBasicTransform->Identity();
	oViewBasicTransform->Translate( origin[0], origin[1], origin[2] );

	
	oViewUserTransform->Identity();	
	oViewUserTransform->RotateX(-90);
	if([sender tag]==0)
	{
		
	}
	else if([sender tag]==1)
	{
		oViewUserTransform->RotateY(180);
	}
	else if([sender tag]==2)
	{
		oViewUserTransform->RotateX(-90);
	}
	else if([sender tag]==3)
	{
		oViewUserTransform->RotateX(90);
	}
	else if([sender tag]==4)
	{
		oViewUserTransform->RotateY(90);
	}
	else if([sender tag]==5)
	{
		oViewUserTransform->RotateY(-90);
	}
	[self updateOView];
	[self resetSliders];
	[self updatePageSliders];
	[self cAndAxViewReset];
	
}
- (IBAction)pageAxView:(id)sender
{

	
	if(!cViewMPRorCPRMode)
	{
		if([sender isMouseLeftKeyDown])
			interpolationMode=0;
		else
			interpolationMode=1;
		float locate;
		locate=[sender floatValue];
		locate-=lastAxViewTranslate;
		lastAxViewTranslate = [sender floatValue];
		if(locate!=0||interpolationMode)
		{
			oViewUserTransform->Translate(0,-locate,0);
			[self updateAxView];
			[self updateOView];
			[self updateCView];
		}
//		if(interpolationMode)
//			[self updatePageSliders];
		[axViewLengthText setFloatValue:0.0];
	}
	else
	{
		float locate;
		locate=[sender minValue]+[sender maxValue]-[sender floatValue];
		axViewTransform->Identity();
		axViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
		axViewTransform->RotateZ(oViewToCViewZAngle);
		axViewTransform->RotateX(90+cViewToAxViewZAngle);
		axViewTransform->Translate(0,0,-locate);
		isNeedShowReferenceLine=YES;
		[self updateAxView];
		isNeedShowReferenceLine=NO;
		[axViewLengthText setFloatValue:[sender floatValue]];
	}
}

- (IBAction)pageCView:(id)sender
{
	if(!cViewMPRorCPRMode)
	{
		if([sender isMouseLeftKeyDown])
			interpolationMode=0;
		else
			interpolationMode=1;
		float locate;
		locate=[sender floatValue] - lastCViewTranslate;
		lastCViewTranslate = [sender floatValue];
		if(locate!=0||interpolationMode)
		{
			oViewUserTransform->Translate(locate,0,0);
			[self updateCView];
			[self updateOView];
			[self updateAxView];
				
			
		}
//		if(interpolationMode)
//			[self updatePageSliders];
	}
	//	[self updateCViewAsCurvedMPR];
	
}

- (IBAction)pageOView:(id)sender
{
	if([sender isMouseLeftKeyDown])
		interpolationMode=0;
	else
		interpolationMode=1;
	float locate,step;
	locate=round([sender floatValue]/minSpacing);//to get Seeds ROI but not working well
	step=locate-lastOViewTranslate;
	step*=minSpacing;
	lastOViewTranslate = locate;
	oViewUserTransform->Translate(0,0,step);
	if(step!=0||interpolationMode)
	{
		[self updateOView];
		if(!cViewMPRorCPRMode)
		{
			[self updateCView];
			[self updateAxView];
			
		}
	}
	
	
}
- (void)	onlyPageAxView:(id)sender
{
	float locate;
	locate=[sender floatValue];
	locate-=lastAxViewTranslate;
	lastAxViewTranslate = [sender floatValue];
//	float locate;
//	locate=[sender minValue]+[sender maxValue]-[sender floatValue];
//	axViewTransform->Identity();
//	axViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
//	axViewTransform->RotateZ(oViewToCViewZAngle);
//	axViewTransform->RotateX(90+cViewToAxViewZAngle);
	axViewTransform->Translate(0,0,-locate);
	isNeedShowReferenceLine=YES;
	[self updateAxView];
	isNeedShowReferenceLine=NO;
	
}
- (void)	onlyPageCView:(id)sender
{
	float locate;
	locate=[sender floatValue] - lastCViewTranslate;
	lastCViewTranslate = [sender floatValue];
	cViewTransform->Translate(0,0,locate);
	if(locate!=0)
		[self updateCView];
	
}
- (IBAction)rotateXCView:(id)sender
{
	
	float angle;
	angle=[sender floatValue];
	if([sender isMouseLeftKeyDown])
		interpolationMode=0;
	else
		interpolationMode=1;
	
	if(angle-lastCViewYAngle!=0||interpolationMode)
	{
		cViewTransform->Identity();
		cViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
		cViewTransform->RotateZ(oViewToCViewZAngle);
		cViewTransform->RotateY(-90);
		
		cViewTransform->RotateY(angle);	
		if(currentViewMode==1&&!isStraightenedCPR)
		{
			[oYRotateSlider setFloatValue:[oYRotateSlider floatValue]+angle-lastCViewYAngle];
			[oYRotateSlider performClick:sender];
		}
		else
			[self updateCView];
		
		[cImageSlider setFloatValue:0];
		lastCViewTranslate=0;
		[cViewRotateYText setFloatValue: [sender floatValue]];
		if(currentViewMode==2&&interpolationMode==1)
		{
			[self performLongitudeSectionAnalysis];
			if([[NSString stringWithString:@"Longitudinal Section Width(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]])
			{
				[plotView setViewControllor:self];
				[self vesselAnalysisSetNewSource:self];
				
			}
		}
		lastCViewYAngle=angle;
	}		
	
	
}

- (IBAction)rotateYCView:(id)sender
{
	
	float angle;
	angle=[sender floatValue];
	if([sender isMouseLeftKeyDown])
		interpolationMode=0;
	else
		interpolationMode=1;
	
	if(angle!=0||interpolationMode)
	{
		cViewTransform->Identity();
		cViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
		cViewTransform->RotateZ(oViewToCViewZAngle);
		cViewTransform->RotateY(-90);
		
		cViewTransform->RotateY(angle);	

		[self updateCView];
		
		[cImageSlider setFloatValue:0];
		lastCViewTranslate=0;
		[cViewRotateYText setFloatValue: [sender floatValue]];
		if(currentViewMode==2&&interpolationMode==1)
		{
			[self performLongitudeSectionAnalysis];
			if([[NSString stringWithString:@"Longitudinal Section Width(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]])
			{
				[plotView setViewControllor:self];
				[self vesselAnalysisSetNewSource:self];
				
			}
		}
		
	}		
	
	
}
- (void)rotateZCView:(float)angle
{
	if(angle!=0)
	{
		
		oViewUserTransform->RotateX(-angle);	
		
		[self updateOView];
		if(!(cViewMPRorCPRMode&&isStraightenedCPR))
			[self cAndAxViewReset];
		[self updatePageSliders];		
	}	
	
}
- (void)rotateZAxView:(float)angle
{
	if(angle!=0)
	{
		
		oViewUserTransform->RotateY(-angle);	
		
		[self updateOView];
		if(!(cViewMPRorCPRMode&&isStraightenedCPR))
			[self cAndAxViewReset];
		[self updatePageSliders];		
	}	
	
}
- (IBAction)rotateXOView:(id)sender
{
	
	float angle;
	angle=[sender floatValue] - lastOViewXAngle;
	if([sender isMouseLeftKeyDown])
		interpolationMode=0;
	else
		interpolationMode=1;
	
	if(angle!=0||interpolationMode)
	{
		
		
		lastOViewXAngle = [sender floatValue];
		oViewUserTransform->RotateX(angle);	
		
		[self updateOView];
		if(!(cViewMPRorCPRMode&&isStraightenedCPR))
			[self cAndAxViewReset];
		[self updatePageSliders];
		[oViewRotateXText setFloatValue: [sender floatValue]];
	}	
	
}
- (void)    rotateZOView:(float)angle
{
	if(angle!=0)
	{
		
		oViewUserTransform->RotateZ(angle);	
		
		[self updateOView];
		if(!(cViewMPRorCPRMode&&isStraightenedCPR))
			[self cAndAxViewReset];
		[self updatePageSliders];		
	}	
}
- (IBAction)rotateYOView:(id)sender
{
	
	float angle;
	angle=[sender floatValue] - lastOViewYAngle;
	if([sender isMouseLeftKeyDown])
		interpolationMode=0;
	else
		interpolationMode=1;
	
	if(angle!=0||interpolationMode)
	{
		lastOViewYAngle = [sender floatValue];
		oViewUserTransform->RotateY(angle);
		[self updateOView];
		if(!(cViewMPRorCPRMode&&isStraightenedCPR))
			[self cAndAxViewReset];
		[self updatePageSliders];	
		[oViewRotateYText setFloatValue: [sender floatValue]];
	}
	
	
}
- (void) defaultToolModified: (NSNotification*) note
{
	id sender = [note object];
	int tag;
	
	if( sender)
	{
		if ([sender isKindOfClass:[NSMatrix class]])
		{
			NSButtonCell *theCell = [sender selectedCell];
			tag = [theCell tag];
		}
		else
		{
			tag = [sender tag];
		}
	}
	else tag = [[[note userInfo] valueForKey:@"toolIndex"] intValue];
	
	if( tag >= 0 ) 
	{
//		if( tag > 5)
//			tag = 20;
		if(tag<=5)
			[self changeCurrentTool:tag];
		else
		{
			[originalView setCurrentTool: tag];
			[cPRView setCurrentTool: tag];
			[crossAxiasView setCurrentTool:tag];
		}
	}
	
	
}

- (void) changeWLWW: (NSNotification*) note
{
	id sender = [note object] ;
	if ([sender isKindOfClass:[DCMPix class]]&&(!isChangingWWWLBySelf))
	{
		DCMPix	*otherPix = sender;
		float iwl, iww;
		
		iww = [otherPix ww];
		iwl = [otherPix wl];
		if([oViewPixList containsObject: otherPix]||[cViewPixList containsObject: otherPix]||[axViewPixList containsObject: otherPix])
		{
			isChangingWWWLBySelf=1;
			if( [oViewPixList containsObject: otherPix])
			{
				//if( iww != [originalView curWW] || iwl != [originalView curWL])
				[originalView setIndex: 0 ];
				if( iww != [cPRView curWW] || iwl != [cPRView curWL])
					[cPRView setWLWW:iwl :iww];					
				if( iww != [crossAxiasView curWW] || iwl != [crossAxiasView curWL])
					[crossAxiasView setWLWW:iwl :iww];
				
			}
			else if( [cViewPixList containsObject: otherPix])
			{
				if( iww != [originalView curWW] || iwl != [originalView curWL])
					[originalView setWLWW:iwl :iww];				
				if( iww != [crossAxiasView curWW] || iwl != [crossAxiasView curWL])
					[crossAxiasView setWLWW:iwl :iww];	
			}
			else if( [axViewPixList containsObject: otherPix])
			{
				if( iww != [originalView curWW] || iwl != [originalView curWL])
					[originalView setWLWW:iwl :iww];				
				if( iww != [cPRView curWW] || iwl != [cPRView curWL])
					[cPRView setWLWW:iwl :iww];		
			}
			isChangingWWWLBySelf=0;
		}
	}
	
	
}
- (void) crossMove:(NSNotification*) note
{
	if(activeView==originalView)
	{
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"dragged"] == YES)
		{
			interpolationMode=0;
			if([originalView angle]==0)
			{
				
				if(interpolationMode)
					oViewSlice->SetInterpolationModeToCubic();
				else
					oViewSlice->SetInterpolationModeToNearestNeighbor();
				
				float oX,oY;
				vtkImageData	*tempIm;
				int				imExtent[ 6];
				double		space[ 3], origin[ 3];
				tempIm = oViewSlice->GetOutput();
				tempIm->Update();
				tempIm->GetWholeExtent( imExtent);
				tempIm->GetSpacing( space);
				tempIm->GetOrigin( origin);	
				
				[originalView getCrossCoordinates: &oX  :&oY];
				oY=-oY;
				oX=oX*space[0]+origin[0];
				oY=oY*space[1]+origin[1];
				if(!(oX==0&&oY==0))
				{
					oViewUserTransform->Translate(oX,oY,0);
					if(currentViewMode==0)
					{
						[self updateCView];
						[self updateAxView];
						[axImageSlider setMaxValue: ([axImageSlider maxValue]+oY)];
						[axImageSlider setMinValue: ([axImageSlider minValue]+oY)];
						
						[cImageSlider setMaxValue: ([cImageSlider maxValue]-oX)];
						[cImageSlider setMinValue: ([cImageSlider minValue]-oX)];
						[cYRotateSlider setFloatValue: 0];
						lastCViewYAngle=0;
					}
				}
			}
			else
			{
				float angle= [originalView angle]-lastOViewZAngle;
				oViewUserTransform->RotateZ(angle);
				[self updateCView];
				[self updateAxView];
				lastOViewZAngle=[originalView angle];
			}
		}
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"] == YES)
		{	
//			float angle= [originalView angle];
//			
//			if(angle!=0)
//				[self rotateZOView:angle];
//			else
//			{
				interpolationMode=1;
				[self updateOView];//update oViewSpace and oViewOrigin for other operation , such as root seeds planting
				[self cAndAxViewReset];
				[self updatePageSliders];
//			}
			[originalView setMPRAngle: 0.0];
			lastOViewZAngle=0;
			activeView=nil;
		}
	}
	else if(activeView==cPRView)
	{
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"dragged"] == YES)
		{
			interpolationMode=0;
			if([cPRView angle]==0)
			{
				
				if(interpolationMode)
					cViewSlice->SetInterpolationModeToCubic();
				else
					cViewSlice->SetInterpolationModeToNearestNeighbor();
				
				float oZ,oY;
				vtkImageData	*tempIm;
				int				imExtent[ 6];
				double		space[ 3], origin[ 3];
				tempIm = cViewSlice->GetOutput();
				tempIm->Update();
				tempIm->GetWholeExtent( imExtent);
				tempIm->GetSpacing( space);
				tempIm->GetOrigin( origin);	
				
				[cPRView getCrossCoordinates: &oZ  :&oY];
				oY=-oY;
				oZ=oZ*space[0]+origin[0];
				oY=oY*space[1]+origin[1];
				if(!(oZ==0&&oY==0))
				{
					oViewUserTransform->Translate(0,oY,oZ);
					if(currentViewMode==0)
					{
						[self updateOView];
						[self updateAxView];

						[axImageSlider setMaxValue: ([axImageSlider maxValue]+oY)];
						[axImageSlider setMinValue: ([axImageSlider minValue]+oY)];
						
						[oImageSlider setMaxValue: ([oImageSlider maxValue]-oZ)];
						[oImageSlider setMinValue: ([oImageSlider minValue]-oZ)];
						
					}
				}
			}
			else
			{
				float angle= [cPRView angle]-lastCViewZAngle;
				oViewUserTransform->RotateX(-angle);
				[self updateOView];
				[self updateAxView];
				lastCViewZAngle=[cPRView angle];
			}
		}
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"] == YES)
		{	
//			float angle= [cPRView angle];
//			
//			if(angle!=0)
//				[self rotateZCView:angle];
//			else
//			{
				interpolationMode=1;
				[self updateOView];//update oViewSpace and oViewOrigin for other operation , such as root seeds planting
				[self cAndAxViewReset];
				[self updatePageSliders];
//			}
			[cPRView setMPRAngle: 0.0];
			lastCViewZAngle=0;
			activeView=nil;
		}
	}
	else if(activeView==crossAxiasView)
	{
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"dragged"] == YES)
		{
			interpolationMode=0;
			if([crossAxiasView angle]==0)
			{
				if(interpolationMode)
					axViewSlice->SetInterpolationModeToCubic();
				else
					axViewSlice->SetInterpolationModeToNearestNeighbor();
				
				float oX,oZ;
				vtkImageData	*tempIm;
				int				imExtent[ 6];
				double		space[ 3], origin[ 3];
				tempIm = axViewSlice->GetOutput();
				tempIm->Update();
				tempIm->GetWholeExtent( imExtent);
				tempIm->GetSpacing( space);
				tempIm->GetOrigin( origin);	
				
				[crossAxiasView getCrossCoordinates: &oX  :&oZ];
				oZ=-oZ;
				oX=oX*space[0]+origin[0];
				oZ=oZ*space[1]+origin[1];
				if(!(oX==0&&oZ==0))
				{
					oViewUserTransform->Translate(oX,0,oZ);
					if(currentViewMode==0)
					{
						[self updateOView];
						[self updateCView];
						
						[oImageSlider setMaxValue: ([oImageSlider maxValue]-oZ)];
						[oImageSlider setMinValue: ([oImageSlider minValue]-oZ)];
						
						[cImageSlider setMaxValue: ([cImageSlider maxValue]+oX)];
						[cImageSlider setMinValue: ([cImageSlider minValue]+oX)];
						
					}
				}
			}
			else
			{
				float angle= [crossAxiasView angle]-lastAxViewZAngle;
				oViewUserTransform->RotateY(-angle);;
				[self updateOView];
				[self updateCView];
				lastAxViewZAngle=[crossAxiasView angle];
			}
		}
		if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"] == YES)
		{	
//			float angle= [crossAxiasView angle];
//			
//			if(angle!=0)
//				[self rotateZAxView:angle];
//			else
//			{
				interpolationMode=1;
				[self updateOView];//update oViewSpace and oViewOrigin for other operation , such as root seeds planting
				[self cAndAxViewReset];
				[self updatePageSliders];
//			}
			[crossAxiasView setMPRAngle: 0.0];
			lastAxViewZAngle=0;
			activeView=nil;
		}
	}
	
}
- (IBAction)showAnnotations:(id)sender
{
	if([sender state]==NSOnState)
	{
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"CMIV2DViewANNOTATIONS"];
		[[NSUserDefaults standardUserDefaults] setInteger: 2 forKey: @"ANNOTATIONS"];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setInteger: -1 forKey: @"CMIV2DViewANNOTATIONS"];
		[[NSUserDefaults standardUserDefaults] setInteger: 1 forKey: @"ANNOTATIONS"];
	}
	[self updateOView];
	[self updateCView];
	[self updateAxView];
	
	
}
- (IBAction)crossShow:(id)sender
{
	int showcross;
	if(sender==axViewCrossShowButton)
	{
		if([sender state]==NSOnState)
		{
			showcross=1;
			[crossAxiasView showCrossHair];
		}
		else
		{
			showcross=-1;
			[crossAxiasView hideCrossHair];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowAxViewCrossHair"];
	}
	if(sender==cViewCrossShowButton)
	{
		if([sender state]==NSOnState)
		{
			showcross=1;
			[cPRView showCrossHair];
		}
		else
		{
			showcross=-1;
			[cPRView hideCrossHair];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowCViewCrossHair"];	
	}
	if(sender==oViewCrossShowButton)
	{
		if([sender state]==NSOnState)
		{
			showcross=1;
			[originalView showCrossHair];
		}
		else
		{
			showcross=-1;
			[originalView hideCrossHair];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:showcross forKey:@"CMIV2DViewShowOViewCrossHair"];	
	}
	
	oViewUserTransform->Translate(0,0,0.5);
	oViewUserTransform->Translate(0,0,-0.5);
	[self updateOView];
	[self updateCView];
	[self updateAxView];
	
}

- (void) cAndAxViewReset
{
	
	axViewTransform->Identity();
	axViewTransform->RotateX(90);
	if(!cViewMPRorCPRMode)
	{
		[axImageSlider setFloatValue: 0];
		lastAxViewTranslate=0;
	}
	cViewTransform->Identity();
	cViewTransform->RotateY(-90);
	[cImageSlider setFloatValue: 0];
	if(currentViewMode==0)
	{
		[cYRotateSlider setFloatValue:0];
		lastCViewYAngle=0;
	}
	cPRViewCenter.x=0;
	cPRViewCenter.y=0;
	oViewToCViewZAngle=0;
	cViewToAxViewZAngle=0;	
	[self updateCView];
	[self updateAxView];
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if( [seedsList isEqual:tableView])
	{
		return [contrastList count];
	}
	else if( [centerlinesList isEqual: tableView ])
	{
		return [cpr3DPaths count];
	}
	return 0;
	
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{
	if( originalViewController == 0L) return 0L;
	if( [seedsList isEqual:tableView])
	{
		
		if( [[tableColumn identifier] isEqualToString:@"Index"])
		{
			return [NSString stringWithFormat:@"%d", row+1];
		} 
		if( [[tableColumn identifier] isEqualToString:@"Name"])
		{
			return [[contrastList objectAtIndex:row] objectForKey:@"Name"];
		}
	}
	else if([centerlinesList isEqual:tableView])
	{
		
		if( [[tableColumn identifier] isEqualToString:@"Length"])
		{
			if(!centerlinesLengthArrays)
				centerlinesLengthArrays=[[NSMutableArray alloc] initWithCapacity:0];
			if([centerlinesLengthArrays count]!=[cpr3DPaths count])
				[self recaculateAllCenterlinesLength];
			return [NSString stringWithFormat:@"%d", [[centerlinesLengthArrays objectAtIndex: row] intValue]];
		} 
		if( [[tableColumn identifier] isEqualToString:@"Name"])
		{
			return [centerlinesNameArrays objectAtIndex:row];
		}
	}
	
	
	return 0L;
}
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(int)rowIndex
{
	if( originalViewController == 0L) return;
	if( [seedsList isEqual:aTableView])
	{
		
		if( [[aTableColumn identifier] isEqualToString:@"Name"])
		{
			if([anObject length]>0)
			{
				NSString* newname, *oldname;
				newname=anObject;
				oldname=[[contrastList objectAtIndex:rowIndex] objectForKey:@"Name"];
				unsigned i;
				ROI* temproi;
				for(i=0;i<[totalROIList count];i++)
				{
					temproi=[totalROIList objectAtIndex: i];
					if([[temproi name]isEqualToString:oldname])
						[temproi setName: newname];
				}
				[[contrastList objectAtIndex:rowIndex] setValue:newname forKey:@"Name"];
			}
		}		
		
	}
	else if( [centerlinesList isEqual:aTableView])
	{
		if( [[aTableColumn identifier] isEqualToString:@"Name"])
		{
			if([anObject length]>0)
			{
				
				[centerlinesNameArrays removeObjectAtIndex:rowIndex];
				[centerlinesNameArrays insertObject:anObject atIndex:rowIndex];
			}
		}		
	}
}
- (int)inverseMatrix:(float*)inm :(float*)outm
{
	float detinm=inm[0]*inm[4]*inm[8]+inm[1]*inm[5]*inm[6]+inm[2]*inm[3]*inm[7]-inm[2]*inm[4]*inm[6]-inm[1]*inm[3]*inm[8]-inm[0]*inm[5]*inm[7];
	if(detinm==0) return 0;
	outm[0]=inm[4]*inm[8]-inm[5]*inm[7];
	outm[1]=inm[2]*inm[7]-inm[1]*inm[8];
	outm[2]=inm[1]*inm[5]-inm[2]*inm[4];
	outm[3]=inm[5]*inm[6]-inm[3]*inm[8];
	outm[4]=inm[0]*inm[8]-inm[2]*inm[6];
	outm[5]=inm[2]*inm[3]-inm[0]*inm[5];
	outm[6]=inm[3]*inm[7]-inm[5]*inm[6];
	outm[7]=inm[1]*inm[6]-inm[0]*inm[7];
	outm[8]=inm[0]*inm[4]-inm[1]*inm[3];
	return 1;
}
- (float)TriCubic : (float*) p :(float *)volume : (int) xDim : (int) yDim :(int) zDim
{
	/*
	 * TriCubic - tri-cubic interpolation at point, p.
	 *   inputs:
	 *     p - the interpolation point.
	 *     volume - a pointer to the float volume data, stored in x,
	 *              y, then z order (x index increasing fastest).
	 *     xDim, yDim, zDim - dimensions of the array of volume data.
	 *   returns:
	 *     the interpolated value at p.
	 *   note:
	 *     NO range checking is done in this function.
	 */
	
	int             x, y, z;
	register int    i, j, k;
	float           dx, dy, dz;
	register float *pv;
	float           u[4], v[4], w[4];
	float           r[4], q[4];
	float           vox = 0;
	int             xyDim;
	
	xyDim = xDim * yDim;
	
	x = (int) p[0], y = (int) p[1], z = (int) p[2];
	if (x < 1 || x >= xDim-2 || y < 1 || y >= yDim-2 || z < 1 || z >= zDim-2)
		return (minValueInSeries);
	
	dx = p[0] - (float) x, dy = p[1] - (float) y, dz = p[2] - (float) z;
	pv = volume + (x - 1) + (y - 1) * xDim + (z - 1) * xyDim;
	
# define CUBE(x)   ((x) * (x) * (x))
# define SQR(x)    ((x) * (x))
	/*
	 #define DOUBLE(x) ((x) + (x))
	 #define HALF(x)   ...
	 *
	 * may also be used to reduce the number of floating point
	 * multiplications. The IEEE standard allows for DOUBLE/HALF
	 * operations.
	 */
	
	/* factors for Catmull-Rom interpolation */
	
	u[0] = -0.5 * CUBE (dx) + SQR (dx) - 0.5 * dx;
	u[1] = 1.5 * CUBE (dx) - 2.5 * SQR (dx) + 1;
	u[2] = -1.5 * CUBE (dx) + 2 * SQR (dx) + 0.5 * dx;
	u[3] = 0.5 * CUBE (dx) - 0.5 * SQR (dx);
	
	v[0] = -0.5 * CUBE (dy) + SQR (dy) - 0.5 * dy;
	v[1] = 1.5 * CUBE (dy) - 2.5 * SQR (dy) + 1;
	v[2] = -1.5 * CUBE (dy) + 2 * SQR (dy) + 0.5 * dy;
	v[3] = 0.5 * CUBE (dy) - 0.5 * SQR (dy);
	
	w[0] = -0.5 * CUBE (dz) + SQR (dz) - 0.5 * dz;
	w[1] = 1.5 * CUBE (dz) - 2.5 * SQR (dz) + 1;
	w[2] = -1.5 * CUBE (dz) + 2 * SQR (dz) + 0.5 * dz;
	w[3] = 0.5 * CUBE (dz) - 0.5 * SQR (dz);
	
	for (k = 0; k < 4; k++)
	{
		q[k] = 0;
		for (j = 0; j < 4; j++)
		{
			r[j] = 0;
			for (i = 0; i < 4; i++)
			{
				r[j] += u[i] * *pv;
				pv++;
			}
			q[k] += v[j] * r[j];
			pv += xDim - 4;
		}
		vox += w[k] * q[k];
		pv += xyDim - 4 * xDim;
	}
	return (vox < minValueInSeries ? minValueInSeries : vox);
}
#pragma mark-
#pragma mark 2.2 control CPR views 

- (int) generateSlidingNormals:(int)npts:(double*)pointsxyz:(double*)ptnormals
{
	double sPrev[3], sNext[3], q[3], w[3], normal[3], theta;
	double p[3], pNext[3];
	double c[3], f1, f2;
	int i, j, largeRotation;
	
	
	if(npts<2)
		return 0;
	for (j=0; j<npts; j++) 
	{
		
		if ( j == 0 ) //first point
		{
			
			
			
			for (i=0; i<3; i++) 
			{
				p[i]=*(pointsxyz+j*3+i);
				pNext[i]=*(pointsxyz+j*3+3+i);
				sPrev[i] = pNext[i] - p[i];
				sNext[i] = sPrev[i];
			}
			if ( vtkMath::Normalize(sNext) == 0.0 )
            {
				return 0;
            }
			
			
			// the following logic will produce a normal orthogonal
			// to the first line segment. If we have three points
			// we use special logic to select a normal orthogonal
			// to the first two line segments
			int foundNormal=0;
			if (npts > 2)
			{
				int ipt;
				
				// Look at the line segments (0,1), (ipt-1, ipt)
				// until a pair which meets the following criteria
				// is found: ||(0,1)x(ipt-1,ipt)|| > 1.0E-3.
				// This is used to eliminate nearly parallel cases.
				for(ipt=2; ipt < npts; ipt++)
				{
					double ftmp[3];
					
					for (i=0; i<3; i++) 
					{
						ftmp[i] =*(pointsxyz+ipt*3+i) - *(pointsxyz+ipt*3-3+i);
					}
					
					if ( vtkMath::Normalize(ftmp) == 0.0 )
					{
						continue;
					}
					
					// now the starting normal should simply be the cross product
					// in the following if statement we check for the case where
					// the two segments are parallel 
					vtkMath::Cross(sNext,ftmp,normal);
					if ( vtkMath::Norm(normal) > 1.0E-3 )
					{
						foundNormal = 1;
						break;
					}
				}
			}
			
			if ((npts <= 2)|| !foundNormal) 
			{
				for (i=0; i<3; i++) 
				{
					// a little trick to find othogonal normal
					if ( sNext[i] != 0.0 ) 
					{
						normal[(i+2)%3] = 0.0;
						normal[(i+1)%3] = 1.0;
						normal[i] = -sNext[(i+1)%3]/sNext[i];
						break;
					}
				}
			}
			
			vtkMath::Normalize(normal);
          	for(i=0;i<3;i++)
				*(ptnormals+j*3+i)=normal[i];
		}
		
        else if ( j == (npts-1) ) //last point; just insert previous
		{
			for(i=0;i<3;i++)
				*(ptnormals+j*3+i)=normal[i];
		}
		
        else //inbetween points
		{
			//  Generate normals for new point by projecting previous normal
			for (i=0; i<3; i++)
            {
				p[i] = pNext[i];
				pNext[i]=*(pointsxyz+j*3+3+i);
				sPrev[i] = sNext[i];
				sNext[i] = pNext[i] - p[i];
            }
			
			if ( vtkMath::Normalize(sNext) == 0.0 )
            {
				return 0;
            }
			
			//compute rotation vector
			vtkMath::Cross(sPrev,normal,w);
			if ( vtkMath::Normalize(w) == 0.0 ) 
            {
				return 0;
            }
			
			//see whether we rotate greater than 90 degrees.
			if ( vtkMath::Dot(sPrev,sNext) < 0.0 )
            {
				largeRotation = 1;
            }
			else
            {
				largeRotation = 0;
            }
			
			//compute rotation of line segment
			vtkMath::Cross (sNext, sPrev, q);
			if ( (theta=asin((double)vtkMath::Normalize(q))) == 0.0 ) 
            { //no rotation, use previous normal
				
				for(i=0;i<3;i++)
					*(ptnormals+j*3+i)=normal[i];
				continue;
            }
			if ( largeRotation )
            {
				if ( theta > 0.0 )
				{
					theta = vtkMath::Pi() - theta;
				}
				else
				{
					theta = -vtkMath::Pi() - theta;
				}
            }
			
			// new method
			for (i=0; i<3; i++)
            {
				c[i] = sNext[i] + sPrev[i];
            }
			vtkMath::Normalize(c);
			f1 = vtkMath::Dot(q,normal);
			f2 = 1.0 - f1*f1;
			if (f2 > 0.0)
            {
				f2 = sqrt(1.0 - f1*f1);
            }
			else
            {
				f2 = 0.0;
            }
			vtkMath::Cross(c,q,w);
			vtkMath::Cross(sPrev,q,c);
			if (vtkMath::Dot(normal,c)*vtkMath::Dot(w,c) < 0)
            {
				f2 = -1.0*f2;
            }
			for (i=0; i<3; i++)
            {
				normal[i] = f1*q[i] + f2*w[i];
            }
			
			for(i=0;i<3;i++)
				*(ptnormals+j*3+i)=normal[i];
		}//for this point
	}
	return 1;
}
- (int) generateUnitRobbin:(int)npts:(double*)inputpointsxyz:(double*)ptnormals:(double*)outputpointsxyz:(double)angle:(double)width
{
	/*
	 if ( !this->GeneratePoints(offset,npts,pts,inPts,newPts,pd,outPD,
	 newNormals,inScalars,range,inNormals) )
	 
	 int vtkRibbonFilter::GeneratePoints(vtkIdType offset, 
	 vtkIdType npts, vtkIdType *pts,
	 vtkPoints *inPts, vtkPoints *newPts, 
	 vtkPointData *pd, vtkPointData *outPD,
	 vtkFloatArray *newNormals,
	 vtkDataArray *inScalars, double range[2],
	 vtkDataArray *inNormals)*/
	int i,j;
	double p[3];
	double pNext[3];
	double sNext[3];
	double sPrev[3];
	double n[3];
	double s[3], v[3];
	//double bevelAngle;
	double w[3];
	double nP[3];
	double sFactor=1.0;
	
	
	// Use "averaged" segment to create beveled effect. 
	// Watch out for first and last points.
	//
	for (j=0; j < npts; j++)
    {
		if ( j == 0 ) //first point
		{
			
			for (i=0; i<3; i++) 
			{
				p[i]=*(inputpointsxyz+j*3+i);
				pNext[i]=*(inputpointsxyz+j*3+3+i);
				sNext[i] = pNext[i] - p[i];
				sPrev[i] = sNext[i];
			}
		}
		else if ( j == (npts-1) ) //last point
		{
			for (i=0; i<3; i++)
			{
				sPrev[i] = sNext[i];
				p[i] = pNext[i];
			}
		}
		else
		{
			for (i=0; i<3; i++)
			{
				p[i] = pNext[i];
				pNext[i]=*(inputpointsxyz+j*3+3+i);
				sPrev[i] = sNext[i];
				sNext[i] = pNext[i] - p[i];
			}
		}
		
		for (i=0; i<3; i++)
			n[i]=*(ptnormals+j*3+i);
		
		if ( vtkMath::Normalize(sNext) == 0.0 )
		{
			
			return 0;
		}
		
		for (i=0; i<3; i++)
		{
			s[i] = (sPrev[i] + sNext[i]) / 2.0; //average vector
		}
		// if s is zero then just use sPrev cross n
		if (vtkMath::Normalize(s) == 0.0)
		{
			vtkMath::Cross(sPrev,n,s);
			if (vtkMath::Normalize(s) == 0.0)
			{
				// vtkWarningMacro(<< "Using alternate bevel vector");
			}
		}
		vtkMath::Cross(s,n,w);
		if ( vtkMath::Normalize(w) == 0.0)
		{
			return 0;
		}
		
		vtkMath::Cross(w,s,nP); //create orthogonal coordinate system
		vtkMath::Normalize(nP);
		
		
		for (i=0; i<3; i++) 
		{
			v[i] = (w[i]*cos(angle) + nP[i]*sin(angle));
			// sp[i] = p[i] + width * sFactor * v[i];
			// sm[i] = p[i] - width * sFactor * v[i];
			*(outputpointsxyz+j*3+i)= width * sFactor * v[i];
		}
		
	}//for all points in polyline
	
	return 1;
}
- (void) createEven3DPathForCPR:(int*)pwidth :(int*)pheight 
{	
	
	int i,ii;
	double position[3];
	int width,height;
	int pointNumber=[curvedMPR3DPath count];
	CMIV3DPoint* a3DPoint;
	
	double* inputpointsxyz=(double*)malloc(sizeof(double)*pointNumber*3);
	double* inputpointslen=(double*)malloc(sizeof(double)*pointNumber);
	
	double prepoint[3];
	double path3DLength=0;
	a3DPoint=[curvedMPR3DPath objectAtIndex: 0];
	prepoint[0]=[a3DPoint x];
	prepoint[1]=[a3DPoint y];
	prepoint[2]=[a3DPoint z];	

	for(i=0;i<pointNumber;i++)
	{
		a3DPoint=[curvedMPR3DPath objectAtIndex: i];
		position[0]=[a3DPoint x];
		position[1]=[a3DPoint y];
		position[2]=[a3DPoint z];	
		*(inputpointslen+i)=sqrt((position[0]-prepoint[0])*(position[0]-prepoint[0])+(position[1]-prepoint[1])*(position[1]-prepoint[1])+(position[2]-prepoint[2])*(position[2]-prepoint[2]));
		
		path3DLength+=*(inputpointslen+i);
		for(ii=0;ii<3;ii++)
		{
			*(inputpointsxyz+i*3+ii)=position[ii];
			prepoint[ii]=position[ii];
		}
	}
	
	//width and height
	*pwidth=width=40/cViewSpace[0];//here we use fixed width( 40mm )
	*pheight=height=(int)(path3DLength/cViewSpace[1]);
	

	
	// update axview's slider
	
	[axImageSlider setMinValue: 0];
	[axImageSlider setMaxValue: path3DLength-1];
	if([axImageSlider floatValue]>path3DLength-1)
		[axImageSlider setFloatValue: path3DLength-1];
	else if([axImageSlider floatValue]<0)
		[axImageSlider setFloatValue: 0];
	
	//resample to get even spacing
	double* outputcenterlinexyz;
	outputcenterlinexyz=(double*)malloc(sizeof(double)*height*3);
	for(ii=0;ii<3;ii++)
		*(outputcenterlinexyz+ii)=*(inputpointsxyz+ii);
	
	path3DLength=0;
	int curpointindex=0;
	double curpointdis=0;
	double interpolfactor=1;
	for(i=1;i<height;i++)
	{
		while(curpointdis-path3DLength<cViewSpace[1]&&curpointindex<pointNumber)
		{
			curpointindex++;
			curpointdis+=*(inputpointslen+curpointindex);
			
		}
		if(curpointindex>=pointNumber)
		{
			for(ii=0;ii<3;ii++)
				*(outputcenterlinexyz+i*3+ii)=(*(inputpointsxyz+curpointindex*3-3+ii))*interpolfactor;
			continue;
		}
		
		if((*(inputpointslen+curpointindex))>0)
			interpolfactor=(curpointdis-path3DLength-cViewSpace[1])/(*(inputpointslen+curpointindex));
		else
			interpolfactor=1;
		for(ii=0;ii<3;ii++)
			*(outputcenterlinexyz+i*3+ii)=(*(inputpointsxyz+curpointindex*3+ii))*(1.0-interpolfactor)+(*(inputpointsxyz+curpointindex*3-3+ii))*interpolfactor;	
		if(*(outputcenterlinexyz+i*3)>1000)
			*(outputcenterlinexyz+i*3+ii)=1000;
		
		path3DLength+=cViewSpace[1];
	}
	
	curvedMPREven3DPath=[[NSMutableArray alloc] initWithCapacity: 0];
	for(i=0;i<height;i++)
	{
		CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: *(outputcenterlinexyz+i*3)];
		[new3DPoint setY: *(outputcenterlinexyz+i*3+1)];
		[new3DPoint setZ: *(outputcenterlinexyz+i*3+2)];
		[curvedMPREven3DPath addObject: new3DPoint];
		[new3DPoint release];
	}
	
	
	free(inputpointsxyz);free(inputpointslen);
}
- (float*) caculateStraightCPRImage :(int*)pwidth :(int*)pheight 
{
	float *im=0L;

	int width=0,height=0;
	int i,ii;
	double position[3];
	double* outputcenterlinexyz=nil;
	cViewSpace[0]=cViewSpace[1]=xSpacing;
	
	if(curvedMPREven3DPath==nil)
		[self createEven3DPathForCPR:pwidth :pheight ];
	else
	{
		*pwidth=width=maxWidthofCPR/cViewSpace[0];//here we use fixed width( 40mm )
		*pheight=height=[curvedMPREven3DPath count];
		outputcenterlinexyz=(double*)malloc(sizeof(double)*height*3);
		CMIV3DPoint* a3DPoint;
		for(i=0;i<height;i++)
		{
			a3DPoint=[curvedMPREven3DPath objectAtIndex:i];
			*(outputcenterlinexyz+i*3)=[a3DPoint x];
			*(outputcenterlinexyz+i*3+1)=[a3DPoint y];
			*(outputcenterlinexyz+i*3+2)=[a3DPoint z];
		}
	}
	//create minimum rotate normals 
	double* outputcenterlinenormals=(double*)malloc(sizeof(double)*height*3);
	if([self generateSlidingNormals:height:outputcenterlinexyz:outputcenterlinenormals]==0)
		return nil;
	
	// create a narrow 3d ribbon from the centerline and use this ribbon to get cross-section line from each pair of point along this ribbon 
	double* unitribbonxyz=(double*)malloc(sizeof(double)*height*3);
	float rotateangle=[cYRotateSlider floatValue];
	if(rotateangle<0)
		rotateangle+=360;
	rotateangle=rotateangle*deg2rad;
	if([self generateUnitRobbin:height:outputcenterlinexyz:outputcenterlinenormals:unitribbonxyz:rotateangle:cViewSpace[0]]==0)
		return nil;
	
	
	
	im=(float*)malloc(sizeof(float)*width*height);
	if(!im)
		return 0L;
	
	
	
	int x,y,z;
	int j;
	int pixelindex=0;
	float fposition[3];
	
	for(j=0;j<height;j++)
	{
		for(ii=0;ii<3;ii++)
			position[ii]=*(outputcenterlinexyz+j*3+ii)-width/2*(*(unitribbonxyz+j*3+ii));
		
		
		for(i=0;i<width;i++)
		{
			
			for(ii=0;ii<3;ii++)
				position[ii]+=(*(unitribbonxyz+j*3+ii));
			if(interpolationMode)
			{
				fposition[0]=(position[0]-vtkOriginalX)/xSpacing;
				fposition[1]=(position[1]-vtkOriginalY)/ySpacing;
				fposition[2]=(position[2]-vtkOriginalZ)/zSpacing;
				*(im+pixelindex)=[self TriCubic:fposition: volumeData: imageWidth: imageHeight: imageAmount];
			}
			else
			{
				x = lround((position[0]-vtkOriginalX)/xSpacing);
				y = lround((position[1]-vtkOriginalY)/ySpacing);
				z = lround((position[2]-vtkOriginalZ)/zSpacing);
				if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)		  
					*(im+pixelindex)=*(volumeData + imageSize*z + imageWidth*y+x);
				else
					*(im+pixelindex)=minValueInSeries;
			}
			
			pixelindex++;
		}
		
	}
	
	
	free(outputcenterlinexyz);free(outputcenterlinenormals);free(unitribbonxyz);
	return im;	
	
}
- (float*) caculateCurvedMPRImage :(int*)pwidth :(int*)pheight
{
	
	float* im=0L;
	int i,ii;
	int pointNumber;
	double position[3];
	//cacluate parameters for CPR image (width, height, translateLeftX-Z,translateRightX-Z)
	int width, height;
	float path2DLength;	
	NSMutableArray  *path2DPoints=[curvedMPR2DPath points] ;
	pointNumber=[path2DPoints count];
	
	float curXSpacing,curYSpacing;
	float curOriginX,curOriginY;
	DCMPix* tempix=[oViewPixList objectAtIndex:0];
	
	curXSpacing=[tempix pixelSpacingX];
	curYSpacing=[tempix pixelSpacingY];
	curOriginX = [tempix originX];
	curOriginY = [tempix originY];
	
	cViewSpace[0]=cViewSpace[1]=xSpacing;
	
	float* inputpointsxyz=(float*)malloc(sizeof(float)*pointNumber*3);
	float* inputpointslen=(float*)malloc(sizeof(float)*pointNumber);
	float pre2dpoint[2];
	pre2dpoint[0] = curOriginX + [[path2DPoints objectAtIndex: 0] point].x * curXSpacing;
	pre2dpoint[1] = curOriginY + [[path2DPoints objectAtIndex: 0] point].y * curYSpacing;
	path2DLength=0;
	for(i=0;i<pointNumber;i++)
	{
		position[0] = curOriginX + [[path2DPoints objectAtIndex: i] point].x * curXSpacing;
		position[1] = curOriginY + [[path2DPoints objectAtIndex: i] point].y * curYSpacing;
		position[2] = 0;
		*(inputpointslen+i)=sqrt((position[0]-pre2dpoint[0])*(position[0]-pre2dpoint[0])+(position[1]-pre2dpoint[1])*(position[1]-pre2dpoint[1]));
		path2DLength+=*(inputpointslen+i);
		pre2dpoint[0]=position[0];
		pre2dpoint[1]=position[1];
		oViewUserTransform->TransformPoint(position,position);
		for(ii=0;ii<3;ii++)
			*(inputpointsxyz+i*3+ii)=position[ii];
	}
	
	//width and height
	*pwidth=width=(int)(([oImageSlider maxValue]-[oImageSlider minValue])/cViewSpace[0]);
	*pheight=height=(int)(path2DLength/cViewSpace[1]);
	
	// update axview's slider
	[axImageSlider setMinValue: 0];
	[axImageSlider setMaxValue: path2DLength];
	if([axImageSlider floatValue]>path2DLength)
		[axImageSlider setFloatValue: path2DLength-cViewSpace[1]];
	else if([axImageSlider floatValue]<0)
		[axImageSlider setFloatValue: 0];
	
	//resample to get even spacing
	float* outputcenterlinexyz=(float*)malloc(sizeof(float)*height*3);
	for(ii=0;ii<3;ii++)
		*(outputcenterlinexyz+ii)=*(inputpointsxyz+ii);
	
	path2DLength=0;
	int curpointindex=0;
	float curpointdis=0;
	float interpolfactor;
	for(i=1;i<height;i++)
	{
		while(curpointdis-path2DLength<cViewSpace[1]&&curpointindex<pointNumber)
		{
			curpointindex++;
			curpointdis+=*(inputpointslen+curpointindex);
			
		}
		interpolfactor=(curpointdis-path2DLength-cViewSpace[1])/(*(inputpointslen+curpointindex));
		for(ii=0;ii<3;ii++)
			*(outputcenterlinexyz+i*3+ii)=(*(inputpointsxyz+curpointindex*3+ii))*(1-interpolfactor)+(*(inputpointsxyz+curpointindex*3-3+ii))*interpolfactor;	
		
		path2DLength+=cViewSpace[1];
	}
	
	double traslateunit[3];
	
	traslateunit[0] = position[0] = curOriginX + [[path2DPoints objectAtIndex: 0] point].x * curXSpacing;
	traslateunit[1] = position[1] = curOriginY +[[path2DPoints objectAtIndex: 0] point].y * curYSpacing;
	traslateunit[2] = cViewSpace[0];	
	position[2] = 0;
	oViewUserTransform->TransformPoint(position,position);
	oViewUserTransform->TransformPoint(traslateunit,traslateunit);
	for(ii=0;ii<3;ii++)
		traslateunit[ii]=traslateunit[ii]-position[ii];
	
	
	//create a curved surface from projected centerline
	im=(float*)malloc(sizeof(float)*width*height);
	if(!im)
	{
		*pwidth=0;
		*pheight=0;
		return 0L;
	}
	
	//////////////////////////////////////////////
	
	int x,y,z;
	float fposition[3];
	int j;
	for(i=0;i<height;i++)
	{
		for(ii=0;ii<3;ii++)
			position[ii]=*(outputcenterlinexyz+i*3+ii)+traslateunit[ii]*([oImageSlider minValue]-[oImageSlider floatValue])/cViewSpace[0];
		for(j=0;j<width;j++)
		{
			
			for(ii=0;ii<3;ii++)
				position[ii]+=traslateunit[ii];
			fposition[0]=(position[0]-vtkOriginalX)/xSpacing;
			fposition[1]=(position[1]-vtkOriginalY)/ySpacing;
			fposition[2]=(position[2]-vtkOriginalZ)/zSpacing;
			if(interpolationMode)
				*(im+i*width+j)=[self TriCubic:fposition: volumeData: imageWidth: imageHeight: imageAmount];
			else
			{
				x = lround(fposition[0]);
				y = lround(fposition[1]);
				z = lround(fposition[2]);
				if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)		  
					*(im+i*width+j)=*(volumeData + imageSize*z + imageWidth*y+x);
				else
					*(im+i*width+j)=minValueInSeries;
			}
		}
		
	}
	free(inputpointsxyz);free(inputpointslen);free(outputcenterlinexyz);
	
	
	return im;
	
}

- (void) updateCViewAsCurvedMPR
{
	
	if(!curvedMPR2DPath)
	{
		[self updateCViewAsMPR]; 
		return;
	}
	
	float *im=0L;
	int width, height;
	
	if([curvedMPR3DPath count]<2)
	{
		[self updateCViewAsMPR]; 
		return;
	}
	if(!isStraightenedCPR)
	{
		im = [self caculateCurvedMPRImage :&width :&height];
	}
	else
	{
		im = [self caculateStraightCPRImage :&width :&height];
	}
	
	if(!im)
		return;
	DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :width :height :cViewSpace[0] :cViewSpace[1] :cViewOrigin[0] :cViewOrigin[1] :cViewOrigin[2]];
	[mypix copySUVfrom: curPix];	
	
	[cViewPixList removeAllObjects];
	[cViewPixList addObject: mypix];
	[mypix release];
	
	if(cprImageBuffer) free(cprImageBuffer);//maybe not necessary (the memory should be release when cViewPixList removeAllObjects, but I am confused here)
	cprImageBuffer=im;
	[[cViewROIList objectAtIndex: 0] removeAllObjects];
	if(curvedMPRReferenceLineOfAxis)
	{
		
		NSArray* points=[curvedMPRReferenceLineOfAxis points];
		NSPoint start,end;
		start=[[points objectAtIndex: 1] point];
		end= [[points objectAtIndex: 0] point];
		start.x=0;
		end.x=width-1;
		start.y= end.y = [axImageSlider floatValue]/cViewSpace[1];
		[[points objectAtIndex:1] setPoint: start];
		[[points objectAtIndex:0] setPoint: end];

		[[cViewROIList objectAtIndex: 0] addObject: curvedMPRReferenceLineOfAxis];

		
		
	}
	[curvedMPRReferenceLineOfAxis setROIMode:ROI_sleep];
	[cViewMeasurePolygon setROIMode:ROI_sleep];
	[cPRView setCrossCoordinates:-9999 :-9999 :YES];
	[cPRView setIndex: 0 ];
	
}
- (void) updateCViewAsMPR
{
	vtkImageData	*tempIm;
	int				imExtent[ 6];
	BOOL drawingArrawTool=NO;
	if(interpolationMode)
		cViewSlice->SetInterpolationModeToCubic();
	else
		cViewSlice->SetInterpolationModeToNearestNeighbor();
	tempIm = cViewSlice->GetOutput();
	tempIm->Update();
	tempIm->GetWholeExtent( imExtent);
	tempIm->GetSpacing( cViewSpace);
	tempIm->GetOrigin( cViewOrigin);	
	
	float *im = (float*) tempIm->GetScalarPointer();
	DCMPix*		mypix = [[DCMPix alloc] initwithdata:(float*) im :32 :imExtent[ 1]-imExtent[ 0]+1 :imExtent[ 3]-imExtent[ 2]+1 :cViewSpace[0] :cViewSpace[1] :cViewOrigin[0] :cViewOrigin[1] :cViewOrigin[2]];
	[mypix copySUVfrom: curPix];	
	
	[cViewPixList removeAllObjects];
	[cViewPixList addObject: mypix];
	[mypix release];
	
	if([[cViewROIList objectAtIndex: 0] count])
	{
		
		ROI* roi=[[cViewROIList objectAtIndex: 0] objectAtIndex:0];
		
		float crossX,crossY;
		crossX=-cViewOrigin[0]/cViewSpace[0];
		crossY=-cViewOrigin[1]/cViewSpace[1];
		if(crossX<0)
			crossX=0;
		else if(crossX<-(imExtent[ 1]-imExtent[ 0]))
			crossX=-(imExtent[ 1]-imExtent[ 0]);
		if(crossY<0)
			crossY=0;
		else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
			crossY=-(imExtent[ 3]-imExtent[ 2] );
		if([roi type]==tROI)
		{
			cPRROIRect.origin.x = crossX-cPRROIRect.size.width/2;
			cPRROIRect.origin.y = crossY;
			[roi setROIRect: cPRROIRect];
		}
		else if([roi type]==tArrow)
		{
			NSArray* points=[roi points];
			NSPoint start,end;
			start=[[points objectAtIndex: 1] point];
			end= [[points objectAtIndex: 0] point];
			float height=end.y-start.y;
			start.x=end.x=crossX;
			start.y=crossY;
			end.y = start.y+height;
			[[points objectAtIndex:1] setPoint: start];
			[[points objectAtIndex:0] setPoint: end];
			cViewArrowStartPoint=start;
			drawingArrawTool=YES;
			
		}
		else if([roi type]==tMesure)
		{
			isRemoveROIBySelf=1;
			[[cViewROIList objectAtIndex: 0] removeAllObjects];
			isRemoveROIBySelf=0;
		}
		
	}
	if([cViewCrossShowButton state]== NSOnState&&!drawingArrawTool)
	{
		float crossX,crossY;
		crossX=-cViewOrigin[0]/cViewSpace[0];
		crossY=cViewOrigin[1]/cViewSpace[1];
		if(crossX<0)
			crossX=0;
		else if(crossX>imExtent[ 1]-imExtent[ 0])
			crossX=imExtent[ 1]-imExtent[ 0];
		if(crossY>0)
			crossY=0;
		else if(crossY<-(imExtent[ 3]-imExtent[ 2] ))
			crossY=-(imExtent[ 3]-imExtent[ 2] );
		[cPRView setCrossCoordinates:crossX:crossY :YES];
	}
	else
	{
		[cPRView setCrossCoordinates:-9999 :-9999 :YES];
	}
	[cPRView setIndex: 0 ];
}
- (void) reCaculateCPRPath:(NSMutableArray*) roiList :(int) width :(int)height :(float)spaceX: (float)spaceY : (float)spaceZ :(float)originX :(float)originY:(float)originZ
{
	if(curvedMPR2DPath)
	{
	
		NSArray* points2D=[curvedMPR2DPath points];
		[roiList addObject: curvedMPR2DPath];
		unsigned int i;
		CMIV3DPoint* a3DPoint;
		float position[3];
		
		if([curvedMPR3DPath count]!=[curvedMPRProjectedPaths count])
		{
			[curvedMPRProjectedPaths removeAllObjects];
			for(i=0;i<[curvedMPR3DPath count];i++)
			{
				a3DPoint=[[CMIV3DPoint alloc] init];
				[curvedMPRProjectedPaths addObject: a3DPoint];
				[a3DPoint release];
			}
		}
		
		
		float x,y;
		NSPoint tempPoint;
		
		for(i=0;i<[curvedMPR3DPath count];i++)
		{
			a3DPoint=[curvedMPR3DPath objectAtIndex: i];
			position[0]=[a3DPoint x];
			position[1]=[a3DPoint y];
			position[2]=[a3DPoint z];
			inverseTransform->TransformPoint(position,position);
			x = (position[0]-originX)/spaceX;
			y = (position[1]-originY)/spaceY;

			tempPoint.x=x;
			tempPoint.y=y;
			[[points2D objectAtIndex:i] setPoint: tempPoint];
			a3DPoint=[curvedMPRProjectedPaths objectAtIndex: i];
			[a3DPoint setX: position[0]];
			[a3DPoint setY: position[1]];
			[a3DPoint setZ: position[2]];
			
		}
	}		
	//	referenceline
	if(referenceCurvedMPR2DPath)
	{
		NSArray* points2D=[referenceCurvedMPR2DPath points];
		[roiList addObject: referenceCurvedMPR2DPath];
		unsigned int i;
		CMIV3DPoint* a3DPoint;
		float position[3];
		
		float x,y;
		NSPoint tempPoint;
		
		for(i=0;i<[reference3Dpoints count];i++)
		{
			a3DPoint=[reference3Dpoints objectAtIndex: i];
			position[0]=[a3DPoint x];
			position[1]=[a3DPoint y];
			position[2]=[a3DPoint z];
			inverseTransform->TransformPoint(position,position);
			x = (position[0]-originX)/spaceX;
			y = (position[1]-originY)/spaceY;
			
			tempPoint.x=x;
			tempPoint.y=y;
			[[points2D objectAtIndex:i] setPoint: tempPoint];
			
		}
	}	
	

}
- (void) recaculateAxViewForStraightenedCPR
{
	double position[3],direction[3],position1[3],position2[3];
	int ptId,totalpoint;
	ptId=[axImageSlider floatValue]/cViewSpace[1];
	totalpoint=[curvedMPREven3DPath count];
	if(ptId>=totalpoint-1)
		ptId=totalpoint-2;
	CMIV3DPoint* a3DPoint;
	a3DPoint=[curvedMPREven3DPath objectAtIndex: ptId];
	position1[0]=[a3DPoint x];
	position1[1]=[a3DPoint y];
	position1[2]=[a3DPoint z];
	a3DPoint=[curvedMPREven3DPath objectAtIndex: ptId+1];
	position2[0]=[a3DPoint x];
	position2[1]=[a3DPoint y];
	position2[2]=[a3DPoint z];
	
	int i;
	float localoffset=([axImageSlider floatValue] - ptId*cViewSpace[1])/cViewSpace[1];
	for(i=0;i<3;i++)
	{
		
		position[i] = position1[i]+(position2[i]-position1[i])*localoffset;
		direction[i]=position2[i]-position1[i];
		
	}
	axViewTransformForStraightenCPR->Identity();
	axViewTransformForStraightenCPR->Translate(position);
	float anglex,angley;//anglez;
	if(direction[2]==0)
	{
		if(direction[1]>0)
			anglex=90;
		if(direction[1]<0)
			anglex=-90;
		if(direction[1]==0)
			anglex=0;
	}
	else
	{
		anglex = atan(direction[1]/direction[2]) / deg2rad;
		if(direction[2]<0)
			anglex+=180;
	}
	
	if(direction[0]>cViewSpace[1])
		direction[0]=cViewSpace[1];
	if(direction[0]<-cViewSpace[1])
		direction[0]=-cViewSpace[1];
	
	angley = asin(direction[0]/cViewSpace[1]) / deg2rad;
	axViewTransformForStraightenCPR->RotateX(-anglex);	
	axViewTransformForStraightenCPR->RotateY(angley);
	
	inverseTransform->TransformPoint(position,position);
	oViewUserTransform->Translate(position);
	[self updateOView];
	if(isNeedShowReferenceLine)
	{
		//draw reference line
		
		if(curvedMPRReferenceLineOfAxis)
		{
			
			NSArray* points=[curvedMPRReferenceLineOfAxis points];
			NSPoint start,end;
			start=[[points objectAtIndex: 1] point];
			end= [[points objectAtIndex: 0] point];
			start.y= end.y = [axImageSlider floatValue]/cViewSpace[1];
			[[points objectAtIndex:1] setPoint: start];
			[[points objectAtIndex:0] setPoint: end];
			if(![[cViewROIList objectAtIndex: 0] containsObject:curvedMPRReferenceLineOfAxis])
			{
				[[cViewROIList objectAtIndex: 0] addObject: curvedMPRReferenceLineOfAxis];
			}
			
			
		}
		
		[cPRView setIndex: 0 ];
		
	}	
	
}

- (void) recaculateAxViewForCPR
{
	NSArray* points2D=[curvedMPR2DPath points];
	int pointNum=[points2D count];
	if(pointNum<2)
		return;
	if([curvedMPR3DPath count]!=[curvedMPRProjectedPaths count])
		[self updateOView];
	float path2DLength=0;
	float steplength=0;
	float curLocation = [axImageSlider floatValue]/10;
	int i;
	for( i = 0; i < pointNum-1; i++ )
	{
		steplength = [curvedMPR2DPath Length:[[points2D objectAtIndex:i] point] :[[points2D objectAtIndex:i+1] point]];
		
		if(path2DLength+steplength >= curLocation)
		{
			NSPoint startPoint=[[points2D objectAtIndex: i] point];
			NSPoint tempPt=[[points2D objectAtIndex: i+1] point];
			float z1,z2;
			z1=[[curvedMPRProjectedPaths objectAtIndex: i] z];
			z2=[[curvedMPRProjectedPaths objectAtIndex: i+1] z];
			NSPoint curPoint;
			if(steplength!=0)
			{
				curPoint.x = (tempPt.x-startPoint.x)*(curLocation-path2DLength)/steplength+startPoint.x;
				curPoint.y = (tempPt.y-startPoint.y)*(curLocation-path2DLength)/steplength+startPoint.y;
				z1=(z2-z1)*(curLocation-path2DLength)/steplength+z1;
			}
			else
			{
				curPoint.x = startPoint.x;
				curPoint.y = startPoint.y;
				
			}
			float angle;
			
			tempPt.x-=startPoint.x;
			tempPt.y-=startPoint.y;
			tempPt.x*=oViewSpace[0];
			tempPt.y*=oViewSpace[1];
			
			if(tempPt.y == 0)
			{
				if(tempPt.x > 0)
					angle=90;
				else if(tempPt.x < 0)
					angle=-90;
				else 
					angle=0;
				
			}
			else
			{
				if( tempPt.y < 0)
					angle = 180 + atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
				else 
					angle = atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
			}
			
			
			curPoint.x = curPoint.x*oViewSpace[0]+oViewOrigin[0];
			curPoint.y = curPoint.y*oViewSpace[1]+oViewOrigin[1];				
			
			axViewTransform->Identity();	
			//		axViewTransform->Translate(curPoint.x,curPoint.y,0 );
			
			if(isNeedShowReferenceLine)
			{
				//draw reference line
				
				oViewUserTransform->Translate(curPoint.x,curPoint.y,z1);
				[self updateOView];
				
				if(curvedMPRReferenceLineOfAxis)
				{
					
					NSArray* points=[curvedMPRReferenceLineOfAxis points];
					NSPoint start,end;
					start=[[points objectAtIndex: 1] point];
					end= [[points objectAtIndex: 0] point];
					start.y= end.y = [axImageSlider floatValue]/cViewSpace[1];
					[[points objectAtIndex:1] setPoint: start];
					[[points objectAtIndex:0] setPoint: end];
					if(![[cViewROIList objectAtIndex: 0] containsObject:curvedMPRReferenceLineOfAxis])
					{
						[[cViewROIList objectAtIndex: 0] addObject: curvedMPRReferenceLineOfAxis];
					}
					
					
				}
				
				[cPRView setIndex: 0 ];
				
			}
			else
			{
				axViewTransform->Translate(curPoint.x,curPoint.y,z1 );
			}
			
			if(angle!=0)
				axViewTransform->RotateZ(-angle);
			axViewTransform->RotateX(90);	
			i=pointNum;
		}
		path2DLength += steplength;		
	}
	
	
	
}
- (IBAction)switchStraightenedCPR:(id)sender
{
	if(isStraightenedCPR)
	{
		isStraightenedCPR = NO;
		//[cPRView setTranlateSlider:nil];
		[straightenedCPRSwitchMenu setTitle:@"Straightened CPR"];
		//[cYRotateSlider setEnabled: NO];
		axViewSlice->SetResliceTransform( axViewTransform);
		if(fuzzyConectednessMap)
			axViewROISlice->SetResliceTransform( axViewTransform);
		[straightenedCPRButton setState:NSOffState];
		[self relocateAxViewSlider];
	}
	else
	{
		isStraightenedCPR = YES;
		
		[straightenedCPRSwitchMenu setTitle:@"Curved MPR"];
		//[cYRotateSlider setEnabled: YES];
		axViewSlice->SetResliceTransform( axViewTransformForStraightenCPR);
		if(fuzzyConectednessMap)
			axViewROISlice->SetResliceTransform( axViewTransformForStraightenCPR);

		[straightenedCPRButton setState:NSOnState];	
		[self relocateAxViewSlider];
		//[cPRView setTranlateSlider:cYRotateSlider];
		
		
	}
	axViewSlice->Update();
	[self updatePageSliders];
	[self updateCView];
	[self updateAxView];
	[self updatePageSliders];
}
- (void)relocateAxViewSlider
{
	if([curvedMPR3DPath count]!=[curvedMPRProjectedPaths count])
		[self updateOView];
	NSArray* points2D=[curvedMPR2DPath points];
	int pointNum = [points2D count];
	if(pointNum<2)
		return;
	
	if(isStraightenedCPR)
	{
		
		float path2DLength=0;
		float steplength=0;
		float curLocation = [axImageSlider floatValue]/10;
		int   curPoint=0;
		float substep=0;
		int i;
		for( i = 0; i < pointNum-1; i++ )
		{
			steplength = [curvedMPR2DPath Length:[[points2D objectAtIndex:i] point] :[[points2D objectAtIndex:i+1] point]];
			
			if(path2DLength+steplength >= curLocation)
				break;
			path2DLength+=steplength;
			
		}
		curPoint=i;
		substep=(curLocation-path2DLength)/steplength;
		float x1,y1,z1,x2,y2,z2;
		
		CMIV3DPoint* a3DPoint;
		a3DPoint=[curvedMPR3DPath objectAtIndex: 0];
		x1=[a3DPoint x];
		y1=[a3DPoint y];
		z1=[a3DPoint z];
		curLocation=0;
		for(i=1;i<=curPoint;i++)
		{
			a3DPoint=[curvedMPR3DPath objectAtIndex: i];
			x2=[a3DPoint x];
			y2=[a3DPoint y];
			z2=[a3DPoint z];
			steplength = sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1));
			curLocation += steplength;
			x1=x2;
			y1=y2;
			z1=z2;
		}
		
		a3DPoint=[curvedMPR3DPath objectAtIndex: i];
		x2=[a3DPoint x];
		y2=[a3DPoint y];
		z2=[a3DPoint z];
		steplength = sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1));
		curLocation += steplength*substep;
		[axImageSlider setFloatValue: curLocation];
	}
	else
	{
		float path3DLength=0;
		float steplength=0;
		float curLocation = [axImageSlider floatValue];
		int   curPoint=0;
		float substep=0;
		int i;
		float x1,y1,z1,x2,y2,z2;
		
		CMIV3DPoint* a3DPoint;
		a3DPoint=[curvedMPR3DPath objectAtIndex: 0];
		x1=[a3DPoint x];
		y1=[a3DPoint y];
		z1=[a3DPoint z];
		
		for(i=1;i<pointNum;i++)
		{
			a3DPoint=[curvedMPR3DPath objectAtIndex: i];
			x2=[a3DPoint x];
			y2=[a3DPoint y];
			z2=[a3DPoint z];
			steplength = sqrt((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1)+(z2-z1)*(z2-z1));
			if(path3DLength+steplength >= curLocation)
				break;
			
			path3DLength += steplength;
			x1=x2;
			y1=y2;
			z1=z2;
		}
		curPoint=i-1;
		substep=(curLocation-path3DLength)/steplength;
		
		curLocation=0;
		for( i = 0; i < curPoint; i++ )
		{
			steplength = [curvedMPR2DPath Length:[[points2D objectAtIndex:i] point] :[[points2D objectAtIndex:i+1] point]];
			curLocation+=steplength;
			
		}
		steplength = [curvedMPR2DPath Length:[[points2D objectAtIndex:i] point] :[[points2D objectAtIndex:i+1] point]];
		curLocation += steplength*substep;
		curLocation = curLocation * 10;
		[axImageSlider setFloatValue: curLocation];
	}
}

#pragma mark-
#pragma mark 2.3 MPR&CPR Export functions
/* - (void)mouseEntered:(NSEvent *)theEvent
{
	NSNumber* tagnum=(NSNumber*)[theEvent userData];
	if([tagnum intValue]==1&&exportViewIsClosed)
	{
		//NSRect exportviewrect;
		NSRect exportviewrect=[seedToolTipsTabView frame];
		NSPoint apoint;
		apoint.x=0;apoint.y=0;
		exportviewrect.origin=[[exportView superview] convertPoint:apoint fromView:[seedToolTipsTabView superview]];
		[exportView setFrame:exportviewrect];
		exportViewIsClosed=0;
		
	}
}
- (void)mouseExited:(NSEvent *)theEvent
{
	NSNumber* tagnum=(NSNumber*)[theEvent userData];
	if([tagnum intValue]==2&&!exportViewIsClosed)
	{
		
		NSRect exportviewrect=[exportView frame];
		exportviewrect.origin.y+=exportviewrect.size.height;
		[exportView setFrame:exportviewrect];
		exportViewIsClosed=1;
	}
	
}
 */
- (IBAction)batchExport:(id)sender
{
	if(currentViewMode==0)
	{
		[self showMPRExportDialog];
	}
	else if(currentViewMode==1)
	{
		[self showCPRImageDialog:sender];
	}
	else if(currentViewMode==2)
	{
		[self showCPRImageDialog:sender];
	}
}
- (IBAction)quicktimeExport:(id)sender
{
	
	//FSRef				fsref;
	//FSSpec				spec, newspec;
	//	[vrViewer renderImageWithBestQuality: YES waitDialog: NO];
	{
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForQuickTime: maxFrame:) :20];
		
		NSString* path;
		
		path=[mov createMovieQTKit:YES :NO :[[[originalViewController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];		
	}
	//	[vrViewer endRenderImageWithBestQuality];
	
	
}
-(NSImage*) imageForQuickTime:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	
	[oYRotateSlider setFloatValue:([cur intValue]*18-180)];
	[self rotateYOView:oYRotateSlider];
	NSImage* tempImage=[originalView nsimage];

	return tempImage;
}

- (IBAction)showCPRImageDialog:(id)sender
{
	if(cViewMPRorCPRMode)
	{
		[NSApp beginSheet: exportCPRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[self changAxViewCPRStep:exportAxViewCPRStepSlider];
	}
	else
		NSRunAlertPanel(NSLocalizedString(@"no CPR image", nil), NSLocalizedString(@"Please choose CPR tools again.", nil), NSLocalizedString(@"OK", nil), nil, nil);
	
	
}
- (IBAction)endCPRImageDialog:(id)sender
{
	int tag =[sender tag];
	[exportCPRWindow orderOut:sender];
    [NSApp endSheet:exportCPRWindow returnCode:tag];
	
	if(tag)
	{
		int pathindex,startindex,endindex;
		startindex=0;
		id waitWindow = [originalViewController startWaitWindow:@"processing"];	
		if(tag==6)
		{
			
			endindex=[cpr3DPaths count];
		}
		else
		{
			endindex=1;
		}
		for(pathindex=startindex;pathindex<endindex;pathindex++)
		{
			if(tag==6)
			{
				[centerlinesList selectRow:pathindex byExtendingSelection: YES];
				[self selectANewCenterline:centerlinesList];
				[self changAxViewCPRStep:exportAxViewCPRStepSlider];
			}
			
			ViewerController *new2DViewer;
			
			if([ifExportCrossSectionButton state]== NSOnState)
			{
				int imagenumber=[exportAxViewCPRAmountText intValue];
				if(imagenumber<=0)
					imagenumber=1;
				float step;
				
				step=([axImageSlider maxValue]-[axImageSlider minValue])/imagenumber;
				
				new2DViewer=[self exportCrossSectionImages:[axImageSlider minValue]:step:imagenumber];
				
				if(parent&&new2DViewer)
				{
					NSString* tempstr=[NSString stringWithString:@"Cross Section "];
					unsigned int row;
					row = [centerlinesList selectedRow];
					[new2DViewer checkEverythingLoaded];
					tempstr=[tempstr stringByAppendingString:[centerlinesNameArrays objectAtIndex: row]  ];
					[[new2DViewer window] setTitle:tempstr];
					
					NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey:@"VCList"];
					if(!temparray)
					{
						temparray=[NSMutableArray arrayWithCapacity:0];
						[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
					}
					[temparray addObject:new2DViewer];
					temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
					if(!temparray)
					{
						temparray=[NSMutableArray arrayWithCapacity:0];
						[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
					}
					[temparray addObject:tempstr];
				}
				
				
			}
			
			int imageNumber=[howManyImageToExport intValue] ;
			if(imageNumber>0)
			{
				NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
				NSMutableArray	*tempPixList = [NSMutableArray arrayWithCapacity: 0];
				NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
				
				float angleofstep,currentangle;
				DCMPix * temppix;
				int maxwidth=0,maxheight=0;
				
				
				if([howManyAngleToExport selectedColumn]==0)
					angleofstep=180/imageNumber;
				else
					angleofstep=360/imageNumber;
				int i;
				for( i = 0 ; i < imageNumber; i ++)
				{
					temppix=[cViewPixList objectAtIndex: 0];
					[tempPixList addObject:temppix];
					if(maxwidth<[temppix pwidth])
						maxwidth=[temppix pwidth];
					if(maxheight<[temppix pheight ])
						maxheight=[temppix pheight];
					
					
					if(isStraightenedCPR)
					{
						currentangle=[cYRotateSlider floatValue];
						currentangle+=angleofstep;
						if(currentangle>180)
							currentangle-=360;
						[cYRotateSlider setFloatValue: currentangle ];
						lastCViewYAngle=currentangle;
						[self updateCView];
					}
					else
					{
						currentangle=[oYRotateSlider floatValue];
						currentangle+=angleofstep;
						if(currentangle>180)
							currentangle-=360;
						[oYRotateSlider setFloatValue: currentangle ];
						[self rotateYOView:oYRotateSlider];
					}
					
				}
				float* newVolumeData=nil;
				long size= sizeof(float)*maxwidth*maxheight*imageNumber;
				newVolumeData=(float*) malloc(size);
				if(!newVolumeData)
				{
					NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
					[tempPixList removeAllObjects];
					[originalViewController endWaitWindow: waitWindow];
					return;
				}
				for( i = 0 ; i < imageNumber; i ++)
				{
					//copy data
					int width,height;
					int x,y;
					int offsetx;
					float* tempfloat;
					temppix=[tempPixList objectAtIndex: i];
					
					
					width = [temppix pwidth];
					height = [temppix pheight];
					tempfloat = [temppix fImage];
					offsetx = (maxwidth-width)/2;
					for(y=0;y<maxheight;y++)
						for(x=0;x<maxwidth;x++)
						{
							if(x>=offsetx&&x<(width+offsetx)&&y>=0&&y<height)
								*(newVolumeData+i*maxwidth*maxheight+y*maxwidth+x)=*(tempfloat+y*width+x-offsetx);
							else
								*(newVolumeData+i*maxwidth*maxheight+y*maxwidth+x) = minValueInSeries;
						}
					DCMPix	*newPix = [[DCMPix alloc] initwithdata:(float*) (newVolumeData + i*maxwidth*maxheight ):32 :maxwidth :maxheight :cViewSpace[0] :cViewSpace[1] :cViewOrigin[0] :cViewOrigin[1] :cViewOrigin[2]:YES];
					[newPixList addObject: newPix];
					[newPix release];
					[newDcmList addObject: [[originalViewController fileList] objectAtIndex: 0]];
				}
				
				NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
				
				new2DViewer = [originalViewController newWindow	:newPixList
							   :newDcmList
							   :newData]; 
				[tempPixList removeAllObjects];
				
				if(parent)
				{
					NSString* tempstr=[NSString stringWithString:@"CPR of "];
					unsigned int row;
					row = [centerlinesList selectedRow];
					[new2DViewer checkEverythingLoaded];
					tempstr=[tempstr stringByAppendingString:[centerlinesNameArrays objectAtIndex: row]  ];
					[[new2DViewer window] setTitle:tempstr];
					
					NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey:@"VCList"];
					if(!temparray)
					{
						temparray=[NSMutableArray arrayWithCapacity:0];
						[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
					}
					[temparray addObject:new2DViewer];
					temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
					if(!temparray)
					{
						temparray=[NSMutableArray arrayWithCapacity:0];
						[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
					}
					[temparray addObject:tempstr];
				}
			}
			
			
		}
		
		[originalViewController endWaitWindow: waitWindow];
		if([autoSaveButton state]==NSOnState)
			[parent notifyExportFinished];
		
		
	}
	
	//[[self window] setFrame:screenrect display:YES ];
	[[self window] makeKeyAndOrderFront:parent];
	
}

- (IBAction)exportOrthogonalDataset:(id)sender
{
	
	int tag=[sender tag];
	[exportMPRWindow orderOut:sender];
    [NSApp endSheet:exportMPRWindow returnCode:tag];
	if(tag)
	{
		
		id waitWindow = [originalViewController startWaitWindow:@"processing"];
		ViewerController * newviewer;
		float start;
		
		start=[exportAxViewFromText floatValue];
		if(start>[exportAxViewToText floatValue])
			start=[exportAxViewToText floatValue];	
		newviewer=[self exportCrossSectionImages:start:[exportStepText floatValue]:[exportAxViewAmountText intValue]];
		
		start=[exportCViewFromText floatValue];
		if(start>[exportCViewToText floatValue])
			start=[exportCViewToText floatValue];	
		if(newviewer)
			newviewer=[self exportCViewImages:start:[exportStepText floatValue]:[exportCViewAmountText intValue]];
		
		start=[exportOViewFromText floatValue];
		if(start>[exportOViewToText floatValue])
			start=[exportOViewToText floatValue];		
		
		if(newviewer)
			newviewer=[self exportOViewImages:start:[exportStepText floatValue]:[exportOViewAmountText intValue]];
		
		[originalViewController endWaitWindow: waitWindow];	
	}	
}

- (ViewerController *) exportCrossSectionImages:(float)start:(float)step:(int)slicenumber
{
	

	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*tempRoiList = [NSMutableArray arrayWithCapacity: 0];
	
	int i;
	// cross section view Images
	int imageNumber=slicenumber;
	float distanceofstep,currentdistance,startfromdistance;
	int maxwidth=0,maxheight=0;
	startfromdistance=start;
	currentdistance = [axImageSlider floatValue];
	distanceofstep = step;
	NSRect viewsize = [crossAxiasView frame];
	maxwidth=viewsize.size.width/[crossAxiasView scaleValue];
	maxheight=viewsize.size.height/[crossAxiasView scaleValue];
	float* newVolumeData=nil;
	long size= sizeof(float)*maxwidth*maxheight*imageNumber;
	newVolumeData=(float*) malloc(size);
	if(!newVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return nil;
	}
	
	
	for( i = 0 ; i < imageNumber; i ++)
	{
		[axImageSlider setFloatValue:(startfromdistance+i*distanceofstep)];
		[self pageAxView:axImageSlider];
		DCMPix* newPix=nil;
		NSMutableArray	*imgRoiList=[NSMutableArray arrayWithCapacity: 0];
		newPix=[self getCurPixFromAxView:(newVolumeData+i*maxwidth*maxheight):maxwidth:maxheight:imgRoiList];
		

		if(newPix)
		{
			[newPix setTot:imageNumber ];
			[newPix setFrameNo: 0];
			[newPix setID: i];
			[newPix setSliceLocation:startfromdistance+i*distanceofstep];
			[newPix setSliceThickness: 0];
			[newPix setSliceInterval: distanceofstep];
			[newPixList addObject: newPix];
			[newPix release];
		}
		else
		{
			NSLog(@"error when try to capture AxView");
		}
		
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: 0]];
		[tempRoiList addObject:imgRoiList];
	}
	[axImageSlider setFloatValue:currentdistance];
	[self pageAxView:axImageSlider];	
	
	
	
	NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
				   :newDcmList
				   :newData]; 
	NSMutableArray      *roiList= [new2DViewer roiList];
	unsigned j;
	for(i=0;i<imageNumber;i++)
	{
		for(j=0;j<[[tempRoiList objectAtIndex:i] count];j++)
			[[roiList objectAtIndex:i] addObject:[[tempRoiList objectAtIndex:i] objectAtIndex:j]]; 
		[[tempRoiList objectAtIndex:i] removeAllObjects];
	}
	
	[tempRoiList removeAllObjects];
	[[self window] makeKeyAndOrderFront:parent];
	return new2DViewer;
}
- (ViewerController *) exportCViewImages:(float)start:(float)step:(int)slicenumber
{
	

	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*tempRoiList = [NSMutableArray arrayWithCapacity: 0];
	int i;
	
	// cross section view Images
	int imageNumber=slicenumber;
	float distanceofstep,currentdistance,startfromdistance;
	int maxwidth=0,maxheight=0;
	startfromdistance=start;
	currentdistance = [cImageSlider floatValue];
	distanceofstep = step;
	
	
	NSRect viewsize = [cPRView frame];
	maxwidth=viewsize.size.width/[cPRView scaleValue];
	maxheight=viewsize.size.height/[cPRView scaleValue];
	
	float* newVolumeData=nil;
	long size= sizeof(float)*maxwidth*maxheight*imageNumber;
	newVolumeData=(float*) malloc(size);
	if(!newVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return nil;
	}
	
	
	for( i = 0 ; i < imageNumber; i ++)
	{
		[cImageSlider setFloatValue:(startfromdistance+i*distanceofstep)];
		[self onlyPageCView:cImageSlider];
		
		DCMPix* newPix=nil;
		NSMutableArray	*imgRoiList=[NSMutableArray arrayWithCapacity: 0];
		newPix=[self getCurPixFromCView:(newVolumeData+i*maxwidth*maxheight):maxwidth:maxheight:imgRoiList];
		
		
		if(newPix)
		{
			[newPix setTot:imageNumber ];
			[newPix setFrameNo: 0];
			[newPix setID: i];
			[newPix setSliceLocation:startfromdistance+i*distanceofstep];
			[newPix setSliceThickness: 0];
			[newPix setSliceInterval: distanceofstep];
			[newPixList addObject: newPix];
			[newPix release];
		}
		else
		{
			NSLog(@"error when try to capture AxView");
		}
		
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: 0]];
		[tempRoiList addObject:imgRoiList];
		
		
	}
	[cImageSlider setFloatValue:currentdistance];
	[self onlyPageCView:cImageSlider];	
	
	
	
	NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
				   :newDcmList
				   :newData]; 
	NSMutableArray      *roiList= [new2DViewer roiList];
	unsigned j;
	for(i=0;i<imageNumber;i++)
	{
		for(j=0;j<[[tempRoiList objectAtIndex:i] count];j++)
			[[roiList objectAtIndex:i] addObject:[[tempRoiList objectAtIndex:i] objectAtIndex:j]]; 
		[[tempRoiList objectAtIndex:i] removeAllObjects];
	}
	
	[tempRoiList removeAllObjects];
	[[self window] makeKeyAndOrderFront:parent];
	return new2DViewer;
}
- (ViewerController *) exportOViewImages:(float)start:(float)step:(int)slicenumber
{

	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*tempRoiList = [NSMutableArray arrayWithCapacity: 0];
	
	int i;
	
	// cross section view Images
	
	
	
	
	int imageNumber=slicenumber;
	float distanceofstep,currentdistance,startfromdistance;
	int maxwidth=0,maxheight=0;
	startfromdistance=start;
	currentdistance = [oImageSlider floatValue];
	distanceofstep = step;
	NSRect viewsize = [originalView frame];
	maxwidth=viewsize.size.width/[originalView scaleValue];
	maxheight=viewsize.size.height/[originalView scaleValue];
	
	float* newVolumeData=nil;
	long size= sizeof(float)*maxwidth*maxheight*imageNumber;
	newVolumeData=(float*) malloc(size);
	if(!newVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return nil;
	}
	
	
	for( i = 0 ; i < imageNumber; i ++)
	{
		[oImageSlider setFloatValue:(startfromdistance+i*distanceofstep)];
		[self pageOView:oImageSlider];
		
		DCMPix* newPix=nil;
		NSMutableArray	*imgRoiList=[NSMutableArray arrayWithCapacity: 0];
		newPix=[self getCurPixFromOView:(newVolumeData+i*maxwidth*maxheight):maxwidth:maxheight:imgRoiList];
		
		
		if(newPix)
		{
			[newPix setTot:imageNumber ];
			[newPix setFrameNo: 0];
			[newPix setID: i];
			[newPix setSliceLocation:startfromdistance+i*distanceofstep];
			[newPix setSliceThickness: 0];
			[newPix setSliceInterval: distanceofstep];
			[newPixList addObject: newPix];
			[newPix release];
		}
		else
		{
			NSLog(@"error when try to capture AxView");
		}		
		
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: 0]];
		[tempRoiList addObject:imgRoiList];
		
		
	}
	[oImageSlider setFloatValue:currentdistance];
	[self pageOView:oImageSlider];	
	
	
	
	NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
				   :newDcmList
				   :newData]; 
	NSMutableArray      *roiList= [new2DViewer roiList];
	unsigned j;
	for(i=0;i<imageNumber;i++)
	{
		for(j=0;j<[[tempRoiList objectAtIndex:i] count];j++)
			[[roiList objectAtIndex:i] addObject:[[tempRoiList objectAtIndex:i] objectAtIndex:j]]; 
		[[tempRoiList objectAtIndex:i] removeAllObjects];
	}
	
	[tempRoiList removeAllObjects];
	[[self window] makeKeyAndOrderFront:parent];
	return new2DViewer;
}

- (void)showMPRExportDialog
{
	
    [exportOViewFromSlider setMaxValue:[oImageSlider maxValue]];
	[exportOViewFromSlider setMinValue:[oImageSlider minValue]];
	[exportOViewFromSlider setFloatValue:[oImageSlider floatValue]];
	
	[exportOViewToSlider setMaxValue:[oImageSlider maxValue]];
	[exportOViewToSlider setMinValue:[oImageSlider minValue]];
	[exportOViewToSlider setFloatValue:[oImageSlider floatValue]];
	
	[exportCViewFromSlider setMaxValue:[cImageSlider maxValue]];
	[exportCViewFromSlider setMinValue:[cImageSlider minValue]];
	[exportCViewFromSlider setFloatValue:[cImageSlider floatValue]];
	
	[exportCViewToSlider setMaxValue:[cImageSlider maxValue]];
	[exportCViewToSlider setMinValue:[cImageSlider minValue]];
	[exportCViewToSlider setFloatValue:[cImageSlider floatValue]];
	
	[exportAxViewFromSlider setMaxValue:[axImageSlider maxValue]];
	[exportAxViewFromSlider setMinValue:[axImageSlider minValue]];
	[exportAxViewFromSlider setFloatValue:[axImageSlider floatValue]];
	
	[exportAxViewToSlider setMaxValue:[axImageSlider maxValue]];
	[exportAxViewToSlider setMinValue:[axImageSlider minValue]];
	[exportAxViewToSlider setFloatValue:[axImageSlider floatValue]];
	
	[exportSpacingXText setFloatValue:xSpacing];
	[exportSpacingYText setFloatValue:ySpacing];	
	[exportStepText setFloatValue:2*minSpacing*[exportStepSlider floatValue]];
	
	[exportOViewFromText setFloatValue:[exportOViewFromSlider floatValue]];
	[exportOViewToText setFloatValue:[exportOViewToSlider floatValue]];
	[exportOViewAmountText setIntValue:1];	
	[exportCViewFromText setFloatValue:[exportCViewFromSlider floatValue]];
	[exportCViewToText setFloatValue:[exportCViewToSlider floatValue]];
	[exportCViewAmountText setIntValue:1];
	[exportAxViewFromText setFloatValue:[exportAxViewFromSlider floatValue]];
	[exportAxViewToText setFloatValue:[exportAxViewToSlider floatValue]];
	[exportAxViewAmountText setIntValue:1];
	if(currentViewMode==0)
		[NSApp beginSheet: exportMPRWindow modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	else
		NSRunAlertPanel(NSLocalizedString(@"Can not export MPR image", nil), NSLocalizedString(@"Please Exit CPR Mode.", nil), NSLocalizedString(@"OK", nil), nil, nil);
}
- (IBAction)setExportDialogFromToSlider:(id)sender
{
	
	[exportOViewFromText setFloatValue:[exportOViewFromSlider floatValue]];
	[exportOViewToText setFloatValue:[exportOViewToSlider floatValue]];
	[exportOViewAmountText setIntValue:(int)(fabs([exportOViewFromText floatValue]-[exportOViewToText floatValue])/[exportStepText floatValue]+1)];	
	[exportCViewFromText setFloatValue:[exportCViewFromSlider floatValue]];
	[exportCViewToText setFloatValue:[exportCViewToSlider floatValue]];
	[exportCViewAmountText setIntValue:(int)(fabs([exportCViewFromText floatValue]-[exportCViewToText floatValue])/[exportStepText floatValue]+1)];
	[exportAxViewFromText setFloatValue:[exportAxViewFromSlider floatValue]];
	[exportAxViewToText setFloatValue:[exportAxViewToSlider floatValue]];
	[exportAxViewAmountText setIntValue:(int)(fabs([exportAxViewFromText floatValue]-[exportAxViewToText floatValue])/[exportStepText floatValue]+1)];
	
}
- (IBAction)setExportDialogStepSlider:(id)sender
{
	
	[exportStepText setFloatValue:2*minSpacing*[exportStepSlider floatValue]];
	[self setExportDialogFromToSlider:sender];
}
- (IBAction)setExportDialogFromToButton:(id)sender
{
	int tag=[sender tag];
	switch(tag)
	{
		case 1:
			
			[exportOViewFromSlider setFloatValue:[oImageSlider floatValue]];
			
			[exportOViewToSlider setFloatValue:[oImageSlider floatValue]];
			
			break;
		case 2:
			
			[exportOViewFromSlider setFloatValue:[exportOViewFromSlider minValue]];
			
			[exportOViewToSlider setFloatValue:[exportOViewToSlider maxValue]];
			
			break;
		case 3:
			
			[exportCViewFromSlider setFloatValue:[cImageSlider floatValue]];
			
			[exportCViewToSlider setFloatValue:[cImageSlider floatValue]];
			
			break;
		case 4:
			[exportCViewFromSlider setFloatValue:[exportCViewFromSlider minValue]];
			
			[exportCViewToSlider setFloatValue:[exportCViewToSlider maxValue]];
			
			break;
		case 5:
			
			[exportAxViewFromSlider setFloatValue:[axImageSlider floatValue]];
			
			[exportAxViewToSlider setFloatValue:[axImageSlider floatValue]];
			
			break;
		case 6:
			
			[exportAxViewFromSlider setFloatValue:[exportAxViewFromSlider minValue]];
			
			[exportAxViewToSlider setFloatValue:[exportAxViewToSlider maxValue]];
			
			break;
	}
	[self setExportDialogFromToSlider:sender];
	
	
}
- (IBAction)whyNoThickness:(id)sender
{
	NSRunAlertPanel(NSLocalizedString(@"Thickness", nil), NSLocalizedString(@"The reslice algorithm is trying to resample the volume with a plane which has no thickness. However you can choose the interval between slices by giving a step length.", nil), NSLocalizedString(@"OK", nil), nil, nil);
}
- (IBAction)changAxViewCPRStep:(id)sender
{
	[exportAxViewCPRStepText setFloatValue:[sender floatValue]];
	[exportAxViewCPRAmountText setIntValue:([axImageSlider maxValue]-[axImageSlider minValue])/[exportAxViewCPRStepText floatValue]];
	
}
- (IBAction)exportSingleImageToBasket:(id)sender
{
	int tag=[sender tag];
	DCMPix	*newPix=nil;
	NSImage* newCellICONForBasket=nil;
	NSMutableArray	*imgRoiList=[NSMutableArray arrayWithCapacity: 0];
	float* imgdata;
	int imgwidth,imgheight;
	NSRect viewsize;
	
	switch(tag)
	{
		case 1:
			viewsize = [originalView frame];
			imgwidth=viewsize.size.width/[originalView scaleValue];
			imgheight=viewsize.size.height/[originalView scaleValue];
			imgdata=(float*)malloc(imgwidth*imgheight*sizeof(float));
			if(imgdata)
			{
				newPix=[self getCurPixFromOView:imgdata:imgwidth:imgheight:imgRoiList];
				newCellICONForBasket=[originalView nsimage];
			}
			
			break;
		case 2:
			viewsize = [cPRView frame];
			imgwidth=viewsize.size.width/[cPRView scaleValue];
			imgheight=viewsize.size.height/[cPRView scaleValue];
			imgdata=(float*)malloc(imgwidth*imgheight*sizeof(float));
			if(imgdata)
			{
				newPix=[self getCurPixFromCView:imgdata:imgwidth:imgheight:imgRoiList];
				newCellICONForBasket=[cPRView nsimage];
			}			
			break;
		case 3:
			viewsize = [crossAxiasView frame];
			imgwidth=viewsize.size.width/[crossAxiasView scaleValue];
			imgheight=viewsize.size.height/[crossAxiasView scaleValue];
			imgdata=(float*)malloc(imgwidth*imgheight*sizeof(float));
			if(imgdata)
			{
				newPix=[self getCurPixFromAxView:imgdata:imgwidth:imgheight:imgRoiList];
				newCellICONForBasket=[crossAxiasView nsimage];
			}			
			break;
	}
	if(newPix)
	{
		
		[basketScrollView setPostsBoundsChangedNotifications:YES];
		[basketImageArray addObject:newPix];
		[basketImageROIArray addObject:imgRoiList];
		if([basketMatrix numberOfColumns]<(signed)[basketImageArray count])
			[basketMatrix addColumn];
		[basketMatrix sizeToCells];
		
		NSButtonCell *cell = [basketMatrix cellAtRow: 0 column:[basketMatrix numberOfColumns]-1];
		[cell setRepresentedObject: newPix];
		[cell setImage:newCellICONForBasket];
		[cell setEnabled:YES];
		
		NSPoint origin=NSMakePoint(NSMaxX([[basketScrollView documentView] frame])
						   -NSWidth([[basketScrollView contentView] bounds]),0.0);
		[[basketScrollView documentView] scrollPoint:origin];	
		
	}
	
}
- (DCMPix*)getCurPixFromOView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs
{
	NSPoint point[4];
	NSArray				*pixList = [originalViewController pixList];
	DCMPix	*firstPix=[pixList objectAtIndex: 0];
	DCMPix  *temppix;
	float vector[ 9], origin[3];
	
	//double doublevector[3];

	//copy data
	int x,y;
	int offsetx,offsety;
	int minx,miny,maxx,maxy;
	int width,height;
	float* tempfloat;
	temppix=[oViewPixList objectAtIndex: 0];
	
	
	width = [temppix pwidth];
	height = [temppix pheight];
	tempfloat = [temppix fImage];
	NSRect viewsize = [originalView frame];
	point[0].x=0;
	point[1].x=viewsize.size.width;
	point[2].x=0;
	point[3].x=viewsize.size.width;
	
	point[0].y=0;
	point[1].y=0;
	point[2].y=viewsize.size.height;
	point[3].y=viewsize.size.height;
	
	point[0]=[originalView ConvertFromUpLeftView2GL:point[0]];
	point[1]=[originalView ConvertFromUpLeftView2GL:point[1]];
	point[2]=[originalView ConvertFromUpLeftView2GL:point[2]];
	point[3]=[originalView ConvertFromUpLeftView2GL:point[3]];
	
	minx=maxx=point[0].x;
	miny=maxy=point[0].y;
	unsigned j;
	for(j=1;j<4;j++)
	{
		if(point[j].x<minx)
			minx=point[j].x;
		if(point[j].y<miny)
			miny=point[j].y;
		if(point[j].x>maxx)
			maxx=point[j].x;
		if(point[j].y>maxy)
			maxy=point[j].y;
		
	}
	
	offsetx=minx;
	offsety=miny;
	if(minx<0)
		minx=0;
	if(miny<0)
		miny=0;
	if(maxx>width)
		maxx=width;
	if(maxy>height)
		maxy=height;
	
	for(y=0;y<imgheight;y++)
		for(x=0;x<imgwidth;x++)
		{
			if(x+offsetx>=minx&&x+offsetx<maxx&&y+offsety>=miny&&y+offsety<maxy)
				*(imgdata+y*imgwidth+x)=*(tempfloat+(y+offsety)*width+x+offsetx);
			else
				*(imgdata+y*imgwidth+x) = minValueInSeries;
		}
	
	//calculate orietion
	float inversedvector[9];
	float unitvector[3];
	float originpat[3],unitvectorpat[3];
	[firstPix orientation:vector];
	[self inverseMatrix:vector:inversedvector];
	origin[0]=0;
	origin[1]=0;
	origin[2]=0;
	oViewUserTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];
	
	
	unitvector[0]=1;
	unitvector[1]=0;
	unitvector[2]=0;
	oViewUserTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[0]=unitvectorpat[0]-originpat[0];
	vector[1]=unitvectorpat[1]-originpat[1];
	vector[2]=unitvectorpat[2]-originpat[2];
	
	
	unitvector[0]=0;
	unitvector[1]=1;
	unitvector[2]=0;
	oViewUserTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[3]=unitvectorpat[0]-originpat[0];
	vector[4]=unitvectorpat[1]-originpat[1];
	vector[5]=unitvectorpat[2]-originpat[2];
	
	unitvector[0]=0;
	unitvector[1]=0;
	unitvector[2]=1;
	oViewUserTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[6]=unitvectorpat[0]-originpat[0];
	vector[7]=unitvectorpat[1]-originpat[1];
	vector[8]=unitvectorpat[2]-originpat[2];
	
	
	origin[0]=oViewOrigin[0]+offsetx*oViewSpace[0];
	origin[1]=oViewOrigin[1]+offsety*oViewSpace[1];
	origin[2]=oViewOrigin[2];
	oViewUserTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];	
	origin[0]=originpat[0];
	origin[1]=originpat[1];
	origin[2]=originpat[2];
	
	
	
		
	
	
	DCMPix	*newPix = [firstPix copy];
	[newPix setPwidth: imgwidth];
	//[newPix setRowBytes: imgwidth];
	[newPix setPheight: imgheight];
	
	[newPix setfImage:imgdata];
	[newPix setTot:1 ];
	[newPix setFrameNo: 0];
	[newPix setID: 0];
	[newPix setPixelSpacingX: oViewSpace[0]];
	[newPix setPixelSpacingY: oViewSpace[1]];
	[newPix setOrigin:origin];
	[newPix setOrientation: vector];
	[newPix setSliceLocation:0];
	[newPix setPixelRatio:  oViewSpace[1] / oViewSpace[0]];
	[newPix setSliceThickness: 0];
	[newPix setSliceInterval: 0];
	
	
	//////////////////
	//creat new rois using the new origin
		
	if(cViewMPRorCPRMode&&[oViewCrossShowButton state]== NSOnState)
	{
		NSRect roiRect;
		roiRect.origin.x=-oViewOrigin[0]/oViewSpace[0]-offsetx;
		roiRect.origin.y=-oViewOrigin[1]/oViewSpace[1]-offsety;
		roiRect.size.width=roiRect.size.height=15;
		ROI *aCircleROI = [[ROI alloc] initWithType: tOval :oViewSpace[0] :oViewSpace[1] : NSMakePoint( origin[0],origin[1])];
		[aCircleROI setName:[axImageSlider stringValue]];
		[aCircleROI setComments:@"reference center"];
		[aCircleROI setROIRect:roiRect];
		[imgROIs addObject:aCircleROI];
	}
	for(j=0;j<[[oViewROIList objectAtIndex: 0] count];j++)
	{
		ROI *temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: j];
		
		if([temproi type] == tMesure && [temproi valid])
		{
			ROI* anewroi=[[ROI alloc] initWithType: tMesure :oViewSpace[0]  :oViewSpace[1] : NSMakePoint( origin[0],  origin[1])];
			
			NSArray* oldPoints=[temproi points];
			unsigned int k;
			NSPoint tempPt;
			for(k=0;k<[oldPoints count];k++)
			{
				tempPt=[[oldPoints objectAtIndex: k] point];
				tempPt.x-=offsetx;
				tempPt.y-=offsety;
				
				MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:tempPt];
				[[anewroi points] addObject: lastPoint];
				[lastPoint release];
				
			}
			[anewroi setName:[temproi name]];
			[imgROIs addObject:anewroi];
					
		}
		
	}
	
	
	return newPix;
}
- (DCMPix*)getCurPixFromCView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs
{
	NSPoint point[4];
	NSArray				*pixList = [originalViewController pixList];
	DCMPix	*firstPix=[pixList objectAtIndex: 0];
	DCMPix  *temppix;
	float vector[ 9], origin[3];
	//double doublevector[3];
	
	//copy data
	int x,y;
	int offsetx,offsety;
	int minx,miny,maxx,maxy;
	int width,height;
	float* tempfloat;
	temppix=[cViewPixList objectAtIndex: 0];
	
	
	width = [temppix pwidth];
	height = [temppix pheight];
	tempfloat = [temppix fImage];
	NSRect viewsize = [cPRView frame];
	point[0].x=0;
	point[1].x=viewsize.size.width;
	point[2].x=0;
	point[3].x=viewsize.size.width;
	
	point[0].y=0;
	point[1].y=0;
	point[2].y=viewsize.size.height;
	point[3].y=viewsize.size.height;
	
	point[0]=[cPRView ConvertFromUpLeftView2GL:point[0]];//ConvertFromUpLeftView2GL for 3.1
	point[1]=[cPRView ConvertFromUpLeftView2GL:point[1]];//ConvertFromUpLeftView2GL for 3.1
	point[2]=[cPRView ConvertFromUpLeftView2GL:point[2]];//ConvertFromUpLeftView2GL for 3.1
	point[3]=[cPRView ConvertFromUpLeftView2GL:point[3]];//ConvertFromUpLeftView2GL for 3.1
	
	minx=maxx=point[0].x;
	miny=maxy=point[0].y;
	unsigned j;
	for(j=1;j<4;j++)
	{
		if(point[j].x<minx)
			minx=point[j].x;
		if(point[j].y<miny)
			miny=point[j].y;
		if(point[j].x>maxx)
			maxx=point[j].x;
		if(point[j].y>maxy)
			maxy=point[j].y;
		
	}
	
	offsetx=minx;
	offsety=miny;
	if(minx<0)
		minx=0;
	if(miny<0)
		miny=0;
	if(maxx>width)
		maxx=width;
	if(maxy>height)
		maxy=height;
	
	for(y=0;y<imgheight;y++)
		for(x=0;x<imgwidth;x++)
		{
			if(x+offsetx>=minx&&x+offsetx<maxx&&y+offsety>=miny&&y+offsety<maxy)
				*(imgdata+y*imgwidth+x)=*(tempfloat+(y+offsety)*width+x+offsetx);
			else
				*(imgdata+y*imgwidth+x) = minValueInSeries;
		}
	
	//calculate orietion
	float inversedvector[9];
	float unitvector[3];
	float originpat[3],unitvectorpat[3];
	[firstPix orientation:vector];
	[self inverseMatrix:vector:inversedvector];
	origin[0]=0;
	origin[1]=0;
	origin[2]=0;
	cViewTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];
	
	
	unitvector[0]=1;
	unitvector[1]=0;
	unitvector[2]=0;
	cViewTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[0]=unitvectorpat[0]-originpat[0];
	vector[1]=unitvectorpat[1]-originpat[1];
	vector[2]=unitvectorpat[2]-originpat[2];
	
	
	unitvector[0]=0;
	unitvector[1]=1;
	unitvector[2]=0;
	cViewTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[3]=unitvectorpat[0]-originpat[0];
	vector[4]=unitvectorpat[1]-originpat[1];
	vector[5]=unitvectorpat[2]-originpat[2];
	
	unitvector[0]=0;
	unitvector[1]=0;
	unitvector[2]=1;
	cViewTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[6]=unitvectorpat[0]-originpat[0];
	vector[7]=unitvectorpat[1]-originpat[1];
	vector[8]=unitvectorpat[2]-originpat[2];
	
	
	origin[0]=cViewOrigin[0]+offsetx*cViewSpace[0];
	origin[1]=cViewOrigin[1]+offsety*cViewSpace[1];
	origin[2]=cViewOrigin[2];
	cViewTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];	
	origin[0]=originpat[0];
	origin[1]=originpat[1];
	origin[2]=originpat[2];
	/* origin[0]=0;
	origin[1]=0;
	origin[2]=0;
	cViewTransform->TransformPoint(origin,origin);


	[firstPix orientation:vector];

	doublevector[0]=vector[0];
	doublevector[1]=vector[1];
	doublevector[2]=vector[2];
	cViewTransform->TransformPoint(doublevector,doublevector);
	vector[0]=doublevector[0]-origin[0];
	vector[1]=doublevector[1]-origin[1];
	vector[2]=doublevector[2]-origin[2];

	doublevector[0]=vector[3];
	doublevector[1]=vector[4];
	doublevector[2]=vector[5];
	cViewTransform->TransformPoint(doublevector,doublevector);
	vector[3]=doublevector[0]-origin[0];
	vector[4]=doublevector[1]-origin[1];
	vector[5]=doublevector[2]-origin[2];

	doublevector[0]=vector[6];
	doublevector[1]=vector[7];
	doublevector[2]=vector[8];
	cViewTransform->TransformPoint(doublevector,doublevector);
	vector[6]=doublevector[0]-origin[0];
	vector[7]=doublevector[1]-origin[1];
	vector[8]=doublevector[2]-origin[2];


	origin[0]=cViewOrigin[0]+offsetx*cViewSpace[0];
	origin[1]=cViewOrigin[1]+offsety*cViewSpace[1];
	origin[2]=cViewOrigin[2];
	cViewTransform->TransformPoint(origin,origin);
	 */	
	
	
	
	DCMPix	*newPix = [firstPix copy];
	[newPix setPwidth: imgwidth];
	//[newPix setRowBytes: imgwidth];
	[newPix setPheight: imgheight];
	
	[newPix setfImage:imgdata];
	[newPix setTot:1 ];
	[newPix setFrameNo: 0];
	[newPix setID: 0];
	[newPix setPixelSpacingX: cViewSpace[0]];
	[newPix setPixelSpacingY: cViewSpace[1]];
	[newPix setOrigin:origin];
	[newPix setOrientation: vector];
	[newPix setSliceLocation:0];
	[newPix setPixelRatio:  cViewSpace[1] / cViewSpace[0]];
	[newPix setSliceThickness: 0];
	[newPix setSliceInterval: 0];
	
	for(j=0;j<[[cViewROIList objectAtIndex: 0] count];j++)
	{
		ROI *temproi=[[cViewROIList objectAtIndex: 0] objectAtIndex: j];
		
		if(([temproi type] == tMesure||[temproi type] == tCPolygon) && [temproi valid])
		{
			ROI* anewroi=[[ROI alloc] initWithType: tMesure :cViewSpace[0]  :cViewSpace[1] : NSMakePoint( origin[0],  origin[1])];
			
			NSArray* oldPoints=[temproi points];
			unsigned int k;
			NSPoint tempPt;
			for(k=0;k<[oldPoints count];k++)
			{
				tempPt=[[oldPoints objectAtIndex: k] point];
				tempPt.x-=offsetx;
				tempPt.y-=offsety;
				
				MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:tempPt];
				[[anewroi points] addObject: lastPoint];
				[lastPoint release];
				
			}
			[anewroi setName:[temproi name]];
			RGBColor color;
			color= [temproi rgbcolor];		
			[anewroi setColor:color];
			[imgROIs addObject:anewroi];
						
		}
		
	}
		return newPix;
}
- (DCMPix*)getCurPixFromAxView:(float*)imgdata:(int)imgwidth:(int)imgheight:(NSMutableArray*)imgROIs
{
	//crop the origin Image to fit current view size
	NSPoint point[4];
	NSArray				*pixList = [originalViewController pixList];
	DCMPix	*firstPix=[pixList objectAtIndex: 0];
	DCMPix  *temppix;	
	int x,y;
	int offsetx,offsety;
	int minx,miny,maxx,maxy;
	int width,height;
	float* tempfloat;
	float vector[ 9], origin[3];
	//double doublevector[3];
	vtkTransform* currentTransform;

	if(isStraightenedCPR)
		currentTransform=axViewTransformForStraightenCPR;
	else
		currentTransform=axViewTransform;
	
	temppix=[axViewPixList objectAtIndex: 0];
	
	
	width = [temppix pwidth];
	height = [temppix pheight];
	tempfloat = [temppix fImage];
	NSRect viewsize = [crossAxiasView frame];
	point[0].x=0;
	point[1].x=viewsize.size.width;
	point[2].x=0;
	point[3].x=viewsize.size.width;
	
	point[0].y=0;
	point[1].y=0;
	point[2].y=viewsize.size.height;
	point[3].y=viewsize.size.height;
	
	point[0]=[crossAxiasView ConvertFromUpLeftView2GL:point[0]];
	point[1]=[crossAxiasView ConvertFromUpLeftView2GL:point[1]];
	point[2]=[crossAxiasView ConvertFromUpLeftView2GL:point[2]];
	point[3]=[crossAxiasView ConvertFromUpLeftView2GL:point[3]];
	
	minx=maxx=point[0].x;
	miny=maxy=point[0].y;
	unsigned j;
	for(j=1;j<4;j++)
	{
		if(point[j].x<minx)
			minx=point[j].x;
		if(point[j].y<miny)
			miny=point[j].y;
		if(point[j].x>maxx)
			maxx=point[j].x;
		if(point[j].y>maxy)
			maxy=point[j].y;
		
	}
	
	offsetx=minx;
	offsety=miny;
	if(minx<0)
		minx=0;
	if(miny<0)
		miny=0;
	if(maxx>width)
		maxx=width;
	if(maxy>height)
		maxy=height;
	
	for(y=0;y<imgheight;y++)
		for(x=0;x<imgwidth;x++)
		{
			if(x+offsetx>=minx&&x+offsetx<maxx&&y+offsety>=miny&&y+offsety<maxy)
				*(imgdata+y*imgwidth+x)=*(tempfloat+(y+offsety)*width+x+offsetx);
			else
				*(imgdata+y*imgwidth+x) = minValueInSeries;
		}
	
	//calculate orietion
	float inversedvector[9];
	float unitvector[3];
	float originpat[3],unitvectorpat[3];
	[firstPix orientation:vector];
	[self inverseMatrix:vector:inversedvector];
	origin[0]=0;
	origin[1]=0;
	origin[2]=0;
	currentTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];
	
	
	unitvector[0]=1;
	unitvector[1]=0;
	unitvector[2]=0;
	currentTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[0]=unitvectorpat[0]-originpat[0];
	vector[1]=unitvectorpat[1]-originpat[1];
	vector[2]=unitvectorpat[2]-originpat[2];
	
	
	unitvector[0]=0;
	unitvector[1]=1;
	unitvector[2]=0;
	currentTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[3]=unitvectorpat[0]-originpat[0];
	vector[4]=unitvectorpat[1]-originpat[1];
	vector[5]=unitvectorpat[2]-originpat[2];
	
	unitvector[0]=0;
	unitvector[1]=0;
	unitvector[2]=1;
	currentTransform->TransformPoint(unitvector,unitvector);
	unitvectorpat[0]= unitvector[0] * inversedvector[0] + unitvector[1] * inversedvector[1] + unitvector[2]*inversedvector[2];
	unitvectorpat[1]= unitvector[0] * inversedvector[3] + unitvector[1] * inversedvector[4] + unitvector[2]*inversedvector[5];
	unitvectorpat[2]= unitvector[0] * inversedvector[6] + unitvector[1] * inversedvector[7] + unitvector[2]*inversedvector[8];
	vector[6]=unitvectorpat[0]-originpat[0];
	vector[7]=unitvectorpat[1]-originpat[1];
	vector[8]=unitvectorpat[2]-originpat[2];
	
	
	origin[0]=axViewOrigin[0]+offsetx*axViewSpace[0];
	origin[1]=axViewOrigin[1]+offsety*axViewSpace[1];
	origin[2]=axViewOrigin[2];
	currentTransform->TransformPoint(origin,origin);
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];	
	origin[0]=originpat[0];
	origin[1]=originpat[1];
	origin[2]=originpat[2];
	/* origin[0]=0;
	origin[1]=0;
	origin[2]=0;
	currentTransform->TransformPoint(origin,origin);


	[firstPix orientation:vector];

	doublevector[0]=vector[0];
	doublevector[1]=vector[1];
	doublevector[2]=vector[2];
	currentTransform->TransformPoint(doublevector,doublevector);
	vector[0]=doublevector[0]-origin[0];
	vector[1]=doublevector[1]-origin[1];
	vector[2]=doublevector[2]-origin[2];

	doublevector[0]=vector[3];
	doublevector[1]=vector[4];
	doublevector[2]=vector[5];
	currentTransform->TransformPoint(doublevector,doublevector);
	vector[3]=doublevector[0]-origin[0];
	vector[4]=doublevector[1]-origin[1];
	vector[5]=doublevector[2]-origin[2];

	doublevector[0]=vector[6];
	doublevector[1]=vector[7];
	doublevector[2]=vector[8];
	currentTransform->TransformPoint(doublevector,doublevector);
	vector[6]=doublevector[0]-origin[0];
	vector[7]=doublevector[1]-origin[1];
	vector[8]=doublevector[2]-origin[2];


	origin[0]=axViewOrigin[0]+offsetx*axViewSpace[0];
	origin[1]=axViewOrigin[1]+offsety*axViewSpace[1];
	origin[2]=axViewOrigin[2];
	currentTransform->TransformPoint(origin,origin);

	 */	
	
	
	DCMPix	*newPix = [firstPix copy];
	[newPix setPwidth: imgwidth];
	//[newPix setRowBytes: imgwidth];
	[newPix setPheight: imgheight];
	
	[newPix setfImage:imgdata];
	[newPix setTot:1 ];
	[newPix setFrameNo: 0];
	[newPix setID: 0];
	[newPix setPixelSpacingX: axViewSpace[0]];
	[newPix setPixelSpacingY: axViewSpace[1]];
	[newPix setOrigin:origin];
	[newPix setOrientation: vector];
	[newPix setSliceLocation:0];
	[newPix setPixelRatio:  axViewSpace[1] / axViewSpace[0]];
	[newPix setSliceThickness: 0];
	[newPix setSliceInterval: 0];
	
	
	
	//creat new rois using the new origin
	
	int ifpolygonfound=0;
	for(j=0;j<[[axViewROIList objectAtIndex: 0] count];j++)
	{
		ROI *temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex: j];
		
		if([temproi type] == tPlain)
		{
			ROI *anewroi=[[ROI alloc] initWithTexture:[temproi textureBuffer] textWidth:[temproi textureWidth] textHeight:[temproi textureHeight] textName:[axImageSlider stringValue] positionX:[temproi textureUpLeftCornerX]-offsetx positionY:[temproi textureUpLeftCornerY]-offsety spacingX:axViewSpace[0] spacingY:axViewSpace[1] imageOrigin:NSMakePoint( origin[0],  origin[1])];
			RGBColor color;
			color= [temproi rgbcolor];		
			[anewroi setColor:color];
			[imgROIs addObject:anewroi];
			[anewroi release];
		}
		else if([temproi type] == tCPolygon && [temproi valid] )
		{
			ROI* anewroi=[[ROI alloc] initWithType: tCPolygon :axViewSpace[0]  :axViewSpace[1] : NSMakePoint( origin[0],  origin[1])];
			
			NSArray* oldPoints=[temproi points];
			unsigned int k;
			NSPoint tempPt;
			for(k=0;k<[oldPoints count];k++)
			{
				tempPt=[[oldPoints objectAtIndex: k] point];
				tempPt.x-=offsetx;
				tempPt.y-=offsety;
				
				MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:tempPt];
				[[anewroi points] addObject: lastPoint];
				[lastPoint release];
				
			}
			[anewroi setName:[temproi name]];
			[anewroi setComments:[temproi comments]];
			RGBColor color;
			color= [temproi rgbcolor];		
			[anewroi setColor:color];
			[imgROIs addObject:anewroi];
			ifpolygonfound=1;
			
		}
		else if([temproi type] == tMesure && [temproi valid])
		{
			ROI* anewroi=[[ROI alloc] initWithType: tMesure :axViewSpace[0]  :axViewSpace[1] : NSMakePoint( origin[0],  origin[1])];
			
			NSArray* oldPoints=[temproi points];
			unsigned int k;
			NSPoint tempPt;
			for(k=0;k<[oldPoints count];k++)
			{
				tempPt=[[oldPoints objectAtIndex: k] point];
				tempPt.x-=offsetx;
				tempPt.y-=offsety;
				
				MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:tempPt];
				[[anewroi points] addObject: lastPoint];
				[lastPoint release];
				
			}
			[anewroi setName:[temproi name]];
			[anewroi setComments:[temproi comments]];
			RGBColor color;
			color= [temproi rgbcolor];		
			[anewroi setColor:color];
			[imgROIs addObject:anewroi];
			ifpolygonfound=1;
			
		}
		
	}
	if(!ifpolygonfound && axViewROIMode != 0)
	{
		NSRect roiRect;
		roiRect.origin.x=-axViewOrigin[0]/axViewSpace[0]-offsetx;
		roiRect.origin.y=-axViewOrigin[1]/axViewSpace[1]-offsety;
		roiRect.size.width=roiRect.size.height=1;
		ROI *aPointROI = [[ROI alloc] initWithType: t2DPoint :axViewSpace[0] :axViewSpace[1] : NSMakePoint( origin[0],origin[1])];
		[aPointROI setName:@"no segment result"];
		[aPointROI setComments:[axImageSlider stringValue]];
		[aPointROI setROIRect:roiRect];
		[imgROIs addObject:aPointROI];
	}
	return newPix;
	
}
- (IBAction)deleteImageInBasket:(id)sender
{
	unsigned int index=[basketMatrix selectedColumn];
	if(index<[basketImageArray count])
	{
		[basketImageArray removeObjectAtIndex:index];
		[basketImageROIArray removeObjectAtIndex:index];
		if([basketMatrix numberOfColumns]>1)
		{
			[basketMatrix removeColumn:index];
			if(index<[basketImageArray count])
			{
				[basketMatrix selectCellAtRow:0 column:index];
			}
			else
			{
				[basketMatrix selectCellAtRow:0 column:index-1];
			}
		}
		else
		{
			NSButtonCell *cell = [basketMatrix cellAtRow: 0 column:0];
			[cell setRepresentedObject: nil];
			[cell setImage:[NSImage imageNamed: @"trash"]];
			[cell setEnabled:YES];
			
		}
	}
	
}
- (IBAction)emptyImageInBasket:(id)sender
{
	[basketImageArray removeAllObjects];
	[basketImageROIArray removeAllObjects];
	while([basketMatrix numberOfColumns]>1)
	{
		[basketMatrix removeColumn:1];
	}

	NSButtonCell *cell = [basketMatrix cellAtRow: 0 column:0];
	[cell setRepresentedObject: nil];
	[cell setImage:[NSImage imageNamed: @"trash"]];
	[cell setEnabled:YES];

}
- (IBAction)saveImagesInBasket:(id)sender
{
	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	
	
	int i;
	float* newVolumeData=nil;
	long size= 0;
	int imageNumber=[basketImageArray count];
	DCMPix* tempPix,*newPix=nil;
	int curwidth,curheight;
	for(i=0;i<imageNumber;i++)
	{
		tempPix=[basketImageArray objectAtIndex:i];
		curwidth = [tempPix pwidth];
		curheight = [tempPix pheight];
		size+=curwidth*curheight*sizeof(float);
	}

	newVolumeData=(float*) malloc(size);
	if(!newVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return;
	}
	
	float* imgdata=newVolumeData;
	int curimgsize=0;
	for( i = 0 ; i < imageNumber; i ++)
	{
		tempPix=[basketImageArray objectAtIndex:i] ;
		curwidth = [tempPix pwidth];
		curheight = [tempPix pheight];
		curimgsize = curwidth*curheight;
		float* oldimgdata=[tempPix fImage];
		memcpy(imgdata,oldimgdata,curimgsize*sizeof(float));
		
		newPix=[tempPix copy];
		[newPix setPwidth:curwidth];
		//[newPix setRowBytes: curwidth];
		[newPix setPheight: curheight];
		[newPix setfImage:imgdata];
		[newPix setTot:imageNumber ];
		[newPix setFrameNo: 0];
		[newPix setID: i];
		[newPixList addObject: newPix];
		[newPix release];

		imgdata+=curimgsize;
		
		
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: 0]];

	}
	
	
	NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
	ViewerController *new2DViewer;
	new2DViewer = [originalViewController newWindow	:newPixList
				   :newDcmList
				   :newData]; 
	
	NSMutableArray      *roiList= [new2DViewer roiList];
	unsigned j;
	for(i=0;i<imageNumber;i++)
	{
		for(j=0;j<[[basketImageROIArray objectAtIndex:i] count];j++)
			[[roiList objectAtIndex:i] addObject:[[basketImageROIArray objectAtIndex:i] objectAtIndex:j]]; 
		
	}
	[new2DViewer resetImage:self];
	
	[self emptyImageInBasket:self];
	
	[[self window] makeKeyAndOrderFront:parent];
	return;
	
}
#pragma mark-
#pragma mark 3. Seeding&ROI functions
- (IBAction)changeSeedingTool:(id)sender
{
	int seedingtoolindex=2-[seedingToolMatrix selectedColumn]+6;
	[self changeCurrentTool:seedingtoolindex];
}
- (IBAction)addSeed:(id)sender
{
	NSMutableDictionary *contrast;
	
	contrast = [NSMutableDictionary dictionary];
	[contrast setObject:[NSString stringWithString:[seedName stringValue] ]  forKey:@"Name"];
	[contrast setObject: [seedColor color] forKey:@"Color"];
	[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
	[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
	[contrastList addObject: contrast];
	[seedsList reloadData];
	[seedsList selectRow:[contrastList count]-1 byExtendingSelection:NO];
	[self selectAContrast: seedsList];
	
}
- (IBAction)removeSeed:(id)sender
{

	unsigned int i;
	int row=[seedsList selectedRow];
	NSString *name;
	name =[[contrastList objectAtIndex: row]objectForKey:@"Name"];
	
	for(i=0;i<[totalROIList count];i++)
		if([[[totalROIList objectAtIndex: i] name] isEqualToString:name])
		{
			[[NSNotificationCenter defaultCenter] postNotificationName: @"removeROI" object:[totalROIList objectAtIndex: i] userInfo: 0L];
			i--;
		}

	

	[contrastList removeObjectAtIndex:row];

	[seedsList reloadData];
	if(row>=(int)([contrastList count]))
		row=(int)([contrastList count])-1;
	[seedsList selectRow:row byExtendingSelection:NO];
	[self selectAContrast: seedsList];	

	[self updateOView];
	[self cAndAxViewReset];
	[self updatePageSliders];		

}
- (IBAction)changeSeedColor:(id)sender
{
}
- (IBAction)changeSeedName:(id)sender
{
}
- (int) initSeedsList
{
	//initilize contrast list
	contrastList= [[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableDictionary *contrast;
	if(!isInWizardMode)
	{
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"Artery"]  forKey:@"Name"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject: [NSColor redColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Seeds for arteries"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"Vein"]  forKey:@"Name"];
		[contrast setObject: [NSColor blueColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Seeds for veins"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"Bone"]  forKey:@"Name"];
		[contrast setObject: [NSColor brownColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject: [NSNumber numberWithFloat:4.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Seeds for bones"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"LCA"]  forKey:@"Name"];
		[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
		[contrast setObject: [NSColor redColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Step2 Place Virtual catheter in LCA\nDraw an arrow in the left window at the root of LCA, adjust the arrow's direction along the long axis artery in the right buttom window if necessary, move and zoom the circle in right top window to include the whole cross section of the vessel."]  forKey:@"Tips"];
		[contrastList addObject: contrast];	
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"RCA"]  forKey:@"Name"];
		[contrast setObject: [NSColor greenColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Step3 Place Virtual catheter in RCA\nDraw an arrow in the left window at the root of RCA, adjust the arrow's direction along the long axis artery in the right buttom window if necessary, move and zoom the circle in right top window to include the whole cross section of the vessel."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"other"]  forKey:@"Name"];
		[contrast setObject: [NSColor yellowColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:3.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Step4 Mark Unwanted Structure\nDraw yellow lines in the left window. Make sure you have marked following structures: both ventricles, desending aorta, vertebra, sternum and vein of liver."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"barrier"]  forKey:@"Name"];
		[contrast setObject: [NSColor purpleColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:1.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:6] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Sepcial seed to stop propagation."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		
	}	
	else if(isInWizardMode==1)
	{
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"LCA"]  forKey:@"Name"];
		[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
		[contrast setObject: [NSColor redColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Step2 Place Virtual catheter in LCA\nDraw an arrow in the left window at the root of LCA, adjust the arrow's direction along the long axis artery in the right buttom window if necessary, move and zoom the circle in right top window to include the whole cross section of the vessel."]  forKey:@"Tips"];
		[contrastList addObject: contrast];	
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"RCA"]  forKey:@"Name"];
		[contrast setObject: [NSColor greenColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Step3 Place Virtual catheter in RCA\nDraw an arrow in the left window at the root of RCA, adjust the arrow's direction along the long axis artery in the right buttom window if necessary, move and zoom the circle in right top window to include the whole cross section of the vessel."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"other"]  forKey:@"Name"];
		[contrast setObject: [NSColor yellowColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:3.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Step4 Mark Unwanted Structure\nDraw yellow lines in the left window. Make sure you have marked following structures: both ventricles, desending aorta, vertebra, sternum and vein of liver."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"barrier"]  forKey:@"Name"];
		[contrast setObject: [NSColor purpleColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:1.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:6] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Sepcial seed to stop propagation."]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		needSaveSeeds=YES;
	}
	else if(isInWizardMode==2)
	{		
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"other"]  forKey:@"Name"];
		[contrast setObject: [NSColor yellowColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:3.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:8] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"barrier"]  forKey:@"Name"];
		[contrast setObject: [NSColor purpleColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithFloat:1.0] forKey:@"BrushWidth"];
		[contrast setObject: [NSNumber numberWithInt:6] forKey:@"CurrentTool"];
		[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		
		contrast = [NSMutableDictionary dictionary];
		[contrast setObject:[NSString stringWithString:@"Aorta"]  forKey:@"Name"];
		[contrast setObject: [NSColor greenColor] forKey:@"Color"];
		[contrast setObject: [NSNumber numberWithInt:7] forKey:@"CurrentTool"];
		[contrast setObject: [NSNumber numberWithFloat:2.0] forKey:@"BrushWidth"];
		[contrast setObject:[NSString stringWithString:@"Automatic Procedure"]  forKey:@"Tips"];
		[contrastList addObject: contrast];
		needSaveSeeds=YES;
	}
	
	contrast = [contrastList objectAtIndex: 0];
	[seedColor setColor:  [contrast objectForKey:@"Color"] ];
	[seedName setStringValue: [contrast objectForKey:@"Name"] ];
	[brushWidthText setIntValue:[[contrast objectForKey: @"BrushWidth"] intValue]];
	[brushWidthSlider setFloatValue:[[contrast objectForKey: @"BrushWidth"] floatValue]];
	[brushStatSegment setSelectedSegment:0];
	
	
	//intilize roi list
	totalROIList = [[NSMutableArray alloc] initWithCapacity: 0];
	uniIndex = 0;
	isRemoveROIBySelf=0;
	[convertToSeedButton setHidden:YES];
	[brushStatSegment setHidden:YES];
	[brushWidthSlider setHidden:YES];
	[brushWidthText setHidden:YES];
	
	
	
	return [self reloadSeedsFromExportedROI];
}
- (int) reloadSeedsFromExportedROI
{
	
	return 0;
}
- (void) creatROIListFromSlices:(NSMutableArray*) roiList :(int) width:(int)height:(short unsigned int*)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY
{
	int x,y;
	unsigned int i;
	short unsigned marker;
	RGBColor color;
	ROI* roi;
	NSRect rect;
	rect.origin.x=-1;
	rect.origin.y=-1;
	rect.size.width =-1;
	rect.size.height =-1;
	for(i=0;i<[totalROIList count];i++)
		[[totalROIList objectAtIndex:i] setROIRect:rect];
	
	for(y=0;y<height;y++)
		for(x=0;x<width;x++)
		{
			marker=*(im+y*width+x);
			if(marker>0&&marker<=[totalROIList count])
			{
				roi=[totalROIList objectAtIndex:marker-1];
				rect=[roi rect];
				if(rect.origin.x<0)
				{
					rect.origin.x=x;
					rect.origin.y=y;
					rect.size.width=0;
					rect.size.height=0;
				}
				else
				{
					if(rect.origin.x>x)
					{
						rect.size.width+=(rect.origin.x-x);
						rect.origin.x=x;
					}
					else if(rect.origin.x+rect.size.width <x)
						rect.size.width = x-rect.origin.x;
					if(rect.origin.y>y)
					{
						rect.size.height+=(rect.origin.y-y);
						rect.origin.y=y;
					}
					else if(rect.origin.y+rect.size.height <y)
						rect.size.height = y-rect.origin.y;
				}
				[roi setROIRect: rect];
				
				
				
			}
		}
	
	for(i=0;i<[totalROIList count];i++)
	{
		roi=[totalROIList objectAtIndex:i];
		rect = [roi rect];
		
		if(rect.origin.x>=0)
		{
			rect.size.width+=1;
			rect.size.height+=1; 
			unsigned char* textureBuffer= (unsigned char*)malloc((int)(rect.size.width *rect.size.height));
			
			for(y=0;y<rect.size.height;y++)
				for(x=0;x<rect.size.width;x++)
				{
					int ii=(int)((y+rect.origin.y)*width+x+rect.origin.x);
					int jj=(int)(y*rect.size.width + x);
					if(*(im+ii)==i+1)
						*(textureBuffer+jj)=0xff;
			        else 
						*(textureBuffer+jj)=0x00;
				}
			
			ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:(int)rect.size.width textHeight:(int)rect.size.height textName:[roi name] positionX:(int)rect.origin.x positionY:(int)rect.origin.y spacingX:spaceX spacingY:spaceY imageOrigin:NSMakePoint( originX,  originY)];
			[newROI setComments:[NSString stringWithFormat:@"%d",i+1]];
			
			
			color= [roi rgbcolor];		
			
			[newROI setColor:color];
			[newROI setROIMode:ROI_selected];
			//[newROI setParentROI:roi];
			[roiList addObject:newROI];
			[newROI release];
			free(textureBuffer);
		}
	}
	
}
- (void) roiChanged: (NSNotification*) note
{
	id sender = [note object];
	if(currentTool==4)
	{
		ROI* roi=(ROI*)sender;
		int roitype =[roi type];
		if(roitype!=tMesure)
		{
			[roi setROIMode:ROI_sleep];
		}
	}
	else if(currentTool==8)
	{
		if([[oViewROIList objectAtIndex: 0] containsObject: sender] )
		{
			ROI* roi=(ROI*)sender;
			int roitype =[roi type];
			if(roitype==tPlain)
			{
				short unsigned int marker=(short unsigned int)[[roi comments] intValue];
				int i,j;
				float point[3];
				unsigned char *texture=[roi textureBuffer];
				//if creating new roiList by self marker is 0
				if(texture&&marker)
				{
					if(!contrastVolumeData)
					{
						int size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
						contrastVolumeData = (unsigned short int*) malloc( size);
						roiReader->SetImportVoidPointer(contrastVolumeData);
					}
					int x,y,z;
					float curXSpacing,curYSpacing;
					float curOriginX,curOriginY;
					curXSpacing=[[roi pix] pixelSpacingX];
					curYSpacing=[[roi pix] pixelSpacingY];
					curOriginX = [roi textureUpLeftCornerX]*curXSpacing+[[roi pix] originX];
					curOriginY = [roi textureUpLeftCornerY]*curYSpacing+[[roi pix] originY];
					for(j=0;j<[roi textureHeight];j++)
						for(i=0;i<[roi textureWidth];i++)
						{
							point[0] = curOriginX + i * curXSpacing;
							point[1] = curOriginY + j * curYSpacing;
							point[2] = 0;
							oViewUserTransform->TransformPoint(point,point);
							x=lround((point[0]-vtkOriginalX)/xSpacing);
							y=lround((point[1]-vtkOriginalY)/ySpacing);
							z=lround((point[2]-vtkOriginalZ)/zSpacing);
							if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
							{
								
								if(*(texture+j*[roi textureWidth]+i))
								{
									*(contrastVolumeData+z*imageSize+y*imageWidth+x)=marker;
									if((i+1)<[roi textureWidth]&&*(texture+j*[roi textureWidth]+i+1))
									{
										point[0] = curOriginX + i * curXSpacing+curXSpacing/2;
										point[1] = curOriginY + j * curYSpacing;
										point[2] = 0;
										oViewUserTransform->TransformPoint(point,point);
										x=lround((point[0]-vtkOriginalX)/xSpacing);
										y=lround((point[1]-vtkOriginalY)/ySpacing);
										z=lround((point[2]-vtkOriginalZ)/zSpacing);
										if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
											*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
										
									}
									if((j+1)<[roi textureHeight]&&*(texture+(j+1)*[roi textureWidth]+i))
									{
										point[0] = curOriginX + i * curXSpacing;
										point[1] = curOriginY + j * curYSpacing+curYSpacing/2;
										point[2] = 0;
										oViewUserTransform->TransformPoint(point,point);
										x=lround((point[0]-vtkOriginalX)/xSpacing);
										y=lround((point[1]-vtkOriginalY)/ySpacing);
										z=lround((point[2]-vtkOriginalZ)/zSpacing);
										if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
											*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
										
									}
									if((i+1)<[roi textureWidth] && (j+1)<[roi textureHeight] && *(texture+(j+1)*[roi textureWidth]+i))
									{
										point[0] = curOriginX + i * curXSpacing+curXSpacing/2;
										point[1] = curOriginY + j * curYSpacing+curYSpacing/2;
										point[2] = 0;
										oViewUserTransform->TransformPoint(point,point);
										x=lround((point[0]-vtkOriginalX)/xSpacing);
										y=lround((point[1]-vtkOriginalY)/ySpacing);
										z=lround((point[2]-vtkOriginalZ)/zSpacing);
										if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
											*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
										
									}
									if((i-1)>0&&(j+1)<[roi textureHeight]&&*(texture+(j+1)*[roi textureWidth]+i))
									{
										point[0] = curOriginX + i * curXSpacing-curXSpacing/2;
										point[1] = curOriginY + j * curYSpacing+curYSpacing/2;
										point[2] = 0;
										oViewUserTransform->TransformPoint(point,point);
										x=lround((point[0]-vtkOriginalX)/xSpacing);
										y=lround((point[1]-vtkOriginalY)/ySpacing);
										z=lround((point[2]-vtkOriginalZ)/zSpacing);
										if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
											*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
										
									}
								}
								else if(*(contrastVolumeData+z*imageSize+y*imageWidth+x)==marker)
									*(contrastVolumeData+z*imageSize+y*imageWidth+x)=0;
								
								
							}
						}
				}
			}
		}
	}
	else if(currentTool==6)
	{
		if([[oViewROIList objectAtIndex: 0] containsObject: sender] )
		{
			ROI* roi=(ROI*)sender;
			
			if([roi isEqual:oViewMeasureLine] )
			{
				cPRViewCenter=[[measureLinePointsArray objectAtIndex: 0] point];
				NSPoint tempPt=[[measureLinePointsArray objectAtIndex: 1] point];
				float angle,length;
				
				tempPt.x-=cPRViewCenter.x;
				tempPt.y-=cPRViewCenter.y;
				tempPt.x*=oViewSpace[0];
				tempPt.y*=oViewSpace[1];
				
				if(tempPt.y == 0)
				{
					if(tempPt.x > 0)
						angle=90;
					else if(tempPt.x < 0)
						angle=-90;
					else 
						angle=0;
					length=tempPt.x;
				}
				else
				{
					if( tempPt.y < 0)
						angle = 180 + atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					else 
						angle = atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					length=tempPt.y/sin(atan( (float) tempPt.y/(float) tempPt.x  ));
				}
				length=fabs(length);
				
				cPRViewCenter.x = cPRViewCenter.x*oViewSpace[0]+oViewOrigin[0];
				cPRViewCenter.y = cPRViewCenter.y*oViewSpace[1]+oViewOrigin[1];				
				
				cViewTransform->Identity();
				cViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
				cViewTransform->RotateZ(-angle);
				oViewToCViewZAngle=-angle;
				cViewTransform->RotateY(-90);
				[self updateCView];
				
				tempPt.x=-cViewOrigin[0]/cViewSpace[0]-cPRROIRect.size.width/2;
				tempPt.y=-cViewOrigin[1]/cViewSpace[1];
				
				
				cPRROIRect.origin=tempPt;
				cPRROIRect.size.height = length/cViewSpace[1];
				
				
			}
		}
		else if([[cViewROIList objectAtIndex:0] containsObject: sender])
		{
			ROI* roi=(ROI*)sender;
			int roitype =[roi type];
			if(roitype==tROI)
			{
				NSRect tempRect=[roi rect];
				cPRROIRect.origin.x = cPRROIRect.origin.x+cPRROIRect.size.width/2-tempRect.size.width/2;
				cPRROIRect.size.width = tempRect.size.width;
				[roi setROIRect: cPRROIRect];
			}
			
		}
	}
	else if(currentTool==7)
	{
		if([sender isEqual:oViewArrow ])
		{
			ROI* roi=(ROI*)sender;
			int roitype =[roi type];
			
			if(roitype==tArrow)
			{
				if([roi ROImode]== ROI_drawing)
				{
					if([[[note userInfo] objectForKey:@"action"] isEqualToString:@"mouseUp"] == YES)
					{
						if([[roi points] count]==3)
							[[roi points] removeLastObject];
#ifdef VERBOSEMODE
						NSLog( @"ROI drawing finished");
#endif
						
						
					}
					else
					{
						MyPoint *oViewEndPoint=[arrowPointsArray objectAtIndex:2];
						if(oViewEndPoint)
						{
							[[arrowPointsArray objectAtIndex:0] setPoint: [oViewEndPoint point]];
						}
#ifdef VERBOSEMODE
						NSLog( @"ROI drawing");
#endif
					}
				}
				
				cPRViewCenter=[[arrowPointsArray objectAtIndex: 1] point];
				NSPoint tempPt=[[arrowPointsArray objectAtIndex: 0] point];
				float angle,length;
				
				tempPt.x-=cPRViewCenter.x;
				tempPt.y-=cPRViewCenter.y;
				tempPt.x*=oViewSpace[0];
				tempPt.y*=oViewSpace[1];
				
				if(tempPt.y == 0)
				{
					if(tempPt.x > 0)
						angle=90;
					else if(tempPt.x < 0)
						angle=-90;
					else 
						angle=0;
					length=tempPt.x;
				}
				else
				{
					if( tempPt.y < 0)
						angle = 180 + atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					else 
						angle = atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					length=tempPt.y/sin(atan( (float) tempPt.y/(float) tempPt.x  ));
				}
				length=fabs(length);
				
				
				
				
				
				
				cPRViewCenter.x = cPRViewCenter.x*oViewSpace[0]+oViewOrigin[0];
				cPRViewCenter.y = cPRViewCenter.y*oViewSpace[1]+oViewOrigin[1];				
				oViewToCViewZAngle=-angle;	
				
				cViewTransform->Identity();
				cViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
				cViewTransform->RotateZ(oViewToCViewZAngle);
				cViewTransform->RotateY(-90);
				
				axViewTransform->Identity();
				axViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
				axViewTransform->RotateZ(oViewToCViewZAngle);
				axViewTransform->RotateX(90);
				
				
				tempPt.x=-cViewOrigin[0]/cViewSpace[0]-cPRROIRect.size.width/2;
				tempPt.y=-cViewOrigin[1]/cViewSpace[1];
				
				
				
#ifdef VERBOSEMODE
				NSLog( @"updating CView Arrow");
#endif
				if(cViewArrow)
				{
					
					NSPoint startPoint,endPoint;
					startPoint=tempPt;
					endPoint.x= tempPt.x;
					endPoint.y= tempPt.y+length/cViewSpace[1];
					
					[[cViewArrowPointsArray objectAtIndex:0] setPoint: endPoint];
					[[cViewArrowPointsArray objectAtIndex:1] setPoint: startPoint];
					
				}
				
#ifdef VERBOSEMODE
				NSLog( @"updating CView Image");
#endif
				
				[self updateCView];
#ifdef VERBOSEMODE
				NSLog( @"updating AxView Image");
#endif
				[self updateAxView];
				
			}
#ifdef VERBOSEMODE
			NSLog( @"finished all roi update");
#endif
			//[cPRView setIndex:0];
			
		}
		else if([sender isEqual:cViewArrow])
		{
			NSPoint start=[[cViewArrowPointsArray objectAtIndex: 1] point];
			if(start.x!= cViewArrowStartPoint.x||start.y!=cViewArrowStartPoint.y)
				[[cViewArrowPointsArray objectAtIndex: 1] setPoint:cViewArrowStartPoint];
			else
			{
				// caculate cViewToAxViewZAngle
				
				NSPoint tempPt=[[cViewArrowPointsArray objectAtIndex: 0] point];
				float angle;
				
				tempPt.x-=start.x;
				tempPt.y-=start.y;
				tempPt.x*=cViewSpace[0];
				tempPt.y*=cViewSpace[1];
				
				if(tempPt.y == 0)
				{
					if(tempPt.x > 0)
						angle=90;
					else if(tempPt.x < 0)
						angle=-90;
					else 
						angle=0;
					
				}
				else
				{
					if( tempPt.y < 0)
						angle = 180 + atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					else 
						angle = atan( (float) tempPt.x / (float) tempPt.y) / deg2rad;
					
				}
				cViewToAxViewZAngle=angle;
				
				axViewTransform->Identity();
				axViewTransform->Translate(cPRViewCenter.x,cPRViewCenter.y,0 );
				axViewTransform->RotateZ(oViewToCViewZAngle);
				axViewTransform->RotateX(90+cViewToAxViewZAngle);
				
				[self updateAxView];
				
			}
			
			
			
		}
	}
	else if(currentTool==9)
	{
		ROI* roi=(ROI*)sender;
		
		if(roi==cViewMeasurePolygon&&[cPRView mouseDragging])
		{
			cViewMeasureNeedToUpdate=YES;
		}
		else if(roi==axViewMeasurePolygon&&[crossAxiasView mouseDragging])
		{
			axViewMeasureNeedToUpdate=YES;
		}
	}
	else if(cViewMPRorCPRMode && curvedMPR2DPath &&[[oViewROIList objectAtIndex: 0] containsObject: sender])
	{
		ROI* roi=(ROI*)sender;
		int roitype =[roi type];
		
		if(roitype==tOPolygon &&currentPathMode==ROI_drawing)
		{
			if([[curvedMPR2DPath points] count]>[curvedMPR3DPath count])//add new end
			{
				float curXSpacing,curYSpacing;
				float curOriginX,curOriginY;
				double position[3];
				NSMutableArray  *path2DPoints=[curvedMPR2DPath points] ;
				DCMPix* tempix=[oViewPixList objectAtIndex:0];
				
				curXSpacing = [tempix pixelSpacingX];
				curYSpacing = [tempix pixelSpacingY];
				curOriginX = [tempix originX];
				curOriginY = [tempix originY];
				
				position[0] = curOriginX + [[path2DPoints lastObject] point].x * curXSpacing;
				position[1] = curOriginY + [[path2DPoints lastObject] point].y * curYSpacing;
				position[2] = 0;
				oViewUserTransform->TransformPoint(position,position);
				
				CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
				[new3DPoint setX: position[0]];
				[new3DPoint setY: position[1]];
				[new3DPoint setZ: position[2]];
				[curvedMPR3DPath addObject: new3DPoint];
				[new3DPoint release];
				
			}
			else if([[curvedMPR2DPath points] count]<[curvedMPR3DPath count])//remove the end
			{
				[curvedMPR3DPath removeLastObject];
			}
			else 
			{
				if([curvedMPR2DPath ROImode]!=currentPathMode)
					[curvedMPR2DPath setROIMode:currentPathMode];
				return;
			}
			
		}
		else
		{
			if([[curvedMPR2DPath points] count]>[curvedMPR3DPath count])//user add new end
			{
				[[curvedMPR2DPath points] removeLastObject];
			}
			if([curvedMPR2DPath ROImode] == ROI_drawing)
				[curvedMPR2DPath setROIMode:currentPathMode];
		}
		
		[self updateCView];
	}
}
- (void) roiAdded: (NSNotification*) note
{
	
	
	id sender =[note object];
	
	
	if( sender&&(currentTool!=4))
	{
		if ([sender isEqual:originalView])
		{
			
			ROI * roi = [[note userInfo] objectForKey:@"ROI"];
			if(roi)
			{
				int roitype =[roi type];
				RGBColor c;
				if(roitype!=tOPolygon)
				{
					
					[roi setName: currentSeedName];
					
					CGFloat r, g, b;
					
					[currentSeedColor getRed:&r green:&g blue:&b alpha:0L];
					
					
					
					c.red =(short unsigned int) (r * 65535.);
					c.green =(short unsigned int)( g * 65535.);
					c.blue = (short unsigned int)(b * 65535.);
					
					[roi setColor:c];
				}
				else
				{

					[roi setName: [NSString stringWithString:@"centerline"]];
									

					
					c.red =(short unsigned int) ( 65535.);
					c.blue =(short unsigned int)( 65535.);
					c.green= (short unsigned int)( 0);
					
					[roi setColor:c];
				}
				
				if(cViewMPRorCPRMode&&roitype==tOPolygon)
				{
					if(curvedMPR2DPath)
					{
						MyPoint* endPoint = 0L;
						endPoint = [[roi points] objectAtIndex:0];
						[endPoint retain];
						[[roi points] removeAllObjects];
						[roi setPoints: [curvedMPR2DPath points]];
						if(endPoint && currentPathMode==ROI_drawing)
							[[roi points] addObject: endPoint];
						isRemoveROIBySelf=1;
						[curvedMPR2DPath release];
						isRemoveROIBySelf=0;
					}
//					if(curvedMPR2DPath&&curvedMPR2DPath!=roi)
//					{
//						isRemoveROIBySelf=1;
//						[curvedMPR2DPath release];
//						isRemoveROIBySelf=0;
//					}
					curvedMPR2DPath=roi;
					[curvedMPR2DPath retain];
					
					[curvedMPR2DPath setThickness:1.0];
					
					[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];

					isRemoveROIBySelf=1;
					unsigned int i;
					for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
						if([temproi type] == tOPolygon)
						{
							if([temproi isEqual:roi]==NO)
							{
								[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
								i--;
							}
						}
					}
					
					isRemoveROIBySelf=0;						
					
				}
				else if(currentTool == 8)
				{
					uniIndex++;
					
					NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
					[roi setComments:indexstr];	
					unsigned int i;
					for(i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						[[roi pix] retain];// to avoid a bug. pix seems not retain by the roi, but will be release
					}
					DCMPix * curImage= [cViewPixList objectAtIndex:0];
					ROI* newROI=[[ROI alloc] initWithType: tROI :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
					[newROI setName:currentSeedName];
					[newROI setComments:indexstr];	
					[newROI setColor:c];
					[totalROIList addObject:newROI];
				}
				else if(currentTool == 6)
				{
					//delete other
					unsigned int i;
					isRemoveROIBySelf=1;
					oViewMeasureLine=nil;
					for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
						if([temproi type] == tMesure)
						{
							if([temproi isEqual:roi]==NO)
							{
								[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
								i--;
							}
						}
					}
					
					[[cViewROIList objectAtIndex: 0] removeAllObjects];
					isRemoveROIBySelf=0;
					oViewMeasureLine=roi;	
					measureLinePointsArray=[oViewMeasureLine points];
					
					DCMPix * curImage= [cViewPixList objectAtIndex:0];
					ROI* newROI=[[ROI alloc] initWithType: tROI :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
					[newROI setName:currentSeedName];
					cPRROIRect.size.width = 20;
					
					[[cViewROIList objectAtIndex: 0] addObject: newROI];
					[newROI release];
					//[newROI setROIRect:roiRect];
				}
				else if(currentTool == 7)
				{
#ifdef VERBOSEMODE
					NSLog( @"ROI added");
#endif
					//delete other
					unsigned int i;
					isRemoveROIBySelf=1;
					oViewArrow=nil;
					cViewArrow=nil;
					for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
						if([temproi type] == tArrow)
						{
							if([temproi isEqual:roi]==NO)
							{
								[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
								i--;
							}
						}
					}
					[[cViewROIList objectAtIndex: 0] removeAllObjects];
					[[axViewROIList objectAtIndex: 0] removeAllObjects];
					
					isRemoveROIBySelf=0;
					//change start and end
					MyPoint *lastPoint=[[MyPoint alloc] initWithPoint:[[[roi points] objectAtIndex:0] point] ];
					arrowPointsArray = [roi points] ;
					[arrowPointsArray addObject:lastPoint];
					[lastPoint release];
					oViewArrow=roi;
#ifdef VERBOSEMODE
					NSLog( @"Get OView ROI");
#endif
					
					
					//create roi in cview and axview
					DCMPix * curImage= [cViewPixList objectAtIndex:0];
					ROI* newROI=[[ROI alloc] initWithType: tArrow :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
					[newROI setName:currentSeedName];
					lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(0,0)];
					cViewArrowPointsArray=[newROI points];
					[cViewArrowPointsArray addObject: lastPoint];
					[lastPoint release];
					lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(0,0)];
					[cViewArrowPointsArray addObject: lastPoint];
					[lastPoint release];
					
					[[cViewROIList objectAtIndex: 0] addObject: newROI];
					cViewArrow=newROI;
					[newROI release];
#ifdef VERBOSEMODE
					NSLog( @"Created CView ROI");
#endif
					
					curImage= [axViewPixList objectAtIndex:0];
					newROI=[[ROI alloc] initWithType: tOval :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
					[newROI setName:currentSeedName];
					[[axViewROIList objectAtIndex: 0] addObject: newROI];
					[newROI release];
#ifdef VERBOSEMODE
					NSLog( @"Created AxView ROI");
#endif
					
					axCircleRect.size.width=10;
					axCircleRect.size.height=10;
					
					
				}
				
			}
			
			
		}
		else if ([sender isEqual:cPRView]&&currentTool == 7 )
		{
			ROI * roi = [[note userInfo] objectForKey:@"ROI"];
			if(roi&&cViewArrow)
			{
				if(![roi isEqual:cViewArrow])
				{
					isRemoveROIBySelf=1;
					[[cViewROIList objectAtIndex:0] removeObject:cViewArrow];
					isRemoveROIBySelf=0;
					cViewArrow=roi;
					cViewArrowPointsArray=[cViewArrow points];
#ifdef VERBOSEMODE
					NSLog( @"Reset CView ROI's points");
#endif
					
				}
				
			}
		}
	}
}

- (void) roiRemoved: (NSNotification*) note
{
	id sender = [note object];
	
	if(sender)
	{
		if ([sender isKindOfClass:[ROI class]])
		{
			ROI* roi=(ROI*)sender;
			if([roi type]==tPlain)
			{
				if(!isRemoveROIBySelf)
				{
					
					NSString * commentstr=[sender comments];
					if([commentstr length]==0)
						return;
					short unsigned int marker=(short unsigned int)[commentstr intValue];
					if(marker&&marker<=[totalROIList count])
					{
						[totalROIList removeObjectAtIndex: marker-1 ];
						unsigned int i;
						for(i = 0;i<[[oViewROIList objectAtIndex: 0] count];i++)
						{ 
							commentstr=[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] comments];
							short unsigned int tempmarker=(short unsigned int)[commentstr intValue];
							if(tempmarker>marker)
								[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] setComments: [NSString stringWithFormat:@"%d",tempmarker-1]];
							if(tempmarker==marker)
								[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] setComments: [NSString stringWithFormat:@"%d",0]];
						}
						
						for(i = marker-1;i<[totalROIList count];i++)
							[[totalROIList objectAtIndex: i] setComments: [NSString stringWithFormat:@"%d",i+1]];
						long j,size;
						size =imageWidth * imageHeight * imageAmount;
						for(j=0;j<size;j++)
						{
							if(*(contrastVolumeData + j)==marker)
								*(contrastVolumeData + j)=0;
							else if (*(contrastVolumeData + j)>marker)
								*(contrastVolumeData + j)=*(contrastVolumeData + j)-1;
						}
						uniIndex--;
						needSaveSeeds=YES;
					}
					
				}
			}
			else if ([roi type]==tMesure)
			{
				if([originalView isEqual:[roi curView]])
				{
					oViewMeasureLine=nil;
					isRemoveROIBySelf=1;
					[[cViewROIList objectAtIndex:0] removeAllObjects];
					[cPRView setIndex: 0];
					[[axViewROIList objectAtIndex: 0] removeAllObjects];
					[crossAxiasView setIndex: 0];
					isRemoveROIBySelf=0;
				}
				
				
			}
			else if ([roi type]==tArrow)
			{
				if([originalView isEqual:[roi curView]])
				{
					oViewArrow=nil;
					cViewArrow=nil;
					isRemoveROIBySelf=1;
					[[cViewROIList objectAtIndex:0] removeAllObjects];
					[cPRView setIndex: 0];
					[[axViewROIList objectAtIndex: 0] removeAllObjects];
					[crossAxiasView setIndex: 0];
					isRemoveROIBySelf=0;
				}
				else if(!isRemoveROIBySelf&&[cPRView isEqual:[roi curView]])
				{
					oViewArrow=nil;
					cViewArrow=nil;
					unsigned int i;
					isRemoveROIBySelf=1;
					for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
						if([temproi type] == tArrow)
						{
							[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
							i--;
						}
					}		
					[originalView setIndex: 0];
					[[axViewROIList objectAtIndex: 0] removeAllObjects];
					[crossAxiasView setIndex: 0];
					isRemoveROIBySelf=0;
					
				}
				
				
				
			}
			
			else if (!isRemoveROIBySelf&&[roi type]==tROI)
			{
				
				if([cPRView isEqual:[roi curView]])
				{
					
					isRemoveROIBySelf=1;
					oViewMeasureLine=nil;
					unsigned int i;
					for ( i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
					{
						ROI* temproi=[[oViewROIList objectAtIndex: 0] objectAtIndex: i] ;
						if([temproi type] == tMesure)
						{
							[[oViewROIList objectAtIndex: 0] removeObjectAtIndex:i];
							i--;
						}
					}
					isRemoveROIBySelf=0;
					[originalView setIndex: 0];
				}
				
			}		
			else if (!isRemoveROIBySelf&&[roi type]==tOPolygon)
			{
				
				if([originalView isEqual:[roi curView]])
				{
//					if(roi!=curvedMPR2DPath)
//					{
//						[curvedMPR2DPath release];
//						curvedMPR2DPath=0L;
//					}
//					[curvedMPR3DPath removeAllObjects];
				}
				
			}			
		}
	}
	
}
- (void) dcmViewMouseDown: (NSNotification*) note
{
	activeView=[note object];
	if(currentTool==9)
	{
		id sender = [note object];
		if(sender==cPRView)
			[[cViewROIList objectAtIndex:0] removeObject:curvedMPRReferenceLineOfAxis] ;
		else if(sender==crossAxiasView)
		{
			unsigned i;
			for (i=0;i<[[axViewROIList objectAtIndex:0] count];i++) {
				if ([[axViewROIList objectAtIndex:0] objectAtIndex:i]!=axViewMeasurePolygon) {
					[[axViewROIList objectAtIndex:0] removeObjectAtIndex:i];
					i--;
					axViewMeasureNeedToUpdate=YES;
				}
			}
		}
	}
	
}
-(void) dcmViewMouseUp: (NSNotification*) note
{

	if(currentTool==9)
	{
		id sender = [note object];
		if(sender==cPRView&&cViewMeasureNeedToUpdate)
		{
			[self updateCViewMeasureAfterROIChanged];
			[[cViewROIList objectAtIndex:0] addObject:curvedMPRReferenceLineOfAxis];
			cViewMeasureNeedToUpdate=NO;
		}
		else if(sender==crossAxiasView&&axViewMeasureNeedToUpdate)
		{
			[self updateAxViewMeasureAfterROIChanged];
			axViewMeasureNeedToUpdate=NO;
		}
	}
}

- (IBAction)selectAContrast:(id)sender
{
	unsigned int row = [seedsList selectedRow];
	NSString *name;
	NSColor *color;
	NSNumber *number;
	
	if(row>=0&&row<[contrastList count])
	{
		currentStep = row;
		name = [[contrastList objectAtIndex: row] objectForKey:@"Name"] ;
		currentSeedName=name;
		[seedName setStringValue:name];
		color =[[contrastList objectAtIndex: row] objectForKey:@"Color"] ;
		currentSeedColor=color;
		[seedColor setColor:color];
		//load brush
		number=[[contrastList objectAtIndex: row] objectForKey:@"BrushWidth"] ;
		[brushWidthText setIntValue:[number intValue]];
		[brushWidthSlider setFloatValue: [number floatValue]];
		[[NSUserDefaults standardUserDefaults] setFloat:[number floatValue] forKey:@"ROIRegionThickness"];
		[brushStatSegment setSelectedSegment:0];
		[originalView setEraserFlag:0];
		//chang current tool
		number=[[contrastList objectAtIndex: row] objectForKey:@"CurrentTool"] ;
		[seedingToolMatrix selectCellAtRow:0 column: 8-[number intValue]];
		[self changeCurrentTool:[number intValue]];
		
	}	
}
- (IBAction)setBrushWidth:(id)sender
{
	[brushWidthText setIntValue: [sender intValue]];
	
	[[NSUserDefaults standardUserDefaults] setFloat:[sender floatValue] forKey:@"ROIRegionThickness"];
	unsigned int row = [seedsList selectedRow];
	
	if(row>=0&&row<[contrastList count])
	{
		[[contrastList objectAtIndex: row] setObject: [NSNumber numberWithFloat:[sender floatValue]] forKey:@"BrushWidth"];
	}
	[self changeCurrentTool:8];
	
}
- (IBAction)setBrushMode:(id)sender
{
	[originalView setEraserFlag: [sender selectedSegment]];
}
- (IBAction)covertRegoinToSeeds:(id)sender
{
#ifdef VERBOSEMODE
	NSLog( @"converting ROI to seeds");
#endif
	if(!contrastVolumeData)
	{
		int size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
		contrastVolumeData = (unsigned short int*) malloc( size);
		roiReader->SetImportVoidPointer(contrastVolumeData);
	}
	if(currentTool==6)
	{
		ROI* roi=[[cViewROIList objectAtIndex: 0] objectAtIndex: 0];
		if(roi&&[roi type]== tROI)
		{
			NSRect tempRect=[roi rect];
			uniIndex++;
			NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
			[roi setComments:indexstr];	
			[totalROIList addObject:roi];
			
			int x,y,z;
			float curXSpacing,curYSpacing;
			float curOriginX,curOriginY;
			short unsigned int marker=uniIndex;
			curXSpacing=cViewSpace[0];
			curYSpacing=cViewSpace[1];
			curOriginX= cViewOrigin[0];
			curOriginY= cViewOrigin[1];
			if(tempRect.size.width<0)
				curOriginX = (tempRect.origin.x+tempRect.size.width)*curXSpacing+curOriginX;		
			
			else
				curOriginX = tempRect.origin.x*curXSpacing+curOriginX;
			
			if(tempRect.size.height<0)
				curOriginY = (tempRect.origin.y+tempRect.size.height)*curYSpacing+curOriginY;				
			else
				curOriginY = tempRect.origin.y*curYSpacing+curOriginY;	
			int i,j,height,width;
			float point[3];
			int minx,maxx,miny,maxy,minz,maxz;
			minx=imageWidth;
			maxx=0;
			miny=imageHeight;
			maxy=0;
			minz=imageAmount;
			maxz=0;
			height=3*abs((int)tempRect.size.height);
			width=3*abs((int)tempRect.size.width );
			//step=0.3 pixel!	
			for(j=0;j<height;j++)
				for(i=0;i<width;i++)
				{
					point[0] = curOriginX + i * curXSpacing/3;
					point[1] = curOriginY + j * curYSpacing/3;
					point[2] = 0;
					cViewTransform->TransformPoint(point,point);
					x=lround((point[0]-vtkOriginalX)/xSpacing);
					y=lround((point[1]-vtkOriginalY)/ySpacing);
					z=lround((point[2]-vtkOriginalZ)/zSpacing);
					if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
					{
						*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
						if(minx>x)
							minx=x;
						if(maxx<x)
							maxx=x;
						if(miny>y)
							miny=y;
						if(maxy<y)
							maxy=y;
						if(minz>z)
							minz=z;
						if(maxz<z)
							maxz=z;
						
						
					}
					
				}
			
			[self fixHolesInBarrier: minx :maxx :miny :maxy :minz :maxz :marker];
			
			oViewUserTransform->Translate(0,0,0.5);
			oViewUserTransform->Translate(0,0,-0.5);
			[self updateOView];
			
		}
	}
	else if(currentTool==7&&[[axViewROIList objectAtIndex: 0] count])
	{
		
		ROI* roi=[[axViewROIList objectAtIndex: 0] objectAtIndex: 0];
		if(roi&&[roi type]== tOval)
		{
			//creat normal seeds with current kind
			NSRect tempRect=[roi rect];
			tempRect.origin.x-=tempRect.size.width/2;
			tempRect.origin.y-=tempRect.size.height/2;
			
			CGFloat rv, gv, bv;
			[currentSeedColor getRed:&rv green:&gv blue:&bv alpha:0L];
			RGBColor c;
			c.red =(short unsigned int) (rv * 65535.);
			c.green =(short unsigned int)( gv * 65535.);
			c.blue = (short unsigned int)(bv * 65535.);
			
			
			uniIndex++;
			NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
			DCMPix* curImage= [axViewPixList objectAtIndex:0];
			ROI* kernelSeedROI=[[ROI alloc] initWithType: tOval :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
			[kernelSeedROI setName:currentSeedName];
			[kernelSeedROI setComments:indexstr];	
			[kernelSeedROI setColor:c];
			[totalROIList addObject:kernelSeedROI];
			float curXSpacing,curYSpacing;
			float curOriginX,curOriginY;
			short unsigned int marker;
			marker=uniIndex;
			curXSpacing=axViewSpace[0];
			curYSpacing=axViewSpace[1];
			curOriginX= axViewOrigin[0];
			curOriginY= axViewOrigin[1];
			
			if(tempRect.size.width<0)
				curOriginX = (tempRect.origin.x+tempRect.size.width)*curXSpacing+curOriginX;		
			
			else
				curOriginX = tempRect.origin.x*curXSpacing+curOriginX;
			
			if(tempRect.size.height<0)
				curOriginY = (tempRect.origin.y+tempRect.size.height)*curYSpacing+curOriginY;				
			else
				curOriginY = tempRect.origin.y*curYSpacing+curOriginY;	
			
			int i,j,height,width;
			int x,y,z;
			float point[3];
			
			height=3*abs((int)tempRect.size.height);
			width=3*abs((int)tempRect.size.width );
			float x0,y0,a,b;
			a=curXSpacing*fabs(tempRect.size.width)/2;
			b=curYSpacing*fabs(tempRect.size.height)/2;	
			x0= curOriginX+a;
			y0= curOriginY+b;
			a=a*a;
			b=b*b;
			if(maxSpacing==0)
				maxSpacing=sqrt(xSpacing*xSpacing+ySpacing*ySpacing+zSpacing*zSpacing);
			//step=0.3 pixel!	
			for(j=0;j<height;j++)
				for(i=0;i<width;i++)
				{
					point[0] = curOriginX + i * curXSpacing/3;
					point[1] = curOriginY + j * curYSpacing/3;
					point[2] = -maxSpacing;
					if((point[0]-x0)*(point[0]-x0)*b+(point[1]-y0)*(point[1]-y0)*a<=a*b)
					{
						axViewTransform->TransformPoint(point,point);
						x=lround((point[0]-vtkOriginalX)/xSpacing);
						y=lround((point[1]-vtkOriginalY)/ySpacing);
						z=lround((point[2]-vtkOriginalZ)/zSpacing);
						if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
						{
							*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
							
							
						}
					}
					
				}				
			
			
			
			//create barrier seeds
			tempRect=[roi rect];
			tempRect.origin.x-=tempRect.size.width;
			tempRect.origin.y-=tempRect.size.height;
			tempRect.size.width+=tempRect.size.width;
			tempRect.size.height+=tempRect.size.height;
			unsigned int ii;
			NSColor *color=0L;
			for(ii=0;ii<[contrastList count];ii++)
			{
				if([[[contrastList objectAtIndex: ii] objectForKey:@"Name"] isEqualToString:@"barrier"])
					color=[[contrastList objectAtIndex: ii] objectForKey:@"Color"] ;	
			}
			if(color)
				[color getRed:&rv green:&gv blue:&bv alpha:0L];
			else
			{
				rv=0.5;
				gv=0.0;
				bv=0.5;
			}
			
			c.red =(short unsigned int) (rv * 65535.);
			c.green =(short unsigned int)( gv * 65535.);
			c.blue = (short unsigned int)(bv * 65535.);
			
			uniIndex++;
			indexstr=[NSString stringWithFormat:@"%d",uniIndex];
			NSString *roiName = [NSString stringWithString:@"barrier"];
			
			[roi setName: roiName];
			[roi setComments:indexstr];	
			[roi setColor:c];
			[totalROIList addObject:roi];
			
			marker=uniIndex;
			curXSpacing=axViewSpace[0];
			curYSpacing=axViewSpace[1];
			curOriginX= axViewOrigin[0];
			curOriginY= axViewOrigin[1];
			if(tempRect.size.width<0)
				curOriginX = (tempRect.origin.x+tempRect.size.width)*curXSpacing+curOriginX;		
			
			else
				curOriginX = tempRect.origin.x*curXSpacing+curOriginX;
			
			if(tempRect.size.height<0)
				curOriginY = (tempRect.origin.y+tempRect.size.height)*curYSpacing+curOriginY;				
			else
				curOriginY = tempRect.origin.y*curYSpacing+curOriginY;	
			
			int minx,maxx,miny,maxy,minz,maxz;
			minx=imageWidth;
			maxx=0;
			miny=imageHeight;
			maxy=0;
			minz=imageAmount;
			maxz=0;
			
			height=3*abs((int)tempRect.size.height);
			width=3*abs((int)tempRect.size.width );
			
			a=curXSpacing*fabs(tempRect.size.width)/2;
			b=curYSpacing*fabs(tempRect.size.height)/2;	
			x0= curOriginX+a;
			y0= curOriginY+b;
			a=a*a;
			b=b*b;
			
			//step=0.3 pixel!	
			for(j=0;j<height;j++)
				for(i=0;i<width;i++)
				{
					point[0] = curOriginX + i * curXSpacing/3;
					point[1] = curOriginY + j * curYSpacing/3;
					point[2] = 0;
					if((point[0]-x0)*(point[0]-x0)*b+(point[1]-y0)*(point[1]-y0)*a<=a*b)
					{
						axViewTransform->TransformPoint(point,point);
						x=lround((point[0]-vtkOriginalX)/xSpacing);
						y=lround((point[1]-vtkOriginalY)/ySpacing);
						z=lround((point[2]-vtkOriginalZ)/zSpacing);
						if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
						{
							*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
							if(minx>x)
								minx=x;
							if(maxx<x)
								maxx=x;
							if(miny>y)
								miny=y;
							if(maxy<y)
								maxy=y;
							if(minz>z)
								minz=z;
							if(maxz<z)
								maxz=z;
							
							
						}
					}
					
				}
			
			[self fixHolesInBarrier: minx :maxx :miny :maxy :minz :maxz :marker];
			
			oViewUserTransform->Translate(0,0,0.5);
			oViewUserTransform->Translate(0,0,-0.5);
			[self updateOView];
			
		}
	}
	[[cViewROIList objectAtIndex:0] removeAllObjects];
	[[axViewROIList objectAtIndex:0] removeAllObjects];
#ifdef VERBOSEMODE
	NSLog( @"converted ROI to seeds");
#endif
}
- (void) fixHolesInBarrier:(int)minx :(int)maxx :(int)miny :(int)maxy :(int)minz :(int)maxz :(short unsigned int) marker
{
	int x,y,z;
	if(minx<maxx&&miny<maxy&&minz<maxz)
	{
		for(z=minz;z<=maxz;z++)
			for(y=miny;y<=maxy;y++)
				for(x=minx;x<=maxx;x++)
					if(*(contrastVolumeData+z*imageSize+y*imageWidth+x) == marker)
					{
						//x,y direction
						if((y+1)<=maxy&& (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) = marker;
							
							
							else if( (x+1)<=maxx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) = marker;
						}
						
						//x,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (x+1)<=maxx && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
						}		
						
						//y,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((y-1)>=miny && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
						}	
						//x,y,z direction
						if((z+1)<=maxz&& (*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) != marker))
						{
							if((y-1)>=miny && (x-1)>minx && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (x-1)>minx && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x-1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							else if((y-1)>=miny && (x+1)<maxx && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker)  && (*(contrastVolumeData+(z+1)*imageSize+(y-1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
							
							else if( (y+1)<=maxy && (x+1)<maxx && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) != marker) && (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z+1)*imageSize+(y+1)*imageWidth+x+1) == marker))
								*(contrastVolumeData+(z+1)*imageSize+y*imageWidth+x) = marker;
							
						}	
						//leak from vertex connection
						if((z-1)>=minz&& (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) != marker))
						{
							if((x-1)>=minx && (y-1)>=miny &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x+1)<=maxx && (y-1)>=miny &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y-1)*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y-1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x-1)>=minx && (y+1)<=maxy &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x-1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x-1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							else if((x+1)<=maxx && (y+1)<=maxy &&  (*(contrastVolumeData+z*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x) == marker) && (*(contrastVolumeData+z*imageSize+(y+1)*imageWidth+x+1) != marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x+1) == marker) && (*(contrastVolumeData+(z-1)*imageSize+(y+1)*imageWidth+x) == marker))
								*(contrastVolumeData+(z-1)*imageSize+y*imageWidth+x) = marker;
							
							
						}	
						
						
					}
	}
}
- (void) checkRootSeeds:(NSArray*)roiList
{
	unsigned int i,j,k;
	ROI* tempROI1,*tempROI2;
	NSString* comments;
	NSString* newComments=[NSString stringWithString:@"root"];
	for(k=0;k<[totalROIList count];k++)
	{
		tempROI1=[totalROIList objectAtIndex: k];
		if([tempROI1 type]==tOval&&![[tempROI1 name] isEqualToString: @"barrier"])
		{
			
			comments=[tempROI1 comments];
			for(i=0;i<[roiList count];i++)
				for(j=0;j<[[roiList objectAtIndex:i] count];j++)
				{
					tempROI2=[[roiList objectAtIndex: i] objectAtIndex: j];
					if([[tempROI2 comments] isEqualToString: comments])
						[tempROI2 setComments:newComments];
					
				}
		}
	}

}
- (void)saveCurrentSeeds
{
	if(!contrastVolumeData)
		return;
	[parent cleanDataOfWizard];
	int size = sizeof(short unsigned int) * imageWidth * imageHeight * imageAmount;
	NSData	*newData = [[NSData alloc] initWithBytesNoCopy:contrastVolumeData length: size freeWhenDone:NO];
	NSMutableDictionary* dic=[parent dataOfWizard];
	[dic setObject:newData forKey:@"SeedMap"];

	[dic setObject:contrastList forKey:@"ContrastList"];
	NSMutableArray* seedsnamearray=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray* rootseedsarray=[NSMutableArray arrayWithCapacity:0];
	unsigned int i;
	for(i=0;i<[totalROIList count];i++)
	{
		ROI* temproi=[totalROIList objectAtIndex:i];
		[seedsnamearray addObject:[temproi name]];
		if([temproi type]==tOval)
			[rootseedsarray addObject:[NSNumber numberWithInt:i]];
		
	}
	[dic setObject:seedsnamearray forKey:@"SeedNameArray"];
	[dic setObject:rootseedsarray forKey:@"RootSeedArray"];
	//[dic setObject:[NSNumber numberWithInt:uniIndex] forKey:@"UniIndex"];
	[parent saveCurrentStep];
	[newData release];
	[parent cleanDataOfWizard];
}
- (void)loadSavedSeeds
{
	NSMutableDictionary* dic=[parent dataOfWizard];
	//NSNumber* lastUniIndex=[dic objectForKey:@"UniIndex"];
	NSData* seedsData=[dic objectForKey:@"SeedMap"];
	NSArray* seednamearray=[dic objectForKey:@"SeedNameArray"];
	NSArray* rootseedarray=[dic objectForKey:@"RootSeedArray"];
	if(contrastVolumeData)
		free(contrastVolumeData);
	contrastVolumeData=(unsigned short*)[seedsData bytes];
	roiReader->SetImportVoidPointer(contrastVolumeData);

	uniIndex=[seednamearray count];//[lastUniIndex intValue];
	[contrastList release];
	contrastList=[dic objectForKey:@"ContrastList"];
	[contrastList retain];

	
	[totalROIList removeAllObjects];
	unsigned int i,j;
	int isarootseed=0;
	for(i=0;i<[seednamearray count];i++)
	{
		isarootseed=0;
		for(j=0;j<[rootseedarray count];j++)
		{
			if([[rootseedarray objectAtIndex:j] intValue]==(signed)i)
				isarootseed=1;
		}
		
		unsigned char textureBuffer[16];
		ROI *newROI;
		if(!isarootseed)
			newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:4 textHeight:4 textName:[seednamearray objectAtIndex:i] positionX:0 positionY:0 spacingX:xSpacing spacingY:ySpacing imageOrigin:NSMakePoint( 0,  0)];
		else
		{
			newROI=[[ROI alloc] initWithType: tOval :xSpacing :ySpacing : NSMakePoint( 0, 0)];
			[newROI setName:[seednamearray objectAtIndex:i]];
		}
		
		RGBColor c;
		for(j=0;j<[contrastList count];j++)
		{
			NSString* namestr=[[contrastList objectAtIndex:j] objectForKey:@"Name"];
			if([namestr isEqualToString:[seednamearray objectAtIndex:i]])
			{
				CGFloat r, g, b;
				
				[[[contrastList objectAtIndex:j] objectForKey:@"Color"] getRed:&r green:&g blue:&b alpha:0L];
				
				
				
				c.red =(short unsigned int) (r * 65535.);
				c.green =(short unsigned int)( g * 65535.);
				c.blue = (short unsigned int)(b * 65535.);
				break;
			}
		}
		
		NSString *indexstr=[NSString stringWithFormat:@"%d",i+1];
		[newROI setComments:indexstr];	
		
		[newROI setColor:c];
		[totalROIList addObject:newROI];
		[newROI release];
		
	}
	
	
}

#pragma mark-
#pragma mark 4. Centerlines functions
- (void)initCenterList
{
	NSMutableDictionary* dic=[parent dataOfWizard];
	if(!cpr3DPaths)
		if([dic objectForKey:@"CenterlinesNames"]&&[dic objectForKey:@"CenterlineArrays"])
			[self loadCenterlinesInPatientsCoordination];
	if(!cpr3DPaths)
		cpr3DPaths=[[NSMutableArray alloc] initWithCapacity:0];
	if(!centerlinesNameArrays)
		centerlinesNameArrays=[[NSMutableArray alloc] initWithCapacity:0];
	if(!centerlinesLengthArrays)
		centerlinesLengthArrays=[[NSMutableArray alloc] initWithCapacity:0];

	
	curvedMPR3DPath = [[NSMutableArray alloc] initWithCapacity: 0];
	reference3Dpoints=[[NSMutableArray alloc] initWithCapacity: 0];
	curvedMPRProjectedPaths=[[NSMutableArray alloc] initWithCapacity: 0];
	[resampleRatioSlider setFloatValue:2.5];
	[resampleRatioText setFloatValue:2.5];
	
	
	DCMPix * curImage= [cViewPixList objectAtIndex:0];
	curvedMPRReferenceLineOfAxis=[[ROI alloc] initWithType: tMesure :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
	[curvedMPRReferenceLineOfAxis setThickness:1.0];
	[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	RGBColor color;
	color.red = 65535;
	color.blue = 65535;
	color.green =0;
	[curvedMPRReferenceLineOfAxis setColor:color];
	[curvedMPRReferenceLineOfAxis setName:[NSString stringWithString: @"Axis Reference Line"] ];
	[curvedMPRReferenceLineOfAxis setROIMode:ROI_sleep];
	MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(0,0)];
	[[curvedMPRReferenceLineOfAxis points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(0,0)];
	[[curvedMPRReferenceLineOfAxis points] addObject: lastPoint];
	[lastPoint release];
	
	
}
- (IBAction)creatCenterLine:(id)sender
{

	needSaveCenterlines=YES;


	if([[creatCenterlineButton title] isEqualToString:@"Create a Centerline"])
	{
		[creatCenterlineButton setTitle:@"Finish Centerline Editing"];
		[ClipUpperCenterlineButton setEnabled:NO];
		[CliplowerCenterlineButton setEnabled:NO];
		[resampleRatioSlider setEnabled:NO];
		[removeCenterlineButton setEnabled:NO];
		[exportCenterlineButton setEnabled:NO];
		[exportCPRButton setEnabled:NO];
		[centerlineTapTips setStringValue:@"Draw a open polygon on the left window while scrolling and rotating. The centerline can be refined using vessel analysis tools later."];
		isDrawingACenterline=1;
		currentPathMode=ROI_drawing;
		if(curvedMPR2DPath)
		{
			[[oViewROIList objectAtIndex:0]	removeAllObjects];		
		}
		isRemoveROIBySelf=1;
		[curvedMPR2DPath release];
		curvedMPR2DPath=nil;
		isRemoveROIBySelf=0;
		if(curvedMPR3DPath)
			[curvedMPR3DPath removeAllObjects];
		
		[self changeCurrentTool:5];
		[self updateOView];
		[self cAndAxViewReset];
		[self updatePageSliders];

		
		
	}
	else
	{
		isDrawingACenterline=0;
		[creatCenterlineButton setTitle:@"Create a Centerline"];
		[ClipUpperCenterlineButton setEnabled:YES];
		[CliplowerCenterlineButton setEnabled:YES];
		[resampleRatioSlider setEnabled:YES];
		
		[removeCenterlineButton setEnabled:YES];
		[exportCenterlineButton setEnabled:YES];
		[exportCPRButton setEnabled:YES];
		[centerlineTapTips setStringValue:@"Choose centerline from the list on the left. Use sliders of the Left Window to control CPR images in the Right Window."];
		currentPathMode=ROI_sleep;
		[self changeCurrentTool:0];
		if(!cpr3DPaths)
			cpr3DPaths=[[NSMutableArray alloc] initWithCapacity:0];
		if(!centerlinesNameArrays)
			centerlinesNameArrays=[[NSMutableArray alloc] initWithCapacity:0];
		if(!centerlinesLengthArrays)
			centerlinesLengthArrays=[[NSMutableArray alloc] initWithCapacity:0];

		NSMutableArray* reversedcenterline=[NSMutableArray arrayWithCapacity:0];
		unsigned i,lastpt=[curvedMPR3DPath count]-1;
		for(i=0;i<[curvedMPR3DPath count];i++)
			[reversedcenterline addObject:[curvedMPR3DPath objectAtIndex: lastpt-i]];
		
		float meanx,meany,meanz;
		meanx=[[reversedcenterline objectAtIndex:0] x]-[[reversedcenterline objectAtIndex:1] x];
		meany=[[reversedcenterline objectAtIndex:0] y]-[[reversedcenterline objectAtIndex:1] y];
		meanz=[[reversedcenterline objectAtIndex:0] z]-[[reversedcenterline objectAtIndex:1] z];
		float firststeplen=sqrt(meanx*meanx+meany*meany+meanz*meanz);
		float resamplesteplen=[resampleRatioSlider floatValue];
		if(firststeplen>resamplesteplen&&[reversedcenterline count]>2)
		{
			
			resamplesteplen+=0.1;
			meanx=((firststeplen-resamplesteplen)*[[reversedcenterline objectAtIndex:0] x]+resamplesteplen*[[reversedcenterline objectAtIndex:1] x])/firststeplen;
			meany=((firststeplen-resamplesteplen)*[[reversedcenterline objectAtIndex:0] y]+resamplesteplen*[[reversedcenterline objectAtIndex:1] y])/firststeplen;
			meanz=((firststeplen-resamplesteplen)*[[reversedcenterline objectAtIndex:0] z]+resamplesteplen*[[reversedcenterline objectAtIndex:1] z])/firststeplen;
			CMIV3DPoint* anewpoint=[[CMIV3DPoint alloc] init];
			[anewpoint setX:meanx];
			[anewpoint setY:meany];
			[anewpoint setZ:meanz];
			[reversedcenterline insertObject:anewpoint atIndex:1];
			[anewpoint release];
		}
		if([reversedcenterline count]>=2)
		{
			[cpr3DPaths addObject:reversedcenterline];
			[centerlinesNameArrays addObject:[NSString stringWithString:@"Centerline"]];
			float pathlen=[self caculateLengthOfAPath:[cpr3DPaths lastObject]];
			[centerlinesLengthArrays addObject:[NSNumber numberWithFloat:pathlen]];
		}		
		[centerlinesList reloadData];

		[centerlinesList selectRow:([cpr3DPaths count]-1) byExtendingSelection: YES];
		[self selectANewCenterline:centerlinesList];


		
	}	
	
	
}
-(void) recaculateAllCenterlinesLength
{
	[centerlinesLengthArrays removeAllObjects];
	unsigned i;
	
	for(i=0;i<[cpr3DPaths count];i++)
	{
		NSMutableArray* temppath=[NSMutableArray arrayWithArray:[cpr3DPaths objectAtIndex:i]];
		[self resample3DPath:[resampleRatioSlider floatValue]:temppath];
		float length=[self caculateLengthOfAPath:temppath];
		[centerlinesLengthArrays addObject:[NSNumber numberWithFloat:length]];
	}
		
	
}
-(double)caculateLengthOfAPath:(NSArray*)apath
{
	int pointNumber=[apath count];
	CMIV3DPoint* a3DPoint;
	double position[3],prepoint[3];
	double path3DLength=0;
	a3DPoint=[apath objectAtIndex: 0];
	prepoint[0]=[a3DPoint x];
	prepoint[1]=[a3DPoint y];
	prepoint[2]=[a3DPoint z];
	
	int i,ii;
	
	for(i=0;i<pointNumber;i++)
	{
		a3DPoint=[apath objectAtIndex: i];
		position[0]=[a3DPoint x];
		position[1]=[a3DPoint y];
		position[2]=[a3DPoint z];	
		path3DLength+=sqrt((position[0]-prepoint[0])*(position[0]-prepoint[0])+(position[1]-prepoint[1])*(position[1]-prepoint[1])+(position[2]-prepoint[2])*(position[2]-prepoint[2]));
		for(ii=0;ii<3;ii++)
		{
			prepoint[ii]=position[ii];
		}
		
	}
	return path3DLength;	
}

- (IBAction)clipCenterLine:(id)sender
{
	int tag=[sender tag];
	int pointNumber;

	NSMutableArray* reversedcenterline=[NSMutableArray arrayWithCapacity:0];
	needSaveCenterlines=YES;
	int i;

	if(!isStraightenedCPR)
	{
		float path2DLength=0;
		float steplength=0;
		float curLocation = [axImageSlider floatValue]/10;
		NSArray* points2D=[curvedMPR2DPath points];
		pointNumber=[points2D count];
		
		for( i = 0; i < pointNumber-1; i++ )
		{
			steplength = [curvedMPR2DPath Length:[[points2D objectAtIndex:i] point] :[[points2D objectAtIndex:i+1] point]];
			
			if(path2DLength+steplength >= curLocation)
				break;
			
			path2DLength += steplength;		
		}
		
		
	}
	else
	{
		CMIV3DPoint* a3DPoint;
		double position[3],prepoint[3];
		double path3DLength=0;
		pointNumber=[curvedMPR3DPath count];
		a3DPoint=[curvedMPR3DPath objectAtIndex: 0];
		prepoint[0]=[a3DPoint x];
		prepoint[1]=[a3DPoint y];
		prepoint[2]=[a3DPoint z];
		
		int ii;
		
		for(i=0;i<pointNumber;i++)
		{
			a3DPoint=[curvedMPR3DPath objectAtIndex: i];
			position[0]=[a3DPoint x];
			position[1]=[a3DPoint y];
			position[2]=[a3DPoint z];	
			path3DLength+=sqrt((position[0]-prepoint[0])*(position[0]-prepoint[0])+(position[1]-prepoint[1])*(position[1]-prepoint[1])+(position[2]-prepoint[2])*(position[2]-prepoint[2]));
			for(ii=0;ii<3;ii++)
			{
				prepoint[ii]=position[ii];
			}
			if(path3DLength>[axImageSlider floatValue])
				break;
			
		}
		
	}
	pointNumber=[curvedMPR3DPath count];
	if(tag==0)
	{
		int j;
		i--;
		for(j=0;j<i;j++)
			[curvedMPR3DPath removeObjectAtIndex:0];
		
		
		int lastpt=[curvedMPR3DPath count]-1;
		for(j=0;j<lastpt+1;j++)
			[reversedcenterline addObject:[curvedMPR3DPath objectAtIndex:lastpt-j]];
		

		unsigned int row = [centerlinesList selectedRow];
		if(row>=0&&row<[cpr3DPaths count])
		{
			
			[cpr3DPaths replaceObjectAtIndex:row withObject:reversedcenterline];
			float length=[self caculateLengthOfAPath:reversedcenterline];
			[centerlinesLengthArrays replaceObjectAtIndex:row withObject:[NSNumber numberWithFloat:length]];
		}
		
		[centerlinesList reloadData];
		[centerlinesList selectRow:row byExtendingSelection: YES];
		[self selectANewCenterline:centerlinesList];
		
		
	}
	else if(tag==1)
	{
		
		int j;
		for(j=i+1;j<pointNumber;j++)
			[curvedMPR3DPath removeLastObject];

		int lastpt=[curvedMPR3DPath count]-1;
		for(j=0;j<lastpt+1;j++)
			[reversedcenterline addObject:[curvedMPR3DPath objectAtIndex:lastpt-j]];	
		unsigned int row = [centerlinesList selectedRow];
		if(row>=0&&row<[cpr3DPaths count])
		{
			
			[cpr3DPaths replaceObjectAtIndex:row withObject:reversedcenterline];
			float length=[self caculateLengthOfAPath:reversedcenterline];
			[centerlinesLengthArrays replaceObjectAtIndex:row withObject:[NSNumber numberWithFloat:length]];
		}
		
		[centerlinesList reloadData];
		[centerlinesList selectRow:row byExtendingSelection: YES];
		[self selectANewCenterline:centerlinesList];		
		
	}
	
}
-(NSMutableArray *) create3DPathFromROIs:(NSString*) roiName
{
	
	NSMutableArray *tempRoiList=[NSMutableArray arrayWithCapacity:0];
	NSMutableArray *temp3DPath=[[NSMutableArray alloc] initWithCapacity: 0];
	
	NSMutableArray *curRoiList = [originalViewController roiList];
	unsigned int i,j,k;
	ROI * tempROI;
	unsigned int pointNum;
	int err=1;
	float x=0,y=0,z=0;
	for(i=0;i<[curRoiList count];i++)
		for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
		{
			tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
			if([tempROI type]==tPlain && [[tempROI name] isEqualToString: roiName])
			{
				[tempRoiList addObject: tempROI];
				
			}
			if([tempROI type]==t2DPoint && [[tempROI name] isEqualToString: roiName])
			{
				err=0;
				
			}
		}
	if(err)
	{
		[tempRoiList removeAllObjects];
		[temp3DPath release];
		return nil;	
	}
	
	
	pointNum=[tempRoiList count];
	
	
	for(i=0;i<pointNum;i++)
	{
		for(j=0;j<[tempRoiList count];j++)
		{
			tempROI=[tempRoiList objectAtIndex: j];
			if([[tempROI comments] intValue]==(signed)i)
			{
				x = [tempROI textureUpLeftCornerX];
				y = [tempROI textureUpLeftCornerY];
				for(k=0;k<[curRoiList count];k++)
					if([[curRoiList objectAtIndex:k] containsObject:tempROI])
					{
						z=k;
						k=[curRoiList count];
					}
				//x = vtkOriginalX + x*xSpacing;
				//y = vtkOriginalY + y*ySpacing;
				//z = vtkOriginalZ + z*zSpacing;
				
				CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
				[new3DPoint setX: x];
				[new3DPoint setY: y];
				[new3DPoint setZ: z];
				[temp3DPath addObject: new3DPoint];
				[new3DPoint release];
				[tempRoiList removeObjectAtIndex:j];
				j=[tempRoiList count];
				
				
			}
		}
		if([temp3DPath count]<=i)
		{
			err=1;
			i=pointNum;
		}
		
		
	}
	
	[tempRoiList removeAllObjects];
	if(!err)
	{
		
		return temp3DPath;
		
	}
	else
	{
		[temp3DPath removeAllObjects];
		[temp3DPath release];
		return nil;	
	}
	
}
- (void) setCurrentCPRPathWithPath:(NSArray*)path:(float)resampelrate
{
	[curvedMPR3DPath removeAllObjects];
	int pointNum=[path count]-1;
	unsigned int i;
	for(i=0;i<[path count];i++)
		[curvedMPR3DPath addObject: [path objectAtIndex: pointNum - i]];
	if(resampelrate>0)
		[self resample3DPath:resampelrate:curvedMPR3DPath];
	if(!curvedMPR2DPath)
	{
		DCMPix * curImage= [oViewPixList objectAtIndex:0];
		curvedMPR2DPath=[[ROI alloc] initWithType: tOPolygon :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
		NSString *roiName = [NSString stringWithString:@"Centerline"];
		RGBColor color;
		color.red = 65535;
		color.blue = 65535;
		color.green =0;
		[curvedMPR2DPath setName:roiName];
		[curvedMPR2DPath setColor: color];
		
		[curvedMPR2DPath setThickness:1.0];
		
		[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	}
	NSMutableArray* points2D=[curvedMPR2DPath points];
	[points2D removeAllObjects];
	for(i=0;i<[curvedMPR3DPath count];i++)
	{
		MyPoint *mypt = [[MyPoint alloc] initWithPoint: NSMakePoint(0,0)];
		
		[points2D addObject: mypt];
		
		[mypt release];
		
		
	}
	[[oViewROIList objectAtIndex: 0] addObject: curvedMPR2DPath];
	int width,height;
	[self createEven3DPathForCPR:&width :&height ];
	
	//currentPathMode=ROI_selectedModify;
	//[self changeCurrentTool:5];
	
	[self updateOView];
	[self updatePageSliders];
	[self cAndAxViewReset];
	[self updatePageSliders];
	
	[vesselAnalysisMeanHu removeAllObjects];
	[vesselAnalysisMaxHu removeAllObjects];
	[vesselAnalysisArea removeAllObjects];
	[vesselAnalysisLongDiameter removeAllObjects];
	[vesselAnalysisShortDiameter removeAllObjects];
	[vesselAnalysisCentersInLongtitudeSection removeAllObjects];
	
}
- (void) resample3DPath:(float)step:(NSMutableArray*)apath
{
	
	if(step<0)
		return;
	int i,origincount;
	origincount=(int)[apath count];
	if(origincount==2)
		return;
	float resamplestep=(step*step);//*4*(xSpacing*xSpacing+ySpacing*ySpacing+zSpacing*xSpacing);
	CMIV3DPoint* a3DPoint;
	float prex,prey,prez,distance3d,nextx,nexty,nextz,totallength=0;
	
	a3DPoint=[apath objectAtIndex: origincount-1];
	prex=[a3DPoint x];
	prey=[a3DPoint y];
	prez=[a3DPoint z];
	
	for(i=origincount-2;i>=0;i--)
	{
		a3DPoint=[apath objectAtIndex: i];
		nextx=[a3DPoint x];
		nexty=[a3DPoint y];
		nextz=[a3DPoint z];
		distance3d=(nextx-prex)*(nextx-prex)+(nexty-prey)*(nexty-prey)+(nextz-prez)*(nextz-prez);
		if(distance3d<resamplestep)
		{
			[apath removeObjectAtIndex:i ];
			
		}
		else
		{
			prex=nextx;	prey=nexty;	prez=nextz;
			totallength+=sqrt(distance3d);
		}
		
	}

	
	
	
	int controlnodenum=(int)[apath count];
	
	double* tdata, *originpath, *originpathx, *originpathy, *originpathz;
	originpath=(double*)malloc(controlnodenum*sizeof(double)*3);
	tdata=(double*)malloc(controlnodenum*sizeof(double));
	originpathx=originpath;
	originpathy=originpath+controlnodenum;
	originpathz=originpath+2*controlnodenum;
	soomthedpathlen=4*totallength/xSpacing;
	if(soomthedpath)
		free(soomthedpath);
	soomthedpath=(double*)malloc(soomthedpathlen*sizeof(double)*3);
	for(i=0;i<controlnodenum;i++)
	{
		a3DPoint=[apath objectAtIndex: i];
		*(originpathx+i)=[a3DPoint x];
		*(originpathy+i)=[a3DPoint y];
		*(originpathz+i)=[a3DPoint z];
		*(tdata+i)=i;
	}
	double tval=0,tstep=(double)controlnodenum/(double)soomthedpathlen;
	
	[apath removeAllObjects];
	
	for(i=0;i<soomthedpathlen;i++)
	{
		*(soomthedpath+i*3)=spline_b_val ( controlnodenum, tdata, originpathx, tval );
		*(soomthedpath+i*3+1)=spline_b_val ( controlnodenum, tdata, originpathy, tval );
		*(soomthedpath+i*3+2)=spline_b_val ( controlnodenum, tdata, originpathz, tval );
		tval+=tstep;
		CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: *(soomthedpath+i*3)];
		[new3DPoint setY: *(soomthedpath+i*3+1)];
		[new3DPoint setZ: *(soomthedpath+i*3+2)];
		[apath addObject: new3DPoint];
		[new3DPoint release];
	}
	free(originpath);
	free(tdata);
	
}
- (IBAction)selectANewCenterline:(id)sender
{
	unsigned int row = [centerlinesList selectedRow];
	if(row>=0&&row<[cpr3DPaths count])
	{
		[curvedMPREven3DPath removeAllObjects];
		[curvedMPREven3DPath release];
		curvedMPREven3DPath=nil;
		
		[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex:row]:[resampleRatioSlider floatValue]];
	}
	
}

- (void) convertCenterlinesToVTKCoordinate:(NSArray*)centerlines
{
	CMIV3DPoint* temppoint;
	float x,y,z;
	unsigned int i,j;
	for(i=0;i<[centerlines count];i++)
		for(j=0;j<[[centerlines objectAtIndex: i] count];j++)
		{
			temppoint=[[centerlines objectAtIndex:i] objectAtIndex: j];
			x= [temppoint x];
			y= [temppoint y];
			z= [temppoint z];
			[temppoint setX: vtkOriginalX + x*xSpacing+xSpacing*0.5];
			[temppoint setY: vtkOriginalY + y*ySpacing+ySpacing*0.5];
			[temppoint setZ: vtkOriginalZ + z*zSpacing+zSpacing*0.5];
			
		}
	
}
- (IBAction)setResampleRatio:(id)sender
{
	[resampleRatioText setFloatValue: [sender floatValue]];
	
	unsigned int row = [centerlinesList selectedRow];
	
	
	if(row>=0&&row<[cpr3DPaths count])
	{
		[curvedMPREven3DPath removeAllObjects];
		[curvedMPREven3DPath release];
		curvedMPREven3DPath=nil;
		[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex:row]:[resampleRatioSlider floatValue]];
	}
	
}
- (IBAction)exportCenterlines:(id)sender
{
	NSArray* pathsList=cpr3DPaths;
	NSArray* namesList=centerlinesNameArrays;
	
	NSArray				*pixList = [originalViewController pixList];
	curPix = [pixList objectAtIndex: 0];
	id waitWindow = [originalViewController startWaitWindow:@"processing"];		
	long size=sizeof(float)*imageWidth*imageHeight*imageAmount;
	float* newVolumeData=(float*)malloc(size);
	if(!newVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		[originalViewController endWaitWindow: waitWindow];
		return ;	
	}
	float* tempinput=[originalViewController volumePtr:0];
	memcpy(newVolumeData,tempinput,size);
	
	NSMutableArray	*newPixList = [NSMutableArray arrayWithCapacity: 0];
	NSMutableArray	*newDcmList = [NSMutableArray arrayWithCapacity: 0];
	NSData	*newData = [NSData dataWithBytesNoCopy:newVolumeData length: size freeWhenDone:YES];
	int z;
	unsigned i;
	for( z = 0 ; z < imageAmount; z ++)
	{
		curPix = [pixList objectAtIndex: z];
		DCMPix	*copyPix = [curPix copy];
		[newPixList addObject: copyPix];
		[copyPix release];
		[newDcmList addObject: [[originalViewController fileList] objectAtIndex: z]];
		
		[[newPixList lastObject] setfImage: (float*) (newVolumeData + imageSize * z)];
	}
	ViewerController *new2DViewer=0L;
	new2DViewer = [originalViewController newWindow	:newPixList
				   :newDcmList
				   :newData];  
	if(new2DViewer)
	{
		NSMutableArray      *newROIList= [new2DViewer roiList];
		curPix = [pixList objectAtIndex: 0];
		for(i=0;i<[pathsList count];i++)
			[self creatROIfrom3DPath:[pathsList objectAtIndex: i]:[namesList objectAtIndex:i]:newROIList];
	}
	
	[originalViewController endWaitWindow: waitWindow];
	if(parent)
	{
		NSMutableArray	*temparray=[[parent dataOfWizard] objectForKey: @"VCList"];
		if(!temparray)
		{
			temparray=[NSMutableArray arrayWithCapacity:0];
			[[parent dataOfWizard] setObject:temparray forKey:@"VCList"];
		}
		[temparray addObject:new2DViewer];
		temparray=[[parent dataOfWizard] objectForKey: @"VCTitleList"];
		if(!temparray)
		{
			temparray=[NSMutableArray arrayWithCapacity:0];
			[[parent dataOfWizard] setObject:temparray forKey:@"VCTitleList"];
		}
		[temparray addObject:[NSString stringWithString:@"Centerlines"]];
	}
	//[[self window] setFrame:screenrect display:YES ];
	[[self window] makeKeyAndOrderFront:parent];
	
}
- (void) creatROIfrom3DPath:(NSArray*)path:(NSString*)name:(NSMutableArray*)newViewerROIList
{
	RGBColor color;
	color.red = 65535;
	color.blue = 0;
	color.green = 0;
	unsigned char * textureBuffer;
	CMIV3DPoint* temp3dpoint;
	
	float xv,yv,zv;
	int x=0,y=0,z=0;
	int pointIndex=0;
	unsigned int j;
	
	for(j=0;j<[path count];j++)
	{
		temp3dpoint=[path objectAtIndex: j];
		xv=[temp3dpoint x];
		yv=[temp3dpoint y];
		zv=[temp3dpoint z];
		x=(int)((xv-vtkOriginalX)/xSpacing);
		y=(int)((yv-vtkOriginalY)/ySpacing);
		z=(int)((zv-vtkOriginalZ)/zSpacing);
		textureBuffer = (unsigned char *) malloc(sizeof(unsigned char ));
		*textureBuffer = 0xff;
		ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:1 textHeight:1 textName:name positionX:x positionY:y spacingX:[curPix pixelSpacingY] spacingY:[curPix pixelSpacingY]  imageOrigin:NSMakePoint( [curPix originX], [curPix originY])];
		
		[[newViewerROIList objectAtIndex: z] addObject:newROI];
		[newROI setColor: color];
		NSString *indexstr=[NSString stringWithFormat:@"%d",pointIndex];
		[newROI setComments:indexstr];	
		pointIndex++;
		[newROI release];
	}
	if([path count])
	{
		temp3dpoint=[path objectAtIndex: 0];
		xv=[temp3dpoint x];
		yv=[temp3dpoint y];
		zv=[temp3dpoint z];
		x=(int)((xv-vtkOriginalX)/xSpacing);
		y=(int)((yv-vtkOriginalY)/ySpacing);
		z=(int)((zv-vtkOriginalZ)/zSpacing);
	}
	NSRect roiRect;
	roiRect.origin.x=x;
	roiRect.origin.y=y;
	roiRect.size.width=roiRect.size.height=1;
	ROI *endPointROI = [[ROI alloc] initWithType: t2DPoint :[curPix pixelSpacingX] :[curPix pixelSpacingY] : NSMakePoint( [curPix originX], [curPix originY])];
	[endPointROI setName:name];
	[endPointROI setROIRect:roiRect];
	[[newViewerROIList objectAtIndex: z] addObject:endPointROI];
	[endPointROI release];
	
}

- (IBAction)removeCenterline:(id)sender
{
	needSaveCenterlines=YES;
	unsigned int row = [centerlinesList selectedRow];
	if(row>=0&&row<[cpr3DPaths count])
	{
		NSMutableArray      * path= [cpr3DPaths objectAtIndex: row];
		[path removeAllObjects];
		[cpr3DPaths removeObjectAtIndex:row];
		[centerlinesNameArrays removeObjectAtIndex:row];
		[centerlinesLengthArrays removeObjectAtIndex:row];
	}		
	[centerlinesList reloadData];
	if(row>=[cpr3DPaths count])
		row=[cpr3DPaths count]-1;
	[centerlinesList selectRow:row byExtendingSelection:NO];
	[self selectANewCenterline: centerlinesList];	
	
}
-(BOOL)loadCenterlinesInPatientsCoordination
{
	float vector[9];
	NSArray				*pixList = [originalViewController pixList];
	DCMPix	*firstPix=[pixList objectAtIndex: 0];
	[firstPix orientation:vector];
	NSMutableDictionary* dic=[parent dataOfWizard];

	if(centerlinesNameArrays)
		[centerlinesNameArrays release];
	centerlinesNameArrays=[dic objectForKey:@"CenterlinesNames"];
	[centerlinesNameArrays retain];
	if(!cpr3DPaths)
		cpr3DPaths=[[NSMutableArray alloc] initWithCapacity:0];
	NSMutableArray* savedCenterlines=[dic objectForKey:@"CenterlineArrays"];
	unsigned i,j;
	for(i=0;i<[savedCenterlines count];i++)
	{
		NSMutableArray* anewcenterline=[NSMutableArray arrayWithCapacity:0];
		for(j=0;j<[[savedCenterlines objectAtIndex:i] count];j++)
		{
			CMIV3DPoint* apoint;
			float x,y,z,ptx,pty,ptz;
			NSNumber* anumber=[[savedCenterlines objectAtIndex:i] objectAtIndex:j];
			ptx=[anumber floatValue];
			j++;
			anumber=[[savedCenterlines objectAtIndex:i] objectAtIndex:j];
			pty=[anumber floatValue];
			j++;
			anumber=[[savedCenterlines objectAtIndex:i] objectAtIndex:j];
			ptz=[anumber floatValue];
			x = ptx * vector[0] + pty * vector[1] + ptz * vector[2];
			y = ptx * vector[3] + pty * vector[4] + ptz * vector[5];
			z = ptx * vector[6] + pty * vector[7] + ptz * vector[8];	
			apoint=[[CMIV3DPoint alloc] init];
			[apoint setX:x];
			[apoint setY:y];
			[apoint setZ:z];
			[anewcenterline addObject:apoint];
			[apoint release];
		}
		[cpr3DPaths addObject:anewcenterline];
	}
	return YES;
}
-(BOOL)saveCenterlinesInPatientsCoordination
{
	float inversedvector[9],vector[9];
	float originpat[3],origin[3];
	NSArray				*pixList = [originalViewController pixList];
	DCMPix	*firstPix=[pixList objectAtIndex: 0];
	[firstPix orientation:vector];
	[self inverseMatrix:vector:inversedvector];
	originpat[0]= origin[0] * inversedvector[0] + origin[1] * inversedvector[1] + origin[2]*inversedvector[2];
	originpat[1]= origin[0] * inversedvector[3] + origin[1] * inversedvector[4] + origin[2]*inversedvector[5];
	originpat[2]= origin[0] * inversedvector[6] + origin[1] * inversedvector[7] + origin[2]*inversedvector[8];
	unsigned i,j;
	NSMutableArray* cpr3DPathsForSave=[NSMutableArray arrayWithCapacity:0];
	for(i=0;i<[cpr3DPaths count];i++)
	{
		NSMutableArray* anewcenterline=[NSMutableArray arrayWithCapacity:0];
		for(j=0;j<[[cpr3DPaths objectAtIndex:i] count];j++)
		{
			CMIV3DPoint* apoint=[[cpr3DPaths objectAtIndex:i] objectAtIndex:j];
			float x,y,z,ptx,pty,ptz;
			x=[apoint x];
			y=[apoint y];
			z=[apoint z];
			ptx = x * inversedvector[0] + y * inversedvector[1] + z*inversedvector[2];
			pty = x * inversedvector[3] + y * inversedvector[4] + z*inversedvector[5];
			ptz = x * inversedvector[6] + y * inversedvector[7] + z*inversedvector[8];	
			[anewcenterline addObject:[NSNumber numberWithFloat:ptx]];
			[anewcenterline addObject:[NSNumber numberWithFloat:pty]];
			[anewcenterline addObject:[NSNumber numberWithFloat:ptz]];
		}
		[cpr3DPathsForSave addObject:anewcenterline];
	}
	[parent cleanDataOfWizard];
	NSMutableDictionary* dic=[parent dataOfWizard];
	
	[dic setObject:cpr3DPathsForSave forKey:@"CenterlineArrays"];
	[dic setObject:centerlinesNameArrays forKey:@"CenterlinesNames"];
	[parent saveCurrentStep];
	return YES;
}
- (IBAction)openABPointFile:(id)sender
{
	NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    
    long result = [oPanel runModalForDirectory:0L file:nil types:[NSArray arrayWithObject:@"txt"]];
    
    if (result == NSOKButton) 
    {
		float x,y,z;
		NSString* pointstr=[NSString stringWithContentsOfFile:[[oPanel filenames] objectAtIndex:0]];
		NSArray* lines=[pointstr componentsSeparatedByString:@"\n"];
		unsigned i;
		
		if([lines count]>3)
		{
			[reference3Dpoints removeAllObjects];
			for(i=0;i<[lines count];i++)
			{
				NSArray* nums=[[lines objectAtIndex:i] componentsSeparatedByString:@" "];
				if([nums  count]<3)
					continue;
				CMIV3DPoint* anewpoint=[[CMIV3DPoint alloc] init];
				anewpoint.x=[[nums objectAtIndex:0] floatValue];
				anewpoint.y=[[nums objectAtIndex:1] floatValue];
				anewpoint.z=[[nums objectAtIndex:2] floatValue];
				[reference3Dpoints insertObject:anewpoint atIndex:0 ];
				[anewpoint release];
				
			}
			[self resample3DPath:0.4:reference3Dpoints];
			if(!referenceCurvedMPR2DPath)
			{
				DCMPix * curImage= [oViewPixList objectAtIndex:0];
				referenceCurvedMPR2DPath=[[ROI alloc] initWithType: tOPolygon :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
				NSString *roiName = [NSString stringWithString:@"Centerline"];
				RGBColor color;
				color.red = 65535;
				color.blue = 0;
				color.green =0;
				[referenceCurvedMPR2DPath setName:roiName];
				[referenceCurvedMPR2DPath setColor: color];
				
				[referenceCurvedMPR2DPath setThickness:1.0];
				
				[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
			}
			
			NSMutableArray* points2D=[referenceCurvedMPR2DPath points];
			[points2D removeAllObjects];
			for(i=0;i<[reference3Dpoints count];i++)
			{
				MyPoint *mypt = [[MyPoint alloc] initWithPoint: NSMakePoint(0,0)];
				
				[points2D addObject: mypt];
				
				[mypt release];
				
				
			}
			[[oViewROIList objectAtIndex: 0] addObject: referenceCurvedMPR2DPath];
			[self updateOView];
			[self cAndAxViewReset];
			[self resetSliders];	
			//if(!cpr3DPaths||[cpr3DPaths count]==0)
			{
				if(!cpr3DPaths)
					cpr3DPaths=[[NSMutableArray alloc] initWithCapacity:0];
				if(!centerlinesNameArrays)
					centerlinesNameArrays=[[NSMutableArray alloc] initWithCapacity:0];
				if(!centerlinesLengthArrays)
					centerlinesLengthArrays=[[NSMutableArray alloc] initWithCapacity:0];
				
				NSMutableArray* reversedcenterline=[NSMutableArray arrayWithCapacity:0];
				unsigned i,lastpt=[reference3Dpoints count]-1;
				for(i=0;i<[reference3Dpoints count];i++)
					[reversedcenterline addObject:[reference3Dpoints objectAtIndex: lastpt-i]];
				[cpr3DPaths addObject:reversedcenterline];
				[centerlinesNameArrays addObject:[NSString stringWithString:@"Centerline"]];
				float pathlen=[self caculateLengthOfAPath:[cpr3DPaths lastObject]];
				[centerlinesLengthArrays addObject:[NSNumber numberWithFloat:pathlen]];
				
				[centerlinesList reloadData];
				
				[centerlinesList selectRow:([cpr3DPaths count]-1) byExtendingSelection: YES];
				[self selectANewCenterline:centerlinesList];
			}
			
		}
		else 
		{
			NSArray* nums=[[lines objectAtIndex:[lines count]-2] componentsSeparatedByString:@" "];
			x=[[nums objectAtIndex:0] floatValue];
			y=[[nums objectAtIndex:1] floatValue];
			z=[[nums objectAtIndex:2] floatValue];	
			oViewBasicTransform->Identity();
			oViewBasicTransform->Translate( x, y, z );
			//oViewBasicTransform->RotateX(-90);
			oViewUserTransform->Identity ();
			
			[self updateOView];
			[self cAndAxViewReset];
			[self resetSliders];	
		}
		
		
	}
	
	
}
- (IBAction)exportCenterlineToText:(id)sender
{
	if(curvedMPREven3DPath==nil)
		return;
	NSSavePanel     *panel = [NSSavePanel savePanel];
	
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"txt"];
	NSString* filename=[NSString stringWithString:@"result"];
	
	if( [panel runModalForDirectory:0L file:filename] == NSFileHandlingPanelOKButton)
	{
		NSString* exportinfo=[NSString stringWithString:@""];
		unsigned int i;
		float	x, y, z;
		CMIV3DPoint* a3DPoint;
		unsigned int amount=[curvedMPREven3DPath count];
		for(i=0;i<amount;i++)
		{
			a3DPoint=[curvedMPREven3DPath objectAtIndex:i];
			x=[a3DPoint x];
			y=[a3DPoint y];
			z=[a3DPoint z];			
			
			exportinfo=[exportinfo stringByAppendingFormat:@"%f %f %f\n",x,y,z];
			
		}
		
		[exportinfo writeToFile:[panel filename] atomically:YES];
		
	}
	
}

#pragma mark-
#pragma mark 5.1 VesselAnalysis functions
- (void)initVesselAnalysis
{
	//axview Polygon
	RGBColor color;
	DCMPix * curImage= [axViewPixList objectAtIndex:0];
	axViewMeasurePolygon=[[ROI alloc] initWithType: tCPolygon :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
	[axViewMeasurePolygon setComments: @"updating"];
	[axViewMeasurePolygon setThickness:0.7];
	[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	color.red = 0;
	color.green = 65000;
	color.blue = 0;
	[axViewMeasurePolygon setColor:color];
	axViewNOResultROI = [[ROI alloc] initWithType: t2DPoint :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
	[axViewNOResultROI setName:@"no segment result"];
	
	//[axViewNOResultROI setComments:[axImageSlider stringValue]];
	//[axViewNOResultROI setROIRect:roiRect];
	
	
	MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(-1,-1)];
	[[axViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(-1,1)];
	[[axViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(1,1)];
	[[axViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(1,-1)];
	[[axViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	
	curImage= [cViewPixList objectAtIndex:0];
	cViewMeasurePolygon= [[ROI alloc] initWithType: tCPolygon :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
	[cViewMeasurePolygon setThickness:0.7];
	[[NSUserDefaults standardUserDefaults] setFloat:defaultROIThickness forKey:@"ROIThickness"];
	
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(-1,-1)];
	[[cViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(-1,1)];
	[[cViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(1,1)];
	[[cViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];
	lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(1,-1)];
	[[cViewMeasurePolygon points] addObject: lastPoint];
	[lastPoint release];

	[cViewMeasurePolygon setColor:color];
	

	
	[axViewAreathText setFloatValue:[axViewAreaSlider floatValue]];
	axViewCostMapWidth=[axViewAreathText floatValue]/xSpacing;
	axViewCostMapHeight=[axViewAreathText floatValue]/ySpacing;
	axLevelSetMapReader->SetWholeExtent(0, axViewCostMapWidth-1, 0, axViewCostMapHeight-1, 0, 0);
	axLevelSetMapReader->SetDataSpacing(1.0,1.0,0);
	axLevelSetMapReader->SetDataOrigin( 0,0,0 );
	axLevelSetMapReader->SetDataExtentToWholeExtent();
	axLevelSetMapReader->SetDataScalarTypeToFloat();
	axViewLowerThresholdFloat=[axViewLowerThresholdSlider floatValue];
	[axViewLowerThresholdText setFloatValue:axViewLowerThresholdFloat];
	axViewUpperThresholdFloat=[axViewUpperThresholdSlider floatValue];
	[axViewUpperThresholdText setFloatValue:axViewUpperThresholdFloat];
	[axViewSigemaText setFloatValue:[axViewSigemaSlider floatValue]];
	[self vesselAnalysisSetStep:vesselAnalysisParaStepSlider];
	
	levelsetCurvatureScaling=[axViewSigemaText floatValue];
	
	isNeedSmoothImgBeforeSegment=NO;
	
	//[vesselAnalysisPlotSourceButton removeAllItems];
	//[vesselAnalysisPlotSourceButton addItemWithTitle: @"Longtitude Section Width(mm)"];
	//[vesselAnalysisPlotSourceButton addItemWithTitle: @"Cross Section Diameter(mm)"];	
	//[vesselAnalysisPlotSourceButton addItemWithTitle: @"Cross Section Area(mm^2)"];
	[vesselAnalysisPlotSourceButton selectItemAtIndex:0];
	vesselAnalysisMeanHu=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisMaxHu=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisArea=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisLongDiameter=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisShortDiameter=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisCentersInLongtitudeSection=[[NSMutableArray alloc] initWithCapacity:0];
	vesselAnalysisLongitudeStep=[vesselAnalysisParaStepSlider floatValue];
	vesselAnalysisCrossSectionStep=cViewSpace[1];
	int showShortAxisInAx=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVShowShortAxisInAxView"];
	if(showShortAxisInAx==0)
	{
		showShortAxisInAx=1;
		[[NSUserDefaults standardUserDefaults] setInteger:showShortAxisInAx forKey:@"CMIVShowShortAxisInAxView"];
	}
	if(showShortAxisInAx==-1)
		[vesselAnalysisParaShowShortAxisOption setState:NSOffState];
	else
		[vesselAnalysisParaShowShortAxisOption setState:NSOnState];
	int showLongAxisInAx=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVShowLongAxisInAxView"];
	if(showLongAxisInAx==0)
	{
		showLongAxisInAx=1;
		[[NSUserDefaults standardUserDefaults] setInteger:showLongAxisInAx forKey:@"CMIVShowLongAxisInAxView"];
	}
	if(showLongAxisInAx==-1)
		[vesselAnalysisParaShowLongAxisOption setState:NSOffState];
	else
		[vesselAnalysisParaShowLongAxisOption setState:NSOnState];
	
	int showMeanAxisInAx=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVShowMeanAxisInAxView"];
	if(showMeanAxisInAx==0)
	{
		showMeanAxisInAx=-1;
		[[NSUserDefaults standardUserDefaults] setInteger:showMeanAxisInAx forKey:@"CMIVShowMeanAxisInAxView"];
	}
	if(showMeanAxisInAx==-1)
		[vesselAnalysisParaShowMeanAxisOption setState:NSOffState];
	else
		[vesselAnalysisParaShowMeanAxisOption setState:NSOnState];
	
}
- (IBAction)changeROIShowingInAxView:(id)sender
{
	int showShortAxisInAx=-1,showLongAxisInAx=-1,showMeanAxisInAx=-1;
	if([vesselAnalysisParaShowShortAxisOption state]==NSOnState)
		showShortAxisInAx=1;

	if([vesselAnalysisParaShowLongAxisOption  state]==NSOnState)
		showLongAxisInAx=1;
			
	if([vesselAnalysisParaShowMeanAxisOption   state]==NSOnState)
		showMeanAxisInAx=1;

	[[NSUserDefaults standardUserDefaults] setInteger:showShortAxisInAx forKey:@"CMIVShowShortAxisInAxView"];
	[[NSUserDefaults standardUserDefaults] setInteger:showLongAxisInAx forKey:@"CMIVShowLongAxisInAxView"];
	[[NSUserDefaults standardUserDefaults] setInteger:showMeanAxisInAx forKey:@"CMIVShowMeanAxisInAxView"];
	[self updateAxViewMeasureAfterROIChanged];
}
- (IBAction)vesselAnalysisSetNewSource:(id)sender
{
	[plotView removeCurCurve];
	if([[NSString stringWithString:@"Cross Section Area(mm^2)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]] && [vesselAnalysisArea count])
		[plotView setACurve:@"area":vesselAnalysisArea:[NSColor greenColor]:vesselAnalysisCrossSectionStep:1.0];
	else if([[NSString stringWithString:@"Cross Section Shortest Diameter(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]] && [vesselAnalysisShortDiameter count])
		[plotView setACurve:@"shortDiameter":vesselAnalysisShortDiameter:[NSColor cyanColor]:vesselAnalysisCrossSectionStep:1.0];
	else if([[NSString stringWithString:@"Longitudinal Section Width(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]])
	{
		if([[cViewROIList objectAtIndex: 0] containsObject:cViewMeasurePolygon] && [vesselAnalysisLongDiameter count])
			[plotView setACurve:@"longitudeDiameter":vesselAnalysisLongDiameter:[NSColor cyanColor]:vesselAnalysisLongitudeStep:1.0];
	}
	else if([[NSString stringWithString:@"Cross Section Mean Hu"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]] && [vesselAnalysisMeanHu count])
		[plotView setACurve:@"MeanHu":vesselAnalysisMeanHu:[NSColor cyanColor]:vesselAnalysisCrossSectionStep:1.0];
	else if([[NSString stringWithString:@"Cross Section Max Hu"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]] && [vesselAnalysisMaxHu count])
		[plotView setACurve:@"MaxHu":vesselAnalysisMaxHu:[NSColor cyanColor]:vesselAnalysisCrossSectionStep:1.0];

}
- (IBAction)vesselAnalysisParaInitialize:(id)sender
{
	
	[vesselAnalysisParaStepText setFloatValue:1.0] ;


	[axViewAreaSlider setFloatValue:15.0] ;	
	[axViewAreathText setFloatValue:15.0] ;	
	[axViewSigemaSlider setFloatValue:30.0] ;	
	[axViewSigemaText setFloatValue:30.0] ;	
	[axViewLowerThresholdSlider setFloatValue:150.0] ;	
	[axViewLowerThresholdText setFloatValue:150.0] ;	
	[axViewUpperThresholdSlider setFloatValue:650.0] ;	
	[axViewUpperThresholdText setFloatValue:650.0] ;
}

- (IBAction)vesselAnalysisSetStep:(id)sender
{
	if(vesselAnalysisParaStepText == sender)
		[vesselAnalysisParaStepSlider setFloatValue:[vesselAnalysisParaStepText floatValue]];
	[vesselAnalysisParaStepText  setFloatValue:[vesselAnalysisParaStepSlider floatValue]];
}

- (IBAction)vesselAnalysisChoiceADefaultParaset:(id)sender
{
	if([[vesselAnalysisParaSetNameCombo stringValue] isEqualToString:@"Coronary arteries"])
	{

		[vesselAnalysisParaStepText setFloatValue:1.0] ;
		[vesselAnalysisParaStepSlider setFloatValue:1.0] ;	
		
		[axViewAreaSlider setFloatValue:15.0] ;	
		[axViewAreathText setFloatValue:15.0] ;	
		[axViewSigemaSlider setFloatValue:30.0] ;	
		[axViewSigemaText setFloatValue:30.0] ;	
		[axViewLowerThresholdSlider setFloatValue:150.0] ;	
		[axViewLowerThresholdText setFloatValue:150.0] ;	
		[axViewUpperThresholdSlider setFloatValue:650.0] ;	
		[axViewUpperThresholdText setFloatValue:650.0] ;	
	}
	else if([[vesselAnalysisParaSetNameCombo stringValue] isEqualToString:@"Aorta"])
	{
		[vesselAnalysisParaStepText setFloatValue:5.0] ;
		[vesselAnalysisParaStepSlider setFloatValue:5.0] ;	
	
		[axViewAreaSlider setFloatValue:100.0] ;	
		[axViewAreathText setFloatValue:100.0] ;	
		[axViewSigemaSlider setFloatValue:80.0] ;	
		[axViewSigemaText setFloatValue:80.0] ;	
		[axViewLowerThresholdSlider setFloatValue:200.0] ;	
		[axViewLowerThresholdText setFloatValue:200.0] ;
		[axViewUpperThresholdSlider setFloatValue:750.0] ;	
		[axViewUpperThresholdText setFloatValue:750.0] ;
	}
	else if([[vesselAnalysisParaSetNameCombo stringValue] isEqualToString:@"Extremity arteries"])
	{

		[vesselAnalysisParaStepText setFloatValue:3.0] ;
		[vesselAnalysisParaStepSlider setFloatValue:3.0] ;	
		
		[axViewAreaSlider setFloatValue:30.0] ;	
		[axViewAreathText setFloatValue:30.0] ;	
		[axViewSigemaSlider setFloatValue:70.0] ;	
		[axViewSigemaText setFloatValue:70.0] ;	
		[axViewLowerThresholdSlider setFloatValue:150.0] ;	
		[axViewLowerThresholdText setFloatValue:150.0] ;	
		[axViewUpperThresholdSlider setFloatValue:650.0] ;	
		[axViewUpperThresholdText setFloatValue:650.0] ;
	}
}
- (void)syncWithPlot
{
	if([plotView curPtX]<[axImageSlider maxValue]&&[plotView curPtX]>=0)
		[axImageSlider setFloatValue:[plotView curPtX] ];
	[self pageAxView:axImageSlider];

	
}
- (void)performCrossSectionAnalysis
{
	[axViewMeasurePolygon setComments: @"updating"];
	if([vesselAnalysisParaAutoRefineOption state]==NSOnState)
		[self refineCenterlineWithCrossSection:self];
	
	
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
	float len;
	float startdistance,enddistance,distanceofstep=[vesselAnalysisParaStepText floatValue];
	NSMutableArray* endPoints=[NSMutableArray arrayWithArray:0];
	
	startdistance=[axImageSlider minValue];
	enddistance=[axImageSlider maxValue];
	
	ROI* temproi;
	[vesselAnalysisMeanHu removeAllObjects];
	[vesselAnalysisMaxHu removeAllObjects];
	[vesselAnalysisArea removeAllObjects];
	[vesselAnalysisShortDiameter removeAllObjects];
	DCMPix* curImage;
	for( len = startdistance ; len < enddistance; len+=distanceofstep)
	{
		
		[axImageSlider setFloatValue:len];
		[self pageAxView:axImageSlider];
		curImage=[axViewPixList objectAtIndex:0];
		unsigned int i;
		temproi=nil;
		for(i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
		{
			temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex:i];
			if([temproi type]==tCPolygon)
				break;
		}
		if(temproi&&[temproi type]==tCPolygon)
		{
			float x1,y1,x2,y2;
			[endPoints removeAllObjects];
			float meandiameter=[self measureAPolygonROI:temproi :endPoints];
			float sdiameter=0;
			if(meandiameter>0)
			{
				CMIV3DPoint* apoint=[endPoints objectAtIndex:1];
				x1=[apoint x];
				y1=[apoint y];
				apoint=[endPoints objectAtIndex:2];
				x2=[apoint x];
				y2=[apoint y];
				sdiameter=sqrt((x1-x2)*(x1-x2)*[curImage pixelSpacingX]*[curImage pixelSpacingX]+(y1-y2)*(y1-y2)*[curImage pixelSpacingY]*[curImage pixelSpacingY]);
			}
			[vesselAnalysisShortDiameter addObject:[NSNumber numberWithFloat:sdiameter]];
			float area=[temproi roiArea];
			[vesselAnalysisArea addObject:[NSNumber numberWithFloat:area]];
			float	rmean, rmax, rmin, rdev, rtotal;
			[[axViewPixList objectAtIndex:0] computeROI:temproi :&rmean :&rtotal :&rdev :&rmin :&rmax];
			[vesselAnalysisMaxHu addObject:[NSNumber numberWithFloat:rmax]];
			[vesselAnalysisMeanHu addObject:[NSNumber numberWithFloat:rmean]];

		}
		else
		{
			[vesselAnalysisShortDiameter addObject:[NSNumber numberWithFloat:0]];
			[vesselAnalysisArea addObject:[NSNumber numberWithFloat:0]];
			[vesselAnalysisMaxHu addObject:[NSNumber numberWithFloat:0]];
			[vesselAnalysisMeanHu addObject:[NSNumber numberWithFloat:0]];
		}
	}
	[originalViewController endWaitWindow: waitWindow];
	vesselAnalysisCrossSectionStep =distanceofstep;
	
}
- (void) performLongitudeSectionAnalysis
{
	[cViewMeasurePolygon setComments: @"updating"];
	[vesselAnalysisLongDiameter removeAllObjects];
	[vesselAnalysisCentersInLongtitudeSection removeAllObjects];
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
	DCMPix* curCViewPix=[cViewPixList objectAtIndex:0];
	float *im=[curCViewPix fImage];
	int i,imwidth=[curCViewPix pwidth], imsize=[curCViewPix pwidth]*[curCViewPix pheight]-1;
	for(i=0;i<imwidth;i++)
	{
		*(im+i)=-1000;
		*(im+imsize-i)=-1000;
	}
	
	[self creatCPRROIListFromFuzzyConnectedness:[cViewROIList objectAtIndex: 0] :[curCViewPix pwidth] :[curCViewPix pheight] :im : cViewSpace[0]:cViewSpace[1]:cViewOrigin[0]:cViewOrigin[1]];
	[cPRView setIndex: 0 ];
	float distanceofstep=1;
	vesselAnalysisMaxLongitudeDiameter=[self measureDiameterOfLongitudePolygon:cViewMeasurePolygon:distanceofstep:[curCViewPix pheight]:cViewSpace[0]:vesselAnalysisLongDiameter:vesselAnalysisCentersInLongtitudeSection];
	vesselAnalysisLongitudeStep=distanceofstep*cViewSpace[1];
	[cViewMeasurePolygon setComments: @"done"];
	[originalViewController endWaitWindow: waitWindow];
}
- (IBAction)vesselAnalysisStart:(id)sender
{
	if([[NSString stringWithString:@"Longitudinal Section Width(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]])
	{
		[self performLongitudeSectionAnalysis];
		[plotView setViewControllor:self];
		[self vesselAnalysisSetNewSource:self];

	}
	else
	{
		[self performCrossSectionAnalysis];
		[plotView setViewControllor:self];
		[self vesselAnalysisSetNewSource:self];
	
	}
	
	
	
	
	

	//[seedsList reloadData];
	
}

- (IBAction)vesselAnalysisShowAllPara:(id)sender
{
	if([vesselAnalysisShowAllParaButton state]!=NSOnState)
	{
		NSRect plotframe= [plotView frame];
		NSRect paraframe=[vesselAnalysisPanel frame];
		[vesselAnalysisPanel setHidden:YES];
		if(plotframe.origin.x+plotframe.size.width<paraframe.origin.x+paraframe.size.width)
		{
			plotframe.size.width=paraframe.origin.x+paraframe.size.width-plotframe.origin.x;
			[plotView setFrame:plotframe];
		}
		
		
	}	
	else
	{
		NSRect plotframe= [plotView frame];
		NSRect paraframe=[vesselAnalysisPanel frame];
		[vesselAnalysisPanel setHidden:NO];
		if(plotframe.origin.x+plotframe.size.width>=paraframe.origin.x)
		{
			plotframe.size.width=paraframe.origin.x-plotframe.origin.x;
			[plotView setFrame:plotframe];
		}
		
	}	
}
- (IBAction)vesselAnalysisSetNeedRefineCenterline:(id)sender
{
	
}

- (IBAction)vesselAnalysisSetUseSmoothFilter:(id)sender
{
}


- (void) creatAxROIListFromFuzzyConnectedness:(NSMutableArray*) roiList :(int) width:(int)height:(float *)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY
{

	[axViewMeasurePolygon setComments: @"updating"];
	//float fuzzyThreshold=[axViewLowerThresholdSlider floatValue];
	
	int x,y,x1,y1;
	x1=(int)((-axViewCostMapWidth*spaceX/2-originX)/spaceX);
	y1=(int)((-axViewCostMapHeight*spaceY/2-originY)/spaceY);
	if(axViewConnectednessCostMapMaxSize<(signed)(axViewCostMapHeight*axViewCostMapWidth*sizeof(float)))
	{
		free(axViewConnectednessCostMap);
		axViewConnectednessCostMapMaxSize=axViewCostMapHeight*axViewCostMapWidth*sizeof(float)*2;
		axViewConnectednessCostMap=(float*)malloc(axViewConnectednessCostMapMaxSize);
		if(!axViewConnectednessCostMap)
			return;
	}
	if(connectednessROIBuffer&&connectednessROIBufferMaxSize<(signed)(axViewCostMapHeight*axViewCostMapWidth*sizeof(char)))
	{
		free(connectednessROIBuffer);
		connectednessROIBufferMaxSize=axViewCostMapHeight*axViewCostMapWidth*sizeof(char)*2;
		connectednessROIBuffer=(unsigned char*)malloc(connectednessROIBufferMaxSize);
		if(!connectednessROIBuffer)
			return;
	}
	for(y=0;y<axViewCostMapHeight;y++)
		for(x=0;x<axViewCostMapWidth;x++)
		{
			if(x1+x>=0 && x1+x<width && y1+y>=0 && y1+y<height)
				*(axViewConnectednessCostMap+y*axViewCostMapWidth+x)
				=*(im+(y+y1)*width+x+x1);
			else
				*(axViewConnectednessCostMap+y*axViewCostMapWidth+x)=minValueInSeries;
		}
				   
   axViewLevelsetRect.origin.x=x1;
   axViewLevelsetRect.origin.y=y1;
   axViewLevelsetRect.size.width =axViewCostMapWidth;
   axViewLevelsetRect.size.height =axViewCostMapHeight;
	
	float initdiameter;
	//if(lastLevelsetDiameter>0)
	//	initdiameter=lastLevelsetDiameter;
	//else
		initdiameter=2.0;
	if(![self thresholdLeveLSetAlgorithm:axViewConnectednessCostMap:axViewCostMapWidth:axViewCostMapHeight:x1:y1:spaceX:spaceY:levelsetCurvatureScaling:axViewLowerThresholdFloat:axViewUpperThresholdFloat:initdiameter:connectednessROIBuffer:axViewMeasurePolygon:0])  	
	{
		/* do not show brush roi of segment area
		if(connectednessROIBuffer)
		{
			unsigned char* textureBuffer= connectednessROIBuffer;
		
			ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:(int)axViewLevelsetRect.size.width textHeight:(int)axViewLevelsetRect.size.height textName:[axImageSlider stringValue] positionX:(int)axViewLevelsetRect.origin.x positionY:(int)axViewLevelsetRect.origin.y spacingX:spaceX spacingY:spaceY imageOrigin:NSMakePoint( originX,  originY)];
			[newROI setComments:[axViewLowerThresholdText stringValue]];
			[roiList addObject:newROI];
			[newROI release];
		}*/
		float roiarea=[axViewMeasurePolygon  roiArea]*100;
		[axViewMeasurePolygon setName:[NSString stringWithFormat:@"Area:%.1fmm^2",roiarea]];
		[axViewMeasurePolygon setComments:[axImageSlider stringValue]];
		[roiList addObject:axViewMeasurePolygon];
		if([vesselAnalysisParaShowShortAxisOption state]==NSOnState||[vesselAnalysisParaShowLongAxisOption state]==NSOnState||[vesselAnalysisParaShowMeanAxisOption state]==NSOnState)
		{
			BOOL needShowMin=NO,needShowMax=NO,needShowMean=NO;
			if([vesselAnalysisParaShowShortAxisOption state]==NSOnState)
				needShowMin=YES;
			if([vesselAnalysisParaShowLongAxisOption state]==NSOnState)
				needShowMax=YES;
			if([vesselAnalysisParaShowMeanAxisOption state]==NSOnState)
				needShowMean=YES;
			[self creatPolygonROIsMeasurementROIsForAImage:roiList:[axViewPixList objectAtIndex:0]:needShowMin:needShowMax:needShowMean];
			
		}

	
	}
	else
	{
		NSRect roiRect;
		roiRect.origin.x=-axViewOrigin[0]/axViewSpace[0];
		roiRect.origin.y=-axViewOrigin[1]/axViewSpace[1];
		roiRect.size.width=roiRect.size.height=1;
		
		[axViewNOResultROI setComments:[axImageSlider stringValue]];
		[axViewNOResultROI setROIRect:roiRect];
		[roiList addObject:axViewNOResultROI];
	}
/*for test
	int i,j;
	float* fimage=[[axViewPixList objectAtIndex:0] fImage];
	int aViewImageWidth=[[axViewPixList objectAtIndex:0] pwidth];
	int aViewImageHeight=[[axViewPixList objectAtIndex:0] pheight];
	for(j=0;j<axViewCostMapHeight;j++)
		for(i=0;i<axViewCostMapWidth;i++)
			*(fimage+(j+aViewImageHeight/4)*aViewImageWidth+i+aViewImageWidth/4)=(*(axViewConnectednessCostMap+j*axViewCostMapWidth+i));	*/
	
	

}
- (void) creatCPRROIListFromFuzzyConnectedness:(NSMutableArray*) roiList :(int) width:(int)height:(float *)im:(float)spaceX:(float)spaceY:(float)originX:(float)originY
{
	
	//float fuzzyThreshold=[axViewLowerThresholdSlider floatValue];
	NSRect rect;
	int x1,y1;
	x1=0;//(int)((-axViewCostMapWidth*spaceX/2-originX)/spaceX);
	y1=0;//(int)((-axViewCostMapHeight*spaceY/2-originY)/spaceY);
	
	rect.origin.x=x1;
	rect.origin.y=y1;
	rect.size.width =width;
	rect.size.height =height;
	if(connectednessROIBuffer&&connectednessROIBufferMaxSize<(signed)(width*height*sizeof(char)))
	{
		free(connectednessROIBuffer);
		connectednessROIBufferMaxSize=width*height*sizeof(char)*2;
		connectednessROIBuffer=(unsigned char*)malloc(connectednessROIBufferMaxSize);
		if(!connectednessROIBuffer)
			return;
	}
	[cViewMeasurePolygon setComments: @"updating"];
	if(![self thresholdLeveLSetAlgorithm:im:width:height:x1:y1:spaceX:spaceY:[axViewSigemaText floatValue]:[axViewLowerThresholdText floatValue]:[axViewUpperThresholdText floatValue]:2:connectednessROIBuffer:cViewMeasurePolygon:1])   
	{
		/*do not show brush roi of segment area
		if(connectednessROIBuffer)
		{
			unsigned char* textureBuffer= connectednessROIBuffer;
			
			ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:(int)rect.size.width textHeight:(int)rect.size.height textName:[cYRotateSlider stringValue] positionX:(int)rect.origin.x positionY:(int)rect.origin.y spacingX:spaceX spacingY:spaceY imageOrigin:NSMakePoint( originX,  originY)];
			[newROI setComments:[axViewLowerThresholdText stringValue]];
			[roiList addObject:newROI];
			[newROI release];

		}*/
		[cViewMeasurePolygon setName:[cYRotateSlider stringValue]];
		[roiList addObject:cViewMeasurePolygon];
				
	}
	[cViewMeasurePolygon setComments: @"done"];
	
}


-(int) thresholdLeveLSetAlgorithm:(float*)imgdata :(int)imgwidth: (int)imgheight :(int)offsetx :(int)offsety :(float)spaceX :(float)spaceY :(float)curscale :(float)lowerthreshold: (float)upperthreshold:(float)initdis :(unsigned char*)outrgndata :(ROI*)outroi:(int)seedmode
{
	typedef   float           InternalPixelType;
	const     unsigned int    Dimension = 2;
	typedef itk::Image< InternalPixelType, Dimension >  InternalImageType;
	typedef unsigned char OutputPixelType;
	typedef itk::Image< OutputPixelType, Dimension > OutputImageType;	
	typedef itk::ImportImageFilter< InternalPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	//itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = imgwidth; // size along X
	itksize[1] = imgheight; // size along Y
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	double origin[ 2 ];
	origin[0] = 0;
	origin[1] = 0;
	importFilter->SetOrigin( origin );
	
	double spacing[ 2 ];
	spacing[0] = spaceX;
	spacing[1] = spaceY;
	importFilter->SetSpacing( spacing );
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( imgdata, itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
	
	typedef   itk::CurvatureAnisotropicDiffusionImageFilter< 	InternalImageType, 	InternalImageType >  SmoothingFilterType;
	SmoothingFilterType::Pointer smoothing = SmoothingFilterType::New();
	smoothing->SetTimeStep( 0.125 );
	smoothing->SetNumberOfIterations(  5 );
	smoothing->SetConductanceParameter( 9.0 );
	
	
	typedef itk::BinaryThresholdImageFilter<InternalImageType, OutputImageType>
    ThresholdingFilterType;
	
	ThresholdingFilterType::Pointer thresholder = ThresholdingFilterType::New();
	
	thresholder->SetLowerThreshold( -1000.0 );
	thresholder->SetUpperThreshold(     0.0 );
	
	thresholder->SetOutsideValue(  0  );
	thresholder->SetInsideValue(  255 );
	
	typedef  itk::FastMarchingImageFilter< InternalImageType, InternalImageType >
    FastMarchingFilterType;
	
	FastMarchingFilterType::Pointer  fastMarching = FastMarchingFilterType::New();
	
	typedef  itk::ThresholdSegmentationLevelSetImageFilter< InternalImageType, 
    InternalImageType > ThresholdSegmentationLevelSetImageFilterType;
	ThresholdSegmentationLevelSetImageFilterType::Pointer thresholdSegmentation =
    ThresholdSegmentationLevelSetImageFilterType::New();
	thresholdSegmentation->SetPropagationScaling( 1.0 );
	thresholdSegmentation->SetCurvatureScaling( curscale );
	thresholdSegmentation->SetMaximumRMSError( 0.02 );
    thresholdSegmentation->SetNumberOfIterations( 400 );
	
	smoothing->SetInput( importFilter->GetOutput() );
	
	thresholdSegmentation->SetUpperThreshold( upperthreshold );
	thresholdSegmentation->SetLowerThreshold(lowerthreshold );
	thresholdSegmentation->SetIsoSurfaceValue(0.0);
	thresholdSegmentation->SetInput( fastMarching->GetOutput() );
	if(isNeedSmoothImgBeforeSegment)
		thresholdSegmentation->SetFeatureImage( smoothing->GetOutput() );
	else
		thresholdSegmentation->SetFeatureImage( importFilter->GetOutput() );
	thresholder->SetInput( thresholdSegmentation->GetOutput() );
	
		

	typedef FastMarchingFilterType::NodeContainer           NodeContainer;
	typedef FastMarchingFilterType::NodeType                NodeType;
	
	NodeContainer::Pointer seeds = NodeContainer::New();
	
	InternalImageType::IndexType  seedPosition;
	
	
	const double initialDistance = initdis;
	
	NodeType node;
	
	const double seedValue = - initialDistance;
	seeds->Initialize();
	int ii;
	if(seedmode==0)
	{
	
		seedPosition[0] = imgwidth/2;//start from center
		seedPosition[1] = imgheight/2;//start from center	
		
		node.SetValue( seedValue * spaceX);
		node.SetIndex( seedPosition );
		

		seeds->InsertElement( 0, node );
	}
	else if(seedmode==1)
	{
		for(ii=1;ii<imgheight/3;ii++)
		{
			seedPosition[0] = imgwidth/2;//start from center
			seedPosition[1] = ii*3;//start from center	
			
			node.SetValue( seedValue * spaceX);
			node.SetIndex( seedPosition );
			
			
			seeds->InsertElement( ii-1, node );
		}
	}
	fastMarching->SetTrialPoints(  seeds  );
	
	fastMarching->SetSpeedConstant( 1.0 );
	fastMarching->SetOutputSize( itksize);
	
	try
    {
		importFilter->Update();
		fastMarching->SetOutputSpacing( importFilter->GetOutput()->GetSpacing() );
		thresholder->Update();
    }
	catch( itk::ExceptionObject & excep )
    {
		NSLog(@"ITK region growing failed!");
		return 1;
    }
	

	unsigned char* ucsegresult=thresholder->GetOutput()->GetBufferPointer();	
	if(outrgndata)
	{
		int buffersize=	imgwidth*imgheight*sizeof(char);
		memcpy(outrgndata,ucsegresult,buffersize);
	}
	float* fsegresult=thresholdSegmentation->GetOutput()->GetBufferPointer();	
	axLevelSetMapReader->SetImportVoidPointer(axViewConnectednessCostMap);
	axLevelSetMapReader->SetImportVoidPointer(fsegresult);
	axLevelSetMapReader->SetWholeExtent(0, imgwidth-1, 0, imgheight-1, 0, 0);
	axLevelSetMapReader->SetDataSpacing(1.0,1.0,0);
	axLevelSetMapReader->SetDataExtentToWholeExtent();
	axLevelSetMapReader->SetDataScalarTypeToFloat();
	vtkPolyData *output = axViewPolygonfilter2->GetOutput();//axROIOutlineFilter->GetOutput();
	output->Update();
	int pointnumber;
	pointnumber=output->GetNumberOfPoints();
	if(pointnumber<3)
		return 1;
	[[outroi points] removeAllObjects];


	for( ii = 0; ii < output->GetNumberOfLines(); ii+=2)
	{
		double p[ 3];
		output->GetPoint(ii, p);
		MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(offsetx+p[0]+0.5, offsety+p[1]+0.5)];
		//MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(offsetx+p[0], offsety+p[1])];
		[[outroi points] addObject: lastPoint];
		[lastPoint release];
		
	}
	ii--;
	if(ii>= output->GetNumberOfLines()) ii-=2;
	for( ; ii >= 0; ii-=2)
	{
		double p[ 3];
		output->GetPoint(ii, p);
		MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(offsetx+p[0]+0.5, offsety+p[1]+0.5)];
		//MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(offsetx+p[0], offsety+p[1])];
		[[outroi points] addObject: lastPoint];
		[lastPoint release];
	}
/*	for test
	int i,j;
	float* fimage=[[oViewPixList objectAtIndex:0] fImage];
	int aViewImageWidth=[[oViewPixList objectAtIndex:0] pwidth];
	int aViewImageHeight=[[oViewPixList objectAtIndex:0] pheight];
	for(j=0;j<axViewCostMapHeight;j++)
		for(i=0;i<axViewCostMapWidth;i++)
			*(fimage+(j+aViewImageHeight/4)*aViewImageWidth+i+aViewImageWidth/4)=(*(fsegresult+j*axViewCostMapWidth+i))*100;
	*/
	
	
	return 0;
	
}


- (IBAction)changAxViewROIArea:(id)sender
{
	if(sender==axViewAreathText)
		[axViewAreaSlider setFloatValue:[axViewAreathText floatValue]];
	else
		[axViewAreathText setFloatValue:[axViewAreaSlider floatValue]];
	axViewCostMapWidth=[axViewAreathText floatValue]/xSpacing;
	axViewCostMapHeight=[axViewAreathText floatValue]/ySpacing;
	axLevelSetMapReader->SetWholeExtent(0, axViewCostMapWidth-1, 0, axViewCostMapHeight-1, 0, 0);
	axLevelSetMapReader->SetDataSpacing(1.0,1.0,0);
	axLevelSetMapReader->SetDataOrigin( 0,0,0 );
	axLevelSetMapReader->SetDataExtentToWholeExtent();
	axLevelSetMapReader->SetDataScalarTypeToFloat();
	if([axViewAreathText floatValue]>maxWidthofCPR)
	{
		maxWidthofCPR=[axViewAreathText floatValue];
		[self updateCView];
	}
	[self updateAxView];
}
- (IBAction)changLeveSetSigema:(id)sender
{
	if(sender==axViewSigemaText)
		[axViewSigemaSlider setFloatValue:[axViewSigemaText floatValue]];
	else
		[axViewSigemaText setFloatValue:[axViewSigemaSlider floatValue]];

	levelsetCurvatureScaling=[axViewSigemaText floatValue];

	[self updateAxView];
}
- (IBAction)setAxViewThreshold:(id)sender
{
	if(sender==axViewLowerThresholdText)
		[axViewLowerThresholdSlider setFloatValue:[axViewLowerThresholdText floatValue]];
	else if(sender==axViewLowerThresholdSlider)
		[axViewLowerThresholdText setFloatValue:[axViewLowerThresholdSlider floatValue]];
	else if(sender==axViewUpperThresholdText)
		[axViewUpperThresholdSlider setFloatValue:[axViewUpperThresholdText floatValue]];
	else if(sender==axViewUpperThresholdSlider)
		[axViewUpperThresholdText setFloatValue:[axViewUpperThresholdSlider floatValue]];
	
	if(axViewLowerThresholdFloat==[axViewLowerThresholdText floatValue]&&axViewUpperThresholdFloat==[axViewUpperThresholdText floatValue])
		return;
	
	axViewLowerThresholdFloat=[axViewLowerThresholdText floatValue];
	axViewUpperThresholdFloat=[axViewUpperThresholdText floatValue];
	

	[self updateAxView];
	
}
-(void)updateCViewMeasureAfterROIChanged
{
	[vesselAnalysisLongDiameter removeAllObjects];
	[vesselAnalysisCentersInLongtitudeSection removeAllObjects];
	
	DCMPix* curCViewPix=[cViewPixList objectAtIndex:0];
	float distanceofstep=1;
	
	vesselAnalysisMaxLongitudeDiameter=[self measureDiameterOfLongitudePolygon:cViewMeasurePolygon:distanceofstep:[curCViewPix pheight]:cViewSpace[0]:vesselAnalysisLongDiameter:vesselAnalysisCentersInLongtitudeSection];
	vesselAnalysisLongitudeStep=distanceofstep*cViewSpace[1];
	[self vesselAnalysisSetNewSource:self];
}
-(void)updateAxViewMeasureAfterROIChanged
{
	BOOL needShowMin=NO,needShowMax=NO,needShowMean=NO;
	if([vesselAnalysisParaShowShortAxisOption state]==NSOnState)
		needShowMin=YES;
	if([vesselAnalysisParaShowLongAxisOption state]==NSOnState)
		needShowMax=YES;
	if([vesselAnalysisParaShowMeanAxisOption state]==NSOnState)
		needShowMean=YES;
	unsigned i=0;
	for(i=0;i<[[axViewROIList objectAtIndex:0] count];i++)
	{
		if([[axViewROIList objectAtIndex:0] objectAtIndex:i]!=axViewMeasurePolygon)
		{
			[[axViewROIList objectAtIndex:0] removeObjectAtIndex:i];
			i--;
		}
	}
	
	[self creatPolygonROIsMeasurementROIsForAImage:[axViewROIList objectAtIndex:0]:[axViewPixList objectAtIndex:0]:needShowMin:needShowMax:needShowMean];
	
}
- (IBAction)refineCenterline:(id)sender
{
		if([[NSString stringWithString:@"Longitudinal Section Width(mm)"]  isEqualToString:[vesselAnalysisPlotSourceButton titleOfSelectedItem]])
		{
			[self refineCenterlineWithLongitudeSection:sender];
		}
		else
		{
			[self refineCenterlineWithCrossSection:sender];
		}
}
- (IBAction)refineCenterlineWithLongitudeSection:(id)sender
{
	[cViewMeasurePolygon setComments: @"updating"];
	if([[cViewROIList objectAtIndex:0] containsObject:cViewMeasurePolygon])
	{
		[vesselAnalysisLongDiameter removeAllObjects];
		[vesselAnalysisCentersInLongtitudeSection removeAllObjects];
		
		DCMPix* curCViewPix=[cViewPixList objectAtIndex:0];
		float distanceofstep=1;
		
		vesselAnalysisMaxLongitudeDiameter=[self measureDiameterOfLongitudePolygon:cViewMeasurePolygon:distanceofstep:[curCViewPix pheight]:cViewSpace[0]:vesselAnalysisLongDiameter:vesselAnalysisCentersInLongtitudeSection];
		vesselAnalysisLongitudeStep=distanceofstep*cViewSpace[1];
	}
	else
	{
		[self performLongitudeSectionAnalysis];
	}
	
	int width,height;
	int i,ii;
	double position[3];
	double* outputcenterlinexyz;
	width=maxWidthofCPR/cViewSpace[0];
	height=[curvedMPREven3DPath count];
	outputcenterlinexyz=(double*)malloc(sizeof(double)*height*3);
	CMIV3DPoint* a3DPoint;
	for(i=0;i<height;i++)
	{
		a3DPoint=[curvedMPREven3DPath objectAtIndex:i];
		*(outputcenterlinexyz+i*3)=[a3DPoint x];
		*(outputcenterlinexyz+i*3+1)=[a3DPoint y];
		*(outputcenterlinexyz+i*3+2)=[a3DPoint z];
	}
	//create minimum rotate normals 
	double* outputcenterlinenormals=(double*)malloc(sizeof(double)*height*3);
	if([self generateSlidingNormals:height:outputcenterlinexyz:outputcenterlinenormals]==0)
		return;
	
	// create a narrow 3d ribbon from the centerline and use this ribbon to get cross-section line from each pair of point along this ribbon 
	double* unitribbonxyz=(double*)malloc(sizeof(double)*height*3);
	float rotateangle=[cYRotateSlider floatValue];
	if(rotateangle<0)
		rotateangle+=360;
	rotateangle=rotateangle*deg2rad;
	if([self generateUnitRobbin:height:outputcenterlinexyz:outputcenterlinenormals:unitribbonxyz:rotateangle:cViewSpace[0]]==0)
		return;
	

	int j;

	NSMutableArray* newCenterline=[NSMutableArray arrayWithArray:0];
	float deltax;
	for(j=0;j<height;j++)
	{
		
			
		if(j<(int)[vesselAnalysisCentersInLongtitudeSection count]-2)
		{
			if(j>=0&&j<3)
				deltax=[[vesselAnalysisCentersInLongtitudeSection objectAtIndex:3] floatValue];
			else
				deltax=[[vesselAnalysisCentersInLongtitudeSection objectAtIndex:j] floatValue];
			if(deltax<0)
				deltax=width/2;
		}
		else
			deltax=width/2;
		for(ii=0;ii<3;ii++)
			position[ii]=*(outputcenterlinexyz+j*3+ii)+(deltax-width/2)*(*(unitribbonxyz+j*3+ii));
		CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: position[0]];
		[new3DPoint setY: position[1]];
		[new3DPoint setZ: position[2]];
		[newCenterline insertObject:new3DPoint atIndex:0 ];
		
	}

	unsigned int row = [centerlinesList selectedRow];
	if(row>=0&&row<[cpr3DPaths count])
	{
		[curvedMPREven3DPath removeAllObjects];
		[curvedMPREven3DPath release];
		curvedMPREven3DPath=nil;
		[cpr3DPaths removeObjectAtIndex:row];
		[cpr3DPaths insertObject:newCenterline atIndex:row];
		[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex:row]:1.0];
	}
	
	
	free(outputcenterlinexyz);free(outputcenterlinenormals);free(unitribbonxyz);
	[self performLongitudeSectionAnalysis];
	[self vesselAnalysisSetNewSource:self];
	[cViewMeasurePolygon setComments: @"done"];
	return;	
	
	
}
- (IBAction)refineCenterlineWithCrossSection:(id)sender
{
	[axViewMeasurePolygon setComments: @"updating"];
	if(!isStraightenedCPR)
		[self switchStraightenedCPR:straightenedCPRButton];
	
	id waitWindow = [originalViewController startWaitWindow:@"refine centerline"];	
	float origin[3];
	float len;
	float startdistance,enddistance,refinedis,distanceofstep=[vesselAnalysisParaStepText floatValue];
	vtkTransform* currentTransform;
	if(isStraightenedCPR)
		currentTransform=axViewTransformForStraightenCPR;
	else
		currentTransform=axViewTransform;
	
	startdistance=[axImageSlider minValue];
	enddistance=[axImageSlider maxValue];
	refinedis=[axImageSlider minValue];//[axImageSlider floatValue];
	NSMutableArray* newCenterline=[NSMutableArray arrayWithArray:0];
	for( len = startdistance ; len < enddistance; len+=distanceofstep)
	{
		
		[axImageSlider setFloatValue:len];
		[self pageAxView:axImageSlider];

		int center[2];
		float meandia=[self findingCenterOfSegment:connectednessROIBuffer :axViewCostMapWidth :axViewCostMapHeight:center]*2;
		if(meandia==0)
		{
			origin[0]=0;
			origin[1]=0;
			origin[2]=0;
			
		}
		else
		{
			
			center[0]+=(int)((-axViewCostMapWidth*axViewSpace[0]/2-axViewOrigin[0])/axViewSpace[0]);
			center[1]+=(int)((-axViewCostMapHeight*axViewSpace[1]/2-axViewOrigin[1])/axViewSpace[1]);

			
			origin[0]=axViewOrigin[0]+center[0]*axViewSpace[0];
			origin[1]=axViewOrigin[1]+center[1]*axViewSpace[1];
			origin[2]=0;
		
		}			
		currentTransform->TransformPoint(origin,origin);
		CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: origin[0]];
		[new3DPoint setY: origin[1]];
		[new3DPoint setZ: origin[2]];
		[newCenterline insertObject:new3DPoint atIndex:0 ];
		[new3DPoint release];
	}
	unsigned int row = [centerlinesList selectedRow];
	if(row>=0&&row<[cpr3DPaths count])
	{
		[curvedMPREven3DPath removeAllObjects];
		[curvedMPREven3DPath release];
		curvedMPREven3DPath=nil;
		[cpr3DPaths removeObjectAtIndex:row];
		[cpr3DPaths insertObject:newCenterline atIndex:row];
		[self setCurrentCPRPathWithPath:[cpr3DPaths objectAtIndex:row]:[resampleRatioSlider floatValue]];
	}
	[self performCrossSectionAnalysis];
	[self vesselAnalysisSetNewSource:self];
	[originalViewController endWaitWindow: waitWindow];
	//[seedsList reloadData];
}
-(float)findingCenterOfSegment:(unsigned char*)buffer:(int)width:(int)height:(int*)center
{
	int buffersize=	width*height;
	int i;
	for(i=0;i<buffersize;i++)
		buffer[i]=!buffer[i];
	
	typedef  unsigned char   InputPixelType;
	typedef  float  OutputPixelType;
	const     unsigned int    Dimension = 2;
	typedef itk::Image< InputPixelType,  2 >   InputImageType;
	typedef itk::Image< OutputPixelType, 2 >   OutputImageType;
	
	typedef itk::ImportImageFilter< InputPixelType, Dimension > ImportFilterType;
	
	ImportFilterType::Pointer importFilter;
	
	//itk::MultiThreader::SetGlobalDefaultNumberOfThreads( MPProcessors());
	
	importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType itksize;
	itksize[0] = width; // size along X
	itksize[1] = height; // size along Y
	ImportFilterType::IndexType start;
	start.Fill( 0 );
	ImportFilterType::RegionType region;
	region.SetIndex( start );
	region.SetSize( itksize );
	importFilter->SetRegion( region );
	double origin[ 2 ];
	origin[0] = 0;
	origin[1] = 0;
	importFilter->SetOrigin( origin );
	
	double spacing[ 2 ];
	spacing[0] = axViewSpace[0];
	spacing[1] = axViewSpace[1];
	importFilter->SetSpacing( spacing );
	
	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer( buffer, itksize[0] * itksize[1], importImageFilterWillOwnTheBuffer);
	
	
	
	
	typedef itk::DanielssonDistanceMapImageFilter<	InputImageType, OutputImageType >  FilterType;
	FilterType::Pointer filter = FilterType::New();
	
	filter->SetInput( importFilter->GetOutput() );
	filter->InputIsBinaryOn();
	
	try
    {
		filter->Update();
    }
	catch( itk::ExceptionObject & excep )
    {
		NSLog(@"ITK distance map failed!");
		return -1;
    }
	float* fsegresult=filter->GetOutput()->GetBufferPointer();	
	int maxindex=0;
	float maxdis=*fsegresult;
	for(i=0;i<buffersize;i++)
		if(*(fsegresult+i)>maxdis)
		{
			maxindex=i;
			maxdis=*(fsegresult+i);
		}
	
	for(i=0;i<buffersize;i++)
		buffer[i]=!buffer[i];
	center[1]=maxindex/width;
	center[0]=maxindex-center[1]*width;
	
	
	return maxdis;
}
-(void)findingGravityCenterOfSegment:(unsigned char*)buffer:(int)width:(int)height:(int*)center
{
	int i,j;
	float totalx=0,totaly=0,totalpoint=0;
	for(j=0;j<height;j++)
		for(i=0;i<width;i++)
		{
			if(*(buffer+j*width+i))
			{
				totalx+=i;
				totaly+=j;
				totalpoint++;
			}
		}
	if(totalpoint)
	{
		center[0]=totalx/totalpoint;
		center[1]=totaly/totalpoint;
	}
	else
	{
		center[0]=0;
		center[1]=0;
	}
	return;
}

#pragma mark-
#pragma mark 5.2 Cross Section Polygon ROI functions
- (int) showPolygonMeasurementPanel:(ViewerController *) vc: (CMIV_CTA_TOOLS*) owner
{
	
	originalViewController=vc;	
	parent = owner;
	[NSBundle loadNibNamed:@"Scissors_Panel" owner:self];
	screenrect=[[[originalViewController window] screen] visibleFrame];
	screenrect.size.width=551;
	screenrect.size.height=266;
	
	[NSApp beginSheet: polygonMeasureWindow modalForWindow:[originalViewController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	
	[polygonMeasureWindow setFrame:screenrect display:YES ];
	
	return 0;
}
- (void)  creatPolygonROIsMeasurementROIsForViewController
{
	
	NSArray      *roiList= [originalViewController roiList];
	NSArray      *pixList=[originalViewController pixList];
	
	
	unsigned int i;
	BOOL needAddMin=NO,needAddMax=NO,needAddMean=NO;
	if([caculateMinDiameterButton state]==NSOnState)
		needAddMin=YES;
	if([caculateMaxDiameterButton state]==NSOnState)
		needAddMax=YES;
	if([caculateMeanDiameterButton state]==NSOnState)
		needAddMean=YES;
	

	for(i=0;i<[roiList count];i++)
		[self creatPolygonROIsMeasurementROIsForAImage:[roiList objectAtIndex:i] :[pixList objectAtIndex:i]:needAddMin:needAddMax:needAddMean];
	
	return ;
}
-(void)creatPolygonROIsMeasurementROIsForAImage:(NSMutableArray*)imgroilist:(DCMPix*) curImage:(BOOL)addMin:(BOOL)addMax:(BOOL)addMean
{
	ROI* temproi;
	RGBColor color;
	NSMutableArray* endPoints=[NSMutableArray arrayWithArray:0];
	unsigned ii;
	for(ii=0;ii<[imgroilist count];ii++)
	{
		temproi=[imgroilist objectAtIndex:ii];
		if([temproi type]==tCPolygon)
		{
			float x1,y1,x2,y2;
			
			[endPoints removeAllObjects];
			float lenofMeanDiameter=[self measureAPolygonROI:temproi:endPoints];
			if(lenofMeanDiameter<=0)
				continue;
			CMIV3DPoint* apoint=[endPoints objectAtIndex:1];
			x1=[apoint x];
			y1=[apoint y];
			apoint=[endPoints objectAtIndex:2];
			x2=[apoint x];
			y2=[apoint y];
			
			float mindiameter=sqrt((x1-x2)*(x1-x2)*[curImage pixelSpacingX]*[curImage pixelSpacingX]+(y1-y2)*(y1-y2)*[curImage pixelSpacingY]*[curImage pixelSpacingY]);
			ROI* minDiameterROI=[[ROI alloc] initWithType: tMesure :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
			lastLevelsetDiameter=mindiameter;
			[minDiameterROI setName:[NSString stringWithFormat: @"min:%.1fmm",mindiameter] ];
			[minDiameterROI setROIMode:ROI_sleep];
			MyPoint* lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(x1,y1)];
			[[minDiameterROI points] addObject: lastPoint];
			[lastPoint release];
			lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(x2,y2)];
			[[minDiameterROI points] addObject: lastPoint];
			[lastPoint release];

			color.red = 65000;
			color.green = 0;
			color.blue = 0;
			[minDiameterROI setColor:color];
			[minDiameterROI setComments: @"Polygon Measurement:min Axis"];
			
			apoint=[endPoints objectAtIndex:3];
			x1=[apoint x];
			y1=[apoint y];
			apoint=[endPoints objectAtIndex:4];
			x2=[apoint x];
			y2=[apoint y];
			
			ROI* maxDiameterROI=[[ROI alloc] initWithType: tMesure :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
			[maxDiameterROI setName:[NSString stringWithFormat: @"max:%.1fmm",sqrt((x1-x2)*(x1-x2)*[curImage pixelSpacingX]*[curImage pixelSpacingX]+(y1-y2)*(y1-y2)*[curImage pixelSpacingY]*[curImage pixelSpacingY])] ];
			[maxDiameterROI setROIMode:ROI_sleep];
			lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(x1,y1)];
			[[maxDiameterROI points] addObject: lastPoint];
			[lastPoint release];
			lastPoint=[[MyPoint alloc] initWithPoint:NSMakePoint(x2,y2)];
			[[maxDiameterROI points] addObject: lastPoint];
			[lastPoint release];
			color.red = 0;
			color.green = 65000;
			color.blue = 0;
			[maxDiameterROI setColor:color];
			[maxDiameterROI setComments: @"Polygon Measurement:max Axis"];
			
			ROI* meanDiameterROI=[[ROI alloc] initWithType: tOval :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
			[meanDiameterROI setName:[NSString stringWithFormat: @"mean:%.1fmm",lenofMeanDiameter*[curImage pixelSpacingX]] ];
			[meanDiameterROI setROIMode:ROI_sleep];

			color.red = 0;
			color.green = 0;
			color.blue = 65000;
			[meanDiameterROI setColor:color];
			[meanDiameterROI setComments: @"Polygon Measurement:mean Axis"];
			apoint=[endPoints objectAtIndex:0];
			NSRect roirect;
			roirect.origin.x=[apoint x];
			roirect.origin.y=[apoint y];
			roirect.size.width=lenofMeanDiameter/2.0;
			roirect.size.height=lenofMeanDiameter/2.0;
			[meanDiameterROI setROIRect:roirect];
			if(addMin)
				[imgroilist addObject:minDiameterROI];
			[minDiameterROI release];
			if(addMax)
				[imgroilist addObject:maxDiameterROI];
			[maxDiameterROI release];
			if(addMean)
				[imgroilist addObject:meanDiameterROI];
			[meanDiameterROI release];
		}
	}			
	
}
- (float)signedPolygonArea:(NSArray*)ptarray
{

	unsigned int i,j;
	float area = 0;
	NSPoint pt1,pt2;
	
	for (i=0;i<[ptarray count];i++) {
		j = (i + 1) % [ptarray count];
		pt1=[[ptarray objectAtIndex:i] point];
		pt2=[[ptarray objectAtIndex:j] point];
		area += pt1.x * pt2.y;
		area -= pt1.y * pt2.x;
	}
	area /= 2.0;
	
	return(area);
	//return(area < 0 ? -area : area); for unsigned
}


/* CENTROID */

-(NSPoint)polygonCenterOfMass:(NSArray*)ptarray
{
	float cx=0,cy=0;
	float A=[self signedPolygonArea:ptarray];
	NSPoint res;
	unsigned int i,j;
	NSPoint pt1,pt2;
	float factor=0;
	for (i=0;i<[ptarray count];i++) {
		j = (i + 1) % [ptarray count];
		pt1=[[ptarray objectAtIndex:i] point];
		pt2=[[ptarray objectAtIndex:j] point];
		factor=(pt1.x*pt2.y-pt2.x*pt1.y);
		cx+=(pt1.x+pt2.x)*factor;
		cy+=(pt1.y+pt2.y)*factor;
	}
	A*=6.0;
	factor=1.0/A;
	cx*=factor;
	cy*=factor;
	res.x=cx;
	res.y=cy;
	return res;
}
-(float) measureAPolygonROI:(ROI*)aPolygon:(NSMutableArray*)axisesPoints
{
	float distance[360];
	float diameterpts[720];
	
	
	NSArray* splinepoints=[aPolygon splinePoints];
	int j,ptnumber;
	ptnumber=[splinepoints count];
	if(ptnumber<5)
		return 0;
	float *floatpoints=(float*)malloc(ptnumber*sizeof(float)*3);
	float *floatangles=floatpoints+2*ptnumber;
	float xmean=0, ymean=0;
	NSPoint gravitycenter=[self polygonCenterOfMass:splinepoints];
	
	xmean=gravitycenter.x;
	ymean=gravitycenter.y;

	for(j=0;j<ptnumber;j++)
	{
		*(floatpoints+j*2)=[[splinepoints objectAtIndex:j] point].x;
		*(floatpoints+j*2+1)=[[splinepoints objectAtIndex:j] point].y;

		*(floatpoints+j*2)-=xmean;
		*(floatpoints+j*2+1)-=ymean;
		if(*(floatpoints+j*2)!=0)
			*(floatangles+j)=atan((*(floatpoints+j*2+1))/(*(floatpoints+j*2)))/ deg2rad;
		else
			*(floatangles+j)=90;
		if(*(floatpoints+j*2)<0)
			*(floatangles+j)+=180;
		else if(*(floatpoints+j*2+1)<0)
			*(floatangles+j)+=360;
		
		
	}
	
	for(j=0;j<360;j++)
	{
		int k;
		
		float x,y;
		float x1,y1,x2,y2;
		distance[j]=-1;
		for(k=0;k<=ptnumber;k++)
		{
			float minangle,maxangle,tempangle;
			if(floatangles[k%ptnumber]<floatangles[(k+1)%ptnumber])
			{
				minangle=floatangles[k%ptnumber];
				maxangle=floatangles[(k+1)%ptnumber];
			}
			else
			{
				maxangle=floatangles[k%ptnumber];
				minangle=floatangles[(k+1)%ptnumber];
				
			}
			if(maxangle-minangle>180)
			{
				if(j<90)
				{
					tempangle=maxangle-360;
					maxangle=minangle;
					minangle=tempangle;
				}
				else
				{
					tempangle=minangle+360;
					minangle=maxangle;
					maxangle=tempangle;
				}
			}
			if(minangle<=j&&j<=maxangle)
			{
				x1=floatpoints[(k%ptnumber)*2];
				y1=floatpoints[(k%ptnumber)*2+1];
				x2=floatpoints[((k+1)%ptnumber)*2];
				y2=floatpoints[((k+1)%ptnumber)*2+1];
				if(j==90||j==270)
				{
					x=0;
					if(x2!=x1)
						y=(y1*x2-y2*x1)/(x2-x1);
					else
						y=y1;
				}
				else
				{
					float k1,k2;
					k2=tan(j*deg2rad);
					
					if(x1==x2)
					{
						x=x1;
					}
					else
					{
						
						k1=(y2-y1)/(x2-x1);
						if(k2==k1)
							x=x1;
						else
							x=((y1*x2-y2*x1)/(x2-x1))/(k2-k1);
					}
					y=x*k2;
					
				}
				float tempdis=sqrt(x*x+y*y);
				if(distance[j]==-1||tempdis<distance[j])
				{
					distance[j]=tempdis;
					diameterpts[j*2]=x;
					diameterpts[j*2+1]=y;
				}
			}
			
			
		}
	}
	float mindiameter,maxdiameter,meandiameter=0;
	int minangle,maxangle;
	minangle=maxangle=0;
	mindiameter=maxdiameter=sqrt((diameterpts[0]-diameterpts[360])*(diameterpts[0]-diameterpts[360])+(diameterpts[1]-diameterpts[361])*(diameterpts[1]-diameterpts[361]));
	for(j=0;j<180;j++)
	{
		distance[j]=sqrt((diameterpts[2*j]-diameterpts[2*j+360])*(diameterpts[2*j]-diameterpts[2*j+360])+(diameterpts[2*j+1]-diameterpts[2*j+361])*(diameterpts[2*j+1]-diameterpts[2*j+361]));
		if(mindiameter>distance[j])
		{
			mindiameter=distance[j];
			minangle=j;
		}
		if(maxdiameter<distance[j])
		{
			maxdiameter=distance[j];
			maxangle=j;
		}
		meandiameter+=distance[j];
	}
	meandiameter/=180;
	if(axisesPoints)
	{
		CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: xmean];
		[new3DPoint setY: ymean];
		[axisesPoints addObject: new3DPoint];
		[new3DPoint release];
		
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: diameterpts[2*minangle]+xmean];
		[new3DPoint setY: diameterpts[2*minangle+1]+ymean];
		[axisesPoints addObject: new3DPoint];
		[new3DPoint release];
		
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: diameterpts[2*minangle+360]+xmean];
		[new3DPoint setY: diameterpts[2*minangle+361]+ymean];
		[axisesPoints addObject: new3DPoint];
		[new3DPoint release];
		
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: diameterpts[2*maxangle]+xmean];
		[new3DPoint setY: diameterpts[2*maxangle+1]+ymean];
		[axisesPoints addObject: new3DPoint];
		[new3DPoint release];
		
		new3DPoint=[[CMIV3DPoint alloc] init] ;
		[new3DPoint setX: diameterpts[2*maxangle+360]+xmean];
		[new3DPoint setY: diameterpts[2*maxangle+361]+ymean];
		[axisesPoints addObject: new3DPoint];
		[new3DPoint release];
	}	
	free(floatpoints);
	return meandiameter;
	
}
- (float) measureDiameterOfLongitudePolygon:(ROI*)aroi:(float)step:(float)length :(float)xspace :(NSMutableArray*)diameterarray:(NSMutableArray*)centerptarray
{
	int buffersize=length/step;
	NSArray* splinepoints=[aroi splinePoints];
	int i;
	float miny,maxy;
	float diameter,centerx,maxdiameter=0;
	int minyindex=0,maxyindex=0;
	miny=maxy=[[splinepoints objectAtIndex:0] point].y;
	int roiarraysize=[splinepoints count];
	for(i=1;i<roiarraysize;i++)
	{
		if([[splinepoints objectAtIndex:i] point].y<miny)
		{
			miny=[[splinepoints objectAtIndex:i] point].y;
			minyindex=i;
		}
		if([[splinepoints objectAtIndex:i] point].y>maxy)
		{
			maxy=[[splinepoints objectAtIndex:i] point].y;
			maxyindex=i;
		}
	}
	int leftborderfromindex,leftbordertoinedex;
	int rightborderfromindex,rightbordertoindex;
	leftborderfromindex=minyindex;
	leftbordertoinedex=maxyindex;
	if(leftborderfromindex>leftbordertoinedex)
		leftbordertoinedex+=roiarraysize;
	float leftmeamx=0,rightmeanx=0;
	for(i=leftborderfromindex;i<leftbordertoinedex;i++)
	{
		leftmeamx+=[[splinepoints objectAtIndex:i%roiarraysize] point].x;
	}
	leftmeamx=leftmeamx/(leftbordertoinedex-leftborderfromindex);

	rightborderfromindex=maxyindex;
	rightbordertoindex=minyindex;
	if(rightborderfromindex>rightbordertoindex)
		rightbordertoindex+=roiarraysize;
	for(i=rightborderfromindex;i<rightbordertoindex;i++)
	{
		rightmeanx+=[[splinepoints objectAtIndex:i%roiarraysize] point].x;
	}
	rightmeanx=rightmeanx/(rightbordertoindex-rightborderfromindex);
	if(leftmeamx>rightmeanx)
	{
		leftborderfromindex=maxyindex ;
		leftbordertoinedex=minyindex;
		if(leftborderfromindex>leftbordertoinedex)
			leftbordertoinedex+=roiarraysize;
		rightborderfromindex=minyindex;
		rightbordertoindex=maxyindex;
		if(rightborderfromindex>rightbordertoindex)
			rightbordertoindex+=roiarraysize;
	}
	
	float currenty=0;
	int j;
	float x1,x2,y1,y2,x;
	float meandiameter=0;
	for(i=0;i<buffersize;i++,currenty+=step)
	{
		float maxleftx=0;
		float minrightx=10000;
		for(j=leftborderfromindex;j<leftbordertoinedex;j++)
		{
			x1=[[splinepoints objectAtIndex:j%roiarraysize] point].x;
			x2=[[splinepoints objectAtIndex:(j+1)%roiarraysize] point].x;
			y1=[[splinepoints objectAtIndex:j%roiarraysize] point].y;
			y2=[[splinepoints objectAtIndex:(j+1)%roiarraysize] point].y;
			
			if((y1-currenty)*(y2-currenty)<=0)
			{
				if(y2==y1)
					x=(x1>x2)?x1:x2;
				else
					x=x1+(currenty-y1)*(x2-x1)/(y2-y1);
				if(x>maxleftx)
					maxleftx=x;
			}
			
		}
		for(j=rightborderfromindex;j<rightbordertoindex;j++)
		{
			x1=[[splinepoints objectAtIndex:j%roiarraysize] point].x;
			x2=[[splinepoints objectAtIndex:(j+1)%roiarraysize] point].x;
			y1=[[splinepoints objectAtIndex:j%roiarraysize] point].y;
			y2=[[splinepoints objectAtIndex:(j+1)%roiarraysize] point].y;
			
			if((y1-currenty)*(y2-currenty)<=0)
			{
				if(y2==y1)
					x=(x1<x2)?x1:x2;
				else
					x=x1+(currenty-y1)*(x2-x1)/(y2-y1);
				if(x<minrightx)
					minrightx=x;
				
			}
			
		}
		if(maxleftx!=0 && minrightx!=10000 && maxleftx<minrightx)
		{
			diameter=minrightx-maxleftx;
			centerx=(maxleftx+minrightx)/2;
		}
		else
		{
			diameter=0;
			centerx=-1;

		}
		meandiameter+=diameter;
		if(maxdiameter<diameter)
			maxdiameter=diameter;
		if(diameterarray)
		{
			[diameterarray addObject:[NSNumber numberWithFloat:diameter*xspace]];
		}
		if(centerptarray)
		{
			[centerptarray addObject:[NSNumber numberWithFloat:centerx]];
		}
		
		
		
	}
	meandiameter/=buffersize;
	//return maxdiameter*xspace;
	return meandiameter*xspace;
	
	
}
- (void)  exportPolygonROIsInformation
{
	NSSavePanel     *panel = [NSSavePanel savePanel];
	
	[panel setCanSelectHiddenExtension:YES];
	[panel setRequiredFileType:@"txt"];
	NSArray* filelist=[originalViewController fileList];
	NSString* filename=[[filelist objectAtIndex:0] valueForKeyPath: @"series.study.patientID"];
	if(!filename)
		filename=[NSString stringWithString:@""];
	filename=[filename stringByAppendingString:[[originalViewController window] title]];
	filename=[filename stringByAppendingString:@"measurement"];
	
	if( [panel runModalForDirectory:0L file:filename] == NSFileHandlingPanelOKButton)
	{
		NSArray      *roiList= [originalViewController roiList];
		NSArray      *pixList=[originalViewController pixList];
		NSString* exportinfo=[NSString stringWithString:@""];
		unsigned int i,j;
		float	rarea, rmean, rmax, rmin, rdev, rtotal,mindiamter,maxdiameter,meandiameter;
		ROI* temproi,*polygonroi,*pointroi;
		for(i=0;i<[roiList count];i++)
		{
			polygonroi=nil;
			pointroi=nil;
			mindiamter=0,maxdiameter=0,meandiameter=0;
			rarea=0, rmean=0, rmax=0, rmin=0, rdev=0, rtotal=0;
			
			for(j=0;j<[[roiList objectAtIndex:i] count];j++)
			{
				temproi=[[roiList objectAtIndex:i] objectAtIndex:j];
				if([temproi type]==tCPolygon)
					polygonroi=temproi;
				else if([temproi type]==t2DPoint&&[[temproi name] isEqualToString:@"no segment result"])
					pointroi=temproi;
				else if([[temproi comments] isEqualToString:@"Polygon Measurement:min Axis"])
					mindiamter=[temproi Length:[[[temproi points] objectAtIndex:0] point] :[[[temproi points] objectAtIndex:1] point] ];
				else if([[temproi comments] isEqualToString:@"Polygon Measurement:max Axis"])
					maxdiameter=[temproi Length:[[[temproi points] objectAtIndex:0] point] :[[[temproi points] objectAtIndex:1] point]];
				else if([[temproi comments] isEqualToString:@"Polygon Measurement:mean Axis"])
					meandiameter=[temproi rect].size.width;
				
			}
			
			if(polygonroi)
			{
				[[pixList objectAtIndex:i] computeROI:polygonroi :&rmean :&rtotal :&rdev :&rmin :&rmax];
				rarea=[polygonroi roiArea];
				exportinfo=[exportinfo stringByAppendingFormat:@"%d\t%@",i,[polygonroi comments]];
			}
			else if(pointroi)
			{
				exportinfo=[exportinfo stringByAppendingFormat:@"%d\t%@",i,[pointroi comments]];
			}
			else
				exportinfo=[exportinfo stringByAppendingFormat:@"%d\t%d",i,0];
			meandiameter*=[[pixList objectAtIndex:i] pixelSpacingX]*0.2;
			
			
			if([caculateAreaButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",rarea];
			if([caculateMeanDiameterButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",meandiameter];
			if([caculateMinDiameterButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",mindiamter];
			if([caculateMaxDiameterButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",maxdiameter];
			
			if([caculateMeanHuButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",rmean];
			if([caculateMinHuButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",rmin];
			if([caculateMaxHuButton state]==NSOnState)
				exportinfo=[exportinfo stringByAppendingFormat:@"\t%f",rmax];			
			exportinfo=[exportinfo stringByAppendingString:@"\n"];	
			
		}
		
		[exportinfo writeToFile:[panel filename] atomically:YES];
	}
	
	
}
-(void) removeMeasurementROIs
{
	NSMutableArray      *roiList= [originalViewController roiList];
	unsigned i,j;
	for(i=0;i<[roiList count];i++)
		for(j=0;j<[[roiList objectAtIndex:i] count];j++)
		{
			ROI * temproi=[[roiList objectAtIndex:i] objectAtIndex:j];
			NSString* measureMarker=[temproi comments];
			if([measureMarker length]>19)
				measureMarker=[measureMarker substringToIndex:19];
			if([measureMarker isEqualToString:@"Polygon Measurement"])
			{
				[[roiList objectAtIndex:i] removeObject:temproi];
				j--;
			}
		}
}
- (IBAction)endPolygonMeasureDialog:(id)sender
{
	
	switch ([sender tag]) 
	{
		case 0:
			[polygonMeasureWindow orderOut:sender];
			[NSApp endSheet:polygonMeasureWindow returnCode:[sender tag]];
			originalViewController=nil;
			originalViewVolumeData=nil;
			originalViewPixList=nil;
			
			break;
		case 1:
			[self removeMeasurementROIs];
			[self creatPolygonROIsMeasurementROIsForViewController];
			[self exportPolygonROIsInformation];
			[self removeMeasurementROIs];
			break;
		case 2:
			[self creatPolygonROIsMeasurementROIsForViewController];
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"ROITEXTNAMEONLY"];
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ROITEXTIFSELECTED"];
			
			break;
		case 3:
			[self removeMeasurementROIs];
			
			break;
			
		default:
			break;
	}
	[[originalViewController imageView] setIndex:[[originalViewController imageView] curImage]];
	
	
}
#pragma mark-
#pragma mark 6. Wizard Mode functions
- (void) runSegmentation
{
	if(!contrastVolumeData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no seed found", nil), NSLocalizedString(@"You have to plant seeds first, choose the label from the left list and draw on the left lower view", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	[centerlinesNameArrays removeAllObjects];
	[cpr3DPaths removeAllObjects];// prevent save centerline 
	if(needSaveSeeds)
		[self saveCurrentSeeds];
	long size =  imageWidth * imageHeight * imageAmount;
	[self loadVesselnessMap];
	if(vesselnessMap)
		[self mergeVesselnessAndIntensityMap:volumeData:vesselnessMap:size];
	free(vesselnessMap);
	vesselnessMap=nil;
	//[parentVesselnessMap release];
//	parentVesselnessMap=nil;

	size = sizeof(float) * imageWidth * imageHeight * imageAmount;
	float               *inputData=0L, *outputData=0L;
	unsigned char       *colorData=0L, *directionData=0L;
	inputData = volumeData;
	NSLog( @"start step 3");
	outputData = (float*) malloc( size);
	if( !outputData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return ;	
	}
	size = sizeof(char) * imageWidth * imageHeight * imageAmount;
	colorData = (unsigned char*) malloc( size);
	if( !colorData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free(outputData);
		return ;	
	}	
	directionData= (unsigned char*) malloc( size);
	if( !directionData)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free(outputData);
		free(colorData);
		
		return ;	
	}		
	
	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
	
	memset(directionData,0,size);
	int i;
	size=imageWidth * imageHeight * imageAmount;
	float minValueInCurSeries = [curPix minValueOfSeries]-1;
	for(i=0;i<size;i++)
		*(outputData+i)=minValueInCurSeries;
	
	int seednumber = [self plantSeeds:inputData:outputData:directionData];
	if(seednumber < 1)
	{
		
		NSRunAlertPanel(NSLocalizedString(@"no seed", nil), NSLocalizedString(@"no seeds are found, draw ROI first.", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free( outputData );	
		free( colorData );
		free(directionData);
		[originalViewController endWaitWindow: waitWindow];
		return;
		
	}			
	
	float spacing[3];
	spacing[0]=xSpacing;
	spacing[1]=ySpacing;
	spacing[2]=zSpacing;
	
	//start seed growing	
	CMIVSegmentCore *segmentCoreFunc = [[CMIVSegmentCore alloc] init];
	[segmentCoreFunc setImageWidth:imageWidth Height: imageHeight Amount: imageAmount Spacing:spacing];
	
	[segmentCoreFunc startShortestPathSearchAsFloat:inputData Out:outputData :colorData Direction: directionData];
	//initilize the out and color buffer
	memset(colorData,0,size);
	[segmentCoreFunc caculateColorMapFromPointerMap:colorData:directionData]; 
	[segmentCoreFunc release];
	if(isInWizardMode==2)
		[self saveDirectionMap:directionData];
	[originalViewController endWaitWindow: waitWindow];
	
	[self showPreviewResult:inputData:outputData:directionData:colorData];
}
- (void) saveDirectionMap:(unsigned char*)outData
{
//	if([parent loadCrashBackup])
	{
		NSMutableDictionary* dic=[parent dataOfWizard];
		[dic setObject:[NSString stringWithString:@"Step3"] forKey:@"Step"];
		int size= sizeof(unsigned char)*imageWidth*imageHeight*imageAmount;
		NSData* newData = [[NSData alloc] initWithBytesNoCopy:outData length: size freeWhenDone:NO];
		[dic setObject:newData  forKey:@"DirectionMap"];
		[dic setObject:[NSNumber numberWithInt:size] forKey:@"DirectionMapSize"];
		[newData release];
		[parent saveCurrentStep];
	}
}
//- (IBAction)loadSegmentationResult:(id)sender 
//{
//	[self loadVesselnessMap];
//	long size =  imageWidth * imageHeight * imageAmount;
//	if(vesselnessMap)
//		[self mergeVesselnessAndIntensityMap:volumeData:vesselnessMap:size];
//	vesselnessMap=nil;
//	[parentVesselnessMap release];
//	parentVesselnessMap=nil;
//	
//	size = sizeof(float) * imageWidth * imageHeight * imageAmount;
//	float               *inputData=0L, *outputData=0L;
//	unsigned char       *colorData=0L, *directionData=0L;
//	inputData = volumeData;
//	NSLog( @"loading step 3");
//	outputData = (float*) malloc( size);
//	if( !outputData)
//	{
//		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
//		
//		return ;	
//	}
//	size = sizeof(char) * imageWidth * imageHeight * imageAmount;
//	colorData = (unsigned char*) malloc( size);
//	if( !colorData)
//	{
//		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
//		free(outputData);
//		return ;	
//	}	
//	directionData= (unsigned char*) malloc( size);
//	if( !directionData)
//	{
//		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
//		free(outputData);
//		free(colorData);
//		
//		return ;	
//	}		
//	
//	id waitWindow = [originalViewController startWaitWindow:@"processing"];	
//	[self loadDirectionData:directionData];
//	//creat roi edit history
//	[totalROIList removeAllObjects];
//	unsigned j;
//	int barrierindex=0;
//	
//	for(j=0;j<[contrastList count];j++)
//	{
//		
//		NSString* roiname=[[contrastList objectAtIndex: j] objectForKey:@"Name"];
//		ROI* anewroi;
//		if([roiname isEqualToString:@"Aorta"])
//		{
//			NSRect temprect;
//			temprect.origin.x=0;
//			temprect.origin.y=0;
//			temprect.size.width = 10;
//			temprect.size.height = 10;
//			anewroi=[[ROI alloc] initWithType: tOval :[curPix pixelSpacingX] :[curPix pixelSpacingY] : NSMakePoint( [curPix originX], [curPix originY])];
//			[anewroi setROIRect:temprect];
//		}
//		else
//		{
//			unsigned char textureBuffer[16];
//			anewroi=[[ROI alloc] initWithTexture:textureBuffer textWidth:4 textHeight:4 textName:roiname positionX:0 positionY:0 spacingX:xSpacing spacingY:ySpacing imageOrigin:NSMakePoint( 0,  0)];
//		}
//
//		[anewroi setName: roiname];	
//		NSColor* seedcolor =[[contrastList objectAtIndex: j] objectForKey:@"Color"] ;
//		CGFloat r, g, b;
//		[seedcolor getRed:&r green:&g blue:&b alpha:0L];
//		RGBColor c;
//		c.red =(short unsigned int) (r * 65535.);
//		c.green =(short unsigned int)( g * 65535.);
//		c.blue = (short unsigned int)(b * 65535.);
//		[anewroi setColor:c];
//		[totalROIList addObject:anewroi];
//		[anewroi release];
//		if([roiname isEqualToString:@"barrier"])
//		{
//			barrierindex=j+1;
//		}
//	
//	}
//
//	int i;
//	size=imageWidth * imageHeight * imageAmount;
//	float minValueInCurSeries = [curPix minValueOfSeries]-1;
//	for(i=0;i<size;i++)
//		*(outputData+i)=minValueInCurSeries;
//	minValueInCurSeries+=1;
//	for(i=0;i<size;i++)
//		if(directionData[i]&0x80)
//		{
//			contrastVolumeData[i]=directionData[i]&0x3f;
//			if(contrastVolumeData[i]==0)
//				contrastVolumeData[i]=barrierindex;
//		}
//
//	
//	float spacing[3];
//	spacing[0]=xSpacing;
//	spacing[1]=ySpacing;
//	spacing[2]=zSpacing;
//	
//	//start seed growing	
//	CMIVSegmentCore *segmentCoreFunc = [[CMIVSegmentCore alloc] init];
//	[segmentCoreFunc setImageWidth:imageWidth Height: imageHeight Amount: imageAmount Spacing:spacing];
//	
//	[segmentCoreFunc calculateFuzzynessMap:inputData Out:outputData  withDirection: directionData Minimum:minValueInCurSeries];
//	//initilize the out and color buffer
//	memset(colorData,0,size);
//	[segmentCoreFunc caculateColorMapFromPointerMap:colorData:directionData]; 
//	[segmentCoreFunc release];
//
//	
//	[originalViewController endWaitWindow: waitWindow];
//	[self showPreviewResult:inputData:outputData:directionData:colorData];
//}

- (int) plantSeeds:(float*)inData:(float*)outData:(unsigned char *)directData
{
	int seedNumber=0;
	unsigned char * colorLookup;
	int marker;
	unsigned char colorindex;
	int size;
	NSString* roiname;
	ROI* temproi;
	colorLookup=(unsigned char *)malloc(uniIndex);
	if(!colorLookup)
	{
		NSRunAlertPanel(NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"no enough RAM", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return seedNumber;
	}
	int i=0;
	unsigned j;
	for(i=0;i<uniIndex;i++)
	{
		temproi=[totalROIList objectAtIndex: i];
		marker=[[temproi comments] intValue];
		roiname=[temproi name];
		colorindex=0;
		if([roiname isEqualToString:@"barrier"])
			colorindex=0;
		else
		{
			for(j=0;j<[contrastList count];j++)
				if([roiname isEqualToString: [[contrastList objectAtIndex: j] objectForKey:@"Name"]])
					colorindex=j+1;
		}
		
		colorLookup[i]=colorindex;
	}
	size=imageWidth*imageHeight*imageAmount;
	for(i=0;i<size;i++)
	{
		marker=(int)(*(contrastVolumeData+i));
		if(marker)
		{
			colorindex=*(colorLookup+marker-1);
			if(colorindex)
			{
				*(outData+i)=*(inData+i);
				*(directData + i) = colorindex | 0x80;
				
				seedNumber++;
				
			}
			else
			{
				*(directData + i) = 0x80;
			}
		}
	}
	free(colorLookup);
	
	return seedNumber;
	
}
- (void) showPreviewResult:(float*)inData:(float*)outData:(unsigned char *)directData :(unsigned char *)colorData
{
	[parent cleanDataOfWizard];
	int size= sizeof(float)*imageWidth*imageHeight*imageAmount;
	NSData	*newData = [[NSData alloc] initWithBytesNoCopy:inData length: size freeWhenDone:NO];
	NSMutableDictionary* dic=[parent dataOfWizard];
	[dic setObject:newData forKey:@"InputData"];
	[newData release];
	newData = [[NSData alloc] initWithBytesNoCopy:outData length: size freeWhenDone:YES];
	[dic setObject:newData  forKey:@"OutputData"];
	[newData release];
	size= sizeof(unsigned char)*imageWidth*imageHeight*imageAmount;
	newData = [[NSData alloc] initWithBytesNoCopy:directData length: size freeWhenDone:YES];
	[dic setObject:newData  forKey:@"DirectionData"];
	[newData release];
	newData = [[NSData alloc] initWithBytesNoCopy:colorData length: size freeWhenDone:YES];
	[dic setObject:newData  forKey:@"ColorData"];
	[newData release];
	size= sizeof(unsigned short int)*imageWidth*imageHeight*imageAmount;	
	newData = [[NSData alloc] initWithBytesNoCopy:contrastVolumeData length: size freeWhenDone:YES];
	[dic setObject:newData  forKey:@"SeedData"];
	[newData release];
	NSMutableArray  *shownColorList=[[NSMutableArray alloc] initWithCapacity: 0] ;	
	NSMutableArray  *seedListInResult=[[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableArray  *passedOnROIList=[[NSMutableArray alloc] initWithCapacity: 0];
	unsigned int i;
	NSRect temprect;
	temprect.origin.x=0;
	temprect.origin.y=0;
	temprect.size.width = 10;
	temprect.size.height = 10;
	for(i=0;i<[contrastList count];i++)
	{
		ROI* temproi= [[ROI alloc] initWithType: tOval :[curPix pixelSpacingX] :[curPix pixelSpacingY] : NSMakePoint( [curPix originX], [curPix originY])];
		[temproi setROIRect:temprect];
		NSString* seedname = [[contrastList objectAtIndex: i] objectForKey:@"Name"] ;
		[temproi setName: seedname];	
		NSColor* seedcolor =[[contrastList objectAtIndex: i] objectForKey:@"Color"] ;
		CGFloat r, g, b;
		[seedcolor getRed:&r green:&g blue:&b alpha:0L];
		RGBColor c;
		c.red =(short unsigned int) (r * 65535.);
		c.green =(short unsigned int)( g * 65535.);
		c.blue = (short unsigned int)(b * 65535.);
		[temproi setColor:c];
		[seedListInResult addObject: temproi];
		if((![seedname isEqualToString: @"barrier"])&&(![seedname isEqualToString: @"other"]))
			[shownColorList addObject: [NSNumber numberWithInt:i+1]];
		
	}
	
	
	[dic setObject:seedListInResult  forKey:@"SeedList"];
	[seedListInResult release];
	[dic setObject:shownColorList  forKey:@"ShownColorList"];
	[shownColorList release];
	[passedOnROIList addObjectsFromArray:totalROIList];
	[dic setObject:passedOnROIList  forKey:@"ROIList"];
//	[parent setDataofWizard:dic];
	contrastVolumeData=nil;
	NSString* tabidstr=[[seedToolTipsTabView selectedTabViewItem] identifier];
	if(tabidstr&&[[NSString stringWithString:@"SeedTools"] isEqualToString:tabidstr])
		[self onCancel:saveButton];
	else if(tabidstr&&[[NSString stringWithString:@"Tips"] isEqualToString:tabidstr])
		[self onCancel:nextButton];
	
	
	
}
- (IBAction)goNextStep:(id)sender
{
	
	if(currentTool == 7)
	{
		if([[axViewROIList objectAtIndex:0] count])
		{
			[self covertRegoinToSeeds:nil];
		}
		else
		{
			NSRunAlertPanel(NSLocalizedString(@"no seeds found", nil), NSLocalizedString(@"No seeds found for this step, please follow the instruction in the tips bos and do it again", nil), NSLocalizedString(@"OK", nil), nil, nil);
			return;
		}
	}
	if(currentStep>=(totalSteps-1))
	{
		[self runSegmentation];
		return;
	}
	else 
	{

		[self goSubStep:currentStep+1:YES];
		if(currentStep>=(totalSteps-1))
			[nextButton setTitle:@"Run Segmentation"];
		if(currentStep>0)
			[previousButton setEnabled: YES];

	}
}
- (IBAction)goPreviousStep:(id)sender
{
	[self updateOView];
	if(currentStep>0)
		[self goSubStep:currentStep-1:YES];
	if(currentStep<(totalSteps-1))
		[nextButton setTitle:@"Next Step"]; 
	if(currentStep<=0)
		[previousButton setEnabled: NO];
}
- (void) goSubStep:(int)step:(bool)needResetViews
{
	if(step<0)
		step=0;
	else if(step>=totalSteps)
		step=totalSteps-1;
	
	NSString *tempstr;
	NSColor *color;
	NSNumber *number;
	
	if(step>=0&&step<(signed)[contrastList count])
	{
		
		currentStep=step;
		//load name
		tempstr = [[contrastList objectAtIndex: step] objectForKey:@"Name"] ;
		currentSeedName=tempstr;
		//load color
		color =[[contrastList objectAtIndex: step] objectForKey:@"Color"] ;
		currentSeedColor=color;
		//load brush
		number=[[contrastList objectAtIndex: step] objectForKey:@"BrushWidth"] ;
		[[NSUserDefaults standardUserDefaults] setFloat:[number floatValue] forKey:@"ROIRegionThickness"];
		
		//chang current tool
		number=[[contrastList objectAtIndex: step] objectForKey:@"CurrentTool"] ;
		[self changeCurrentTool:[number intValue]];
		//load tips
		tempstr = [[contrastList objectAtIndex: step] objectForKey:@"Tips"] ;
		[currentTips setStringValue:tempstr];
		
	}	
	if(needResetViews)
		[self resetOriginalView:nil];
}
- (IBAction)continuePlanting:(id)sender
{
	[nextButton setEnabled: YES];
	if(currentStep>0)
		[previousButton setEnabled: YES];
	[self goSubStep:currentStep:NO];
	[continuePlantingButton setHidden: YES];
}
-(void)mergeVesselnessAndIntensityMap:(float*)img:(float*)vesselimg:(int)size
{
	int i;
	for(i=0;i<size;i++)
			*(img+i)=*(img+i)+3*(*(vesselimg+i));
	parent.ifVesselEnhanced=YES;
}
- (void)loadVesselnessMap
{
	if(!vesselnessMap)
	vesselnessMap=(float*)malloc(imageWidth*imageHeight*imageAmount*sizeof(float));
	if(!vesselnessMap)
	{
		//NSRunAlertPanel(NSLocalizedString(@"no enough memory", nil), NSLocalizedString(@"No enough memory for loading vesselness map, running segmentation withour it!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		return;
	}
	float origin[3],spacing[3];
	long dimension[3];
	origin[0]=vtkOriginalX;origin[1]=vtkOriginalY;origin[2]=vtkOriginalZ;
	spacing[0]=xSpacing;spacing[1]=ySpacing;spacing[2]=zSpacing;
	dimension[0]=imageWidth;dimension[1]=imageHeight;dimension[2]=imageAmount;
	if([parent loadVesselnessMap:vesselnessMap:origin:spacing:dimension])
	{
		//parentVesselnessMap=[[NSData alloc] initWithBytesNoCopy:vesselnessMap length: imageWidth*imageHeight*imageAmount*sizeof(float) freeWhenDone:YES];	
	}
	else
	{
		//NSRunAlertPanel(NSLocalizedString(@"no vesselness map found", nil), NSLocalizedString(@"No vesselness map found, running segmentation withour it!", nil), NSLocalizedString(@"OK", nil), nil, nil);
		free(vesselnessMap);
		vesselnessMap=nil;
		return;
	}
	
}
-(void)loadDirectionData:(unsigned char*)outData
{
	//	if([parent loadCrashBackup])
	//	{
	//		NSMutableDictionary* dic=[parent dataOfWizard];
	//		NSNumber* directionmapsize=[dic objectForKey:@"DirectionMapSize"];
	//		NSString* directionmapfile=[dic objectForKey:@"DirectionMapPath"];
	//		
	//		if(volumeData)
	//		{
	//			FILE* tempFile;
	//			tempFile= fopen([directionmapfile cString],"r");
	//			fread(outData,sizeof(char),[directionmapsize intValue],tempFile);
	//			fclose(tempFile);
	//		}
	//
	//	}
	//	return;
}
- (IBAction)cancelAutoSegmentaion:(id)sender
{
	if(autoSegmentTimer)
	{
		[autoSegmentTimer invalidate];
		[autoSegmentTimer release];
		autoSegmentTimer=nil;
	}
	[cancelSegmentationButton setHidden:YES];
	[saveButton setTitle:@"run segmentaion"];
}
-(void)changeSegmentButtonTitle:(id)sender
{
	timeCountDown--;
	[saveButton setTitle:[NSString stringWithFormat:@"Seg. start in %d seconds",timeCountDown]];
	if(timeCountDown<0)
	{
		if(autoSegmentTimer)
		{
			[autoSegmentTimer invalidate];
			[autoSegmentTimer release];
			autoSegmentTimer=nil;
		}
		[self onOK:saveButton];
	}
	
}
#pragma mark-
#pragma mark 7. Automatic Seeding functions


/* -(void)crossSectionRegionGrowing:(id)parameters
{
	id waitWindow = [originalViewController startWaitWindow:@"Detecting Aorta..."];	
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	//[self updateOView];
	[self cAndAxViewReset];
	NSLog(@"cross section growing start");
	ROI* lastroi=nil;
	ROI* temproi;
	double origin[3],neworigin[3];
	float lastAxViewOrigin[2];
	float centeroffsetx,centeroffsety;
	int lasttotalpoints=0;
	int continueGrowingCondition;
	float comulatedis=0;
	int lastjointindex=1;
	NSMutableArray* newCenterline=[NSMutableArray arrayWithArray:0];
	vtkTransform* currentTransform;
	if(isStraightenedCPR)
		currentTransform=axViewTransformForStraightenCPR;
	else
		currentTransform=axViewTransform;
	int ifneedgoback=0;
	
	unsigned int i;
	temproi=nil;
	for(i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
	{
		temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex:i];
		if([temproi type]==tPlain)
			break;
	}
	if(temproi&&[temproi type]==tPlain)
	{
		lastroi=temproi;
		centeroffsetx=0;
		centeroffsety=0;
		lastAxViewOrigin[0]=axViewOrigin[0];
		lastAxViewOrigin[1]=axViewOrigin[1];
		[lastroi retain];
	}
	else
	{
		return;
	}
	
	
	do
	{

		continueGrowingCondition=0;

		temproi=nil;

		for(i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
		{
			temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex:i];
			if([temproi type]==tPlain)
				break;
		}
		
		if(temproi&&[temproi type]==tPlain)
		{
			//NSLog(@"debug log plain roi found");
			if(lastroi)
			{
				unsigned char* lastroibuffer=[lastroi textureBuffer];
				unsigned char* temproibuffer=[temproi textureBuffer];
				int x1,y1,x2,y2,corneroffsetx,corneroffsety;
				x1=[lastroi textureUpLeftCornerX];
				y1=[lastroi textureUpLeftCornerY];
				x2=[lastroi textureDownRightCornerX];
				y2=[lastroi textureDownRightCornerY];
				x1-=(centeroffsetx+axViewOrigin[0]-lastAxViewOrigin[0])/axViewSpace[0];
				x2-=(centeroffsetx+axViewOrigin[0]-lastAxViewOrigin[0])/axViewSpace[0];
				y1-=(centeroffsety+axViewOrigin[1]-lastAxViewOrigin[1])/axViewSpace[1];
				y2-=(centeroffsety+axViewOrigin[1]-lastAxViewOrigin[1])/axViewSpace[1];
				corneroffsetx=[temproi textureUpLeftCornerX]-x1;
				corneroffsety=[temproi textureUpLeftCornerY]-y1;
				x1-=[temproi textureUpLeftCornerX];
				y1-=[temproi textureUpLeftCornerY];
				x2-=[temproi textureUpLeftCornerX];
				y2-=[temproi textureUpLeftCornerY];
				if(x1<0)
					x1=0;
				if(y1<0)
					y1=0;
				if(x2>[temproi textureDownRightCornerX])
					x2=[temproi textureDownRightCornerX];
				if(y2>[temproi textureDownRightCornerY])
					y2=[temproi textureDownRightCornerY];
				int x,y,hitpoints=0,curtotalpoints=0;
				int lastwidth,curwidth,curheight;
				lastwidth=[lastroi textureWidth];
				curwidth=[temproi textureWidth];
				curheight=[temproi textureHeight];
				for(y=0;y<curheight;y++)
					for(x=0;x<curwidth;x++)
					{
						
						if(*(temproibuffer+y*curwidth+x))
						{
							curtotalpoints++;
							if(x>=x1 && x<=x2 && y>=y1 && y<=y2)
								if(*(lastroibuffer+(y+corneroffsety)*lastwidth+x+corneroffsetx))
									hitpoints++;
						}
					}
				float hitmissratio=0;
				if(lasttotalpoints>curtotalpoints)
					hitmissratio=(float)hitpoints/(float)lasttotalpoints;
				else
					hitmissratio=(float)hitpoints/(float)curtotalpoints;
				if(hitmissratio>0.75)
					continueGrowingCondition=1;
				else
				{
					NSLog(@"no enough cross area");
					ifneedgoback=1;
					continueGrowingCondition=0;
				}
				lasttotalpoints=curtotalpoints;
				//NSLog(@"debug log compared with last roi");
				
			}
			else
			{
				unsigned char* temproibuffer=[temproi textureBuffer];
				int curwidth,curheight;
				curwidth=[temproi textureWidth];
				curheight=[temproi textureHeight];
				int x,y;
				lasttotalpoints=0;
				for(y=0;y<curheight;y++)
					for(x=0;x<curwidth;x++)
					{
						
						if(*(temproibuffer+y*curwidth+x))
						{
							lasttotalpoints++;
						}
					}
				
				continueGrowingCondition=1;
			}
		}
		else
		{
			NSLog(@"no roi");
			if(lastroi)
				ifneedgoback=1;
			break;
		}
		if(continueGrowingCondition)
		{
			[temproi retain];
			[lastroi release];
			lastroi=temproi;

			int center[2],heavycenter[2];
			float centerdis=0;
			float radis=[self findingCenterOfSegment:[temproi textureBuffer] :[temproi textureWidth] :[temproi textureHeight]:center];
			[self findingGravityCenterOfSegment:[temproi textureBuffer] :[temproi textureWidth] :[temproi textureHeight]:heavycenter];
			if(radis==-1)
			{
				NSLog(@"fail to location the center of the cross section");
				break;
			}
			else
			{
				centerdis=sqrt((center[0]-heavycenter[0])*(center[0]-heavycenter[0])+(center[1]-heavycenter[1])*(center[1]-heavycenter[1]));
				if(centerdis>radis/2)
				{
					NSLog(@"irregular cross section found");
					break;
				}
				
				center[0]+=[temproi textureUpLeftCornerX];
				center[1]+=[temproi textureUpLeftCornerY];
				origin[0]=axViewOrigin[0]+(center[0]) *axViewSpace[0];
				origin[1]=axViewOrigin[1]+(center[1]) *axViewSpace[1];
				origin[2]=0;
			}
			
			float oX,oY,oZ;
			oX=origin[0];
			oZ=origin[1];
			oY=1;
			//NSLog(@"debug log check if need go further");
			if([newCenterline count] && sqrt(oX*oX+oZ*oZ)>radis*axViewSpace[0]/2)
			{
				NSLog(@"center shift too much");
				break;
			}
			[self createAortaRootSeeds:center[0]:center[1]];
			
			currentTransform->TransformPoint(origin,neworigin);
			
			if([newCenterline count])
				comulatedis+=1.0;//sqrt(oX*oX+oZ*oZ+1);
			if(comulatedis<10)
			{
				centeroffsetx=origin[0];
				centeroffsety=origin[1];
				lastAxViewOrigin[0]=axViewOrigin[0];
				lastAxViewOrigin[1]=axViewOrigin[1];


				oViewUserTransform->Translate(oX,oY,oZ);
			}
			else
			{
				//NSLog(@"debug log correct z direction");
				comulatedis=0;
				[lastroi release];
				lastroi=nil;
				double position[3],direction[3];
				currentTransform->TransformPoint(origin,position);	
				if(lastjointindex>=(signed)[newCenterline count])
				{
					NSLog(@"lastjointindex = new points");
					break;
				}
				int pnums=[newCenterline count]-lastjointindex;
				int ii;
				double zxdata[pnums*2],zydata[pnums*2];
				CMIV3DPoint* a3DPoint;
				double x1=0,y1=0,z1=0,x2=0,y2=0,z2=0,kx=0,bx=0,ky=0,by=0;
				for(ii=0;ii<pnums;ii++)
				{
					a3DPoint=[newCenterline objectAtIndex:ii];
					zxdata[2*ii]=[a3DPoint z];
					zxdata[2*ii+1]=[a3DPoint x];
					zydata[2*ii]=[a3DPoint z];
					zydata[2*ii+1]=[a3DPoint y];
					if(ii==0)
						z1=[a3DPoint z];
					z2=[a3DPoint z];

				}
				[self LinearRegression:zxdata :pnums:&bx:&kx];
				[self LinearRegression:zydata :pnums:&by:&ky];
				x1=kx*z1+bx;
				x2=kx*z2+bx;
				y1=ky*z1+by;
				y2=ky*z2+by;
				a3DPoint=[newCenterline objectAtIndex:0];
				position[0]=[a3DPoint x];
				position[1]=[a3DPoint y];
				position[2]=[a3DPoint z];
				
				direction[0]=x1-x2;
				direction[1]=y1-y2;
				direction[2]=z1-z2;
				//oViewUserTransform->GetPosition(position);
				oViewUserTransform->Identity();
				oViewBasicTransform->Identity();
				oViewBasicTransform->Translate(position);
				float anglex=0,angley=0;
				if(direction[2]==0)
				{
					if(direction[1]>0)
						anglex=90;
					if(direction[1]<0)
						anglex=-90;
					if(direction[1]==0)
						anglex=0;
				}
				else
				{
					anglex = atan(direction[1]/direction[2]) / deg2rad;
					if(direction[2]<0)
						anglex+=180;
				}
				
				
				angley = asin(direction[0]/sqrt(direction[0]*direction[0]+direction[1]*direction[1]+direction[2]*direction[2])) / deg2rad;
				oViewUserTransform->RotateX(-anglex);	
				oViewUserTransform->RotateY(angley);
				oViewUserTransform->RotateX(90);
				lastjointindex=[newCenterline count];
				
			}
			//[self updateOView];
			NSLog(@"debug log updating ax");
			[self cAndAxViewReset];
			NSLog(@"debug log updated ax");
			
			
			
			CMIV3DPoint* new3DPoint=[[CMIV3DPoint alloc] init] ;
			[new3DPoint setX: neworigin[0]];
			[new3DPoint setY: neworigin[1]];
			[new3DPoint setZ: neworigin[2]];
			[newCenterline insertObject:new3DPoint atIndex:0 ];
			[new3DPoint release];
			


		}

		
		

	}while(continueGrowingCondition);
	if(ifneedgoback)
	{
		oViewUserTransform->Translate(-centeroffsetx,-1,-centeroffsety);
		[self cAndAxViewReset];
		//sleep(1000);
	}
	//[self updateOView];
	//[self cAndAxViewReset];
	currentPathMode=ROI_selectedModify;
	//[self changeCurrentTool:5];
	
	if(lastroi)
		[lastroi release];
	NSLog(@"cross section growing end");

	[self createVentricleRootSeeds];
	NSLog(@"debug log ventericalseeds created");
	[self goSubStep:2:NO];
	//[self plantExtraSeedsForRightCoronaryArtery];
	//[self plantExtraSeedsForLeftCoronaryArtery];
	[self plantSeedsForTopAndBottom];
	[self goSubStep:2:NO];
	NSLog(@"debug log other seeds created");

	[self setCurrentCPRPathWithPath:newCenterline:-1.0];
	[newCenterline removeAllObjects];
	isRemoveROIBySelf=1;
	NSString* emptystr=[NSString stringWithString:@""];
	if([oViewROIList count])
	{
		for(i=0;i<[[oViewROIList objectAtIndex: 0] count];i++)
			[[[oViewROIList objectAtIndex: 0] objectAtIndex: i] setComments:emptystr];

	
		[[oViewROIList objectAtIndex: 0] removeAllObjects];
	}
	if([axViewROIList count])
		[[axViewROIList objectAtIndex:0] removeAllObjects];
	isRemoveROIBySelf=0;
	[pool release];
	[originalViewController endWaitWindow: waitWindow];
} */
/* - (IBAction)startCrossSectionRegionGrowing:(id)sender
{
	
	[self goSubStep:2:NO];
	//[self plantExtraSeedsForRightCoronaryArtery];
	//[self plantExtraSeedsForLeftCoronaryArtery];
	CGFloat rv, gv, bv;
	[currentSeedColor getRed:&rv green:&gv blue:&bv alpha:0L];
	RGBColor c;
	c.red =(short unsigned int) (rv * 65535.);
	c.green =(short unsigned int)( gv * 65535.);
	c.blue = (short unsigned int)(bv * 65535.);
	
	uniIndex++;
	NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
	DCMPix* curImage= [axViewPixList objectAtIndex:0];
	ROI* topROI=[[ROI alloc] initWithType: tOval :[curImage pixelSpacingX] :[curImage pixelSpacingY] : NSMakePoint( [curImage originX], [curImage originY])];
	[topROI setName:currentSeedName];
	[topROI setComments:indexstr];	
	[topROI setColor:c];
	[totalROIList addObject:topROI];
	[topROI release];
	aortamarker=uniIndex;
	
	[[oViewROIList objectAtIndex:0] removeAllObjects];
	[[axViewROIList objectAtIndex:0] removeAllObjects];
	//[axViewROIMode selectCellAtRow: 1 column:0];
	//[NSThread detachNewThreadSelector:@selector(crossSectionRegionGrowing:) toTarget:self withObject:self];
	[self crossSectionRegionGrowing:nil];
} */
// -(void)createVentricleRootSeeds
//{
//	ROI* temproi;
//	
//		
//	
//	unsigned int i;
//	temproi=nil;
//	if([axViewROIList count]==0)
//		return;
//	
//	for(i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
//	{
//		temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex:i];
//		if([temproi type]==tCPolygon)
//			break;
//	}
//	if(temproi&&[temproi type]==tCPolygon)
//	{
//		float centerx,centery;
//		centerx=-(axViewOrigin[0]/axViewSpace[0]);
//		centery=-(axViewOrigin[1]/axViewSpace[1]);
//		NSArray* splinepoints=[temproi splinePoints];
//		int j,ptnumber;
//		ptnumber=[splinepoints count];
//		
//		float x,y,maxradius=0;
//		for(j=0;j<ptnumber;j++)
//		{
//			x=[[splinepoints objectAtIndex:j] point].x;
//			y=[[splinepoints objectAtIndex:j] point].y;
//			x-=centerx;
//			y-=centery;
//			if(sqrt(x*x+y*y)>maxradius)
//				maxradius=sqrt(x*x+y*y);
//			
//		}
//		if(maxradius>0)
//		{
//			// clean aorta seeds cross barrier
//			if(maxSpacing==0)
//				maxSpacing=sqrt(xSpacing*xSpacing+ySpacing*ySpacing+zSpacing*zSpacing);
//				
//			int xx,yy,zz;	
//			float point[3];
//			inverseAxViewTransform= (vtkTransform*)axViewTransform->GetLinearInverse();
//			for(zz=0;zz<imageAmount;zz++)
//				for(yy=0;yy<imageHeight;yy++)
//					for(xx=0;xx<imageWidth;xx++)
//						if(*(contrastVolumeData+zz*imageSize+yy*imageWidth+xx)==aortamarker)//
//						{
//							point[0]=xx*xSpacing+vtkOriginalX;
//							point[1]=yy*ySpacing+vtkOriginalY;
//							point[2]=zz*zSpacing+vtkOriginalZ;
//							inverseAxViewTransform->TransformPoint(point,point);
//							if(point[2]<maxSpacing)
//								*(contrastVolumeData+zz*imageSize+yy*imageWidth+xx)=0;
//							
//						}
//			//now plant the seeds
//			[self goSubStep:0:NO];
//			[[axViewROIList objectAtIndex: 0] removeAllObjects];
//			ROI* aortaSeedROI=[[ROI alloc] initWithType: tOval :axViewSpace[0] :axViewSpace[1] : NSMakePoint( axViewOrigin[0], axViewOrigin[1])];
//			[aortaSeedROI setName: currentSeedName];
//			[aortaSeedROI setROIMode:ROI_sleep];
//			RGBColor color;
//			color.red = 0;
//			color.green = 65000;
//			color.blue = 0;
//			[aortaSeedROI setColor:color];
//			maxradius+=1/xSpacing;
//
//			NSRect roirect;
//			roirect.origin.x=centerx;
//			roirect.origin.y=centery;
//			roirect.size.width=maxradius;
//			roirect.size.height=maxradius;
//			[aortaSeedROI setROIRect:roirect];
//			[[axViewROIList objectAtIndex: 0] addObject:aortaSeedROI];
//			[aortaSeedROI release];
//			int temptool=currentTool;
//			currentTool=7;
//			[self covertRegoinToSeeds:nil];
//			/*
//			[self goSubStep:2:NO];
//			[[axViewROIList objectAtIndex: 0] removeAllObjects];
//			aortaSeedROI=[[ROI alloc] initWithType: tOval :axViewSpace[0] :axViewSpace[1] : NSMakePoint( axViewOrigin[0], axViewOrigin[1])];
//			[aortaSeedROI setName: currentSeedName];
//			[aortaSeedROI setROIMode:ROI_sleep];
//
//			color.red = 0;
//			color.green = 65000;
//			color.blue = 0;
//			[aortaSeedROI setColor:color];
//			
//
//			roirect.origin.x=centerx;
//			roirect.origin.y=centery;
//			roirect.size.width=maxradius;
//			roirect.size.height=maxradius;
//			[aortaSeedROI setROIRect:roirect];
//			[[axViewROIList objectAtIndex: 0] addObject:aortaSeedROI];
//			[aortaSeedROI release];
//			if(maxSpacing==0)
//				maxSpacing=sqrt(xSpacing*xSpacing+ySpacing*ySpacing+zSpacing*zSpacing);
//			maxSpacing=-maxSpacing;
//			[self covertRegoinToSeeds:nil];
//			maxSpacing=-maxSpacing;
//			*/
//			
//			currentTool=temptool;
//			
//		
//		}
//	}
//} 
//-(void)createAortaRootSeeds:(int)centerx:(int)centery
//{
//	ROI* temproi;
//	
//	unsigned int i;
//	temproi=nil;
//	for(i=0;i<[[axViewROIList objectAtIndex: 0] count];i++)
//	{
//		temproi=[[axViewROIList objectAtIndex: 0] objectAtIndex:i];
//		if([temproi type]==tCPolygon)
//			break;
//	}
//	if(temproi&&[temproi type]==tCPolygon)
//	{
//
//		NSArray* splinepoints=[temproi splinePoints];
//		int j=0,ptnumber=0;
//		ptnumber=[splinepoints count];
//		if(ptnumber<=5)
//			return;
//		
//		float x=0,y=0,minradius=10000;
//		for(j=0;j<ptnumber;j++)
//		{
//			x=[[splinepoints objectAtIndex:j] point].x;
//			y=[[splinepoints objectAtIndex:j] point].y;
//			x-=centerx;
//			y-=centery;
//			if(sqrt(x*x+y*y)<minradius)
//				minradius=sqrt(x*x+y*y);
//			
//		}
//
//		if(minradius>0&&minradius!=10000)
//		{
//			float curXSpacing,curYSpacing;
//			float curOriginX,curOriginY;
//			short unsigned int marker;
//			marker=aortamarker;
//			curXSpacing=axViewSpace[0];
//			curYSpacing=axViewSpace[1];
//			curOriginX= axViewOrigin[0];
//			curOriginY= axViewOrigin[1];
//			curOriginX = (centerx-minradius)*curXSpacing+curOriginX;		
//			curOriginY = (centery-minradius)*curYSpacing+curOriginY;
//			
//			int i,j,height,width;
//			int x,y,z;
//			float point[3];
//			
//			height=3*minradius*2;
//			width=3*minradius*2;
//			float x0,y0,a,b;
//			a=curXSpacing*minradius;
//			b=curYSpacing*minradius;	
//			x0= curOriginX+a;
//			y0= curOriginY+b;
//			a=a*a;
//			b=b*b;
//
//			//step=0.3 pixel!	
//			for(j=0;j<height;j++)
//				for(i=0;i<width;i++)
//				{
//					point[0] = curOriginX + i * curXSpacing/3;
//					point[1] = curOriginY + j * curYSpacing/3;
//					point[2] = 0;
//					if((point[0]-x0)*(point[0]-x0)*b+(point[1]-y0)*(point[1]-y0)*a<=a*b)
//					{
//						axViewTransform->TransformPoint(point,point);
//						x=lround((point[0]-vtkOriginalX)/xSpacing);
//						y=lround((point[1]-vtkOriginalY)/ySpacing);
//						z=lround((point[2]-vtkOriginalZ)/zSpacing);
//						if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
//						{
//							*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
//							
//							
//						}
//					}
//					
//				}				
//			
//		}
//	}
//}
//-(void)plantSeedsForTopAndBottom
//{
//	[self goSubStep:0:NO];
//
//
//	uniIndex++;
//	unsigned char textureBuffer[16];
//	ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:4 textHeight:4 textName:currentSeedName positionX:0 positionY:0 spacingX:xSpacing spacingY:ySpacing imageOrigin:NSMakePoint( 0,  0)];
//	
//	CGFloat rv, gv, bv;
//	[currentSeedColor getRed:&rv green:&gv blue:&bv alpha:0L];
//	RGBColor c;
//	c.red =(short unsigned int) (rv * 65535.);
//	c.green =(short unsigned int)( gv * 65535.);
//	c.blue = (short unsigned int)(bv * 65535.);
//	NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
//	[newROI setComments:indexstr];	
//	
//	[newROI setColor:c];
//	[totalROIList addObject:newROI];
//	[newROI release];
//	
//	float curXSpacing,curYSpacing;
//	float curOriginX,curOriginY;
//	short unsigned int marker;
//	marker=uniIndex;
//	curXSpacing=axViewSpace[0];
//	curYSpacing=axViewSpace[1];
//	curOriginX= axViewOrigin[0];
//	curOriginY= axViewOrigin[1];
//		
//	int i;
//	for(i=0;i<imageSize;i++)
//		*(contrastVolumeData+i)=marker;
//	for(i=0;i<imageSize;i++)
//		*(contrastVolumeData+(imageAmount-1)*imageSize+i)=marker;
//	/*
//	 int j,height,width;
//	int x,y,z;
//	float point[3];
//	
//	height=[curImage pheight];
//	width=[curImage pwidth];
//	
//	for(j=0;j<height;j++)
//		for(i=0;i<width;i++)
//		{
//			point[0] = curOriginX + i * curXSpacing;
//			point[1] = curOriginY + j * curYSpacing;
//			point[2] = 0;
//
//			axViewTransform->TransformPoint(point,point);
//			x=lround((point[0]-vtkOriginalX)/xSpacing);
//			y=lround((point[1]-vtkOriginalY)/ySpacing);
//			z=lround((point[2]-vtkOriginalZ)/zSpacing);
//			if(x>=0 && x<imageWidth && y>=0 && y<imageHeight && z>=0 && z<imageAmount)
//			{
//				*(contrastVolumeData+z*imageSize+y*imageWidth+x) = marker;
//	
//			}
//
//			
//		}	
//	 */
//	
//
//}
//-(int) LinearRegression:(double*)data :(int)rows:(double*)a:(double*)b
//{
//	int m;
//	double *p,Lxx=0,Lxy=0,xa=0,ya=0;
//	if(data==0||a==0||b==0||rows<1)
//		return -1;
//	for(p=data,m=0;m<rows;m++)
//	{
//		xa+=*p++;
//		ya+=*p++;
//	}
//	xa/=rows;
//	ya/=rows;
//	for(p=data,m=0;m<rows;m++,p+=2)
//	{
//		Lxx+=((*p-xa)*(*p-xa));
//		Lxy+=((*p-xa)*(*(p+1)-ya));
//	}
//	*b=Lxy/Lxx;
//	*a=ya-*b*xa;
//	return 0;
//}

//-(void)plantExtraSeedsForRightCoronaryArtery
//{
//
//	float* blenddata= vesselnessMap;;
//	if(blenddata==nil)
//		return;
//	
//	typedef   float  InternalPixelType;
//	typedef   unsigned long   LabelPixelType;
//	const     unsigned int    Dimension = 3;
//	
//	typedef itk::Image< InternalPixelType, Dimension >  InternalImageType;
//	typedef itk::Image< LabelPixelType, Dimension>   LabelImageType;
//	
//	
//	typedef itk::ImportImageFilter< InternalPixelType, Dimension > ImportFilterType;
//	
//	ImportFilterType::Pointer importFilter;
//	
//	importFilter = ImportFilterType::New();
//	
//	ImportFilterType::SizeType itksize;
//	itksize[0] = imageWidth/2; // size along X
//	itksize[1] = imageHeight/2; // size along Y
//	itksize[2] = imageAmount/2;// size along Z
//	
//	ImportFilterType::IndexType start;
//	start.Fill( 0 );
//	
//	ImportFilterType::RegionType region;
//	region.SetIndex( start );
//	region.SetSize( itksize );
//	importFilter->SetRegion( region );
//	
//	double origin[ 3 ];
//	origin[0] = 0; // X coordinate
//	origin[1] = 0; // Y coordinate
//	origin[2] = 0; // Z coordinate
//	importFilter->SetOrigin( origin );
//	
//	double spacing[ 3 ];
//	spacing[0] = 1; // along X direction
//	spacing[1] = 1; // along Y direction
//	spacing[2] = 1; // along Z direction
//	importFilter->SetSpacing( spacing ); 
//	
//	const bool importImageFilterWillOwnTheBuffer = false;
//	importFilter->SetImportPointer( blenddata, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
//	
//	
//	
//	
//	
//	typedef itk::BinaryThresholdImageFilter< InternalImageType, InternalImageType > ThresholdFilterType;
//	typedef itk::ConnectedComponentImageFilter< InternalImageType, LabelImageType > ConnectedComponentType;
//	typedef itk::RelabelComponentImageFilter< LabelImageType, LabelImageType > RelabelComponentType;
//	
//	typedef itk::LabelStatisticsImageFilter< InternalImageType, LabelImageType> StatisticsFilterType;
//	
//	ThresholdFilterType::Pointer threshold = ThresholdFilterType::New();
//	ConnectedComponentType::Pointer connected = ConnectedComponentType::New();
//	RelabelComponentType::Pointer relabel = RelabelComponentType::New();
//	
//	StatisticsFilterType::Pointer statistics = StatisticsFilterType::New();
//	
//	
//	
//	
//	threshold->SetInput (importFilter->GetOutput());
//	threshold->SetInsideValue(itk::NumericTraits<InternalPixelType>::One);
//	threshold->SetOutsideValue(itk::NumericTraits<InternalPixelType>::Zero);
//	threshold->SetLowerThreshold(10);
//	threshold->SetUpperThreshold(10000);
//	threshold->Update();
//	
//	
//	connected->SetInput (threshold->GetOutput());
//	relabel->SetInput( connected->GetOutput() );
//	relabel->SetMinimumObjectSize(50);
//	
//	try
//    {
//		//relabel->Modified();
//		relabel->Update();
//	}
//	catch( itk::ExceptionObject & excep )
//    {
//		NSLog(@"relable failed");
//		return ;
//    }
//	
//	
//	try
//    {
//		statistics->SetInput( importFilter->GetOutput() );
//		statistics->SetLabelInput( relabel->GetOutput() );
//		statistics->UseHistogramsOff();
//		statistics->Update();
//    }
//	catch( itk::ExceptionObject & excep )
//    {
//		NSLog(@"statsitic relable failed");
//		return ;
//    }
//	inverseAxViewTransform= (vtkTransform*)axViewTransform->GetLinearInverse();
//	float point[3];
//	unsigned int rcafoundatindex=0;
//	int rcaarea=0;
//	try
//    {
//		unsigned long printNum = statistics->GetNumberOfLabels();
//		if (printNum > 20)
//		{
//			printNum = 20;
//		}
//		float sizex,sizey,sizez,centerx,centery,centerz;
//		for (unsigned int ii=1; ii < printNum; ++ii)
//		{
//			const StatisticsFilterType::BoundingBoxType bbox = statistics->GetBoundingBox(ii);
//			
//			sizex=(bbox[1]-bbox[0])*xSpacing*2;
//			sizey=(bbox[3]-bbox[2])*ySpacing*2;
//			sizez=(bbox[5]-bbox[4])*zSpacing*2;
//			centerx=bbox[1]+bbox[0];
//			centery=bbox[3]+bbox[2];
//			centerz=bbox[5]+bbox[4];
//			point[0]=centerx*xSpacing+vtkOriginalX;
//			point[1]=centery*ySpacing+vtkOriginalY;
//			point[2]=centerz*zSpacing+vtkOriginalZ;
//			inverseAxViewTransform->TransformPoint(point,point);
//			
//			
//			if(sqrt(sizex*sizex+sizey*sizey+sizez*sizez)>20.0)
//			{
//				if(point[0]<0&&point[1]<0&&point[2]>-10.0&&(bbox[1]-bbox[0])*(bbox[3]-bbox[2])>rcaarea)
//				{
//					rcafoundatindex=ii;
//					rcaarea=(bbox[1]-bbox[0])*(bbox[3]-bbox[2]);
//					
//				}
//			}
//			
//		}
//		
//    }
//	catch (itk::ExceptionObject & excep)
//    {
//		NSLog(@"read statsitic  failed");
//		return ;
//    }
//	unsigned long*  labeloutput=relabel->GetOutput()->GetBufferPointer();
//	
//	
//	if(rcafoundatindex==0)
//		return;
//	int x,y,z;
//	unsigned char marker;
//	uniIndex++;
//	marker=uniIndex;
//	for(z=0;z<imageAmount/2;z++)
//		for(y=0;y<imageHeight/2;y++)
//			for(x=0;x<imageWidth/2;x++)
//			{
//				if((*(labeloutput+z*imageSize/4+y*imageWidth/2+x)==rcafoundatindex)&&(*(blenddata+z*imageSize/4+y*imageWidth/2+x)>15))
//					*(contrastVolumeData+z*2*imageSize+y*2*imageWidth+x*2) = marker;
//				
//				
//			}
//	unsigned char textureBuffer[16];
//	ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:4 textHeight:4 textName:currentSeedName positionX:0 positionY:0 spacingX:xSpacing spacingY:ySpacing imageOrigin:NSMakePoint( 0,  0)];
//	
//	CGFloat rv, gv, bv;
//	[currentSeedColor getRed:&rv green:&gv blue:&bv alpha:0L];
//	RGBColor c;
//	c.red =(short unsigned int) (rv * 65535.);
//	c.green =(short unsigned int)( gv * 65535.);
//	c.blue = (short unsigned int)(bv * 65535.);
//	NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
//	[newROI setComments:indexstr];	
//	
//	[newROI setColor:c];
//	[totalROIList addObject:newROI];
//	[newROI release];
//	
//	
//	
//}
//-(void)plantExtraSeedsForLeftCoronaryArtery
//{
//	
//	float* blenddata=vesselnessMap;
//	if(blenddata==nil)
//		return;
//	
//	typedef   float  InternalPixelType;
//	typedef   unsigned long   LabelPixelType;
//	const     unsigned int    Dimension = 3;
//	
//	float labellookuptable[40];
//	memset(labellookuptable, 0x00, 40*sizeof(float));
//	
//	typedef itk::Image< InternalPixelType, Dimension >  InternalImageType;
//	typedef itk::Image< LabelPixelType, Dimension>   LabelImageType;
//	
//	
//	typedef itk::ImportImageFilter< InternalPixelType, Dimension > ImportFilterType;
//	
//	ImportFilterType::Pointer importFilter;
//	
//	importFilter = ImportFilterType::New();
//	
//	ImportFilterType::SizeType itksize;
//	itksize[0] = imageWidth/2; // size along X
//	itksize[1] = imageHeight/2; // size along Y
//	itksize[2] = imageAmount/2;// size along Z
//	
//	ImportFilterType::IndexType start;
//	start.Fill( 0 );
//	
//	ImportFilterType::RegionType region;
//	region.SetIndex( start );
//	region.SetSize( itksize );
//	importFilter->SetRegion( region );
//	
//	double origin[ 3 ];
//	origin[0] = 0; // X coordinate
//	origin[1] = 0; // Y coordinate
//	origin[2] = 0; // Z coordinate
//	importFilter->SetOrigin( origin );
//	
//	double spacing[ 3 ];
//	spacing[0] = 1; // along X direction
//	spacing[1] = 1; // along Y direction
//	spacing[2] = 1; // along Z direction
//	importFilter->SetSpacing( spacing ); 
//	
//	const bool importImageFilterWillOwnTheBuffer = false;
//	importFilter->SetImportPointer( blenddata, itksize[0] * itksize[1] * itksize[2], importImageFilterWillOwnTheBuffer);
//	
//	
//	
//	
//	
//	typedef itk::BinaryThresholdImageFilter< InternalImageType, InternalImageType > ThresholdFilterType;
//	typedef itk::ConnectedComponentImageFilter< InternalImageType, LabelImageType > ConnectedComponentType;
//	typedef itk::RelabelComponentImageFilter< LabelImageType, LabelImageType > RelabelComponentType;
//	
//	typedef itk::LabelStatisticsImageFilter< InternalImageType, LabelImageType> StatisticsFilterType;
//	
//	ThresholdFilterType::Pointer threshold = ThresholdFilterType::New();
//	ConnectedComponentType::Pointer connected = ConnectedComponentType::New();
//	RelabelComponentType::Pointer relabel = RelabelComponentType::New();
//	
//	StatisticsFilterType::Pointer statistics = StatisticsFilterType::New();
//	
//	
//	
//	
//	threshold->SetInput (importFilter->GetOutput());
//	threshold->SetInsideValue(itk::NumericTraits<InternalPixelType>::One);
//	threshold->SetOutsideValue(itk::NumericTraits<InternalPixelType>::Zero);
//	threshold->SetLowerThreshold(5);
//	threshold->SetUpperThreshold(10000);
//	threshold->Update();
//	
//	// Label the components in the image and relabel them so that object
//	// numbers increase as the size of the objects decrease.
//	connected->SetInput (threshold->GetOutput());
//	relabel->SetInput( connected->GetOutput() );
//	//relabel->SetNumberOfObjectsToPrint( 5 );
//	relabel->SetMinimumObjectSize(50);
//	//relabel->Update();
//	//std::cout << "NumberOfObjects: " << relabel->GetNumberOfObjects() << " OriginalNumberOfObjects: " <<
//    //relabel->GetOriginalNumberOfObjects() << " MinimumObjectSize: " << relabel->GetMinimumObjectSize() << std::endl;
//	
//	try
//    {
//		//relabel->Modified();
//		relabel->Update();
//	}
//	catch( itk::ExceptionObject & excep )
//    {
//		NSLog(@"relable failed");
//		return ;
//    }
//	
//	
//	try
//    {
//		statistics->SetInput( importFilter->GetOutput() );
//		statistics->SetLabelInput( relabel->GetOutput() );
//		statistics->UseHistogramsOff();
//		statistics->Update();
//    }
//	catch( itk::ExceptionObject & excep )
//    {
//		NSLog(@"statsitic relable failed");
//		return ;
//    }
//	inverseAxViewTransform= (vtkTransform*)axViewTransform->GetLinearInverse();
//	float point[3];
//	unsigned int lcafoundatindex=0;
//	int lcatop=0,lcacenterx=0,lcacentery=0,lcarelativetop=0;
//	int lcaarea=0;
//	try
//    {
//		unsigned long printNum = statistics->GetNumberOfLabels();
//		if (printNum > 40)
//		{
//			printNum = 40;
//		}
//		float sizex,sizey,sizez,centerx,centery,centerz;
//		for (unsigned int ii=1; ii < printNum; ++ii)
//		{
//			const StatisticsFilterType::BoundingBoxType bbox = statistics->GetBoundingBox(ii);
//			
//			sizex=(bbox[1]-bbox[0])*xSpacing*2;
//			sizey=(bbox[3]-bbox[2])*ySpacing*2;
//			sizez=(bbox[5]-bbox[4])*zSpacing*2;
//			centerx=bbox[1]+bbox[0];
//			centery=bbox[3]+bbox[2];
//			centerz=bbox[5]+bbox[4];
//			point[0]=centerx*xSpacing+vtkOriginalX;
//			point[1]=centery*ySpacing+vtkOriginalY;
//			point[2]=centerz*zSpacing+vtkOriginalZ;
//			inverseAxViewTransform->TransformPoint(point,point);
//			
//			if(sqrt(sizex*sizex+sizey*sizey+sizez*sizez)>10.0)
//			{
//				if(point[0]>0&&point[2]>-30.0&&point[1]/point[0]<1&&(bbox[1]-bbox[0])*(bbox[3]-bbox[2])>lcaarea)
//				{
//					
//					lcafoundatindex=ii;
//					lcaarea=(bbox[1]-bbox[0])*(bbox[3]-bbox[2]);
//					lcatop=bbox[5];
//					lcarelativetop=point[2];
//					lcacenterx=bbox[1]+bbox[0];//&&(bbox[1]+bbox[0])>lcacenterx
//					lcacentery=bbox[3]+bbox[2];
//				}
//			}
//			
//			
//		}
//		if(lcafoundatindex)
//		{
//			labellookuptable[lcafoundatindex]=1;
//			for (unsigned int ii=1; ii < printNum; ++ii)
//			{
//				const StatisticsFilterType::BoundingBoxType bbox = statistics->GetBoundingBox(ii);
//				
//				sizex=(bbox[1]-bbox[0])*xSpacing*2;
//				sizey=(bbox[3]-bbox[2])*ySpacing*2;
//				sizez=(bbox[5]-bbox[4])*zSpacing*2;
//				centerx=bbox[1]+bbox[0];
//				centery=bbox[3]+bbox[2];
//				centerz=bbox[5]+bbox[4];
//				point[0]=centerx*xSpacing+vtkOriginalX;
//				point[1]=centery*ySpacing+vtkOriginalY;
//				point[2]=centerz*zSpacing+vtkOriginalZ;
//				inverseAxViewTransform->TransformPoint(point,point);
//				
//				if(lcafoundatindex!=ii&&sqrt(sizex*sizex+sizey*sizey+sizez*sizez)>10.0)
//				{
//					if(point[0]>0&&point[2]>-40.0&&point[2]<lcarelativetop&&point[1]/point[0]<0&&bbox[5]<lcatop&&(bbox[3]+bbox[2])<lcacentery)
//						labellookuptable[ii]=1;
//				}
//				
//			}
//		}
//    }
//	catch (itk::ExceptionObject & excep)
//    {
//		NSLog(@"read statsitic  failed");
//		return ;
//    }
//	
//	if(lcafoundatindex==0)
//		return;
//	
//	
//	unsigned long*  labeloutput=relabel->GetOutput()->GetBufferPointer();
//	
//	
//	
//	int x,y,z;
//	unsigned char marker;
//	uniIndex++;
//	marker=uniIndex;
//	for(z=0;z<imageAmount/2;z++)
//		for(y=0;y<imageHeight/2;y++)
//			for(x=0;x<imageWidth/2;x++)
//			{
//				int label=*(labeloutput+z*imageSize/4+y*imageWidth/2+x);
//				if(label&&labellookuptable[label])//&&(*(blenddata+z*imageSize/4+y*imageWidth/2+x)>10)
//					*(contrastVolumeData+z*2*imageSize+y*2*imageWidth+x*2) = marker;
//				
//				
//			}
//	unsigned char textureBuffer[16];
//	ROI *newROI=[[ROI alloc] initWithTexture:textureBuffer textWidth:4 textHeight:4 textName:currentSeedName positionX:0 positionY:0 spacingX:xSpacing spacingY:ySpacing imageOrigin:NSMakePoint( 0,  0)];
//	
//	CGFloat rv, gv, bv;
//	[currentSeedColor getRed:&rv green:&gv blue:&bv alpha:0L];
//	RGBColor c;
//	c.red =(short unsigned int) (rv * 65535.);
//	c.green =(short unsigned int)( gv * 65535.);
//	c.blue = (short unsigned int)(bv * 65535.);
//	NSString *indexstr=[NSString stringWithFormat:@"%d",uniIndex];
//	[newROI setComments:indexstr];	
//	
//	[newROI setColor:c];
//	[totalROIList addObject:newROI];
//	[newROI release];
//	
//	
//	
//}
//
	
@end

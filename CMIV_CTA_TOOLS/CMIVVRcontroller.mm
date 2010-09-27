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
#import "CMIVVRcontroller.h"
#import "QuicktimeExport.h"
#import "DICOMExport.h"
#include "VRMakeObject.h"
#import <QTKit/QTKit.h>
#import "OsiriX Headers/BrowserController.h"


static void needAdjustClipPlane(vtkObject*,unsigned long c, void* ptr, void*)
{
	CMIVVRcontroller* controller = (CMIVVRcontroller*) ptr;
	[controller resetClipPlane];
}
@implementation CMIVVRcontroller

-(NSImage*) imageForFrame:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	
	
	int curangle=[cur intValue]/maxMovieIndex;
	int cursegment=[cur intValue]%maxMovieIndex;
	QTMovie			*mMovie = [imagesFor4DQTVR objectAtIndex:0];
	QTTime			curTime;
	NSImage* curimage;
	long long timeValue =60*(cursegment*220+curangle);
	long timeScale = 600;
	curTime = QTMakeTime(timeValue, timeScale);
	curimage=[mMovie frameImageAtTime:curTime];
	
	return curimage;
	
	
}
-(NSImage*) imageForVR:(NSNumber*) cur maxFrame:(NSNumber*) max
{
	
	if ([max intValue]==220)
	{
		int iteminrow=20,itemincolumn=10;
		if( [cur intValue] == 0)
		{
			[vrViewer Vertical: 45];
			[vrViewer Vertical: 45];
			verticalAngleForVR=90;
		}
		else
		{
			if( verticalAngleForVR==-90 ) 
			{
				aCamera->Roll(360/iteminrow);
			}
			else if( verticalAngleForVR==90) 
			{
				aCamera->Roll(-360/iteminrow);
			}
			else
			{
				[vrViewer Vertical: -verticalAngleForVR];
			}
			
			if([cur intValue]%iteminrow==0)
			{
				if( verticalAngleForVR==-90 || verticalAngleForVR==90) 
				{
					[vrViewer Vertical: -45];
					[vrViewer Vertical: -45];
					aCamera->Azimuth(-360/iteminrow);
				}
				verticalAngleForVR-=180/itemincolumn;
				if( verticalAngleForVR==-90 ) 
				{
					aCamera->Azimuth(360/iteminrow);
					[vrViewer Vertical: -45];
					[vrViewer Vertical: -45];
				}
				
				
			}
			if( verticalAngleForVR!=-90 && verticalAngleForVR!=90)
			{
				aCamera->Azimuth(360/iteminrow);
				aCamera->Elevation(verticalAngleForVR);
			}
		}
	}
	NSImage* tempImage=[vrViewer nsimageQuicktime];
	if ([max intValue]==220)
	{
		int iteminrow=20;//itemincolumn=10;
		if( [cur intValue] == 219)
		{
			aCamera->Roll(360/iteminrow);
			[vrViewer Vertical: 45];
			[vrViewer Vertical: 45];
			verticalAngleForVR=0;
		}
	}
	return tempImage;
}
- (int) prepareImageFor4DQTVR
{
	QTTime			curTime;
	QTMovie			*mMovie = 0L;
	
	
	NSString		*fileName = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/TEMP/CMIV4DQTVR.mov"] ;
	NSDictionary *myDict = [NSDictionary dictionaryWithObjectsAndKeys: @"jpeg", QTAddImageCodecType, [NSNumber numberWithInt: codecHighQuality], QTAddImageCodecQuality, nil];	//qdrw , tiff, jpeg
	[[QTMovie movie] writeToFile: fileName withAttributes: 0L];
	
	mMovie = [QTMovie movieWithFile:fileName error:nil];
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	long long timeValue = 60;
	long timeScale = 600;
	
	curTime = QTMakeTime(timeValue, timeScale);
	
	int i,j;
	
	NSImage* tempImage;
	
	for(i=0;i<maxMovieIndex;i++)
	{
		[segmentList selectRow:i byExtendingSelection:NO];
		[self selectASegment:segmentList];
		
		for(j=0;j<220;j++)
		{
			NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
			
			tempImage=[self imageForVR:[NSNumber numberWithInt:j] maxFrame:[NSNumber numberWithInt:220]];
			[mMovie addImage:tempImage forDuration:curTime withAttributes: myDict];
			[pool release];
		}
	}
	[imagesFor4DQTVR addObject:mMovie];
	return [imagesFor4DQTVR count];
}

- (IBAction)capureImage:(id)sender
{
	if(!isSegmentVR)
	{
		int i;
		float			o[ 9];
		DCMPix *firstObject=[[originalViewController pixList] objectAtIndex: 0];
		
		DICOMExport		*dcmSequence = [[DICOMExport alloc] init];
		
		
		[dcmSequence setSeriesNumber:6700 + [[NSCalendarDate date] minuteOfHour]  + [[NSCalendarDate date] secondOfMinute]];
		[dcmSequence setSeriesDescription:@"4D VR"];
		[dcmSequence setSourceFile: [firstObject sourceFile]];
		
		[vrViewer renderImageWithBestQuality: YES waitDialog: NO];
		for(i=0;i<maxMovieIndex;i++)
		{
			NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
			float* newVolumeData=[originalViewController volumePtr:i];
			//[vrViewer movieBlendingChangeSource:i];
			[vrViewer movieChangeSource: newVolumeData];
			[self setBlendVolumeCLUT];
			
			volumeOfVRView = (vtkVolume * )[vrViewer volume]; 
			volumeMapper=(vtkVolumeMapper *) volumeOfVRView->GetMapper() ;
			if([cutPlaneSwitch state] == NSOnState)
				volumeMapper->AddClippingPlane(clipPlane1);
			
			[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:i ]];
			[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:i ]];
			[clutViewer setClutChanged];
			[clutViewer updateView];
	//		[clutViewer setCLUTtoVRViewWithoutRedraw];
//			[vrViewer display];
			[vrViewer renderImageWithBestQuality: YES waitDialog: NO display: YES];
			
			
			
			long	width, height, spp, bpp, err;
			
			unsigned char *dataPtr = [vrViewer getRawPixels:&width :&height :&spp :&bpp :YES :NO];
			[vrViewer endRenderImageWithBestQuality];
			if( dataPtr)
			{
				[vrViewer getOrientation: o];
				[dcmSequence setOrientation: o];
				
				[dcmSequence setPixelData: dataPtr samplePerPixel:spp bitsPerPixel:bpp width: width height: height];
				
				NSString *f = [dcmSequence writeDCMFile: 0L];
	
				if( f)
					[BrowserController addFiles: [NSArray arrayWithObject: f]
								 toContext: [[BrowserController currentBrowser] managedObjectContext]
								toDatabase: [BrowserController currentBrowser]
								 onlyDICOM: YES 
						  notifyAddedFiles: YES
					   parseExistingObject: YES
								  dbFolder: [[BrowserController currentBrowser] documentsDirectory]
						 generatedByOsiriX: YES];
				
				free( dataPtr);
			}
			
			[pool release];
		}
		
		[vrViewer endRenderImageWithBestQuality];
		
		
		
		
		[dcmSequence release];
		
		
	}
	else
	{
		[vrViewer exportDCMCurrentImage];
	}
}
- (IBAction)openQTVRExportDlg:(id)sender
{
	[NSApp beginSheet: qtvrsettingwin modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}
- (IBAction)creatQTVRFromFile:(id)sender
{
	int                 result;
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	
    
	
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    
    result = [oPanel runModalForDirectory:0L file:nil types:nil];
    
    if (result == NSOKButton) 
    {
		
		NSString* path;
		path=[[oPanel filenames] objectAtIndex: 0];
		
		QTTime			curTime;
		QTMovie			*mMovie = 0L;
		
		
		
		mMovie = [QTMovie movieWithFile:path error:nil];
		[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
		
		long long timeValue = 60;
		long timeScale = 600;
		
		curTime = QTMakeTime(timeValue, timeScale);
		imagesFor4DQTVR=[[NSMutableArray alloc] initWithCapacity: 0];
		[imagesFor4DQTVR addObject:mMovie];
		
		do
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :220*maxMovieIndex];
			path=[mov createMovieQTKit:YES :NO :[[[originalViewController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
			[mov release];
		}while(path);
		
		[imagesFor4DQTVR removeAllObjects];
		[imagesFor4DQTVR release];		
	}
}
- (IBAction)closeQTVRExportDlg:(id)sender
{
	int tag =[sender tag];
	[qtvrsettingwin orderOut:sender];
    [NSApp endSheet:qtvrsettingwin returnCode:tag];
}
- (IBAction)exportQTVR:(id)sender
{
	
	//FSRef				fsref;
	//FSSpec				spec, newspec;
	//	[vrViewer renderImageWithBestQuality: YES waitDialog: NO];
	if(!isSegmentVR)
	{
		//	[vrViewer renderImageWithBestQuality: YES waitDialog: NO];
		[self closeQTVRExportDlg:sender];
		imagesFor4DQTVR=[[NSMutableArray alloc] initWithCapacity: 0];
		
		[self prepareImageFor4DQTVR];
		NSString* path;
		do
		{
			QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForFrame: maxFrame:) :220*maxMovieIndex];
			path=[mov createMovieQTKit:YES :NO :[[[originalViewController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
			[mov release];
		}while(path);
		
		
		[imagesFor4DQTVR removeAllObjects];
		[imagesFor4DQTVR release];
		NSString		*fileName = [[self osirixDocumentPath] stringByAppendingPathComponent:@"/TEMP/CMIV4DQTVR.mov"] ;
		[[NSFileManager defaultManager] removeFileAtPath:fileName handler:nil];
	}
	else
	{
		verticalAngleForVR = 0;
		QuicktimeExport *mov = [[QuicktimeExport alloc] initWithSelector: self : @selector(imageForVR: maxFrame:) :220];
		
		NSString* path;
		
		path=[mov createMovieQTKit:YES :NO :[[[originalViewController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.name"]];
		
		[mov release];		
	}
	//	[vrViewer endRenderImageWithBestQuality];
	
	
}
- (IBAction)endPanel:(id)sender
{
	if(clipCallBack)
		[vrViewer renderWindow]->RemoveObserver(clipCallBack);
	if(clipPlaneWidget)
		clipPlaneWidget->Delete(); 
	if(clipCallBack)
		clipCallBack->Delete();
	if(clipPlane1)
		clipPlane1->Delete();
	clipCallBack=nil;
	clipPlaneWidget=nil;
	clipPlane1=nil;
	
	[segmentList setDataSource:nil];
	[[self window] performClose:sender];
}
- (void)windowWillClose:(NSNotification *)notification
{	
	if( [notification object] == [self window])
	{

		if(isSegmentVR)
		{
			
			if(volumePropteryOfVRView)
				volumeOfVRView->SetProperty( volumePropteryOfVRView);
			[propertyDictList removeAllObjects];
			if(colorMapFromFile)
				free(colorMapFromFile);
		}
		unsigned int i,j;
		for(i=0;i<[mutiplePhaseOpacityCurves count];i++)//evever segment or volume
		{
			for(j=0;j<[[mutiplePhaseOpacityCurves objectAtIndex:i] count];j++)//ever curve for each segment or volume
			{
				[[[mutiplePhaseOpacityCurves objectAtIndex:i] objectAtIndex:j] removeAllObjects];
				[[[mutiplePhaseColorCurves objectAtIndex:i] objectAtIndex:j] removeAllObjects];
			}
			[[mutiplePhaseOpacityCurves objectAtIndex:i] removeAllObjects];
			[[mutiplePhaseColorCurves objectAtIndex:i] removeAllObjects];
		}
		
		[mutiplePhaseOpacityCurves removeAllObjects];
		[mutiplePhaseColorCurves removeAllObjects];
		[mutiplePhaseOpacityCurves release];
		[mutiplePhaseColorCurves release];
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		if(	inROIArray)
			[inROIArray removeAllObjects];
		
		[[self window] setDelegate:nil];	
		[originalViewController release];
		[originalViewVolumeData release];
		[originalViewPixList release];
		[self release];
		
	}	
}
-(void) dealloc
{
	if(clipCallBack)
		[vrViewer renderWindow]->RemoveObserver(clipCallBack);
	if(clipPlaneWidget)
		clipPlaneWidget->Delete(); 
	if(clipCallBack)
		clipCallBack->Delete();
	if(clipPlane1)
		clipPlane1->Delete();
	
	[super dealloc];
	[vrViewer prepareForRelease];
}


- (IBAction)setColorProtocol:(id)sender
{
	unsigned int row = [segmentList selectedRow];
	[self applyCLUTToPropertyList:row];
	[self applyCLUT];
}
- (IBAction)setBackgroundColor:(id)sender
{
	[vrViewer changeColorWith:[colorControl color]];
	
}
- (IBAction)setOpacity:(id)sender
{
	unsigned int row = [segmentList selectedRow];
	float opacity = [opacitySlider floatValue];
	if(row>=0&&row<[propertyDictList count])
		[[propertyDictList objectAtIndex: row] setObject: [NSNumber numberWithFloat:opacity]  forKey:@"Opacity"];
	[self applyOpacity];
	[segmentList reloadData];
}

- (IBAction)setWLWW:(id)sender
{
	float ww,wl;
	ww = [wwSlider floatValue];
	wl = [wlSlider floatValue];	
	unsigned int i;	
	
	if([wlwwForAll state] == NSOnState)
	{
		
		for(i=0;i<[propertyDictList count];i++)
		{
			
			
			[[propertyDictList objectAtIndex:i] setObject: [NSNumber numberWithFloat:ww]  forKey:@"WW"];
			[[propertyDictList objectAtIndex:i] setObject: [NSNumber numberWithFloat:wl]  forKey:@"WL"];
		}
	}
	else
	{
		i = [segmentList selectedRow];
		if(i>=0&&i<[propertyDictList count])
		{
			[[propertyDictList objectAtIndex:i] setObject: [NSNumber numberWithFloat:ww]  forKey:@"WW"];
			[[propertyDictList objectAtIndex:i] setObject: [NSNumber numberWithFloat:wl]  forKey:@"WL"];			
		}
		
	}
	
	[self applyCLUT];
	[self applyOpacity];	
	
}
- (id) showVRPanel:(ViewerController *) vc:(CMIV_CTA_TOOLS*) owner
{
	//initialize the window
	self = [super initWithWindowNibName:@"VR_Panel"];
	[[self window] setDelegate:self];
	
	//prepare vtk volume for 4d or 3.5d data
	int err=0;
	
	originalViewController=vc;	
	parent = owner;
	blendingController=[vc blendingController];
	originalViewVolumeData=[vc volumeData];
	originalViewPixList=[vc pixList];
	
	[originalViewController retain];
	[originalViewVolumeData retain];
	[originalViewPixList retain];
	
	maxMovieIndex=[vc maxMovieIndex];
	if(maxMovieIndex>1)
		isSegmentVR=0;
	else
		isSegmentVR=1;
	
	if(isSegmentVR)
		err= [self initVRViewForSegmentalVR];
	else
	{
		err= [self initVRViewForDynamicVR];
		// show the window
		screenrect=[[[originalViewController window] screen] visibleFrame];
		[[self window]setFrame:screenrect display:NO animate:NO];
		[super showWindow:parent];

	}
	if(err)
	{
		[self endPanel:self];
		return nil;
	}
	
	[[self window] makeKeyAndOrderFront:parent];
	[[self window] display];
	[[self window] setMovableByWindowBackground:NO];
	
	
	//
	volumeOfVRView = (vtkVolume * )[vrViewer volume]; 
	fixedPointVolumeMapper=(vtkVolumeMapper *) volumeOfVRView->GetMapper() ;
	volumeMapper=fixedPointVolumeMapper;
	volumeImageData=(vtkImageData *)volumeMapper->GetInput();
	realVolumedata=(unsigned short*)volumeImageData->GetScalarPointer();

	 // Prepare clipPlane
	 clipPlane1=vtkPlane::New();
	 //volumeMapper->AddClippingPlane(clipPlane1);
	 double* tempcenter;
	 tempcenter=volumeOfVRView->GetCenter();
	 
	 clipPlane1->SetOrigin(tempcenter);
	 clipPlane1->SetNormal(1,0,0);
	 clipCallBack = vtkCallbackCommand::New();
	 clipCallBack->SetCallback( needAdjustClipPlane);
	 clipCallBack->SetClientData( self);  
	 // need vtk graphics library but cause crash for 2d cross section measurement.
	 
	 
	 [vrViewer renderWindow]->AddObserver(vtkCommand::StartEvent, clipCallBack);
	// clipPlaneWidget=vtkPlaneWidget::New(); 
	
	//Prepare the 16bit CLUT
	[self initCLUTView];
	if(isSegmentVR)
	{
		[clutViewer setVRController:self];
		[self initTaggedColorList];
	}
	
	
	return self;
	
}

- (void)initTaggedColorList
{
	unsigned int i;
	RGBColor	color;
	ROI * tempROI;	
	
	for(i=0;i<[inROIArray count];i++)
	{
		tempROI = [inROIArray objectAtIndex: i];	
		color= [tempROI rgbcolor];
		NSMutableArray *someColors = [[mutiplePhaseColorCurves objectAtIndex:i+1] objectAtIndex:0];
		[someColors replaceObjectAtIndex:1 withObject:[NSColor colorWithDeviceRed:color.red/65536.0 green:color.green/65536.0 blue:color.blue/65536.0 alpha:1.0]];
		[someColors replaceObjectAtIndex:2 withObject:[NSColor colorWithDeviceRed:color.red/65536.0 green:color.green/65536.0 blue:color.blue/65536.0 alpha:1.0]];
	}		
	
}
- (int)loadMaskFromTempFolder
{
	int step=0;//[parent loadCrashBackup];
	if(step!=101)
	{
		return 0;
		
	}
	int size = sizeof(unsigned char ) * imageWidth * imageHeight * imageAmount;
	
	NSMutableDictionary* dic=[parent dataOfWizard];

	NSNumber* maskmapsize=[dic objectForKey:@"MaskMapSize"];
	if(size!=[maskmapsize intValue])
	{
		NSLog(@"maskmapsize doesn't match");
		return 0;
	}
	colorMapFromFile=(unsigned char*)malloc(size);
	if(!colorMapFromFile)
	{
		NSLog(@"no enough memory for mask map");
		return 0;
	}
	NSArray* seednamearray=[dic objectForKey:@"SeedNameArray"];

	NSArray* seedscolorR=[dic objectForKey:@"SeedsColorR"];
	NSArray* seedscolorG=[dic objectForKey:@"SeedsColorG"];
	NSArray* seedscolorB=[dic objectForKey:@"SeedsColorB"];
	
	NSString* maskmapfile=[dic objectForKey:@"MaskMapPath"];

	FILE* tempFile;
	tempFile= fopen([maskmapfile cString],"r");
	fread(colorMapFromFile,sizeof(char),[maskmapsize intValue],tempFile);
	fclose(tempFile);
	[inROIArray removeAllObjects];
	unsigned int i;

	for(i=0;i<[seednamearray count];i++)
	{
		
		ROI *newROI;

		newROI=[[ROI alloc] initWithType: tOval :1.0 :1.0 : NSMakePoint( 0, 0)];
		[newROI setName:[seednamearray objectAtIndex:i]];
	
		RGBColor c;

		c.red =[[seedscolorR objectAtIndex:i] intValue];
		c.green =[[seedscolorG objectAtIndex:i] intValue];
		c.blue = [[seedscolorB objectAtIndex:i] intValue];

		[newROI setColor:c];
		[inROIArray addObject:newROI];
		[newROI release];
		
	}
	[parent cleanDataOfWizard];
	return 1;
	
}
- (void) initCLUTView
{
	
	[clutViewer setVolumePointer:originalVolumeData width:imageWidth height:imageHeight numberOfSlices:imageAmount];
	[clutViewer setHUmin:minInSeries HUmax:maxInSeries];
	[clutViewer computeHistogram];
	[clutViewer addCurveIfNeeded];
	[clutViewer updateView];
	[clutViewer setCLUTtoVRView:NO];
	mutiplePhaseOpacityCurves=[[NSMutableArray alloc] initWithCapacity: 0];
	mutiplePhaseColorCurves=[[NSMutableArray alloc] initWithCapacity: 0];
	isShowingVolumeArray=[[NSMutableArray alloc] initWithCapacity: 0];
	int i;
	if(isSegmentVR)
	{
		for(i=0;i<(signed)[propertyDictList count];i++)
		{
			NSMutableArray* opacitycurves=[NSMutableArray arrayWithCapacity:0];
			[mutiplePhaseOpacityCurves addObject:opacitycurves];
			NSMutableArray* colorcurvers=[NSMutableArray arrayWithCapacity:0];
			[mutiplePhaseColorCurves addObject:colorcurvers];
			[clutViewer setCurves:opacitycurves];
			[clutViewer setPointColors:colorcurvers];
			[clutViewer newCurve:self];
			[isShowingVolumeArray addObject:[NSNumber numberWithInt:1]];
		}
	}
	else
	{
		for(i=0;i<maxMovieIndex;i++)
		{
			NSMutableArray* opacitycurves=[NSMutableArray arrayWithCapacity:0];
			[mutiplePhaseOpacityCurves addObject:opacitycurves];
			NSMutableArray* colorcurvers=[NSMutableArray arrayWithCapacity:0];
			[mutiplePhaseColorCurves addObject:colorcurvers];
			[clutViewer setCurves:opacitycurves];
			[clutViewer setPointColors:colorcurvers];
			[clutViewer newCurve:self];
		}
	}
	[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:0 ]];
	[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:0 ]];
	
	//	[clutOpacityView newCurve:self];
	//if(![view advancedCLUT])[[[clutPopup menu] itemAtIndex:0] setTitle:NSLocalizedString(@"16-bit CLUT", nil)];
	//if(![view advancedCLUT])[self setCurCLUTMenu:NSLocalizedString(@"16-bit CLUT", nil)];
	//[OpacityPopup setEnabled:NO];
}
- (int) initVRViewForSegmentalVR
{
	int err=0;
	DCMPix*				curPix = [[originalViewController pixList] objectAtIndex: [[originalViewController imageView] curImage]];;
	NSMutableArray				*pixList = [originalViewController pixList];
	
	
	maxInSeries = [curPix maxValueOfSeries];
	minInSeries = [curPix minValueOfSeries];
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [pixList count];
	//initilize proptery list
	propertyDictList = [[NSMutableArray alloc] initWithCapacity: 0];
	
	inROIArray = [[NSMutableArray alloc] initWithCapacity: 0];
	NSMutableArray *curRoiList = [originalViewController roiList];
	
	ROI * tempROI;	
	unsigned int i,j,k;
	if(![self loadMaskFromTempFolder])
	{
		int thereIsSameName ;
		for(i=0;i<[curRoiList count];i++)
			for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
			{
				tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
				thereIsSameName=0;
				if([tempROI type]==tPlain)
				{
					for(k=0;k<[inROIArray count];k++)
					{ 
						if ([[tempROI name] isEqualToString:[[inROIArray objectAtIndex: k] name]]==YES)
							thereIsSameName=1;
					}
					if(!thereIsSameName)
					{
						[inROIArray addObject:tempROI];
					}	
				}
				
			}
	}
	
	NSMutableDictionary *tempProperyDict;
	float segmentWW,segmentWL;
	//	segmentWW=[curPix ww];
	//	segmentWL=[curPix wl];
	segmentWW = 600;
	segmentWL = 200;
	segmentWW = segmentWW*2047/(maxInSeries-minInSeries);
	segmentWL = (segmentWL-minInSeries)*2047/(maxInSeries-minInSeries);
	[wlSlider setFloatValue: segmentWL];
	[wwSlider setFloatValue: segmentWW];
	RGBColor	color;
	
	
	NSMutableArray *rArray,*gArray,*bArray,*xArray;
	
	rArray = [[NSMutableArray alloc] initWithCapacity: 0];
	gArray = [[NSMutableArray alloc] initWithCapacity: 0];
	bArray = [[NSMutableArray alloc] initWithCapacity: 0];
	xArray = [[NSMutableArray alloc] initWithCapacity: 0];
	
	[rArray addObject: [NSNumber numberWithFloat:0.0]];
	[gArray addObject: [NSNumber numberWithFloat:0.0]];
	[bArray addObject: [NSNumber numberWithFloat:0.0]];
	[xArray addObject: [NSNumber numberWithFloat:0.0]];
	
	[rArray addObject: [NSNumber numberWithFloat:1.0]];		
	[gArray addObject: [NSNumber numberWithFloat:0.0]];		
	[bArray addObject: [NSNumber numberWithFloat:0.0]];
	[xArray addObject: [NSNumber numberWithFloat:1024.0]];
	
	[rArray addObject: [NSNumber numberWithFloat:1.0]];		
	[gArray addObject: [NSNumber numberWithFloat:1.0]];		
	[bArray addObject: [NSNumber numberWithFloat:0.0]];
	[xArray addObject: [NSNumber numberWithFloat:1500.0]];
	
	[rArray addObject: [NSNumber numberWithFloat:1.0]];
	[gArray addObject: [NSNumber numberWithFloat:1.0]];	
	[bArray addObject: [NSNumber numberWithFloat:1.0]];
	[xArray addObject: [NSNumber numberWithFloat:2047.0]];	
	
	
	
	
	
	tempProperyDict = [NSMutableDictionary dictionary];
	[tempProperyDict setObject:[NSString stringWithString:@"other part"]  forKey:@"Name"];
	[tempProperyDict setObject: [NSNumber numberWithFloat:0.0] forKey:@"RangeFrom"];
	[tempProperyDict setObject: rArray forKey:@"RedTable"];
	[tempProperyDict setObject: gArray forKey:@"GreenTable"];
	[tempProperyDict setObject: bArray forKey:@"BlueTable"];
	[tempProperyDict setObject: xArray forKey:@"xTableForColorPoints"];
	[tempProperyDict setObject: [NSNumber numberWithFloat:0.001]  forKey:@"Opacity"];
	[tempProperyDict setObject: [NSNumber numberWithFloat:segmentWW]  forKey:@"WW"];
	[tempProperyDict setObject: [NSNumber numberWithFloat:segmentWL]  forKey:@"WL"];
	[propertyDictList addObject: tempProperyDict];	
	
	for(i=0;i<[inROIArray count];i++)
	{
		tempROI = [inROIArray objectAtIndex: i];	
		
		rArray = [[NSMutableArray alloc] initWithCapacity: 0];
		gArray = [[NSMutableArray alloc] initWithCapacity: 0];
		bArray = [[NSMutableArray alloc] initWithCapacity: 0];
		xArray = [[NSMutableArray alloc] initWithCapacity: 0];
		[rArray addObject: [NSNumber numberWithFloat:0.0]];
		[gArray addObject: [NSNumber numberWithFloat:0.0]];
		[bArray addObject: [NSNumber numberWithFloat:0.0]];
		[xArray addObject: [NSNumber numberWithFloat:0.0]];
		color= [tempROI rgbcolor];
		[rArray addObject: [NSNumber numberWithFloat:color.red/65536.0]];		
		[gArray addObject: [NSNumber numberWithFloat:color.green /65536.0]];		
		[bArray addObject: [NSNumber numberWithFloat:color.blue/65536.0]];
		[xArray addObject: [NSNumber numberWithFloat:1024.0]];
		
		[rArray addObject: [NSNumber numberWithFloat:1.0]];
		[gArray addObject: [NSNumber numberWithFloat:1.0]];
		[bArray addObject: [NSNumber numberWithFloat:1.0]];
		[xArray addObject: [NSNumber numberWithFloat:2047.0]];
		
		
		
		
		
		
		tempProperyDict = [NSMutableDictionary dictionary];
		[tempProperyDict setObject: [tempROI name] forKey:@"Name"];
		[tempProperyDict setObject: [NSNumber numberWithFloat:(i+1)*2048.0] forKey:@"RangeFrom"];
		[tempProperyDict setObject: rArray forKey:@"RedTable"];
		[tempProperyDict setObject: gArray forKey:@"GreenTable"];
		[tempProperyDict setObject: bArray forKey:@"BlueTable"];
		[tempProperyDict setObject: xArray forKey:@"xTableForColorPoints"];
		[tempProperyDict setObject: [NSNumber numberWithFloat:1.0]  forKey:@"Opacity"];
		[tempProperyDict setObject: [NSNumber numberWithFloat:segmentWW]  forKey:@"WW"];
		[tempProperyDict setObject: [NSNumber numberWithFloat:segmentWL]  forKey:@"WL"];
		[propertyDictList addObject: tempProperyDict];
	}
	
	curProperyDict = [propertyDictList objectAtIndex: 0];
	
	wholeVolumeWW = [propertyDictList count]*2048;
	wholeVolumeWL = wholeVolumeWW/2;
	
	if([curPix SUVConverted])
	{
		NSRunCriticalAlertPanel( NSLocalizedString(@"SUVConverted",nil), NSLocalizedString( @"SUVConverted is true, can not apply segment volume rendering.",nil), NSLocalizedString(@"OK",nil), nil, nil);	
		return 0;
	}
	if( [curPix isRGB])
	{
		NSRunAlertPanel(NSLocalizedString(@"no RGB Support", nil), NSLocalizedString(@"This plugin doesn't surpport RGB images, please convert this series into BW images first", nil), NSLocalizedString(@"OK", nil), nil, nil);
		
		return 0;
	}	
	
	
	//initilize VR view	
	
	originalVolumeData=[originalViewController volumePtr:0];
	err = [vrViewer setPixSource:pixList :originalVolumeData ];
	//clutViewPoints=[colorViewer getPoints];
	//clutViewColors=[colorViewer getColors];
	NSString* path=[parent osirixDocumentPath];
	NSString	*str =  [path stringByAppendingString:@"/CMIVCTACache/VRT.sav"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
//	if(dict)
//		[self applyAdvancedCLUT:dict];

	if( err != 0)
	{
		NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		return err;
	}
	[vrViewer set3DStateDictionary:dict];	
	
	// get the control of color and opacity;	
	renderOfVRView = [vrViewer renderer];
	aCamera = renderOfVRView->GetActiveCamera();
	//volumeCollectionOfVRView = renderOfVRView->GetVolumes();
	volumeOfVRView = (vtkVolume * )[vrViewer volume]; //volumeOfVRView = (vtkVolume * )volumeCollectionOfVRView->GetItemAsObject (0);
	volumePropteryOfVRView = volumeOfVRView->GetProperty();
	myVolumeProperty = vtkVolumeProperty::New();
	myColorTransferFunction = vtkColorTransferFunction::New();
	myOpacityTransferFunction = vtkPiecewiseFunction::New();
	myVolumeProperty->SetColor( myColorTransferFunction );
	myVolumeProperty->SetScalarOpacity(myOpacityTransferFunction);
	myVolumeProperty->ShadeOn();
	myVolumeProperty->SetAmbient(0.15);
	myVolumeProperty->SetDiffuse(0.9);
	myVolumeProperty->SetSpecular(0.3);
	myVolumeProperty->SetSpecularPower(15);
	myVolumeProperty->SetShade( 1);
	
	
	
	
	//	if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask)
	//		myVolumeProperty->SetInterpolationTypeToNearest();
	//   else 
	//		myVolumeProperty->SetInterpolationTypeToLinear();// can not use linear interpolation because the CT value jump at edge
	volumeOfVRView->SetProperty( myVolumeProperty);
	
	//	myGradientTransferFunction = vtkPiecewiseFunction::New();
	//	myGradientTransferFunction->AddPoint(3,0.0);
	//	myGradientTransferFunction->AddPoint(4,1.0);
	////	myGradientTransferFunction->AddPoint(2000,1.0);
	//	myGradientTransferFunction->AddPoint(2001,0.0);
	//	volumePropteryOfVRView->SetGradientOpacity( myGradientTransferFunction );
	//	volumePropteryOfVRView->ShadeOff ();
	//	volumePropteryOfVRView->SetInterpolationTypeToLinear();// can not use linear interpolation because the CT value jump at edge
	
	
	
	//create new datevolume and new pixlist
	
	float tempfloat;
	
	fixedPointVolumeMapper=(vtkVolumeMapper *) volumeOfVRView->GetMapper() ;
	volumeMapper=fixedPointVolumeMapper;
	volumeImageData=(vtkImageData *)volumeMapper->GetInput();
	realVolumedata=(unsigned short*)volumeImageData->GetScalarPointer();
	

	unsigned int size=(unsigned int)(imageWidth*imageHeight*imageAmount);
	for(i=0;i<size;i++)
	{
		if(*(originalVolumeData+i)>10000)
			tempfloat=0;
		tempfloat=( (*(originalVolumeData+i))-minInSeries)*2047/(maxInSeries-minInSeries);
		if( tempfloat<=0)
			tempfloat= 1.0;
		else if(tempfloat>2047.0)
			tempfloat = 2047.0;
		*(realVolumedata+i)=(unsigned short)tempfloat;
	}
	if(colorMapFromFile)
	{
		for(i=0;i<size;i++)
		{
			
			*(realVolumedata+i)+=(*(colorMapFromFile+i))*2048;
		}
	}
	else
	{
		unsigned short segOffset;
		//set segment value
		int x,y,x1,x2,y1,y2,textureWidth;
		unsigned char * texture;
		for(i=0;i<[curRoiList count];i++)
			for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
			{
				tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
				
				if([tempROI type]==tPlain)
					for(k=0;k<[inROIArray count];k++)
						if ([[tempROI name] isEqualToString:[[inROIArray objectAtIndex: k] name]]==YES)
						{
							x1 = [tempROI textureUpLeftCornerX];
							y1 = [tempROI textureUpLeftCornerY];
							x2 = [tempROI textureDownRightCornerX];
							y2 = [tempROI textureDownRightCornerY];
							textureWidth = [tempROI textureWidth];
							texture = [tempROI textureBuffer];
							segOffset = (unsigned short)[[[propertyDictList objectAtIndex: k+1] objectForKey:@"RangeFrom"] floatValue];
							for(y=y1;y<=y2;y++)
								for(x=x1;x<=x2;x++)
								{
									if(*(texture+(y-y1)*textureWidth+x-x1))
										*(realVolumedata+imageWidth*imageHeight*i+imageWidth*y+x)+=segOffset;
									
								}
							
							
							
						}
				
				
			}
	}

	
	osirixOffset=0;//[vrViewer offset];
	//osirixOffset-=100;
	float osirixValueFactor;
	osirixValueFactor =1.0;// [vrViewer valueFactor];
	//	[vrViewer setShadingValues: 0:0 :0:0];
	//	[vrViewer setEngine: 0];
	//	[vrViewer setMode: 0];
	[self applyOpacity];	
	[self applyCLUT];
	// show the window
	screenrect=[[[originalViewController window] screen] visibleFrame];
	//[[self window]setFrame:screenrect display:NO animate:NO];
	[super showWindow:parent];
	
	[segmentList setDataSource:self];	
	
	size=imageWidth*imageHeight*imageAmount;
	for(i=0;i<size;i++)
	{
		tempfloat=( (*(originalVolumeData+i))-minInSeries)*2047/(maxInSeries-minInSeries);
		if( tempfloat<=0)
			tempfloat= 1.0;
		else if(tempfloat>2047.0)
			tempfloat = 2047.0;
		*(realVolumedata+i)=(unsigned short)tempfloat;
	}
	//set segment value
	if(colorMapFromFile)
	{
		for(i=0;i<size;i++)
		{

			*(realVolumedata+i)+=(*(colorMapFromFile+i))*2048;
		}
	}
	else
	{
		unsigned short segOffset;
		int x,y,x1,x2,y1,y2,textureWidth;
		unsigned char * texture;
		for(i=0;i<[curRoiList count];i++)
			for(j=0;j<[[curRoiList objectAtIndex:i] count];j++)
			{
				tempROI = [[curRoiList objectAtIndex: i] objectAtIndex:j];
				
				if([tempROI type]==tPlain)
					for(k=0;k<[inROIArray count];k++)
						if ([[tempROI name] isEqualToString:[[inROIArray objectAtIndex: k] name]]==YES)
						{
							x1 = [tempROI textureUpLeftCornerX];
							y1 = [tempROI textureUpLeftCornerY];
							x2 = [tempROI textureDownRightCornerX];
							y2 = [tempROI textureDownRightCornerY];
							textureWidth = [tempROI textureWidth];
							texture = [tempROI textureBuffer];
							segOffset = (unsigned short)[[[propertyDictList objectAtIndex: k+1] objectForKey:@"RangeFrom"] floatValue];
							for(y=y1;y<=y2;y++)
								for(x=x1;x<=x2;x++)
								{
									if(*(texture+(y-y1)*textureWidth+x-x1))
										*(realVolumedata+imageWidth*imageHeight*i+imageWidth*y+x)+=segOffset;
									
								}
		
						}
				
				
			}
		
	}
	return err;
	
}
- (int) initVRViewForDynamicVR
{
	int err=0;
	
	NSMutableArray				*pixList = [originalViewController pixList];
	
	originalVolumeData=[originalViewController volumePtr:0];
	err = [vrViewer setPixSource:pixList :originalVolumeData ];
	if(blendingController)
	{
		[vrViewer setBlendingPixSource: blendingController];
		[self setBlendVolumeCLUT];
	}
	
	DCMPix*				curPix = [[originalViewController pixList] objectAtIndex: [[originalViewController imageView] curImage]];;
	maxInSeries = [curPix maxValueOfSeries];
	minInSeries = [curPix minValueOfSeries];
	imageWidth = [curPix pwidth];
	imageHeight = [curPix pheight];
	imageAmount = [pixList count];
	
	NSString* path=[parent osirixDocumentPath];
	NSString	*str =  [path stringByAppendingString:@"/CMIVCTACache/VRT.sav"];
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: str];
//	if(dict)
//		[self applyAdvancedCLUT:dict];
	[vrViewer set3DStateDictionary:dict];
	if( err != 0)
	{
		NSRunCriticalAlertPanel( NSLocalizedString(@"Not Enough Memory",nil), NSLocalizedString( @"Not enough memory (RAM) to use the 3D engine.",nil), NSLocalizedString(@"OK",nil), nil, nil);
		return 0L;
	}
	
	
	[self SetMusclarCLUT];
	
	renderOfVRView = [vrViewer renderer];
	aCamera = renderOfVRView->GetActiveCamera();
	[opacitySlider setEnabled: NO];
	[wlSlider setEnabled: NO];
	[wwSlider setEnabled: NO];
	[segmentList setDataSource:self];	
	
	return err;
	
}
- (IBAction)disableCLUTView:(id)sender
{
	unsigned int row = [segmentList selectedRow];
	if([sender state]== NSOnState)
	{	//[self SetMusclarCLUT];
		[isShowingVolumeArray replaceObjectAtIndex:row withObject:[NSNumber numberWithInt:1]];
	}
	else
	{	//[self initCLUTView];
		[isShowingVolumeArray replaceObjectAtIndex:row withObject:[NSNumber numberWithInt:0]];
	}
	[clutViewer setClutChanged];
	[clutViewer updateView];

	
	
}
- (void)setBlendVolumeCLUT
{
	if(blendingController)
	{
		
		Pixel_8			*alphaTable, *redTable, *greenTable, *blueTable;
		float			iwl, iww;
		
		[[originalViewController imageView] blendingColorTables:&alphaTable :&redTable :&greenTable :&blueTable];
		
		[vrViewer setBlendingCLUT :redTable :greenTable :blueTable];
		
		[[blendingController imageView] getWLWW: &iwl :&iww];
		[vrViewer setBlendingWLWW :iwl :iww];
		
		renderOfVRView = [vrViewer renderer];
		
		volumeCollectionOfVRView = renderOfVRView->GetVolumes();
		volumeOfVRView = (vtkVolume * )volumeCollectionOfVRView->GetItemAsObject (1);
		fixedPointVolumeMapper=(vtkVolumeMapper *) volumeOfVRView->GetMapper() ;
		blendedVolumeMapper=fixedPointVolumeMapper;
	}
		
}
- (void) SetMusclarCLUT
{
	NSDictionary		*aCLUT,*aOpacity;
	NSArray				*array;
	long				i;
	unsigned char		red[256], green[256], blue[256];
	
	aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey: @"VR Muscles-Bones"];
	if( aCLUT)
	{
		array = [aCLUT objectForKey:@"Red"];
		for( i = 0; i < 256; i++)
		{
			red[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Green"];
		for( i = 0; i < 256; i++)
		{
			green[i] = [[array objectAtIndex: i] longValue];
		}
		
		array = [aCLUT objectForKey:@"Blue"];
		for( i = 0; i < 256; i++)
		{
			blue[i] = [[array objectAtIndex: i] longValue];
		}
		
		[vrViewer setCLUT:red :green: blue];
		
	}
	aOpacity = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"OPACITY"] objectForKey: NSLocalizedString(@"Logarithmic Inverse Table", nil)];
	if( aOpacity)
	{
		array = [aOpacity objectForKey:@"Points"];
		
		[vrViewer setOpacity:array];
	}
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if([segmentList isEqual:tableView])
	{
		if(isSegmentVR)
		{
			return [propertyDictList count];
		}
		else
		{
			return maxMovieIndex;
		}
	}
	
	return 0;
	
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(int)row
{
	if( originalViewController == 0L) return 0L;
	if([segmentList isEqual:tableView])
	{
		if(isSegmentVR)
		{
			
			if( [[tableColumn identifier] isEqualToString:@"Index"])
			{
				return [NSString stringWithFormat:@"%d", row+1];
			} 
			if( [[tableColumn identifier] isEqualToString:@"Name"])
			{
				return [[propertyDictList objectAtIndex:row] objectForKey:@"Name"];
			}
			if( [[tableColumn identifier] isEqualToString:@"Opacity"])
			{
				return [[propertyDictList objectAtIndex:row] objectForKey:@"Opacity"];
			}
		}
		else
		{
			if( [[tableColumn identifier] isEqualToString:@"Index"])
			{
				return [NSString stringWithFormat:@"%d", row+1];
			} 
			if( [[tableColumn identifier] isEqualToString:@"Name"])
			{
				return [NSString stringWithFormat:@"volume%d", row+1];
			}
			if( [[tableColumn identifier] isEqualToString:@"Not Available"])
			{
				return @"Opacity";
			}
			
		}
	}
	
	
	return 0L;
}
- (void)applyOpacity
{
	int err=0;
	myOpacityTransferFunction->RemoveAllPoints ();
	unsigned int i;
	float offset,val;
	float ww,wl,start,end;
	for(i=0;i<[propertyDictList count];i++)
	{
		offset = [[[propertyDictList objectAtIndex:i] objectForKey:@"RangeFrom"] floatValue];
		offset += osirixOffset;
		val = 0.0;
		err=myOpacityTransferFunction->AddPoint (offset, val);
		ww = [[[propertyDictList objectAtIndex:i]objectForKey:@"WW"]floatValue];
		wl = [[[propertyDictList objectAtIndex:i]objectForKey:@"WL"]floatValue];	
		start = wl-ww/2;
		end = wl+ww/2;
		if(start>0)
			err=myOpacityTransferFunction->AddPoint (start+offset, val);			
		
		val = [[[propertyDictList objectAtIndex:i] objectForKey:@"Opacity"] floatValue];
		if(end<2047)
			err=myOpacityTransferFunction->AddPoint (offset+end, val);
		
		err=myOpacityTransferFunction->AddPoint (offset+2047.0, val);
	}
	[vrViewer setWLWW: wl :ww];
	
}
- (void)setAdvancedCLUT:(NSMutableDictionary*)clut lowResolution:(BOOL)lowRes
{
	
	unsigned row;
	float x,maxx,maxval,offset,val,zoomfactor;
	zoomfactor=2047/(maxInSeries-minInSeries);
	myColorTransferFunction->RemoveAllPoints();
	myOpacityTransferFunction->RemoveAllPoints();

	for(row=0;row<[mutiplePhaseOpacityCurves count];row++)
	{
		
		NSArray *curves = [mutiplePhaseOpacityCurves objectAtIndex:row ];
		NSArray *pointColors = [mutiplePhaseColorCurves objectAtIndex:row ];
		if([mutiplePhaseColorCurves count]<=0)
			continue;
		
		offset = [[[propertyDictList objectAtIndex:row] objectForKey:@"RangeFrom"] floatValue];
		offset += osirixOffset;
		maxx=offset;
		val = 0.0;
		myOpacityTransferFunction->AddPoint (offset, val);
		myColorTransferFunction->AddRGBPoint(offset,0,0,0);
		
		unsigned int i,j;
		int ifshowing=[[isShowingVolumeArray objectAtIndex:row] intValue];
		if(ifshowing)
		{
			for(i=0; i<[curves count]; i++)
			{
				NSMutableArray *aCurve = [NSMutableArray arrayWithArray:[curves objectAtIndex:i]];
				NSMutableArray *someColors = [NSMutableArray arrayWithArray:[pointColors objectAtIndex:i]];
				for(j=0; j<[aCurve count]; j++)
				{
					
					x=[[aCurve objectAtIndex:j] pointValue].x;
					x=offset+zoomfactor*(x-minInSeries);
					val=[[aCurve objectAtIndex:j] pointValue].y * [[aCurve objectAtIndex:j] pointValue].y;
					
					if(maxx<x)
					{
						maxx=x;
						maxval=val;
					}
								
					myOpacityTransferFunction->AddPoint(x,val);
					myColorTransferFunction->AddRGBPoint(x, [[someColors objectAtIndex:j] redComponent], [[someColors objectAtIndex:j] greenComponent], [[someColors objectAtIndex:j] blueComponent]);
					
					
				}
			}
			myOpacityTransferFunction->AddPoint (offset+2047, maxval);
	
		}
		else
			myOpacityTransferFunction->AddPoint (offset+2047, 0.0);
		myColorTransferFunction->AddRGBPoint(offset+2047,1.0,1.0,1.0);
		
	}

	
	
	
}
- (IBAction)addCLUTToAllVolume:(id)sender
{
	int tag=[sender tag];
	unsigned i;
	for(i=0;i<[propertyDictList count];i++)
	{
		[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:i ]];
		[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:i ]];
		switch(tag)
		{
			case 1:
				[clutViewer newTrapezoidCurve];
				break;
			case 2:
				break;
			case 3:
				break;
		}
		
	}

}
- (void)applyCLUT
{
 	myColorTransferFunction->RemoveAllPoints ();
	unsigned int i,j;
	float x,r,g,b;
	float offset,ww,wl;
	NSArray	*rArray,*gArray,*bArray,*xArray;
	
	
	for(i=0;i<[propertyDictList count];i++)
	{
		offset = [[[propertyDictList objectAtIndex:i] objectForKey:@"RangeFrom"] floatValue] + osirixOffset;
		rArray = [[propertyDictList objectAtIndex:i] objectForKey:@"RedTable"];
		gArray = [[propertyDictList objectAtIndex:i] objectForKey:@"GreenTable"];		
		bArray = [[propertyDictList objectAtIndex:i] objectForKey:@"BlueTable"];
		xArray = [[propertyDictList objectAtIndex:i] objectForKey:@"xTableForColorPoints"];
		ww = [[[propertyDictList objectAtIndex: i] objectForKey:@"WW"] floatValue];
		wl = [[[propertyDictList objectAtIndex: i] objectForKey:@"WL"] floatValue];	
		if(wl-ww/2>0)
			myColorTransferFunction->AddRGBPoint(offset,0,0,0);
		if(wl+ww/2<2047)
			myColorTransferFunction->AddRGBPoint(offset+2047,1.0,1.0,1.0);
		for(j=0;j<[xArray count];j++)
		{
			r = [[rArray objectAtIndex: j] floatValue];
			g = [[gArray objectAtIndex: j] floatValue];
			b = [[bArray objectAtIndex: j] floatValue];
			x = [[xArray objectAtIndex: j] floatValue];
			x = wl-ww/2+x*ww/2048;
			if(x<0)
				x=0;
			else if(x>2047)
				x=2047;
			x += offset;
			myColorTransferFunction->AddRGBPoint(x,r,g,b);
		}
	}
 	[vrViewer setWLWW: wholeVolumeWL :wholeVolumeWW];
}
- (IBAction)selectASegment:(id)sender
{
	unsigned int row = [segmentList selectedRow];
	
	if(isSegmentVR)
	{
		if(row>=0&&row<[propertyDictList count])
		{
			/*opacity = [[[propertyDictList objectAtIndex: row] objectForKey:@"Opacity"] floatValue];
			 [opacitySlider setFloatValue: opacity];
			 ww = [[[propertyDictList objectAtIndex: row] objectForKey:@"WW"] floatValue];
			 wl = [[[propertyDictList objectAtIndex: row] objectForKey:@"WL"] floatValue];
			 [wwSlider setFloatValue: ww];
			 [wlSlider setFloatValue: wl];
			 [self restoreCLUTFromPropertyList:row];
			 //[colorViewer display];*/
			int ifshowing=[[isShowingVolumeArray objectAtIndex:row] intValue];
			[showVolumeSwitch setState:ifshowing];
			[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:row ]];
			[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:row ]];
			[clutViewer setClutChanged];
			[clutViewer updateView];
			
			
		}
	}
	else
	{
		if(row>=0&&row<maxMovieIndex)
		{
			float* newVolumeData=[originalViewController volumePtr:row];
			[vrViewer movieBlendingChangeSource:row];
			[vrViewer movieChangeSource: newVolumeData];
			[self setBlendVolumeCLUT];

			volumeOfVRView = (vtkVolume * )[vrViewer volume]; 
			volumeMapper=(vtkVolumeMapper *) volumeOfVRView->GetMapper() ;
			if([cutPlaneSwitch state] == NSOnState)
			{
				volumeMapper->AddClippingPlane(clipPlane1);
				//blendedVolumeMapper->AddClippingPlane(clipPlane1);
			}
			
			[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:row ]];
			[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:row ]];
			[clutViewer setClutChanged];
			[clutViewer updateView];
			
			
			
		}
		
	}
}
- (IBAction)applyCLUTToAll:(id)sender
{
	unsigned int row = [segmentList selectedRow];
	unsigned int i,j,k;
	NSArray* tempcurve;
	NSArray* tempcolor;
	
	for(i=0;i<[mutiplePhaseOpacityCurves count];i++)//evever segment or volume
	{
		if(i!=row)
		{
			for(j=0;j<[[mutiplePhaseOpacityCurves objectAtIndex:i] count];j++)//ever curve for each segment or volume
			{
				[[[mutiplePhaseOpacityCurves objectAtIndex:i] objectAtIndex:j] removeAllObjects];
				[[[mutiplePhaseColorCurves objectAtIndex:i] objectAtIndex:j] removeAllObjects];
			}
			[[mutiplePhaseOpacityCurves objectAtIndex:i] removeAllObjects];
			[[mutiplePhaseColorCurves objectAtIndex:i] removeAllObjects];
			
			
			
			for(j=0;j<[[mutiplePhaseOpacityCurves objectAtIndex:row] count];j++)//ever curve for each segment or volume
			{
				NSMutableArray* tempopacitycurve=[NSMutableArray arrayWithCapacity:0];
				NSMutableArray* tempcolorcurver=[NSMutableArray arrayWithCapacity:0];
				tempcurve=[[mutiplePhaseOpacityCurves objectAtIndex:row] objectAtIndex:j];
				tempcolor=[[mutiplePhaseColorCurves objectAtIndex:row] objectAtIndex:j];
				for(k=0;k<[tempcurve count];k++)
				{
					[tempopacitycurve addObject:[[tempcurve objectAtIndex:k] copy]];
					[tempcolorcurver addObject:[[tempcolor objectAtIndex:k] copy]];
				}
				[[mutiplePhaseOpacityCurves objectAtIndex:i] addObject:tempopacitycurve];
				[[mutiplePhaseColorCurves objectAtIndex:i] addObject:tempcolorcurver];	
				
			}
			
		}
		
	}
	
	
	
	
}
- (IBAction)switchBetweenVRTorMIP:(id)sender
{
	[vrViewer setMode:[sender selectedRow]];
}
- (IBAction)switchShadingONorOFF:(id)sender
{
	if(isSegmentVR)
	{
		if([sender state] == NSOnState)
			myVolumeProperty->ShadeOn();
		else
			myVolumeProperty->ShadeOff();
	}
	else
	{
		if([sender state] == NSOnState)
			[vrViewer activateShading:YES];
		else
			[vrViewer activateShading:NO];
	}
	float savedWl, savedWw;
	[vrViewer getWLWW: &savedWl :&savedWw];
	[vrViewer setWLWW: savedWl : savedWw];
	
	
}
- (IBAction)switchCutPlanONorOFF:(id)sender
{
	if([sender state] == NSOnState)
	{
		volumeMapper->AddClippingPlane(clipPlane1);
		//blendedVolumeMapper->AddClippingPlane(clipPlane1);
	}
	else	
	{
		volumeMapper->RemoveClippingPlane(clipPlane1);
		//blendedVolumeMapper->RemoveClippingPlane(clipPlane1);
	}
	float savedWl, savedWw;
	[vrViewer getWLWW: &savedWl :&savedWw];
	[vrViewer setWLWW: savedWl : savedWw];
}
- (void)restoreCLUTFromPropertyList:(int)index
{
	float x;
	NSArray	*rArray,*gArray,*bArray,*xArray;
	rArray = [[propertyDictList objectAtIndex:index] objectForKey:@"RedTable"];
	gArray = [[propertyDictList objectAtIndex:index] objectForKey:@"GreenTable"];		
	bArray = [[propertyDictList objectAtIndex:index] objectForKey:@"BlueTable"];
	xArray = [[propertyDictList objectAtIndex:index] objectForKey:@"xTableForColorPoints"];
	[clutViewPoints removeAllObjects] ;
	[clutViewColors removeAllObjects] ;
	unsigned int i;
	for(i=0;i<[xArray count];i++)
	{
		NSMutableArray* array=[NSMutableArray arrayWithCapacity:0];
		[array addObject:[rArray objectAtIndex: i]];
		[array addObject:[gArray objectAtIndex: i]];
		[array addObject:[bArray objectAtIndex: i]];
		[clutViewColors addObject: array];
		x = [[xArray objectAtIndex: i] floatValue];
		NSNumber *cur=[NSNumber numberWithInt:(int)(255*x/2048)];
		[clutViewPoints addObject: cur];
	}
}
- (void)applyCLUTToPropertyList:(int)index
{
	float x;
	NSMutableArray	*rArray,*gArray,*bArray,*xArray;
	rArray = [[propertyDictList objectAtIndex:index] objectForKey:@"RedTable"];
	gArray = [[propertyDictList objectAtIndex:index] objectForKey:@"GreenTable"];		
	bArray = [[propertyDictList objectAtIndex:index] objectForKey:@"BlueTable"];
	xArray = [[propertyDictList objectAtIndex:index] objectForKey:@"xTableForColorPoints"];
	[rArray removeAllObjects];
	[gArray removeAllObjects];
	[bArray removeAllObjects];
	[xArray removeAllObjects];
	//	[clutViewPoints removeAllObjects] ;
	//	[clutViewColors removeAllObjects] ;
	unsigned int i;
	for(i=0;i<[clutViewPoints count];i++)
	{
		NSArray* array=[clutViewColors objectAtIndex: i];
		
		[rArray addObject:[array objectAtIndex:0 ]];
		[gArray addObject:[array objectAtIndex:1 ]];
		[bArray addObject:[array objectAtIndex:2 ]];
		x = [[clutViewPoints objectAtIndex: i] floatValue];
		NSNumber *cur=[NSNumber numberWithInt:(int)(2048*x/255 )];
		[xArray addObject: cur];
	}
}

- (float) minimumValue
{
	return 0;
}
- (float) maximumValue
{
	return 1000;
}
- (NSMatrix*) toolsMatrix
{
	return toolsMatrix;
}
- (NSMutableArray*) curPixList
{
	return [originalViewController pixList];
}
- (NSString*) style
{
	return @"standard";
}
- (float) blendingMinimumValue
{
	float blendingMinimumValue=0;
	if(blendingController)
	{
		NSArray* blendingPixList = [blendingController pixList];
		blendingMinimumValue = [[blendingPixList objectAtIndex: 0] minValueOfSeries];
		
	}
	return blendingMinimumValue;
}

- (float) blendingMaximumValue
{
	float blendingMaximumValue=1000;
	if(blendingController)
	{
		NSArray* blendingPixList = [blendingController pixList];
		
		blendingMaximumValue = [[blendingPixList objectAtIndex: 0] maxValueOfSeries];
	}
	return blendingMaximumValue;
}

- (ViewerController*) viewer2D
{
	return originalViewController;
}
- (IBAction)changeVRDirection:(id)sender
{
	int tag=[sender tag];
	if(tag==0)
	{
		[vrViewer coView:sender];
		
	}
	else if(tag==4)
	{
		[vrViewer saView: sender];
		
	}
	else if(tag==5)
	{
		[vrViewer saViewOpposite:sender];
		
	}
	else if(tag==3)
	{
		[vrViewer axView:sender];
		
	}
}
- (void) windowDidBecomeMain:(NSNotification *)aNotification
{
	[self reHideToolbar];
}

- (void)reHideToolbar
{
	/*
	 unsigned int i;
	 for( i = 0; i < [toolbarList count]; i++)
	 {
	 [[toolbarList objectAtIndex: i] setVisible: NO];
	 
	 }*/
	
}
- (IBAction)setClipPlaneOrigin:(id)sender
{
	double* tempcenter;
	tempcenter=volumeOfVRView->GetCenter();
	tempcenter[1]+=[sender doubleValue];
	clipPlane1->SetOrigin(tempcenter);

}
- (void)resetClipPlane
{
	double normal[3];
	aCamera->GetViewPlaneNormal( normal);
//	aCamera->GetViewUp( normal);
	int i;
	for(i=0;i<3;i++)
		normal[i]=-normal[i];
	clipPlane1->SetNormal(normal);
}
-(NSString*)osirixDocumentPath
{
	char	s[1024];
	
	FSRef	ref;
	
	
	if( FSFindFolder (kOnAppropriateDisk, kDocumentsFolderType, kCreateFolder, &ref) == noErr )
	{
		NSString	*path;
		BOOL		isDir = YES;
		
		FSRefMakePath(&ref, (UInt8 *)s, sizeof(s));
		
		path = [[NSString stringWithUTF8String:s] stringByAppendingPathComponent:@"/OsiriX Data"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
		
		return path;// not sure if s is in UTF8 encoding:  What's opposite of -[NSString fileSystemRepresentation]?
	}
	
	else
		return nil;
	
}
- (IBAction)changeBlendingFactor:(id)sender
{
	[vrViewer setBlendingFactor: [sender floatValue]];
}
- (IBAction)changeToLinearInterpolation:(id)sender
{
	
	if(!rayCastVolumeMapper)
	{
		myVolumeProperty->SetAmbient(0.15);
		myVolumeProperty->SetDiffuse(0.9);
		myVolumeProperty->SetSpecular(0.3);
		myVolumeProperty->SetSpecularPower(15);
		myVolumeProperty->SetShade( 1);
		myMapper=vtkVolumeRayCastMapper::New();
		myCompositionFunction=vtkVolumeRayCastCompositeFunction::New();
		myCompositionFunction->SetCompositeMethodToClassifyFirst();
		myMapper->SetInput(volumeImageData);
		myMapper->SetVolumeRayCastFunction(myCompositionFunction);
		
		
		
		if( myMapper) myMapper->SetMinimumImageSampleDistance( 2.0);
		if( myMapper) myMapper->SetSampleDistance( [[NSUserDefaults standardUserDefaults] floatForKey: @"BESTRENDERING"]);
		if( myMapper) myMapper->SetMaximumImageSampleDistance( 6.0);
		
		
		volumeOfVRView->SetProperty( myVolumeProperty);
		
		rayCastVolumeMapper=myMapper;
	}
	
	
	if([sender state] == NSOnState)
	{
		myVolumeProperty->SetInterpolationTypeToLinear();
		volumeMapper=rayCastVolumeMapper;
		volumeOfVRView->SetMapper(volumeMapper);
	}
	else
	{
		//myVolumeProperty->SetInterpolationTypeToNearest();
		myVolumeProperty->SetInterpolationTypeToLinear();
		volumeMapper=fixedPointVolumeMapper;
		volumeOfVRView->SetMapper(volumeMapper);
	}
	[vrViewer setWLWW: wholeVolumeWL :wholeVolumeWW];
	
	
}
- (IBAction)saveDirection:(id)sender
{
	NSString* path=[parent osirixDocumentPath];
	
	NSMutableDictionary *dict = [vrViewer get3DStateDictionary];

	NSArray *curves = [clutViewer convertCurvesForPlist];
	NSArray *colors = [clutViewer convertPointColorsForPlist];
	[dict setObject:curves forKey:@"16bitClutCurves"];
	[dict setObject:colors forKey:@"16bitClutColors"];

	
	NSString	*str =  [path stringByAppendingString:@"/CMIVCTACache/VRT.sav"];
	

	[dict writeToFile:str atomically:YES];
	
}
-(void)applyAdvancedCLUT:(NSDictionary*)dict
{
	
	NSMutableArray *curves = [CMIVCLUTOpacityView convertCurvesFromPlist:[dict objectForKey:@"16bitClutCurves"]];
	NSMutableArray *colors = [CMIVCLUTOpacityView convertPointColorsFromPlist:[dict objectForKey:@"16bitClutColors"]];
	
	NSMutableDictionary *clut = [NSMutableDictionary dictionaryWithCapacity:2];
	[clut setObject:curves forKey:@"curves"];
	[clut setObject:colors forKey:@"colors"];
	

	unsigned int row = [segmentList selectedRow];
	unsigned int i,j,k;
	NSArray* tempcurve;
	NSArray* tempcolor;
	
	i=row;
	{
			
			[[mutiplePhaseOpacityCurves objectAtIndex:i] removeAllObjects];
			[[mutiplePhaseColorCurves objectAtIndex:i] removeAllObjects];
			
			
			
			for(j=0;j<[curves count];j++)//ever curve for each segment or volume
			{
				NSMutableArray* tempopacitycurve=[NSMutableArray arrayWithCapacity:0];
				NSMutableArray* tempcolorcurver=[NSMutableArray arrayWithCapacity:0];
				tempcurve=[curves objectAtIndex:j];
				tempcolor=[colors objectAtIndex:j];
				for(k=0;k<[tempcurve count];k++)
				{
					[tempopacitycurve addObject:[[tempcurve objectAtIndex:k] copy]];
					[tempcolorcurver addObject:[[tempcolor objectAtIndex:k] copy]];
				}
				[[mutiplePhaseOpacityCurves objectAtIndex:i] addObject:tempopacitycurve];
				[[mutiplePhaseColorCurves objectAtIndex:i] addObject:tempcolorcurver];	
				
			}
		
			
		}
	
	[clutViewer setCurves:[mutiplePhaseOpacityCurves objectAtIndex:row ]];
	[clutViewer setPointColors:[mutiplePhaseColorCurves objectAtIndex:row ]];
	[clutViewer setClutChanged];
	[clutViewer updateView];
	//[vrViewer setAdvancedCLUT:clut lowResolution:NO];
}
- (IBAction)loadAdvancedCLUT:(id)sender
{
	int                 result;
    NSOpenPanel         *oPanel = [NSOpenPanel openPanel];
	
    
	[oPanel setCanSelectHiddenExtension:YES];
	[oPanel setRequiredFileType:@"clut"];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    
    result = [oPanel runModalForDirectory:0L file:nil types:nil];
    
    if (result == NSOKButton) 
    {
		NSString* path;
		path=[[oPanel filenames] objectAtIndex: 0];
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
		if(dict)
			[self applyAdvancedCLUT:dict];
	}		
}
@end

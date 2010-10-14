//
//  CMIRViewerController.m
//  CMIR_T2_Fit_Map
//
//  Created by lfexon on 5/12/09.
//  Copyright 2009 CSB_MGH. All rights reserved.
//
#import "CMIRViewerController.h"




// ****** duplicated static variables and extern notofications variables
static		NSRecursiveLock				*drawLock = nil;					// DCMView
static		float						deg2rad = 3.14159265358979/180.0;

//NSString* OsirixDCMViewIndexChangedNotification = @"DCMViewIndexChanged";

static NSNotification *lastMenuNotification = nil;
static NSMenu *wlwwPresetsMenu = nil;
static NSMenu *clutPresetsMenu = nil;
static NSMenu *convolutionPresetsMenu = nil;
static NSMenu *opacityPresetsMenu = nil;

NSString* OsirixUpdateWLWWMenuNotification = @"UpdateWLWWMenu";
NSString *OsirixUpdateCLUTMenuNotification = @"UpdateCLUTMenu";
NSString* OsirixUpdateConvolutionMenuNotification = @"UpdateConvolutionMenu";
NSString* OsirixUpdateOpacityMenuNotification = @"UpdateOpacityMenu";
NSString* OsirixDCMUpdateCurrentImageNotification = @"DCMUpdateCurrentImage"; // DCMView



//**********************

@implementation ViewerController(CSB)

	// !!!!! duplicated static function as it is absent in ViewerController.h
	NSInteger sortROIByName(id roi1, id roi2, void *context)
	{
		NSString *n1 = [roi1 name];
		NSString *n2 = [roi2 name];
		return [n1 compare:n2 options:NSNumericSearch];
	}


	// !!!!! ************************************  OVERWRITING
-(void) CSB_ApplyCLUTString:(NSString*) str
{

//!!!!!	OsiriX:   if( blendingController && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
	//!!!!! NEW START
	if (blendingController && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"] && 
			[str isEqualToString: [[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"]])
	//!!!!! NEW END
		
	{
		NSString *c = [[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"];
		[[NSUserDefaults standardUserDefaults] setValue: str forKey: @"PET Blending CLUT"];
		[DCMView computePETBlendingCLUT];
		[[NSUserDefaults standardUserDefaults] setValue: c forKey: @"PET Blending CLUT"];
		
		[curCLUTMenu release];
		curCLUTMenu = [str copy];
		
		[[[clutPopup menu] itemAtIndex:0] setTitle: str];
	}
	else
	{
	
		if( [str isEqualToString:NSLocalizedString(@"No CLUT", nil)] == YES)
		{
			int i, x;
			for ( x = 0; x < maxMovieIndex; x++)
			{
				for ( i = 0; i < [pixList[ x] count]; i ++) [[pixList[ x] objectAtIndex:i] setBlackIndex: 0];
			}
			
			[imageView setCLUT: nil :nil :nil];
			if( thickSlab)
			{
				[thickSlab setCLUT:nil :nil :nil];
			}
			
			[imageView setIndex:[imageView curImage]];
			
			if( str != curCLUTMenu)
			{
				[curCLUTMenu release];
				curCLUTMenu = [str retain];
			}
			
			lastMenuNotification = nil;
			[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
			
			[[[clutPopup menu] itemAtIndex:0] setTitle:str];
			
			[self propagateSettings];
		}
		else
		{
			NSDictionary		*aCLUT;
			NSArray				*array;
			long				i;
			unsigned char		red[256], green[256], blue[256];
			
			aCLUT = [[[NSUserDefaults standardUserDefaults] dictionaryForKey: @"CLUT"] objectForKey:str];
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
				
				if( thickSlab)
				{
					[thickSlab setCLUT:red :green :blue];
				}
				
				int darkness = 256 * 3;
				int darknessIndex = 0;
				
				for( i = 0; i < 256; i++)
				{
					if( red[i] + green[i] + blue[i] < darkness)
					{
						darknessIndex = i;
						darkness = red[i] + green[i] + blue[i];
					}
				}
				
				int x;
				for ( x = 0; x < maxMovieIndex; x++)
				{
					for ( i = 0; i < [pixList[ x] count]; i ++)
					{
						[[pixList[ x] objectAtIndex:i] setBlackIndex: darknessIndex];
					}
				}
				
				[imageView setCLUT:red :green: blue];
				
				[imageView setIndex:[imageView curImage]];
				if( str != curCLUTMenu)
				{
					[curCLUTMenu release];
					curCLUTMenu = [str retain];
				}
				
				lastMenuNotification = nil;
				[[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
				
				[self propagateSettings];
				[[[clutPopup menu] itemAtIndex:0] setTitle:str];
			}
		}
	}
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[imageView curImage]]  forKey:@"curImage"];
	[[NSNotificationCenter defaultCenter] postNotificationName: OsirixDCMUpdateCurrentImageNotification object: imageView userInfo: userInfo];
	
	float   iwl, iww;
	[imageView getWLWW:&iwl :&iww];
	[imageView setWLWW:iwl :iww];
}
//*********************************************************************


// !!!!! duplicated function as it is absent in ViewerController.h
- (void) refreshMenus
{
	lastMenuNotification = nil;
	if( wlwwPresetsMenu == nil) [[NSNotificationCenter defaultCenter] postNotificationName:OsirixUpdateWLWWMenuNotification object: curWLWWMenu userInfo: nil];
	else [wlwwPopup setMenu: [[wlwwPresetsMenu copy] autorelease]];
	
	lastMenuNotification = nil;
	if( clutPresetsMenu == nil) [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateCLUTMenuNotification object: curCLUTMenu userInfo: nil];
	else [clutPopup setMenu: [[clutPresetsMenu copy] autorelease]];
	
	lastMenuNotification = nil;
	if( convolutionPresetsMenu == nil) [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateConvolutionMenuNotification object: curConvMenu userInfo: nil];
	else [convPopup setMenu: [[convolutionPresetsMenu copy] autorelease]];
	
	lastMenuNotification = nil;
	if( opacityPresetsMenu == nil) [[NSNotificationCenter defaultCenter] postNotificationName: OsirixUpdateOpacityMenuNotification object: curOpacityMenu userInfo: nil];
	else [OpacityPopup setMenu: [[opacityPresetsMenu copy] autorelease]];
	
	[clutPopup setTitle:curCLUTMenu];
	[convPopup setTitle:curConvMenu];
	[wlwwPopup setTitle:curWLWWMenu];
	[OpacityPopup setTitle:curOpacityMenu];
	
	[clutPopup display];
	[convPopup display];
	[wlwwPopup display];
	[OpacityPopup display];
}



//!!!!! ************************************************  OVERWRITING
-(void) CSB_ActivateBlending:(ViewerController*) bC
{
//	NSLog(@"!!!!!  ActivateBlnding START self=%d   blend=%d  1st view : self=%d   bc=%d", self, bC, [self imageView], [bC imageView]);	
	
	if( bC == self) return;
	if( blendingController == bC) return;
	
	if( blendingController && bC)
		[self ActivateBlending: nil];
	
	[imageView sendSyncMessage:0];
	
	blendingController = bC;
	
	if( blendingController)
	{
		NSLog( @"Blending Activated!");
		
		if( [blendingController blendingController] == self)	// NO cross blending !
		{
			[blendingController ActivateBlending: nil];
		}
		
		if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[blendingController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
		{
			// By default, re-activate 'propagate settings'
			
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey:@"COPYSETTINGS"];
		}
		
		float orientA[9], orientB[9];
		float result[3];
		
		BOOL proceed = NO;
		
		[[[self imageView] curDCM] orientation:orientA];
		[[[blendingController imageView] curDCM] orientation:orientB];
		
		if( orientB[ 6] == 0 && orientB[ 7] == 0 && orientB[ 8] == 0) proceed = YES;
		if( orientA[ 6] == 0 && orientA[ 7] == 0 && orientA[ 8] == 0) proceed = YES;
		
		// normal vector of planes
		
		result[0] = fabs( orientB[ 6] - orientA[ 6]);
		result[1] = fabs( orientB[ 7] - orientA[ 7]);
		result[2] = fabs( orientB[ 8] - orientA[ 8]);
		
		if( result[0] + result[1] + result[2] > 0.01)  // Planes are not paralel!
		{
			// FROM SAME STUDY
			
			if( [[[[self fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"] isEqualToString: [[[blendingController fileList] objectAtIndex:0] valueForKeyPath:@"series.study.studyInstanceUID"]])
			{
				int result = NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. If you continue the result will be distorted. You can instead 'Resample' the series to have the same origin/orientation.",nil), NSLocalizedString(@"Resample & Fusion",nil), NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Fusion",nil));
				
				switch( result)
				{
					case NSAlertAlternateReturn:
						proceed = NO;
						break;
						
					#ifndef OSIRIX_LIGHT	//10.07.2010
					case NSAlertDefaultReturn:		// Resample
						blendingController = [self resampleSeries: blendingController];
						if( blendingController) proceed = YES;
						break;
					#endif					//10.07.2010
						
					case NSAlertOtherReturn:
						proceed = YES;
						break;
				}
			}
			else	// FROM DIFFERENT STUDY
			{
				if( NSRunCriticalAlertPanel(NSLocalizedString(@"2D Planes",nil),NSLocalizedString(@"These 2D planes are not parallel. If you continue the result will be distorted. You can instead perform a 'Point-based registration' to have correct alignment/orientation.",nil), NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Cancel",nil), nil) != NSAlertDefaultReturn)
				{
					proceed = NO;
				}
				else proceed = YES;
			}
		}
		else proceed = YES;
		
		if( proceed)
		{		
			[imageView setBlending: [blendingController imageView]];
			[blendingSlider setEnabled:YES];
			
			[blendingPercentage setStringValue:[NSString stringWithFormat:@"%0.0f%%", (float) ([blendingSlider floatValue] + 256.) / 5.12]];
			
			if( [[blendingController curCLUTMenu] isEqualToString:NSLocalizedString(@"No CLUT", nil)] && [[[blendingController pixList] objectAtIndex: 0] isRGB] == NO)
			{
				if( [[self modality] isEqualToString:@"PT"] == YES || ([[NSUserDefaults standardUserDefaults] boolForKey:@"clutNM"] == YES && [[self modality] isEqualToString:@"NM"] == YES))
				{
//!!!!!	OsiriX:				if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
//!!!!!	OsiriX:					[self ApplyCLUTString: @"B/W Inverse"];
//!!!!!	OsiriX:				else
						[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];

				}
				
			}
			
			//!!!!!!  NEW START        PET may have "B/W inverse" applied already
			else { 
				if( [[blendingController modality] isEqualToString:@"PT"] == YES)
				{
					[self ApplyCLUTString: [[NSUserDefaults standardUserDefaults] stringForKey:@"PET Default CLUT"]];

				}
			}	
			//!!!!!  NEW END
			
			
			[imageView setBlendingFactor: [blendingSlider floatValue]];
			
			[blendingPopupMenu selectItemWithTag: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
			[imageView setBlendingMode: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
			[seriesView setBlendingMode: [[NSUserDefaults standardUserDefaults] integerForKey: @"DEFAULTPETFUSION"]];
			
			[seriesView ActivateBlending:blendingController blendingFactor:[blendingSlider floatValue]];
		}
		
		[backCurCLUTMenu release];
		backCurCLUTMenu = 0L;
	
//!!!!!	OsiriX:   	if( blendingController && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
//!!!!!  NEW START		
			if( blendingController && ([[blendingController modality] isEqualToString:@"PT"] == YES || [[self modality] isEqualToString:@"PT"] == YES)  && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])	
//!!!!! NEW END				
		{
			backCurCLUTMenu = [curCLUTMenu copy];
			[curCLUTMenu release];
			curCLUTMenu = [[[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"] copy];
			
		}

	}
	else
	{
//!!!!! NEW START		
		if ([curCLUTMenu isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey: @"PET Blending CLUT"]]) //!!!!!
		{
//!!!!!  NEW END			
			[backCurCLUTMenu release];
			backCurCLUTMenu = 0L;
		
			[curCLUTMenu release];
			curCLUTMenu = [NSLocalizedString(@"No CLUT", nil) retain];
//!!!!! NEW START
		} 
//!!!!! NEW END		
		[imageView setBlending: nil];
		[blendingSlider setEnabled:NO];
		[blendingPercentage setStringValue:@"-"];
		[seriesView ActivateBlending: nil blendingFactor:[blendingSlider floatValue]];
		[imageView display];
	}
	
	[self buildMatrixPreview: NO];
	[imageView sendSyncMessage: 0];

	[self ApplyCLUTString:curCLUTMenu];
	[self refreshMenus];
	
}
//************************************************


//!!!!!   *********  used inside this plugin only
- (ViewerController*) CSB_computeRegistrationWithMovingViewer:(ViewerController*) movingViewer
{
	
//!!!!! NEW START
	ViewerController *newViewer = nil;
// !!!!! NEW END
	
	
		//	NSLog(@" ***** Points 2D ***** ");
		// find all the Point ROIs on this viewer (fixed)
		NSMutableArray * modelPointROIs = [self point2DList];
		// find all the Point ROIs on the dragged viewer (moving)
		NSMutableArray * sensorPointROIs = [movingViewer point2DList];
		
		// order the Points by name. Not necessary but useful for debugging.
		[modelPointROIs sortUsingFunction:sortROIByName context:NULL];
		[sensorPointROIs sortUsingFunction:sortROIByName context:NULL];
		
		int numberOfPoints = [modelPointROIs count];
		// we need the same number of points
		BOOL sameNumberOfPoints = ([sensorPointROIs count] == numberOfPoints);
		// we need at least 3 points
		BOOL enoughPoints = (numberOfPoints>=3);
		// each point on the moving viewer needs a twin on the fixed viewer.
		// two points are twin brothers if and only if they have the same name.
		BOOL pointsNamesMatch2by2 = YES;
		// triplets are illegal (since we don't know which point to map)
		BOOL triplets = NO;
		
		NSMutableArray *previousNames = [[NSMutableArray alloc] initWithCapacity:0];
		
		NSString *modelName, *sensorName;
		NSMutableString *errorString = [NSMutableString stringWithString:@""];
		
		BOOL foundAMatchingName;
		
		if (sameNumberOfPoints && enoughPoints)
		{
			HornRegistration *hr = [[HornRegistration alloc] init];
			
			float vectorModel[ 9], vectorSensor[ 9];
			
			[[[movingViewer pixList] objectAtIndex:0] orientation: vectorSensor];
			[[[self pixList] objectAtIndex:0] orientation: vectorModel];
			
			int i,j; // 'for' indexes
			for (i=0; i<[modelPointROIs count] && pointsNamesMatch2by2 && !triplets; i++)
			{
				ROI *curModelPoint2D = [modelPointROIs objectAtIndex:i];
				modelName = [curModelPoint2D name];
				foundAMatchingName = NO;
				
				for (j=0; j<[sensorPointROIs count] && !foundAMatchingName; j++)
				{
					ROI *curSensorPoint2D = [sensorPointROIs objectAtIndex:j];
					sensorName = [curSensorPoint2D name];
					
					for (id loopItem2 in previousNames)
					{
						triplets = triplets || [modelName isEqualToString:loopItem2]
											|| [sensorName isEqualToString:loopItem2];
					}
					
					pointsNamesMatch2by2 = [sensorName isEqualToString:modelName];
					
					if(pointsNamesMatch2by2)
					{
						foundAMatchingName = YES; // stop the research
						[sensorPointROIs removeObjectAtIndex:j]; // to accelerate the research
						j--;
						
						[previousNames addObject:sensorName]; // to avoid triplets
						
						if(!triplets)
						{
							float modelLocation[3], sensorLocation[3];
							
							[[curModelPoint2D pix]	convertPixX:	[[[curModelPoint2D points] objectAtIndex:0] x]
													pixY:			[[[curModelPoint2D points] objectAtIndex:0] y]
													toDICOMCoords:	modelLocation
													pixelCenter: YES];
							
							[[curSensorPoint2D pix]	convertPixX:	[[[curSensorPoint2D points] objectAtIndex:0] x]
													pixY:			[[[curSensorPoint2D points] objectAtIndex:0] y]
													toDICOMCoords:	sensorLocation
													pixelCenter: YES];
							
							// Convert the point in 3D orientation of the model
							
							float modelLocationConverted[ 3];
							
							modelLocationConverted[ 0] = modelLocation[ 0];
							modelLocationConverted[ 1] = modelLocation[ 1];
							modelLocationConverted[ 2] = modelLocation[ 2];
							modelLocationConverted[ 0] = modelLocation[ 0] * vectorModel[ 0] + modelLocation[ 1] * vectorModel[ 1] + modelLocation[ 2] * vectorModel[ 2];
							modelLocationConverted[ 1] = modelLocation[ 0] * vectorModel[ 3] + modelLocation[ 1] * vectorModel[ 4] + modelLocation[ 2] * vectorModel[ 5];
							modelLocationConverted[ 2] = modelLocation[ 0] * vectorModel[ 6] + modelLocation[ 1] * vectorModel[ 7] + modelLocation[ 2] * vectorModel[ 8];
							
							float sensorLocationConverted[ 3];
							
							sensorLocationConverted[ 0] = sensorLocation[ 0];
							sensorLocationConverted[ 1] = sensorLocation[ 1];
							sensorLocationConverted[ 2] = sensorLocation[ 2];
							sensorLocationConverted[ 0] = sensorLocation[ 0] * vectorSensor[ 0] + sensorLocation[ 1] * vectorSensor[ 1] + sensorLocation[ 2] * vectorSensor[ 2];
							sensorLocationConverted[ 1] = sensorLocation[ 0] * vectorSensor[ 3] + sensorLocation[ 1] * vectorSensor[ 4] + sensorLocation[ 2] * vectorSensor[ 5];
							sensorLocationConverted[ 2] = sensorLocation[ 0] * vectorSensor[ 6] + sensorLocation[ 1] * vectorSensor[ 7] + sensorLocation[ 2] * vectorSensor[ 8];
							
							// add the points to the registration method
							[hr addModelPointX: modelLocationConverted[0] Y: modelLocationConverted[1] Z: modelLocationConverted[2]];
							[hr addSensorPointX: sensorLocationConverted[0] Y: sensorLocationConverted[1] Z: sensorLocationConverted[2]];
						}
					}
				}
			}
			
			if(pointsNamesMatch2by2 && !triplets)
			{
				double matrix[ 16];
				
				[hr computeVTK :matrix];
				
				ITKTransform * transform = [[ITKTransform alloc] initWithViewer:movingViewer];
				
//!!!!!  OsiriX:				ViewerController *newViewer = [transform computeAffineTransformWithParameters: matrix resampleOnViewer: self];
//!!!!!  NEW START				
				newViewer = [transform computeAffineTransformWithParameters: matrix resampleOnViewer: self];		
//!!!!!  NEW END				
				//			myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"!!!!! computeReg: newViewer=%d  resampleOnViewer=%d  countOnResample=%d  countOnViewer=%d",  
				//															  newViewer, self, [[self pixList] count], [[newViewer pixList] count]]
				//											   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
				//			[myAlert runModal];
				
				[imageView sendSyncMessage: 0];
				[self adjustSlider];
				
				[transform release];
			}
			[hr release];
		}
		else
		{
			if(!sameNumberOfPoints)
			{
				// warn user to set the same number of points on both viewers
				[errorString appendString:NSLocalizedString(@"Needs same number of points on both viewers.",nil)];
			}
			
			if(!enoughPoints)
			{
				// warn user to set at least 3 points on both viewers
				if([errorString length]!=0) [errorString appendString:@"\n"];
				[errorString appendString:NSLocalizedString(@"Needs at least 3 points on both viewers.",nil)];
			}
		}
		
		if(!pointsNamesMatch2by2)
		{
			// warn user
			if([errorString length]!=0) [errorString appendString:@"\n"];
			[errorString appendString:NSLocalizedString(@"Points names must match 2 by 2.",nil)];
		}
		
		if(triplets)
		{
			// warn user
			if([errorString length]!=0) [errorString appendString:@"\n"];
			[errorString appendString:NSLocalizedString(@"Max. 2 points with the same name.",nil)];
		}
		
		if([errorString length]!=0)
		{			
			NSRunCriticalAlertPanel(NSLocalizedString(@"Point-Based Registration Error", nil),
									errorString,
									NSLocalizedString(@"OK", nil), nil, nil);
		}
		
		[previousNames release];
		
	return newViewer;
	
}
//************************

@end

@implementation DCMView(CSB) 

//!!!!! new methods
-(long*) getBlendingTextureXPtr {return &blendingTextureX;}
-(long) getBlendingTextureX {return blendingTextureX;}
-(long*) getBlendingTextureYPtr {return &blendingTextureY;}
-(long) getBlendingTextureY {return blendingTextureY;}
-(long*) getBlendingTextureWidthPtr {return &blendingTextureWidth;}
-(long) getBlendingTextureWidth {return blendingTextureWidth;}
-(long*) getBlendingTextureHeightPtr {return &blendingTextureHeight;}
-(long) getBlendingTextureHeight {return blendingTextureHeight;}
-(int*) getBlendingResampledBaseAddrSizePtr {return &blendingResampledBaseAddrSize;}
-(GLuint*) getBlendingTextureName {return blendingTextureName;}	
-(void) setBlendingTextureName: (GLuint*)p {blendingTextureName = p;}	
-(unsigned char**) getBlendingColorBufPtr {return &blendingColorBuf;}	
-(char**) getBlendingResampledBaseAddrPtr {return &blendingResampledBaseAddr;}	


//!!!!!  *********************** duplicated as it's absent in DCMView.h
- (void)drawRepulsorToolArea;
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glEnable(GL_BLEND);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	long i;
	
	int circleRes = 20;
	circleRes = (repulsorRadius>5) ? 30 : circleRes;
	circleRes = (repulsorRadius>10) ? 40 : circleRes;
	circleRes = (repulsorRadius>50) ? 60 : circleRes;
	circleRes = (repulsorRadius>70) ? 80 : circleRes;
	
	glColor4f(1.0,1.0,0.0,repulsorAlpha);
	
	NSPoint pt = [self convertFromNSView2iChat: repulsorPosition];
	
	glBegin(GL_POLYGON);	
	for(i = 0; i < circleRes ; i++)
	{
		// M_PI defined in cmath.h
		float alpha = i * 2 * M_PI /circleRes;
		glVertex2f( pt.x + repulsorRadius*cos(alpha)*scaleValue, pt.y + repulsorRadius*sin(alpha)*scaleValue);// *curDCM.pixelSpacingY/curDCM.pixelSpacingX
	}
	glEnd();
	glDisable(GL_BLEND);
}
//********************************

//!!!!! ******************************** duplicated as it's absent in DCMView.h
- (void)drawROISelectorRegion;
{
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glEnable(GL_BLEND);
	glDisable(GL_POLYGON_SMOOTH);
	glDisable(GL_POINT_SMOOTH);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
	glLineWidth( 1);
	
	#define ROISELECTORREGION_R 0.8
	#define ROISELECTORREGION_G 0.8
	#define ROISELECTORREGION_B 1.0
	
	NSPoint startPt, endPt;
	startPt = [self convertFromView2iChat: ROISelectorStartPoint];
	endPt = [self convertFromView2iChat: ROISelectorEndPoint];
	
	// inside: fill
	glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.3);
	glBegin(GL_POLYGON);		
	glVertex2f(startPt.x, startPt.y);
	glVertex2f(startPt.x, endPt.y);
	glVertex2f(endPt.x, endPt.y);
	glVertex2f(endPt.x, startPt.y);
	glEnd();
	
	// border
	glColor4f(ROISELECTORREGION_R, ROISELECTORREGION_G, ROISELECTORREGION_B, 0.75);
	glBegin(GL_LINE_LOOP);
	glVertex2f(startPt.x, startPt.y);
	glVertex2f(startPt.x, endPt.y);
	glVertex2f(endPt.x, endPt.y);
	glVertex2f(endPt.x, startPt.y);
	glEnd();
	
	glDisable(GL_BLEND);
}
//********************************



//!!!!! ********************************************* OVERWRITING
- (void)loadTexturesComputeFusion3
{
	
  [drawLock lock];
	
  @try //10.07.2010
  {	// 10.07.2010
	
//!!!!! OsiriX:  	pTextureName = [self loadTextureIn:pTextureName blending:NO colorBuf:&colorBuf textureX:&textureX textureY:&textureY redTable: redTable greenTable:greenTable blueTable:blueTable textureWidth:&textureWidth textureHeight:&textureHeight resampledBaseAddr:&resampledBaseAddr resampledBaseAddrSize:&resampledBaseAddrSize];
//!!!!!  NEW START
	if (blendingView && [[[self dicomImage] valueForKey:@"modality"] isEqualToString:@"PT"] && [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"]) {
		pTextureName = [self loadTextureIn:pTextureName blending:NO colorBuf:&colorBuf textureX:&textureX textureY:&textureY redTable: [DCMView PETredTable] greenTable:[DCMView PETgreenTable] blueTable:[DCMView PETblueTable] textureWidth:&textureWidth textureHeight:&textureHeight resampledBaseAddr:&resampledBaseAddr resampledBaseAddrSize:&resampledBaseAddrSize];	
	}
	else  pTextureName = [self loadTextureIn:pTextureName blending:NO colorBuf:&colorBuf textureX:&textureX textureY:&textureY redTable: redTable greenTable:greenTable blueTable:blueTable textureWidth:&textureWidth textureHeight:&textureHeight resampledBaseAddr:&resampledBaseAddr resampledBaseAddrSize:&resampledBaseAddrSize]; 
//!!!!!  NEW END
	
	
	if( blendingView)
	{
	
		
/*!!!!! OsiriX:
		if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"]) {
			blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable: PETredTable greenTable:PETgreenTable blueTable:PETblueTable textureWidth:&blendingTextureWidth textureHeight:&blendingTextureHeight resampledBaseAddr:&blendingResampledBaseAddr resampledBaseAddrSize:&blendingResampledBaseAddrSize];
		}	
		else {
 			blendingTextureName = [blendingView loadTextureIn:blendingTextureName blending:YES colorBuf:&blendingColorBuf textureX:&blendingTextureX textureY:&blendingTextureY redTable:nil greenTable:nil blueTable:nil textureWidth:&blendingTextureWidth textureHeight:&blendingTextureHeight resampledBaseAddr:&blendingResampledBaseAddr resampledBaseAddrSize:&blendingResampledBaseAddrSize];
		}	 
*/ 
		
//!!!!!  NEW START		
		DCMView *bV_parent, *bV = self;
		NSMutableArray *listBlendedViewers = [NSMutableArray arrayWithCapacity: 0];
		[listBlendedViewers addObject:bV];	

		while ((bV = [bV blendingView]) != nil) {
			[listBlendedViewers addObject:bV];	
		}
			
		while ([listBlendedViewers count]>0) {
			bV = [listBlendedViewers lastObject];
			[listBlendedViewers removeLastObject];

			if ([listBlendedViewers count]==0) break;

			bV_parent = [listBlendedViewers lastObject];
			
			if(([[[bV dicomImage] valueForKey:@"modality"] isEqualToString:@"PT"]  
//				   ||     ([[[bV_parent dicomImage] valueForKey:@"modality"] isEqualToString:@"PT"] && [[[bV windowController] curCLUTMenu] isEqualToString:@"No CLUT"])
			   )   &&
			   [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"]) 
			{
				[bV_parent setBlendingTextureName: [bV loadTextureIn:[bV_parent getBlendingTextureName] blending:YES colorBuf:[bV_parent getBlendingColorBufPtr] textureX:[bV_parent getBlendingTextureXPtr] textureY:[bV_parent getBlendingTextureYPtr] redTable:[DCMView PETredTable] greenTable:[DCMView PETgreenTable] blueTable:[DCMView PETblueTable] textureWidth:[bV_parent getBlendingTextureWidthPtr] textureHeight:[bV_parent getBlendingTextureHeightPtr] resampledBaseAddr:[bV_parent getBlendingResampledBaseAddrPtr] resampledBaseAddrSize:[bV_parent getBlendingResampledBaseAddrSizePtr]] ];
				
			}	
			else {
				[bV_parent setBlendingTextureName: [bV loadTextureIn:[bV_parent getBlendingTextureName] blending:YES colorBuf:[bV_parent getBlendingColorBufPtr] textureX:[bV_parent getBlendingTextureXPtr] textureY:[bV_parent getBlendingTextureYPtr] redTable:nil greenTable:nil blueTable:nil textureWidth:[bV_parent getBlendingTextureWidthPtr] textureHeight:[bV_parent getBlendingTextureHeightPtr] resampledBaseAddr:[bV_parent getBlendingResampledBaseAddrPtr] resampledBaseAddrSize:[bV_parent getBlendingResampledBaseAddrSizePtr]] ];
//				[bV_parent setBlendingTextureName: [bV loadTextureIn:[bV_parent getBlendingTextureName] blending:YES colorBuf:[bV_parent getBlendingColorBufPtr] textureX:[bV_parent getBlendingTextureXPtr] textureY:[bV_parent getBlendingTextureYPtr] redTable:[bV getRedTable] greenTable:nil blueTable:nil textureWidth:[bV_parent getBlendingTextureWidthPtr] textureHeight:[bV_parent getBlendingTextureHeightPtr] resampledBaseAddr:[bV_parent getBlendingResampledBaseAddrPtr] resampledBaseAddrSize:[bV_parent getBlendingResampledBaseAddrSizePtr]] ];
			}	
			
		}	
		
//!!!!!  NEW END
		
	}
	
	needToLoadTexture = NO;
  
  //10.07.2010	  
  }
  @catch (NSException * e)
  {		
	  NSLog( @"***** exception in %s: %@", __PRETTY_FUNCTION__, e);
  }	  
  
	
	
  [drawLock unlock];
}
//!!!!!************************************************************************


//!!!!!************************************************ OVERWRITING
- (void) drawRectFusion3:(NSRect)aRect withContext:(NSOpenGLContext *)ctx
{
	//10.07.2010
	NSRect savedDrawingFrameRect;
/*!!!!! OsiriX:		
	long		clutBars	= CLUTBARS;
	long		annotations	= ANNOTATIONS;
*/
//!!!!! NEW START
	long		clutBars = [[NSUserDefaults standardUserDefaults] integerForKey: @"CLUTBARS"];
	long		annotations	= [[NSUserDefaults standardUserDefaults] integerForKey: @"ANNOTATIONS"];
	int DISPLAYCROSSREFERENCELINES = [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayCrossReferenceLines"];
//!!!!! NEW END	
	
	
	
	
	
	#ifndef OSIRIX_LIGHT //10.07.2010
		BOOL		iChatRunning = [[IChatTheatreDelegate sharedDelegate] isIChatTheatreRunning];
	#else								//10.07.2010
		BOOL		iChatRunning = NO;	//10.07.2010
	#endif								//10.07.2010
	
	if( firstTimeDisplay == NO && [self is2DViewer])
	{

		firstTimeDisplay = YES;
		[self updatePresentationStateFromSeries];
	}
	
	if( iChatRunning)
	{
		if( drawLock == nil) drawLock = [[NSRecursiveLock alloc] init];
		[drawLock lock];
	}
	else
	{
		[drawLock release];
		drawLock = nil;
	}
	
	[ctx makeCurrentContext];
	
 @try	//10.07.2010
 {		//10.07.2010
	 
	if( needToLoadTexture || iChatRunning) {
		[self loadTexturesCompute];
	}	
	
	if( noScale)
	{
		self.scaleValue = 1.0f;
		[self setOriginX: 0 Y: 0];
	}
	
	NSPoint offset = { 0.0f, 0.0f };
	
	 
	//10.07.2010
	 if( NSEqualRects( drawingFrameRect, aRect) == NO && ctx!=_alternateContext)
	 {
		 [[self openGLContext] clearDrawable];
		 [[self openGLContext] setView: self];
	 }
	 
	 if( ctx == _alternateContext)
		 savedDrawingFrameRect = drawingFrameRect;	 
	 
	 
	 
	 
	drawingFrameRect = aRect;
	
	CGLContextObj cgl_ctx = [[NSOpenGLContext currentContext] CGLContextObj];
	
	glViewport (0, 0, drawingFrameRect.size.width, drawingFrameRect.size.height); // set the viewport to cover entire window
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear (GL_COLOR_BUFFER_BIT);
	
	if( dcmPixList && curImage > -1)
	{
		if( blendingView != nil && syncOnLocationImpossible == NO)// && ctx!=_alternateContext)
		{
			
			glBlendFunc(GL_ONE, GL_ONE);
			//			glBlendFunc(GL_SRC_COLOR, GL_ONE);
			
			glEnable( GL_BLEND);
		}
		else
		{
			glBlendFunc(GL_ONE, GL_ONE);
			glDisable( GL_BLEND);
		}
		
		
		//		glColor4f(1.0f, 0.0f, 0.0f, 1.0);
		
		[self drawRectIn:drawingFrameRect :pTextureName :offset :textureX :textureY :textureWidth :textureHeight];
		
		BOOL noBlending = NO;
		
		if( [self is2DViewer] == YES)
		{
			if( isKeyView == NO) noBlending = YES;
		}	
		
		if( blendingView != nil && syncOnLocationImpossible == NO && noBlending == NO )
		{

			glBlendEquation(GL_FUNC_ADD);
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			//			glBlendFunc(GL_SRC_COLOR, GL_ONE);
			
			
		
/*!!!!! OsiriX:			
			 if( blendingTextureName) {
			 [blendingView drawRectIn:drawingFrameRect :blendingTextureName :offset :blendingTextureX :blendingTextureY :blendingTextureWidth :blendingTextureHeight];
			 
			 }	
			 else
			 NSLog( @"blendingTextureName == nil");
*/			

//!!!!!  NEW START			
			DCMView *bV = self;
			
			while ([bV blendingView] != nil) {

				if( [bV getBlendingTextureName]) {
					[[bV blendingView] drawRectIn:drawingFrameRect :[bV getBlendingTextureName] :offset :[bV getBlendingTextureX] :[bV getBlendingTextureY] :[bV getBlendingTextureWidth] :[bV getBlendingTextureHeight]];
				}	
				else
					NSLog( @"blendingTextureName == nil");
				
				bV = [bV blendingView];
			}
//!!!!!  NEW END
			
			glDisable( GL_BLEND);
		}


		if( [self is2DViewer])
		{
			if( [[self windowController] highLighted] > 0)
			{
			
				glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
				glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
				
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				glEnable(GL_BLEND);
				
				glColor4f (249./255., 240./255., 140./255., [[self windowController] highLighted]);
				glLineWidth(1.0);
				glBegin(GL_QUADS);
				glVertex2f(0.0, 0.0);
				glVertex2f(0.0, drawingFrameRect.size.height);
				glVertex2f(drawingFrameRect.size.width, drawingFrameRect.size.height);
				glVertex2f(drawingFrameRect.size.width, 0);
				glEnd();
				glDisable(GL_BLEND);
			}
		}
		
		// highlight the visible part of the view (the part visible through iChat)
		#ifndef OSIRIX_LIGHT //10.07.2010
		if([[IChatTheatreDelegate sharedDelegate] isIChatTheatreRunning] && ctx!=_alternateContext && [[self window] isMainWindow] && isKeyView && iChatWidth>0 && iChatHeight>0)
		{
		
			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
			glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
			NSPoint topLeft;
			topLeft.x = drawingFrameRect.size.width/2 - iChatWidth/2.0;
			topLeft.y = drawingFrameRect.size.height/2 - iChatHeight/2.0;
			
			glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			glEnable(GL_BLEND);
			
			glColor4f (0.0f, 0.0f, 0.0f, 0.7f);
			glLineWidth(1.0);
			glBegin(GL_QUADS);
				glVertex2f(0.0, 0.0);
				glVertex2f(0.0, topLeft.y);
				glVertex2f(drawingFrameRect.size.width, topLeft.y);
				glVertex2f(drawingFrameRect.size.width, 0.0);
			glEnd();
			
			glBegin(GL_QUADS);
				glVertex2f(0.0, topLeft.y);
				glVertex2f(topLeft.x, topLeft.y);
				glVertex2f(topLeft.x, topLeft.y+iChatHeight);
				glVertex2f(0.0, topLeft.y+iChatHeight);
			glEnd();
			
			glBegin(GL_QUADS);
				glVertex2f(topLeft.x+iChatWidth, topLeft.y);
				glVertex2f(drawingFrameRect.size.width, topLeft.y);
				glVertex2f(drawingFrameRect.size.width, topLeft.y+iChatHeight);
				glVertex2f(topLeft.x+iChatWidth, topLeft.y+iChatHeight);
			glEnd();
			
			glBegin(GL_QUADS);
				glVertex2f(0.0, topLeft.y+iChatHeight);
				glVertex2f(drawingFrameRect.size.width, topLeft.y+iChatHeight);
				glVertex2f(drawingFrameRect.size.width, drawingFrameRect.size.height);
				glVertex2f(0.0, drawingFrameRect.size.height);
			glEnd();
			
			glColor4f (1.0f, 1.0f, 1.0f, 0.8f);
			glBegin(GL_LINE_LOOP);
				glVertex2f(topLeft.x, topLeft.y);
				glVertex2f(topLeft.x, topLeft.y+iChatHeight);
				glVertex2f(topLeft.x+iChatWidth, topLeft.y+iChatHeight);
				glVertex2f(topLeft.x+iChatWidth, topLeft.y);
			glEnd();
			
			glLineWidth(1.0);
			glDisable(GL_BLEND);
			
			// label
			NSPoint iChatTheatreSharedViewLabelPosition;
			iChatTheatreSharedViewLabelPosition.x = drawingFrameRect.size.width/2.0;
			iChatTheatreSharedViewLabelPosition.y = topLeft.y;
			
			[self DrawNSStringGL:NSLocalizedString(@"iChat Theatre shared view", nil) :fontListGL :iChatTheatreSharedViewLabelPosition.x :iChatTheatreSharedViewLabelPosition.y align:DCMViewTextAlignCenter useStringTexture:YES];
		}
		#endif //10.07.2010
		// ***********************
		// DRAW CLUT BARS ********
		
		if( [self is2DViewer] == YES && annotations != annotNone && ctx!=_alternateContext)
		{

			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f /(drawingFrameRect.size.width), -2.0f / (drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
			
			if( clutBars == barOrigin || clutBars == barBoth)
			{

				float			heighthalf = drawingFrameRect.size.height/2 - 1;
				float			widthhalf = drawingFrameRect.size.width/2 - 1;
				NSString		*tempString = nil;
				
				//#define BARPOSX1 50.f
				//#define BARPOSX2 20.f
				
				#define BARPOSX1 62.f
				#define BARPOSX2 32.f
				
				heighthalf = 0;
				
				//					glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
				//					glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f);
				
				glLineWidth(1.0);
				glBegin(GL_LINES);
				for( int i = 0; i < 256; i++ )
				{
					glColor3ub ( redTable[ i], greenTable[ i], blueTable[ i]);
					
					glVertex2f(  widthhalf - BARPOSX1, heighthalf - (-128.f + i));
					glVertex2f(  widthhalf - BARPOSX2, heighthalf - (-128.f + i));
				}
				glColor3ub ( 128, 128, 128);
				glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX2 , heighthalf - -128.f);
				glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);			glVertex2f(  widthhalf - BARPOSX2 , heighthalf - 127.f);
				glVertex2f(  widthhalf - BARPOSX1, heighthalf - -128.f);		glVertex2f(  widthhalf - BARPOSX1, heighthalf - 127.f);
				glVertex2f(  widthhalf - BARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  widthhalf - BARPOSX2, heighthalf - 127.f);
				glEnd();
				
				if( curWW < 50 )
				{

					tempString = [NSString stringWithFormat: @"%0.4f", curWL - curWW/2];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
					
					tempString = [NSString stringWithFormat: @"%0.4f", curWL];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
					
					tempString = [NSString stringWithFormat: @"%0.4f", curWL + curWW/2];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
				}
				else
				{

					tempString = [NSString stringWithFormat: @"%0.0f", curWL - curWW/2];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - -133 rightAlignment: YES useStringTexture: NO];
					
					tempString = [NSString stringWithFormat: @"%0.0f", curWL];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - 0 rightAlignment: YES useStringTexture: NO];
					
					tempString = [NSString stringWithFormat: @"%0.0f", curWL + curWW/2];
					[self DrawNSStringGL: tempString : fontListGL :widthhalf - BARPOSX1: heighthalf - 120 rightAlignment: YES useStringTexture: NO];
				}
			} //clutBars == barOrigin || clutBars == barBoth
			
			if( blendingView )
			{

				if( clutBars == barFused || clutBars == barBoth)
				{

					unsigned char	*bred = nil, *bgreen = nil, *bblue = nil;
					float			heighthalf = drawingFrameRect.size.height/2 - 1;
					float			widthhalf = drawingFrameRect.size.width/2 - 1;
					float			bwl, bww;
					NSString		*tempString = nil;
					
//!!!!!	OsiriX:				if( [[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
//!!!!!  NEW START
					if(([[[blendingView windowController] modality] isEqualToString:@"PT"] || [[[blendingView windowController] modality] isEqualToString:@"PT"]) &&
								[[[NSUserDefaults standardUserDefaults] stringForKey:@"PET Clut Mode"] isEqualToString: @"B/W Inverse"])
//!!!!!  NEW END
					{
						
//!!!!!  OsiriX:						if( PETredTable == nil) {
//!!!!!  NEW START						
						if( [DCMView PETredTable] == nil) {
//!!!!!  NEW END
							[DCMView computePETBlendingCLUT];
						}
						
//!!!!! OsiriX:						bred = PETredTable;
//!!!!! OsiriX:						bgreen = PETgreenTable;
//!!!!! OsiriX:						bblue = PETblueTable;
//!!!!!  NEW START						
						bred = [DCMView PETredTable];
						bgreen = [DCMView PETgreenTable];
						bblue = [DCMView PETblueTable];
//!!!!!  NEW END						
					}
					else [blendingView getCLUT:&bred :&bgreen :&bblue];
					
					
					#define BBARPOSX1 55.f
					#define BBARPOSX2 25.f
					
					heighthalf = 0;
					
					glLineWidth(1.0);
					glBegin(GL_LINES);
					
					if( bred)
					{
		
						for( int i = 0; i < 256; i++ )
						{
			
							glColor3ub ( bred[ i], bgreen[ i], bblue[ i]);
							
							glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - (-128.f + i));
							glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - (-128.f + i));
						}
					}
					else
						NSLog( @"bred == nil");
					
					glColor3ub ( 128, 128, 128);
					glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - -128.f);
					glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);		glVertex2f(  -widthhalf + BBARPOSX2 , heighthalf - 127.f);
					glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - -128.f);		glVertex2f(  -widthhalf + BBARPOSX1, heighthalf - 127.f);
					glVertex2f(  -widthhalf + BBARPOSX2 ,heighthalf -  -128.f);		glVertex2f(  -widthhalf + BBARPOSX2, heighthalf - 127.f);
					glEnd();
					
					[blendingView getWLWW: &bwl :&bww];
					
					if( curWW < 50)
					{

						tempString = [NSString stringWithFormat: @"%0.4f", bwl - bww/2];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
						
						tempString = [NSString stringWithFormat: @"%0.4f", bwl];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
						
						tempString = [NSString stringWithFormat: @"%0.4f", bwl + bww/2];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
					}
					else
					{
	
						tempString = [NSString stringWithFormat: @"%0.0f", bwl - bww/2];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - -133];
						
						tempString = [NSString stringWithFormat: @"%0.0f", bwl];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 0];
						
						tempString = [NSString stringWithFormat: @"%0.0f", bwl + bww/2];
						[self DrawNSStringGL: tempString : fontListGL :-widthhalf + BBARPOSX1 + 4: heighthalf - 120];
					}
				}
			} //blendingView
		} //[self is2DViewer] == YES
		
		if (annotations != annotNone)
		{

			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
			
			//FRAME RECT IF MORE THAN 1 WINDOW and IF THIS WINDOW IS THE FRONTMOST : BORDER AROUND THE IMAGE
			
			if(( [ViewerController numberOf2DViewer] > 1 && [self is2DViewer] == YES && stringID == nil) || [stringID isEqualToString:@"OrthogonalMPRVIEW"])
			{

				// draw line around key View
				
				if( [[self window] isMainWindow] && isKeyView && ctx!=_alternateContext)
				{

					float heighthalf = drawingFrameRect.size.height/2;
					float widthhalf = drawingFrameRect.size.width/2;
					
					// red square
					
					//					glEnable(GL_BLEND);
					glColor4f (1.0f, 0.0f, 0.0f, 0.8f);
					glLineWidth(8.0);
					glBegin(GL_LINE_LOOP);
						glVertex2f(  -widthhalf, -heighthalf);
						glVertex2f(  -widthhalf, heighthalf);
						glVertex2f(  widthhalf, heighthalf);
						glVertex2f(  widthhalf, -heighthalf);
					glEnd();
					glLineWidth(1.0);
					//					glDisable(GL_BLEND);
				}
			}  //drawLines for ImageView Frames
			
			if ((_imageColumns > 1 || _imageRows > 1) && [self is2DViewer] == YES && stringID == nil )
			{

				float heighthalf = drawingFrameRect.size.height/2 - 1;
				float widthhalf = drawingFrameRect.size.width/2 - 1;
				
				glColor3f (0.5f, 0.5f, 0.5f);
				glLineWidth(1.0);
				glBegin(GL_LINE_LOOP);
				glVertex2f(  -widthhalf, -heighthalf);
				glVertex2f(  -widthhalf, heighthalf);
				glVertex2f(  widthhalf, heighthalf);
				glVertex2f(  widthhalf, -heighthalf);
				glEnd();
				glLineWidth(1.0);
				if (isKeyView && [[self window] isMainWindow])
				{

					float heighthalf = drawingFrameRect.size.height/2 - 1;
					float widthhalf = drawingFrameRect.size.width/2 - 1;
					
					glColor3f (1.0f, 0.0f, 0.0f);
					glLineWidth(2.0);
					glBegin(GL_LINE_LOOP);
						glVertex2f(  -widthhalf, -heighthalf);
						glVertex2f(  -widthhalf, heighthalf);
						glVertex2f(  widthhalf, heighthalf);
						glVertex2f(  widthhalf, -heighthalf);
					glEnd();
					glLineWidth(1.0);
				}
			}
			
			glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
			glTranslatef( origin.x + originOffset.x, -origin.y - originOffset.y, 0.0f);
			glScalef( 1.f, curDCM.pixelRatio, 1.f);
			
			// Draw ROIs
			BOOL drawROI = NO;
			
			if( [self is2DViewer] == YES) drawROI = [[[self windowController] roiLock] tryLock];
			else drawROI = YES;
			
			if( drawROI )
			{
	
				BOOL resetData = NO;
				if(_imageColumns > 1 || _imageRows > 1) resetData = YES;	//For alias ROIs
				
				NSSortDescriptor * roiSorting = [[[NSSortDescriptor alloc] initWithKey:@"uniqueID" ascending:NO] autorelease];
				
				rectArray = [[NSMutableArray alloc] initWithCapacity: [curRoiList count]];
				
				for( int i = [curRoiList count]-1; i >= 0; i--)
				{

					ROI *r = [[curRoiList objectAtIndex:i] retain];	// If we are not in the main thread (iChat), we want to be sure to keep our ROIs
					
					if( resetData) [r recompute];
					[r setRoiFont: labelFontListGL :labelFontListGLSize :self];
					[r drawROI: scaleValue : curDCM.pwidth / 2. : curDCM.pheight / 2. : curDCM.pixelSpacingX : curDCM.pixelSpacingY];
					
					[r release];
				}
				
				if ( !suppress_labels )
				{

					NSArray	*sortedROIs = [curRoiList sortedArrayUsingDescriptors: [NSArray arrayWithObject: roiSorting]];
					for( int i = [sortedROIs count]-1; i>=0; i-- )
					{
						
						ROI *r = [[sortedROIs objectAtIndex:i] retain];
						
						@try
						{
							[r drawTextualData];
						}
						@catch (NSException * e)
						{
							NSLog( @"drawTextualData ROI Exception : %@", e);
						}
						
						[r release];
					}
				}
				
				[rectArray release];
				rectArray = nil;
			}
			
			if( drawROI && [self is2DViewer] == YES) [[[self windowController] roiLock] unlock];
			
			// Draw 2D point cross (used when double-click in 3D panel)
			
			[self draw2DPointMarker];
			
			if( blendingView) 	[blendingView draw2DPointMarker];
			
			// Draw any Plugin objects
			
			NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:	[NSNumber numberWithFloat: scaleValue], @"scaleValue",
																					[NSNumber numberWithFloat: curDCM.pwidth /2. ], @"offsetx",
																					[NSNumber numberWithFloat: curDCM.pheight /2.], @"offsety",
																					[NSNumber numberWithFloat: curDCM.pixelSpacingX], @"spacingX",
																					[NSNumber numberWithFloat: curDCM.pixelSpacingY], @"spacingY",
									  nil];
			
			[[NSNotificationCenter defaultCenter] postNotificationName: @"PLUGINdrawObjects" object: self userInfo: userInfo];
			
			//**SLICE CUR FOR 3D MPR
			//			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f);
			//			if( stringID )
			{
				//				if( [stringID isEqualToString:@"OrthogonalMPRVIEW"])
				{
					[self subDrawRect: aRect];
					
					self.scaleValue = scaleValue;
				}
			}
			
			//** SLICE CUT BETWEEN SERIES - CROSS REFERENCES LINES
			
			if( (stringID == nil || [stringID isEqualToString:@"export"]) && [[self window] isMainWindow] == NO)
			{

				glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA );
				glEnable(GL_BLEND);
				glEnable(GL_POINT_SMOOTH);
				glEnable(GL_LINE_SMOOTH);
				glEnable(GL_POLYGON_SMOOTH);
				
				if( DISPLAYCROSSREFERENCELINES)
				{

					if( sliceFromTo[ 0][ 0] != HUGE_VALF)
					{

						if( sliceFromToS[ 0][ 0] != HUGE_VALF)
						{

							glColor3f (1.0f, 0.6f, 0.0f);
							
							glLineWidth(2.0);
							[self drawCrossLines: sliceFromToS ctx: cgl_ctx perpendicular: NO];
							
							glLineWidth(2.0);
							[self drawCrossLines: sliceFromToE ctx: cgl_ctx perpendicular: NO];
						}
						
						glColor3f (0.0f, 0.6f, 0.0f);
						glLineWidth(2.0);
						[self drawCrossLines: sliceFromTo ctx: cgl_ctx perpendicular: YES];
						
						if( sliceFromTo2[ 0][ 0] != HUGE_VALF)
						{

							glLineWidth(2.0);
							[self drawCrossLines: sliceFromTo2 ctx: cgl_ctx perpendicular: YES];
						}
					}
				}
				
				if( slicePoint3D[ 0] != HUGE_VALF)
				{

					float tempPoint3D[ 2];
					
					glLineWidth(2.0);
					
					tempPoint3D[0] = slicePoint3D[ 0] / curDCM.pixelSpacingX;
					tempPoint3D[1] = slicePoint3D[ 1] / curDCM.pixelSpacingY;
					
					tempPoint3D[0] -= curDCM.pwidth * 0.5f;
					tempPoint3D[1] -= curDCM.pheight * 0.5f;
					
					glColor3f (0.0f, 0.6f, 0.0f);
					glLineWidth(2.0);
					
					if( sliceFromTo[ 0][ 0] != HUGE_VALF && (sliceVector[ 0] != 0 || sliceVector[ 1] != 0  || sliceVector[ 2] != 0))
					{

						float a[ 2];
						// perpendicular vector
						
						a[ 1] = sliceFromTo[ 0][ 0] - sliceFromTo[ 1][ 0];
						a[ 0] = sliceFromTo[ 0][ 1] - sliceFromTo[ 1][ 1];
						
						// normalize
						double t = a[ 1]*a[ 1] + a[ 0]*a[ 0];
						t = sqrt(t);
						a[0] = a[0]/t;
						a[1] = a[1]/t;
						
						#define LINELENGTH 15
						
						glBegin(GL_LINES);
							glVertex2f( scaleValue*(tempPoint3D[ 0]-LINELENGTH/curDCM.pixelSpacingX * a[ 0]), scaleValue*(tempPoint3D[ 1]+LINELENGTH/curDCM.pixelSpacingY*(a[ 1])));
							glVertex2f( scaleValue*(tempPoint3D[ 0]+LINELENGTH/curDCM.pixelSpacingX * a[ 0]), scaleValue*(tempPoint3D[ 1]-LINELENGTH/curDCM.pixelSpacingY*(a[ 1])));
						glEnd();
					}
					else
					{

						glBegin(GL_LINES);
							glVertex2f( scaleValue*(tempPoint3D[ 0]-LINELENGTH/curDCM.pixelSpacingX), scaleValue*(tempPoint3D[ 1]));
							glVertex2f( scaleValue*(tempPoint3D[ 0]+LINELENGTH/curDCM.pixelSpacingX), scaleValue*(tempPoint3D[ 1]));
						
							glVertex2f( scaleValue*(tempPoint3D[ 0]), scaleValue*(tempPoint3D[ 1]-LINELENGTH/curDCM.pixelSpacingY));
							glVertex2f( scaleValue*(tempPoint3D[ 0]), scaleValue*(tempPoint3D[ 1]+LINELENGTH/curDCM.pixelSpacingY));
						glEnd();
					}
					glLineWidth(1.0);
				}
				
				glDisable(GL_LINE_SMOOTH);
				glDisable(GL_POLYGON_SMOOTH);
				glDisable(GL_POINT_SMOOTH);
				glDisable(GL_BLEND);
			}
			
			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
			
			glColor3f (0.0f, 1.0f, 0.0f);
			
			if( annotations >= annotBase)
			{

				//** PIXELSPACING LINES
				float yOffset = 24;
				float xOffset = 32;
				//float xOffset = 10;
				//float yOffset = 12;
				glLineWidth( 1.0);
				glBegin(GL_LINES);
				//		 NSLog(@"!!!!! %d drawRect: 31 1 31 1 31 1", rrr);		
				
				if( curDCM.pixelSpacingX != 0 && curDCM.pixelSpacingX * 1000.0 < 1)
				{

					glVertex2f(scaleValue  * (-0.02/curDCM.pixelSpacingX), drawingFrameRect.size.height/2 - yOffset); 
					glVertex2f(scaleValue  * (0.02/curDCM.pixelSpacingX), drawingFrameRect.size.height/2 - yOffset);
					
					glVertex2f(-drawingFrameRect.size.width/2 + xOffset , scaleValue  * (-0.02/curDCM.pixelSpacingY*curDCM.pixelRatio)); 
					glVertex2f(-drawingFrameRect.size.width/2 + xOffset , scaleValue  * (0.02/curDCM.pixelSpacingY*curDCM.pixelRatio));
					
					for ( short i = -20; i<=20; i++ )
					{
						short length = ( i % 10 == 0 )? 10 : 5;
						
						glVertex2f(i*scaleValue *0.001/curDCM.pixelSpacingX, drawingFrameRect.size.height/2 - yOffset);
						glVertex2f(i*scaleValue *0.001/curDCM.pixelSpacingX, drawingFrameRect.size.height/2 - yOffset - length);
						
						glVertex2f(-drawingFrameRect.size.width/2 + xOffset +  length,  i* scaleValue *0.001/curDCM.pixelSpacingY*curDCM.pixelRatio);
						glVertex2f(-drawingFrameRect.size.width/2 + xOffset,  i* scaleValue * 0.001/curDCM.pixelSpacingY*curDCM.pixelRatio);
					}
				}
				else if( curDCM.pixelSpacingX != 0 && curDCM.pixelSpacingY != 0)
				{

					glVertex2f(scaleValue  * (-50/curDCM.pixelSpacingX), drawingFrameRect.size.height/2 - yOffset); 
					glVertex2f(scaleValue  * (50/curDCM.pixelSpacingX), drawingFrameRect.size.height/2 - yOffset);
					
					glVertex2f(-drawingFrameRect.size.width/2 + xOffset , scaleValue  * (-50/curDCM.pixelSpacingY*curDCM.pixelRatio)); 
					glVertex2f(-drawingFrameRect.size.width/2 + xOffset , scaleValue  * (50/curDCM.pixelSpacingY*curDCM.pixelRatio));
					
					for ( short i = -5; i<=5; i++ )
					{
						short length = (i % 5 == 0) ? 10 : 5;
						
						glVertex2f(i*scaleValue *10/curDCM.pixelSpacingX, drawingFrameRect.size.height/2 - yOffset);
						glVertex2f(i*scaleValue *10/curDCM.pixelSpacingX, drawingFrameRect.size.height/2 - yOffset - length);
						
						glVertex2f(-drawingFrameRect.size.width/2 + xOffset +  length,  i* scaleValue *10/curDCM.pixelSpacingY*curDCM.pixelRatio);
						glVertex2f(-drawingFrameRect.size.width/2 + xOffset,  i* scaleValue * 10/curDCM.pixelSpacingY*curDCM.pixelRatio);
					}
				}
				glEnd();
				
				@try
				{
					//					NSLog(@"!!!!! %d drawRect: 34 34 34", rrr);		
					
					[self drawTextualData: drawingFrameRect :annotations];
				}
				
				@catch (NSException * e)
				{
					NSLog( @"drawTextualData Annotations Exception : %@", e);	//10.07.2010
				}
				
			}
			
		} //Annotation  != None
		
		if(repulsorRadius != 0)
		{

			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
			glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
			
			[self drawRepulsorToolArea];
		}
		
		if(ROISelectorStartPoint.x!=ROISelectorEndPoint.x || ROISelectorStartPoint.y!=ROISelectorEndPoint.y)
		{

			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
			glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
			
			[self drawROISelectorRegion];
		}
		
		if(ctx == _alternateContext && [[NSApplication sharedApplication] isActive]) // iChat Theatre context
		{

			glLoadIdentity (); // reset model view matrix to identity (eliminates rotation basically)
			glScalef (2.0f / drawingFrameRect.size.width, -2.0f /  drawingFrameRect.size.height, 1.0f); // scale to port per pixel scale
			glTranslatef (-(drawingFrameRect.size.width) / 2.0f, -(drawingFrameRect.size.height) / 2.0f, 0.0f); // translate center to upper left
			
			NSPoint eventLocation = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
			
			// location of the mouse in the OsiriX View
			eventLocation = [self convertPoint:eventLocation fromView:nil];
			eventLocation.y = [self frame].size.height - eventLocation.y;
			
			
			// location of the mouse in the iChat Theatre View			
			eventLocation = [self convertFromView2iChat:eventLocation];
			
			// generate iChat cursor Texture Buffer (only once)
			if(!iChatCursorTextureBuffer) 
			{

				//				NSLog(@"!!!!! %d drawRect: 38 38 38", rrr);		
				
				NSLog(@"generate iChatCursor Texture Buffer"); //10.07.2010
				NSImage *iChatCursorImage;
				if (iChatCursorImage = [[NSCursor pointingHandCursor] image])
				{

					//					NSLog(@"!!!!! %d drawRect: 39 39 39", rrr);		
					
					iChatCursorHotSpot = [[NSCursor pointingHandCursor] hotSpot];
					iChatCursorImageSize = [iChatCursorImage size];
					
					NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:[iChatCursorImage TIFFRepresentation]]; // [NSBitmapImageRep imageRepWithData: [iChatCursorImage TIFFRepresentation]]
					
					iChatCursorTextureBuffer = malloc([bitmap bytesPerRow] * iChatCursorImageSize.height);
					memcpy(iChatCursorTextureBuffer, [bitmap bitmapData], [bitmap bytesPerRow] * iChatCursorImageSize.height);
					
					[bitmap release];
					
					iChatCursorTextureName = 0;
					glGenTextures(1, &iChatCursorTextureName);
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, iChatCursorTextureName);
					glPixelStorei(GL_UNPACK_ROW_LENGTH, [bitmap bytesPerRow]/4);
					glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
					glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE); //10.07.2010
					glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, iChatCursorImageSize.width, iChatCursorImageSize.height, 0, GL_RGBA, GL_UNSIGNED_INT_8_8_8_8_REV, iChatCursorTextureBuffer);
				}
			}
			
			// draw the cursor in the iChat Theatre View
			if(iChatCursorTextureBuffer)
			{

				//				NSLog(@"!!!!! %d drawRect: 40 40 40", rrr);		
				
				eventLocation.x -= iChatCursorHotSpot.x;
				eventLocation.y -= iChatCursorHotSpot.y;
				
				glEnable(GL_TEXTURE_RECTANGLE_EXT);
				
				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, iChatCursorTextureName);
				glBlendEquation(GL_FUNC_ADD);
				glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
				glEnable(GL_BLEND);
				
				glColor4f(1.0, 1.0, 1.0, 1.0);
				glBegin(GL_QUAD_STRIP);
				glTexCoord2f(0, 0);
				glVertex2f(eventLocation.x, eventLocation.y);
				
				glTexCoord2f(iChatCursorImageSize.width, 0);
				glVertex2f(eventLocation.x + iChatCursorImageSize.width, eventLocation.y);
				
				glTexCoord2f(0, iChatCursorImageSize.height);
				glVertex2f(eventLocation.x, eventLocation.y + iChatCursorImageSize.height);
				
				glTexCoord2f(iChatCursorImageSize.width, iChatCursorImageSize.height);
				glVertex2f(eventLocation.x + iChatCursorImageSize.width, eventLocation.y + iChatCursorImageSize.height);
				
				glEnd();
				glDisable(GL_BLEND);
				
				glDisable(GL_TEXTURE_RECTANGLE_EXT);
			}
		} // end iChat Theatre context	
		
		if( showDescriptionInLarge)
		{

			glMatrixMode (GL_PROJECTION);
			glPushMatrix();
				glLoadIdentity ();
				glMatrixMode (GL_MODELVIEW);
				glPushMatrix();
					glLoadIdentity ();
					glScalef (2.0f / [self frame].size.width, -2.0f /  [self frame].size.height, 1.0f);
					glTranslatef (-[self frame].size.width / 2.0f, -[self frame].size.height / 2.0f, 0.0f);
			
					[showDescriptionInLargeText drawAtPoint:NSMakePoint([self frame].size.width/2 - [showDescriptionInLargeText frameSize].width/2, [self frame].size.height/2 - [showDescriptionInLargeText frameSize].height/2)];
			
					glPopMatrix(); // GL_MODELVIEW
				glMatrixMode (GL_PROJECTION);
			glPopMatrix();
		}
	}  
	else
	{

		//no valid image  ie curImage = -1
		//NSLog(@"no IMage");
		//		NSLog(@"!!!!! %d drawRect: 42 42 42", rrr);		
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear (GL_COLOR_BUFFER_BIT);
	}
	
#ifndef new_loupe
	if( lensTexture)
	{
		/* creating Loupe textures (mask and border) */
		
		NSBundle *bundle = [NSBundle bundleForClass:[DCMView class]];
		if(!loupeImage)
		{

			loupeImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupe.png"]];
			loupeTextureWidth = [loupeImage size].width;
			loupeTextureHeight = [loupeImage size].height;
		}
		if(!loupeMaskImage)
		{

			loupeMaskImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:@"loupeMask.png"]];
			loupeMaskTextureWidth = [loupeMaskImage size].width;
			loupeMaskTextureHeight = [loupeMaskImage size].height;
		}
		
		if(loupeTextureID==0) {
	
			[self makeTextureFromImage:loupeImage forTexture:&loupeTextureID buffer:loupeTextureBuffer textureUnit:GL_TEXTURE3];
		}
		if(loupeMaskTextureID==0) {

			[self makeTextureFromImage:loupeMaskImage forTexture:&loupeMaskTextureID buffer:loupeMaskTextureBuffer textureUnit:GL_TEXTURE0];
		}		
		/* mouse position */
		
		NSPoint eventLocation = [[self window] convertScreenToBase: [NSEvent mouseLocation]];
		eventLocation = [self convertPoint:eventLocation fromView:nil];
		
		if( xFlipped)
		{
			eventLocation.x = drawingFrameRect.size.width - eventLocation.x;
		}
		
		if( yFlipped)
		{
			eventLocation.y = drawingFrameRect.size.height - eventLocation.y;
		}
		
		eventLocation.y = drawingFrameRect.size.height - eventLocation.y;
		eventLocation.y -= drawingFrameRect.size.height/2;
		eventLocation.x -= drawingFrameRect.size.width/2;
		
		float xx = eventLocation.x*cos(rotation*deg2rad) + eventLocation.y*sin(rotation*deg2rad);
		float yy = -eventLocation.x*sin(rotation*deg2rad) + eventLocation.y*cos(rotation*deg2rad);
		
		eventLocation.x = xx;
		eventLocation.y = yy;
		
		eventLocation.x -= LENSSIZE*2*scaleValue/LENSRATIO;
		eventLocation.y -= LENSSIZE*2*scaleValue/LENSRATIO;
		
		glMatrixMode (GL_MODELVIEW);
		glLoadIdentity ();
		
		glScalef (2.0f /(xFlipped ? -(drawingFrameRect.size.width) : drawingFrameRect.size.width), -2.0f / (yFlipped ? -(drawingFrameRect.size.height) : drawingFrameRect.size.height), 1.0f); // scale to port per pixel scale
		glRotatef (rotation, 0.0f, 0.0f, 1.0f); // rotate matrix for image rotation
		
		/* binding lensTexture */
		
		GLuint textID;
		
		glEnable(TEXTRECTMODE);
		glPixelStorei(GL_UNPACK_ROW_LENGTH, LENSSIZE); 
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
		glTexParameteri (GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE); //10.07.2010
		
		glGenTextures(1, &textID);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(TEXTRECTMODE, textID);
		glTexParameteri(TEXTRECTMODE, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(TEXTRECTMODE, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		
		glColor4f( 1, 1, 1, 1);
		#if __BIG_ENDIAN__
		glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, LENSSIZE, LENSSIZE, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, lensTexture);
		#else
		glTexImage2D (TEXTRECTMODE, 0, GL_RGBA, LENSSIZE, LENSSIZE, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8, lensTexture);
		#endif
		
 		glEnable(GL_BLEND);
		glBlendEquation(GL_FUNC_ADD);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		
		/* multitexturing starts */
		
		glActiveTexture(GL_TEXTURE0);
		glEnable(loupeMaskTextureID);
		glBindTexture(TEXTRECTMODE, loupeMaskTextureID);
		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
		glTexEnvf(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_TEXTURE0);
		glTexEnvf(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
		
		glActiveTexture(GL_TEXTURE1);
		glEnable(textID);
		glBindTexture(TEXTRECTMODE, textID);
		glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_RGB, GL_TEXTURE1);
		glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_RGB, GL_SRC_COLOR);
		glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_ALPHA, GL_REPLACE);
		glTexEnvi(GL_TEXTURE_ENV, GL_SOURCE0_ALPHA, GL_PREVIOUS);
		glTexEnvi(GL_TEXTURE_ENV, GL_OPERAND0_ALPHA, GL_SRC_ALPHA);
		
		glActiveTexture(GL_TEXTURE0);
		glEnable(TEXTRECTMODE);
		glActiveTexture(GL_TEXTURE1);
		glEnable(TEXTRECTMODE);
		
		glBegin (GL_QUAD_STRIP);
		glMultiTexCoord2f (GL_TEXTURE1, 0, 0); // lensTexture : upper left in texture coordinates
		glMultiTexCoord2f (GL_TEXTURE0, 0, 0); // mask texture : upper left in texture coordinates
		glVertex3d (eventLocation.x, eventLocation.y, 0.0);
		
		glMultiTexCoord2f (GL_TEXTURE1, LENSSIZE, 0); // lensTexture : lower left in texture coordinates
		glMultiTexCoord2f (GL_TEXTURE0, loupeMaskTextureWidth, 0); // mask texture : lower left in texture coordinates
		glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y, 0.0);
		
		glMultiTexCoord2f (GL_TEXTURE1, 0, LENSSIZE); // lensTexture : upper right in texture coordinates
		glMultiTexCoord2f (GL_TEXTURE0, 0, loupeMaskTextureHeight); // mask texture : upper right in texture coordinates
		glVertex3d (eventLocation.x, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
		
		glMultiTexCoord2f (GL_TEXTURE1, LENSSIZE, LENSSIZE); // lensTexture : lower right in texture coordinates
		glMultiTexCoord2f (GL_TEXTURE0, loupeMaskTextureWidth, loupeMaskTextureHeight); // mask texture : lower right in texture coordinates
		glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
		glEnd();
		
		glActiveTexture(GL_TEXTURE1); // deactivate multitexturing
		glDisable(TEXTRECTMODE);
		glDeleteTextures( 1, &textID);
		
		/* multitexturing ends */
		
		// back to single texturing mode:
		glActiveTexture(GL_TEXTURE0); // activate single texture unit
		glDisable(TEXTRECTMODE);
		
		// drawing loupe border 
		BOOL drawLoupeBorder = YES;
		if(loupeTextureID && drawLoupeBorder)
		{

			glEnable(GL_TEXTURE_RECTANGLE_EXT);
			
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, loupeTextureID);
			
			glColor4f(1.0, 1.0, 1.0, 1.0);
			
			glBegin(GL_QUAD_STRIP);			
				glTexCoord2f(0, 0);
				glVertex3d (eventLocation.x, eventLocation.y, 0.0);
				glTexCoord2f(loupeTextureWidth, 0);
				glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y, 0.0);
				glTexCoord2f(0, loupeTextureHeight);
				glVertex3d (eventLocation.x, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
				glTexCoord2f(loupeTextureWidth, loupeTextureHeight);
				glVertex3d (eventLocation.x+LENSSIZE*4*scaleValue/LENSRATIO, eventLocation.y+LENSSIZE*4*scaleValue/LENSRATIO, 0.0);
			glEnd();
			
			glDisable(GL_TEXTURE_RECTANGLE_EXT);
		}
		
		glDisable(GL_BLEND);
	}
#endif
 } //10.07.2010
  @catch (NSException * e)											//10.07.2010
  {																	//10.07.2010
	  NSLog(@"***** exception in %s: %@", __PRETTY_FUNCTION__, e);	//10.07.2010
  }																	//10.07.2010
	 
	 
	 
	// Swap buffer to screen
	[ctx  flushBuffer];
	
	
	//10.07.2010

	drawingFrameRect = [self frame];
	
	if( ctx == _alternateContext)
		drawingFrameRect = savedDrawingFrameRect;
	
	
	
	
	if(iChatRunning) [drawLock unlock];
	
	(void)[self _checkHasChanged:YES];
	
//10.07.2010	drawingFrameRect = [self frame];
}
//!!!!!************************************************************************

@end


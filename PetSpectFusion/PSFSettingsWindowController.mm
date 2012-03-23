//
//  PSFSettingsWindowController.mm
//  PetSpectFusion
//
//  Created by Brian on 4/1/09.
//  Copyright 2009. All rights reserved.
//

#import <Foundation/NSDebug.h>

#import "PSFSettingsWindowController.h"

@implementation PSFSettingsWindowController

@synthesize rotX;
@synthesize rotY;
@synthesize rotZ;
@synthesize transX;
@synthesize transY;
@synthesize transZ;
@synthesize fixedImageViewer;
@synthesize movingImageViewer;

- (id) initWithFixedImageViewer:(ViewerController*) fViewer movingImageViewer:(ViewerController *) mViewer;
{
	//Set the defaults before loading the window (otherwise parameters will not be initialized)
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:[self getDefaults]];
	
	self = [super initWithWindowNibName:@"PSFSettingsWindow"];
	if(self != nil)
	{
		[self showWindow:self];
		
		fixedImageViewer = fViewer;
		movingImageViewer = mViewer;
		
		//initialize the transform, and the transform wrapper class
		DebugLog(@"Initializing transform");
		transform = [[ITKVersorTransform alloc] initWithViewer:movingImageViewer resampleToViewer:fixedImageViewer];
		fixedImageWrapper = [[ITKImageWrapper alloc] initWithViewer:fixedImageViewer slice:-1];
		fixedImage = [fixedImageWrapper image];
		movingImage = [transform sourceImage];
		itkTransform = TransformType::New();
		initializeTransform(itkTransform, fixedImage, movingImage);
		
		[iterationsLabel setIntValue:0];
		[metricLabel setFloatValue:0.0];
		[levelLabel setIntValue:0];
		regIsRunning = NO;
		[self enableMultiresolution:self];
		
		float scaleValue = [fixedImageViewer scaleValue];
		ParametersType params(6);
		params = itkTransform->GetParameters();
		
		self.rotX = params[0];
		self.rotY = params[1];
		self.rotZ = params[2];
		self.transX = params[3];
		self.transY = params[4];
		self.transZ = params[5];
		
		[self updateDisplay:params];
		[fixedImageViewer setScaleValue:scaleValue];
		
		[settingsTabView setDelegate:self]; //make sure to catch tab switch events so we can redraw correctly

		
	}
	else
		NSLog(@"Failed to init SettingsWindowController, problems loading xib!");
	
	return self;
}

- (NSMutableDictionary*) getDefaults
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setValue:[NSNumber numberWithInt:DEFAULT_BINS] forKey:@"PSFBins"];
	[defaults setValue:[NSNumber numberWithFloat: DEFAULT_SAMPLERATE] forKey:@"PSFSampleRate"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_MINSTEP] forKey:@"PSFMinStep"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_MAXSTEP] forKey:@"PSFMaxStep"];
	[defaults setValue:[NSNumber numberWithInt:DEFAULT_MULTIRES_LEVELS] forKey:@"PSFMultiResLevels"];
	[defaults setValue:@"0" forKey:@"PSFMultiResEnable"];
	
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_XTRANS_SCALE] forKey:@"PSFXTransScale"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_YTRANS_SCALE] forKey:@"PSFYTransScale"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_ZTRANS_SCALE] forKey:@"PSFZTransScale"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_XROT_SCALE] forKey:@"PSFXRotScale"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_YROT_SCALE] forKey:@"PSFYRotScale"];
	[defaults setValue:[NSNumber numberWithFloat:DEFAULT_ZROT_SCALE] forKey:@"PSFZRotScale"];
	return defaults;
}

- (void) dealloc
{
	DebugLog(@"SettingsWindowController dealloc!");
	[fixedImageWrapper release];
	[transform release];
	[super dealloc];
}

- (IBAction) performRegistration:(id) sender
{
	DebugLog(@"performRegistration called");
	if(!regIsRunning)
	{
		[self enableInputs:NO];
		[metricButton setEnabled:NO];
		[registrationButton setTitle:@"Stop"];
		[NSThread detachNewThreadSelector:@selector(startRegistration) toTarget:self withObject:nil];
		
	}
	else
	{
		[self stopRegistration];
	}
	
}

- (void) startRegistration
{
	NSAutoreleasePool* myAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	DebugLog(@"Initializing registration process...");
	
	OptimizerScalesType scales(6);
	scales[0] = [wRotBoxX floatValue];
	scales[1] = [wRotBoxY floatValue];
	scales[2] = [wRotBoxZ floatValue];
	scales[3] = [wTransBoxX floatValue];	
	scales[4] = [wTransBoxY floatValue];
	scales[5] = [wTransBoxZ floatValue];
	
	int levels = 0;
	if([multiResEnableButton state] == NSOnState)
		levels = [multiResLevelsBox intValue];
	
	regIsRunning = YES;
	
	observer = CommandIterationUpdate::New();
	observer->setDisplayObserver(self);
	ParametersType params(6);
	params[0] = self.rotX;
	params[1] = self.rotY;
	params[2] = self.rotZ;
	params[3] = self.transX;
	params[4] = self.transY;
	params[5] = self.transZ;
	itkTransform->SetParameters(params);
	
	//if the levels variable has value > 0, then perform multiresolution registration
	if(levels)
	{	
		DebugLog(@"Performing a multiresolution registration");
		CommandType::Pointer commandObserver = CommandType::New();
		commandObserver->setDisplayObserver(self);
		doMattesMultiRegistration(fixedImage, movingImage, observer, [binsBox intValue], [sampleRateBox floatValue], [minStepBox floatValue],
								  [maxStepBox floatValue], 250, scales, levels, commandObserver, itkTransform);
	}
	else
		doMattesRegistration(fixedImage, movingImage, observer, [binsBox intValue], [sampleRateBox floatValue], [minStepBox floatValue],
							 [maxStepBox floatValue], 250, scales, itkTransform);
	
	DebugLog(@"Registration finished");

	[self performSelectorOnMainThread:@selector(registrationFinished) withObject:nil waitUntilDone:NO];
	
	[myAutoreleasePool release];
}

- (void) stopRegistration
{
	DebugLog(@"Registration stop requested...");
	observer->stopRegistration();
}

-(IBAction) calculateMetric: (id) sender;
{
	DebugLog(@"calculate metric called!");
	
	typedef ITKNS::MattesMutualInformationImageToImageMetric<ImageType, ImageType> MetricType;
	typedef ITKNS:: LinearInterpolateImageFunction<ImageType, double> InterpolatorType;
	
	MetricType::Pointer         metric        = MetricType::New();
	InterpolatorType::Pointer   interpolator  = InterpolatorType::New();
	
	//initialize the metric for Mattes MI
	metric->SetNumberOfHistogramBins([binsBox intValue]);
	ImageType::RegionType fixedImageRegion = fixedImage->GetBufferedRegion();
	
	ParametersType params(6);
	params[0] = self.rotX;
	params[1] = self.rotY;
	params[2] = self.rotZ;
	params[3] = self.transX;
	params[4] = self.transY;
	params[5] = self.transZ;
	
	metric->SetFixedImage(fixedImage);
	metric->SetMovingImage(movingImage);
	metric->SetInterpolator(interpolator);
	metric->SetTransform(itkTransform);
	metric->SetFixedImageRegion(fixedImageRegion);
	metric->UseAllPixelsOn();
	
	try 
	{ 
		metric->Initialize();
	} 
	catch( ITKNS::ExceptionObject & err ) 
	{ 
		NSLog(@"Error calculating the metric value!"); 
		std::cerr << err << std::endl; 
		
		NSRunAlertPanel(@"PetSpectFusion Error", @"Error calculating the metric value, see the console log for more details", nil, nil, nil);
		
		return;
	}
	
	[metricLabel setFloatValue:metric->GetValue(params)];
	
}

- (IBAction) updateParameters: (id) sender
{
	
	DebugLog(@"update Parameters called!");
	
	ParametersType params(6);
	params[0] = self.rotX;
	params[1] = self.rotY;
	params[2] = self.rotZ;
	params[3] = self.transX;
	params[4] = self.transY;
	params[5] = self.transZ;
	
	[self updateDisplay:params];
}

- (IBAction) enableMultiresolution: (id) sender
{
	if([multiResEnableButton state] == NSOnState)
		[multiResLevelsBox setEnabled:YES];
	else
		[multiResLevelsBox setEnabled:NO];
	
}

- (void) enableInputs:(BOOL) enable
{
	[translationBoxX setEnabled:enable];
	[translationBoxY setEnabled:enable];
	[translationBoxZ setEnabled:enable];
	[transStepperX setEnabled:enable];
	[transStepperY setEnabled:enable];
	[transStepperZ setEnabled:enable];
	
	[rotationBoxX setEnabled:enable];
	[rotationBoxY setEnabled:enable];
	[rotationBoxZ setEnabled:enable];
	[rotStepperX setEnabled:enable];
	[rotStepperY setEnabled:enable];
	[rotStepperZ setEnabled:enable];
	
	[binsBox setEnabled:enable];
	[sampleRateBox setEnabled:enable];
	[minStepBox setEnabled:enable];
	[maxStepBox setEnabled:enable];
	[multiResEnableButton setEnabled:enable];
	
	if([multiResEnableButton state] && enable)
		[multiResLevelsBox setEnabled:YES];
	else
		[multiResLevelsBox setEnabled:NO];
	
	
	[wTransBoxX setEnabled:enable];
	[wTransBoxY setEnabled:enable];
	[wTransBoxZ setEnabled:enable];
	[wRotBoxX setEnabled:enable];
	[wRotBoxY setEnabled:enable];
	[wRotBoxZ setEnabled:enable];
	
	[defaultsButton setEnabled:enable];
}

- (void) registrationFinished
{
	regIsRunning = NO;
	[self enableInputs:YES];
	[metricButton setEnabled:YES];
	[registrationButton setTitle:@"Start"];
}

- (void)windowWillClose:(NSNotification *)notification
{
	DebugLog(@"SettingsWindowController close");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self autorelease];
	
}

- (void) viewerWillClose:(NSNotification*)notification
{
	DebugLog(@"One of the necessary viewers have closed");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self autorelease];
}

- (void) levelChanged:(RegUpdate*) updateParams
{
	[levelLabel setIntValue:[updateParams level]];
}

- (void) registrationUpdate:(RegUpdate*) updateParams 
{
	ParametersType& curParams = [updateParams curParams];
	self.rotX = curParams[0];
	self.rotY = curParams[1];
	self.rotZ = curParams[2];
	self.transX = curParams[3];
	self.transY = curParams[4];
	self.transZ = curParams[5];
	
	[metricLabel setFloatValue:[updateParams metricVal]];
	[iterationsLabel setIntValue:[updateParams iteration]];
	[self updateDisplay:curParams];
}

- (void) updateDisplay:(ParametersType &) params
{
	DebugLog(@"Updating fixed viwer display"); 
	[transform applyTransformToViewer:params showWaitingMessage:NO];
	[fixedImageViewer needsDisplayUpdate];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	DebugLog(@"Tab view changed");
	if([[tabViewItem label] isEqualToString:@"Parameters"] )
	{
		NSRect r = [[self window] frame];
		r.size.height = 452; //Size in IB plus 16px title
		[[self window] setFrame:r display:YES animate:YES];
		r = [tabView frame];
		r.size.height = 386;
		[tabView setFrame:r];
	}
	else
	{
		NSRect r = [[self window] frame];
		r.size.height = 497; //Size in IB plus 16px title
		[[self window] setFrame:r display:YES animate:YES];
		
		r = [tabView frame];
		r.size.height = 430;
		[tabView setFrame:r];
	}
}

- (IBAction) applyDefaults:(id) sender
{
	DebugLog(@"Revert to default parameters requested");
	int selection = NSRunAlertPanel(@"Revert to Defaults", @"Do you really want to revert to the default paramters?", @"Yes", @"No", NULL);
	
	if(selection == 1)	//first reset the defaults dictionary, then reset the interface
	{
		[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:[self getDefaults]];
		NSLog(@"PSFSettingsWindowController: Reverting to factory defaults");
		[self enableMultiresolution:self];
		
	}
}

@end

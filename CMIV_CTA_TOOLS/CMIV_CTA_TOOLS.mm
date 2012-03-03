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

#import "CMIV_CTA_TOOLS.h"
#import "CMIVChopperController.h"
//#import "CMIVSpoonController.h"
#import "CMIVContrastController.h"
#import "CMIVVRcontroller.h"
#import "CMIVScissorsController.h"
#import "CMIVContrastPreview.h"
#import "CMIVSaveResult.h"
#import "CMIV_AutoSeeding.h"




@implementation CMIV_CTA_TOOLS
@synthesize ifVesselEnhanced;
- (void) initPlugin
{
    // This version requires OsiriX 4.1 or higher
    NSString *OsiriXVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleShortVersionString"];
    
    if( [[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"] isEqualToString: @"OsiriX"])
    {
        if( [OsiriXVersion compare: @"4.1" options: NSNumericSearch] < 0)
            NSRunCriticalAlertPanel( @"CMIV Plugin", @"This version of CMIV Plugin requires OsiriX 4.1 or higher.", @"OK", nil, nil);
    }
    else if( [[[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"] isEqualToString: @"OsiriX MD"])
    {
        if( [OsiriXVersion compare: @"1.4" options: NSNumericSearch] < 0)
            NSRunCriticalAlertPanel( @"CMIV Plugin", @"This version of CMIV Plugin requires OsiriX MD 1.4 or higher.", @"OK", nil, nil);
    }
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addedToDB:) name:@"OsirixAddToDBNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoSeedingIndicatorStep:) name:@"CMIVLeveIndicatorStep" object:nil];
	//autoseeding parameters
	minimumImagesForEachSeriesToAutoSeeding=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVAutoSeedingMinimumImagesForEachSeries"];
	if(minimumImagesForEachSeriesToAutoSeeding<50)
	{
		minimumImagesForEachSeriesToAutoSeeding=175;
		[[NSUserDefaults standardUserDefaults] setInteger:minimumImagesForEachSeriesToAutoSeeding forKey:@"CMIVAutoSeedingMinimumImagesForEachSeries"];
		//correct history problem disable autoseeding first
		ifAutoSeedingOnReceive=NO;
		[[NSUserDefaults standardUserDefaults] setBool:ifAutoSeedingOnReceive forKey:@"CMIVAutoSeedingOnReceive"];
	}
	ifAutoSeedingOnReceive=[[NSUserDefaults standardUserDefaults] boolForKey:@"CMIVAutoSeedingOnReceive"];

	seriesNeedToAutomaticProcess=[[NSMutableArray alloc] initWithCapacity:0];
	isAutoSeeding=NO;
	performRibCageRemoval=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVAutoRibRemoval"];
	if(performRibCageRemoval==0)//if key not found
	{
		performRibCageRemoval=1;
		[[NSUserDefaults standardUserDefaults] setInteger:performRibCageRemoval forKey:@"CMIVAutoRibRemoval"];
	}
	if(performRibCageRemoval==-1)
		performRibCageRemoval=0;
	performCenterlineTracking=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVAutoCenterlineTracking"];
	if(performCenterlineTracking==0)
	{
		performCenterlineTracking=-1;
		[[NSUserDefaults standardUserDefaults] setInteger:performCenterlineTracking forKey:@"CMIVAutoCenterlineTracking"];
	}
	if(performCenterlineTracking==-1)
		performCenterlineTracking=0;
	performVesselEnhance=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVAutoVesselEnhance"];
	if(performVesselEnhance==0)
	{
		performVesselEnhance=-1;
		[[NSUserDefaults standardUserDefaults] setInteger:performVesselEnhance forKey:@"CMIVAutoVesselEnhance"];
	}
	if(performVesselEnhance==-1)
		performVesselEnhance=0;
	autoCleanCachDays=[[NSUserDefaults standardUserDefaults] integerForKey:@"CMIVAutoCleanCachDays"];
	if(autoCleanCachDays==0)
	{
		autoCleanCachDays=10;
		[[NSUserDefaults standardUserDefaults] setInteger:autoCleanCachDays forKey:@"CMIVAutoCleanCachDays"];
	}
	NSLog( @"CMIV CTA Plugin initialized");
}
-(void) dealloc
{
	NSLog(@"CMIV dealloc plugin");
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[seriesNeedToAutomaticProcess release];
	[self cleanUpCachFolder];
	
	[super dealloc];
	
}
- (void) addedToDB:(NSNotification *)note
{
	if(!ifAutoSeedingOnReceive)
		return;
	
	NSArray* fileList = [[note userInfo] objectForKey:@"OsiriXAddToDBArray"] ;
	//[fileList retain];
	//	
	autoWatchOnReceivingStudyDesciptionFilterString=[[NSUserDefaults standardUserDefaults] stringForKey:@"CMIVAutoWatchStudyDescriptionKeyWord"];
	autoWatchOnReceivingSeriesDesciptionFilterString=[[NSUserDefaults standardUserDefaults] stringForKey:@"CMIVAutoWatchSeriesDescriptionKeyWord"];
	if(!autoWatchOnReceivingStudyDesciptionFilterString)
	{
		autoWatchOnReceivingStudyDesciptionFilterString=[NSString stringWithString:@"coronary"];
		[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingStudyDesciptionFilterString forKey:@"CMIVAutoWatchStudyDescriptionKeyWord"];
	}
	if(!autoWatchOnReceivingSeriesDesciptionFilterString)
	{
		autoWatchOnReceivingSeriesDesciptionFilterString=[NSString stringWithString:@"cor"];
		[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingSeriesDesciptionFilterString forKey:@"CMIVAutoWatchSeriesDescriptionKeyWord"];
	}
	
	autoWatchOnReceivingSeriesDesciptionFilterString=[autoWatchOnReceivingSeriesDesciptionFilterString lowercaseString];
	autoWatchOnReceivingStudyDesciptionFilterString= [autoWatchOnReceivingStudyDesciptionFilterString lowercaseString];
	NSManagedObject			*image, *series, *study;
	NSString* seriesDesciption, *studyDescription;
	unsigned i,j;
	for(i=0;i<[fileList count];i++)
	{
		image=[fileList objectAtIndex:i];
		if(![[image valueForKey:@"modality"] isEqualToString:@"CT"])
			continue;
		series=[image valueForKey:@"series"];
		study=[series valueForKey:@"study"];
		seriesDesciption=[series valueForKey:@"name"];
		studyDescription=[study valueForKey:@"studyName"];
		seriesDesciption=[seriesDesciption lowercaseString];
		studyDescription=[studyDescription lowercaseString];
		NSRange find1,find2;
		find1=[seriesDesciption rangeOfString:autoWatchOnReceivingSeriesDesciptionFilterString];
		find2=[studyDescription rangeOfString:autoWatchOnReceivingStudyDesciptionFilterString];
		if([autoWatchOnReceivingSeriesDesciptionFilterString length]==0)
			find1.location=1;
		if([autoWatchOnReceivingStudyDesciptionFilterString length]==0)
			find2.location=1;
		if(find1.location==NSNotFound||find2.location==NSNotFound)
			continue;
		BOOL alreadyInTheList=NO;
		for(j=0;j<[seriesNeedToAutomaticProcess count];j++)
		{
			if([[series valueForKey:@"seriesDICOMUID"] isEqualToString:[[seriesNeedToAutomaticProcess objectAtIndex:j] valueForKey:@"seriesDICOMUID"]])
			{
				alreadyInTheList=YES;
				break;
			}
		}
		if(!alreadyInTheList)
			[seriesNeedToAutomaticProcess addObject:series];
		
	}

	if(!isAutoSeeding&&[seriesNeedToAutomaticProcess count])
		[NSThread detachNewThreadSelector: @selector(startAutoProg:) toTarget: self withObject: nil];
	return;

		
}

-(void) startAutoProg:(id) sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	isAutoSeeding=YES;
	while([seriesNeedToAutomaticProcess count])
	{
		sleep(60);
		NSManagedObject	 *series=[seriesNeedToAutomaticProcess objectAtIndex:0];
		if(series&&![series isFault])
		{
			NSArray	*fileList = [[series valueForKey:@"images"] allObjects] ;
			if(fileList&&[fileList count]>minimumImagesForEachSeriesToAutoSeeding)
			{
				NSMutableArray* pixList =[[NSMutableArray alloc] initWithCapacity:0];
				CMIV_AutoSeeding* autoSeedingController=[[CMIV_AutoSeeding alloc] init] ;
				@try
				{
					NSData*volumeData=[autoSeedingController loadImageFromSeries:series To:pixList];
					if(volumeData)
					{
						float* imgbuff=(float*)[volumeData bytes];
			//			float* testbuff=[viewerController volumePtr];
			//			memcpy(testbuff, imgbuff, [volumeData length]);
						
						[autoSeedingController runAutoSeeding:nil:self:pixList:imgbuff:1:1:1];
						[volumeData release];
					}
				}
				@catch( NSException *ne)
				{
					NSLog(@"CMIV CTA Plugin: failed to auto proceed series- %@", [series valueForKey:@"name"]);
				}
				
				[pixList release];
				
				[seriesNeedToAutomaticProcess removeObject:series];
				[autoSeedingController release];
				
			}
		}
		else
		{
			[seriesNeedToAutomaticProcess removeObjectAtIndex:0];
			NSLog(@"CMIV CTA Plugin: failed to auto proceed series- %@", [series valueForKey:@"name"]);
		}
	}
	isAutoSeeding=NO;
	[pool release];
}


- (long) filterImage:(NSString*) menuName
{
	if(currentController)
		[currentController release];
	currentController=nil;
	int err=0;
	if( [menuName isEqualToString:NSLocalizedString(@"Wizard For Coronary CTA", nil)] == YES)
		err = [self checkIntermediatDataForWizardMode:0];
	else if( [menuName isEqualToString:NSLocalizedString(@"Auto-Seeding", nil)] == YES)
		[self showAutoSeedingDlg];
	else if( [menuName isEqualToString:NSLocalizedString(@"VOI Cutter", nil)] == YES)
		err = [self startChopper:viewerController];
	//else if ( [menuName isEqualToString:NSLocalizedString(@"MathMorph Tool", nil)] == YES)
	//	err = [self startSpoon:viewerController];
	else if ( [menuName isEqualToString:NSLocalizedString(@"2D Views", nil)] == YES)
		err = [self startScissors:viewerController];	
	else if ( [menuName isEqualToString:NSLocalizedString(@"Interactive Segmentation", nil)] == YES)
		err = [self startContrast:viewerController];	
	else if ( [menuName isEqualToString:NSLocalizedString(@"Tagged Volume Rendering", nil)] == YES)
		err = [self startVR:viewerController];
	else if ( [menuName isEqualToString:NSLocalizedString(@"Save Results", nil)] == YES)
		err = [self saveResult:viewerController];
	else if ( [menuName isEqualToString:NSLocalizedString(@"Polygon Measurement", nil)] == YES)
		err = [self startPolygonMeasure:viewerController];
	else if ( [menuName isEqualToString:NSLocalizedString(@"ShowVesselnessMap", nil)] == YES)
	{
		//float* volumeData=[viewerController volumePtr:0];
		//err = [self loadVesselnessMap:volumeData];
	}
	else if ( [menuName isEqualToString:NSLocalizedString(@"Smooth Filter 5", nil)] == YES)
	{
		CMIV_AutoSeeding* autoSeedingController=[[CMIV_AutoSeeding alloc] init] ;
		err=[autoSeedingController smoothingImages3D:viewerController:self:5];
		[autoSeedingController release];
		
	}
	else if ( [menuName isEqualToString:NSLocalizedString(@"Smooth Filter 10", nil)] == YES)
	{
		CMIV_AutoSeeding* autoSeedingController=[[CMIV_AutoSeeding alloc] init] ;
		err=[autoSeedingController smoothingImages3D:viewerController:self:10];
		[autoSeedingController release];
		
	}
	else
		[self showAboutDlg:nil];
	
	return err;
}

- (int)  startAutomaticSeeding:(ViewerController *) vc
{
	int err=0;
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	NSString* seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	NSString* path=[self osirixDocumentPath];
	NSString* file;
	file= [path stringByAppendingFormat:@"/CMIVCTACache/%@.sav",seriesUid];
	NSMutableDictionary* savedData=[[NSMutableDictionary alloc] initWithContentsOfFile:file];
	if(savedData)
	{
		[savedData release];
		int nrespond=NSRunAlertPanel(NSLocalizedString  (@"Found Previous Results", nil), NSLocalizedString(@"Auto seeding processing will delete all seeds and centerlines info created before.  Do you want to continue?", nil), NSLocalizedString(@"Continue", nil), NSLocalizedString(@"Cancel", nil), nil);
		
		
		if(nrespond==1)
		{
			
			
			[[NSFileManager defaultManager] removeFileAtPath:file handler:nil];
			
			
		}
		else if(nrespond==0)
		{
			
			return 0;
		}
		
	}
	CMIV_AutoSeeding* autoSeedingController=[[CMIV_AutoSeeding alloc] init] ;
	err=[autoSeedingController runAutoSeeding:vc:self:[vc pixList]:[vc volumePtr]:performRibCageRemoval:performCenterlineTracking:performVesselEnhance];
	[autoSeedingController release];
	if(!err)
	{
		if(performCenterlineTracking!=1)
			[self checkIntermediatDataForWizardMode:1]; 
		else
			[self checkIntermediatDataForFreeMode:1]; 
	}

	return err;
	
}

- (int)  startChopper:(ViewerController *) vc
{
	int err=0;
	CMIVChopperController* chopperController=[[CMIVChopperController alloc] showChopperPanel:vc:self];
	if(!chopperController)
		err=1;
	return err;
}

/*
- (int)  startSpoon:(ViewerController *) vc
{
	int err=0;
	CMIVSpoonController* spoonController=[[CMIVSpoonController alloc] init];
	err=[spoonController showSpoonPanel:vc:self];
	if(!err)
		currentController=spoonController;
	return err;
}
*/

- (int)  startScissors:(ViewerController *) vc
{
	return [self checkIntermediatDataForFreeMode:-1];
	
}


- (int)  startContrast:(ViewerController *) vc
{
	int err=0;
	CMIVContrastController* contrastController = [[CMIVContrastController alloc] init];
	err=[contrastController showContrastPanel:vc:self];
	if(!err)
		currentController=contrastController;
	return err;
	
}


- (int)  startVR:(ViewerController *) vc
{
	int err=0;
	CMIVVRcontroller* vrController = [[CMIVVRcontroller alloc] showVRPanel:vc:self];
	if(!vrController)
		err=1;
	return err;
	
}
- (int)  saveResult:(ViewerController *) vc
{
	int err=0;
	
	CMIVSaveResult *saver=[[CMIVSaveResult alloc] showSaveResultPanel:vc:self];

	
//	CMIVSaveResult *saver=[[CMIVSaveResult alloc] init];
//	err = [saver showSaveResultPanel:vc:self];

	if(!err)
		currentController=saver;
	return err;
}

- (void) gotoStepNo:(int)stage
{
	if(currentController)
		[currentController release];
	currentController=nil;

	if(stage==1)// VOI cutter
	{

		NSLog( @"step 1");

		[[CMIVChopperController alloc] showPanelAsWizard:viewerController:self];

	}
	else if(stage==2)// 2D viewer
	{

		NSLog( @"step 2");

		[[CMIVScissorsController alloc]  showPanelAsWizard:viewerController:self]; 
	
	}
	else if(stage==3) //result preview
	{
		NSLog( @"finish step 3");
		[[CMIVContrastPreview alloc] showPanelAsWizard:viewerController:self]; 

	}
	else if(stage==4) //2D viewer CPR only
	{
		NSLog( @"finish step 4");
		[[CMIVScissorsController alloc] showPanelAsCPROnly:viewerController:self]; 

	}
	
}
- (NSMutableDictionary*) dataOfWizard
{
	if(!dataOfWizard)
		dataOfWizard=[[NSMutableDictionary alloc] initWithCapacity: 0];
	return dataOfWizard;
}
- (void) setDataofWizard:(NSMutableDictionary*) dic
{
	[dataOfWizard release];
	dataOfWizard=dic;
	[dic retain];
}
- (void) cleanDataOfWizard
{
	
	if(dataOfWizard)
	{

		NSArray* temparray=[dataOfWizard objectForKey:@"VCList"];
		NSArray* tempnamearray=[dataOfWizard objectForKey:@"VCTitleList"];
		if(temparray&&tempnamearray)
		{
			unsigned int i;
			for(i=0;i<[temparray count];i++)
				[[[temparray objectAtIndex: i] window] setTitle:[tempnamearray objectAtIndex: i]];

		}
		[dataOfWizard removeAllObjects];//list in list shoule be clean separatedly
	}
}
- (void) cleanSharedData
{
	if(dataOfWizard)
	{
		NSString* stepstr=[dataOfWizard objectForKey:@"Step"];
		if([stepstr isEqualToString:@"finish"])
			[self cleanUpCachFolder];
		
		[self cleanDataOfWizard];
		[dataOfWizard release];
		dataOfWizard=nil;
	}
	if(currentController)
		[currentController release];
	currentController=nil;
}
- (void)notifyExportFinished
{
	if(!dataOfWizard)
		return;
	NSMutableArray* temparray,*tempnamearray;
	temparray=[dataOfWizard objectForKey:@"VCList"];
	tempnamearray=[dataOfWizard objectForKey:@"VCTitleList"];
	if(temparray&&tempnamearray)
	{
		while([temparray count]&&[tempnamearray count])
		{
			ViewerController* vc=[temparray objectAtIndex: 0];
			NSString* sname=[tempnamearray objectAtIndex: 0];
		
			if(autosaver==nil)
				autosaver=[[CMIVSaveResult alloc] init];
			if(autoSaveSeriesNumber==0)
				autoSaveSeriesNumber=6700 + [[NSCalendarDate date] minuteOfHour] + [[NSCalendarDate date] secondOfMinute];
			else
				autoSaveSeriesNumber++;
			[autosaver exportSeries:vc:sname:autoSaveSeriesNumber:self];
			[temparray removeObject:vc];
			[tempnamearray removeObject:sname];
		}

		if(autosaver)
			[autosaver release];
		autosaver=nil;
		autoSaveSeriesNumber=0;

			
	}
	
}
- (void) showAutoSeedingDlg
{
	if(!window)[NSBundle loadNibNamed:@"AboutDlg" owner:self];
	[NSApp beginSheet: window modalForWindow:[viewerController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	[self checkMaxValueForSeedingIndicator];
}
- (IBAction)clickAutoSeeding:(id)sender
{
	[self startAutomaticSeeding:viewerController];
	[self closeAutoSeedingDlg:nil];
}

- (void) autoSeedingIndicatorStep:(NSNotification *)note
{
	if(autoSeedingIndicator)
	{
		int step=[autoSeedingIndicator intValue];
		[autoSeedingIndicator setIntValue:step+1];
		[autoSeedingIndicator displayIfNeeded];
	}
}
- (IBAction)closeAutoSeedingDlg:(id)sender
{
	
	[window close];
    [NSApp endSheet:window returnCode:[sender tag]];
}
- (IBAction) showAdvancedSettingDlg:(id)sender
{
	[NSApp beginSheet: advanceSettingWindow modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
	if(ifAutoSeedingOnReceive)
		[autoWatchOnReceivingButton setState:NSOnState];
	else
		[autoWatchOnReceivingButton setState:NSOffState];
	if(performRibCageRemoval==1)
		[autoRibCageRemovalButton setState:NSOnState];
	else
		[autoRibCageRemovalButton setState:NSOffState];
	if(performCenterlineTracking==1)
		[autoCenterlineButton setState:NSOnState];
	else
		[autoCenterlineButton setState:NSOffState];
	if(performVesselEnhance==1)
		[autoVesselEnhanceButton setState:NSOnState];
	else
		[autoVesselEnhanceButton setState:NSOffState];
	[autoCleanCachDaysText setIntValue:autoCleanCachDays];
	autoWatchOnReceivingStudyDesciptionFilterString=[[NSUserDefaults standardUserDefaults] stringForKey:@"CMIVAutoWatchStudyDescriptionKeyWord"];
	autoWatchOnReceivingSeriesDesciptionFilterString=[[NSUserDefaults standardUserDefaults] stringForKey:@"CMIVAutoWatchSeriesDescriptionKeyWord"];
	if(!autoWatchOnReceivingStudyDesciptionFilterString)
	{
		autoWatchOnReceivingStudyDesciptionFilterString=[NSString stringWithString:@"coronary"];
		[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingStudyDesciptionFilterString forKey:@"CMIVAutoWatchStudyDescriptionKeyWord"];
	}
	if(!autoWatchOnReceivingSeriesDesciptionFilterString)
	{
		autoWatchOnReceivingSeriesDesciptionFilterString=[NSString stringWithString:@"cor"];
		[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingSeriesDesciptionFilterString forKey:@"CMIVAutoWatchSeriesDescriptionKeyWord"];
	}
	
	[autoWatchOnReceivingKeyWordTextField1 setStringValue:autoWatchOnReceivingStudyDesciptionFilterString];
	[autoWatchOnReceivingKeyWordTextField2 setStringValue:autoWatchOnReceivingSeriesDesciptionFilterString];

}

- (IBAction)closeAdvancedSettingDlg:(id)sender
{
	autoWatchOnReceivingStudyDesciptionFilterString=[autoWatchOnReceivingKeyWordTextField1 stringValue];
	autoWatchOnReceivingSeriesDesciptionFilterString=[autoWatchOnReceivingKeyWordTextField2 stringValue];
	if([autoCenterlineButton state]==NSOnState)
		performCenterlineTracking=1;
	else
		performCenterlineTracking=-1;
	[[NSUserDefaults standardUserDefaults] setInteger:performCenterlineTracking forKey:@"CMIVAutoCenterlineTracking"];

	if([autoRibCageRemovalButton state]==NSOnState)
		performRibCageRemoval=1;
	else
		performRibCageRemoval=-1;
	[[NSUserDefaults standardUserDefaults] setInteger:performRibCageRemoval forKey:@"CMIVAutoRibRemoval"];
	

	if([autoWatchOnReceivingButton state]==NSOnState)
		ifAutoSeedingOnReceive=YES;
	else
		ifAutoSeedingOnReceive=NO;
	[[NSUserDefaults standardUserDefaults] setBool:ifAutoSeedingOnReceive forKey:@"CMIVAutoSeedingOnReceive"];
	
	if([autoVesselEnhanceButton state]==NSOnState)
		performVesselEnhance=1;
	else
		performVesselEnhance=-1;
	[[NSUserDefaults standardUserDefaults] setInteger:performVesselEnhance forKey:@"CMIVAutoVesselEnhance"];
	
	if(performCenterlineTracking==-1)
		performCenterlineTracking=0;
	if(performRibCageRemoval==-1)
		performRibCageRemoval=0;

	if(performVesselEnhance==-1)
		performVesselEnhance=0;
	autoCleanCachDays=[autoCleanCachDaysText intValue];
	if(autoCleanCachDays<=0)
	{
		autoCleanCachDays=10;
	}
	[[NSUserDefaults standardUserDefaults] setInteger:autoCleanCachDays forKey:@"CMIVAutoCleanCachDays"];

	autoWatchOnReceivingStudyDesciptionFilterString=[autoWatchOnReceivingKeyWordTextField1 stringValue];
	autoWatchOnReceivingSeriesDesciptionFilterString=[autoWatchOnReceivingKeyWordTextField2 stringValue];
	[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingStudyDesciptionFilterString forKey:@"CMIVAutoWatchStudyDescriptionKeyWord"];
	[[NSUserDefaults standardUserDefaults] setObject:autoWatchOnReceivingSeriesDesciptionFilterString forKey:@"CMIVAutoWatchSeriesDescriptionKeyWord"];
	
	[self cleanUpCachFolder];

	[advanceSettingWindow close];
    [NSApp endSheet:advanceSettingWindow returnCode:[sender tag]];
	[self checkMaxValueForSeedingIndicator];
}
-(void)checkMaxValueForSeedingIndicator
{
	int maxindicatorvalue=4;
	if(performRibCageRemoval==1)
		maxindicatorvalue+=2;
	if(performVesselEnhance==1)
		maxindicatorvalue+=4;
	if(performCenterlineTracking==1)
		maxindicatorvalue+=2;
	if(autoSeedingIndicator)
		[autoSeedingIndicator setMaxValue:maxindicatorvalue];
	[autoSeedingIndicator setIntValue:0];
	[autoSeedingIndicator displayIfNeeded];
}

- (IBAction) showAboutDlg:(id)sender
{
	[NSApp beginSheet: aboutWindow modalForWindow:[NSApp keyWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)closeAboutDlg:(id)sender
{

	[aboutWindow close];
    [NSApp endSheet:aboutWindow returnCode:[sender tag]];
}
- (IBAction)openCMIVWebSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.cmiv.liu.se/"]];
}
- (IBAction)mailToAuthors:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:chunliang.wang@liu.se,orjan.smedby@liu.se"]]; 
}

- (int)  startPolygonMeasure:(ViewerController *) vc
{
	int err=0;
	CMIVScissorsController * scissorsController = [[CMIVScissorsController alloc] init];
	err=[scissorsController showPolygonMeasurementPanel:vc:self];
	if(!err)
		currentController=scissorsController;
	return err;
}
-(NSString*)osirixDocumentPath
{
	char	s[1024];
	
	FSRef	ref;
	
	
	if( [[NSUserDefaults standardUserDefaults] integerForKey: @"DATABASELOCATION"]==1)
	{
		NSString	*path;
		BOOL		isDir = YES;
		NSString* url=[[NSUserDefaults standardUserDefaults] stringForKey: @"DATABASELOCATIONURL"];
		path = [url stringByAppendingPathComponent:@"/OsiriX Data"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
			return path;	
#ifdef VERBOSEMODE
		NSLog( @"incoming folder is url type");
#endif
	}
	
	
	if( FSFindFolder (kOnAppropriateDisk, kDocumentsFolderType, kCreateFolder, &ref) == noErr )
	{
		NSString	*path;
		BOOL		isDir = YES;
		
		FSRefMakePath(&ref, (UInt8 *)s, sizeof(s));
		
		path = [[NSString stringWithUTF8String:s] stringByAppendingPathComponent:@"/OsiriX Data"];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) [[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
#ifdef VERBOSEMODE
		NSLog( @"incoming folder is default type");
#endif
		return path;// not sure if s is in UTF8 encoding:  What's opposite of -[NSString fileSystemRepresentation]?
	}
	
	else
		return nil;
	
}
- (int)  prepareDataForAutoSegmentation:(NSString*)seriesUid
{
	if(dataOfWizard==nil)
		return 1;
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	
	NSString* path=[self osirixDocumentPath];
	NSString* file1=[path stringByAppendingFormat:@"/CTACrashChach/%@CMIV.tmp",seriesUid];
	NSString* file2=[path stringByAppendingFormat:@"/CTACrashChach/%@maskmap.tmp",seriesUid];
	NSString* file3=[path stringByAppendingFormat:@"/CTACrashChach/%@vesselness.tmp",seriesUid];
	NSString* file4=[path stringByAppendingFormat:@"/CTACrashChach/%@directionmap.tmp",seriesUid];
	int err=0;
	NSString* step=[dataOfWizard objectForKey:@"Step"];
	if([step isEqualToString:@"Step1"])
	{
		NSData* tempdata=[dataOfWizard objectForKey:@"VesselnessMap"];
		NSNumber* size=[dataOfWizard objectForKey:@"VesselnessMapSize"];
		char* tempbuffer=(char*)[tempdata bytes];
		FILE* tempFile;
		tempFile= fopen([file3 cString],"wb");
		fwrite(tempbuffer,sizeof(char),[size intValue],tempFile);
		fclose(tempFile);
		[dataOfWizard removeObjectForKey:@"VesselnessMap"];
		[dataOfWizard setObject:file3 forKey:@"VesselnessMapPath"];
		err=[dataOfWizard writeToFile:file1 atomically:YES];
		
		
	}
	else if([step isEqualToString:@"Step2"])
	{
		NSData* tempdata=[dataOfWizard objectForKey:@"SeedMap"];
		NSNumber* size=[dataOfWizard objectForKey:@"SeedMapSize"];
		char* tempbuffer=(char*)[tempdata bytes];
		FILE* tempFile;
		tempFile= fopen([file2 cString],"wb");
		fwrite(tempbuffer,sizeof(char),[size intValue],tempFile);
		fclose(tempFile);
		[dataOfWizard removeObjectForKey:@"SeedMap"];
		if([dataOfWizard objectForKey:@"VesselnessMap"])
			[dataOfWizard removeObjectForKey:@"VesselnessMap"];
		[dataOfWizard setObject:file2 forKey:@"SeedMapPath"];
		err=[dataOfWizard writeToFile:file1 atomically:YES];
	}
	else if([step isEqualToString:@"Step3"])
	{
		NSData* tempdata=[dataOfWizard objectForKey:@"DirectionMap"];
		NSNumber* size=[dataOfWizard objectForKey:@"DirectionMapSize"];
		char* tempbuffer=(char*)[tempdata bytes];
		FILE* tempFile;
		tempFile= fopen([file4 cString],"wb");
		fwrite(tempbuffer,sizeof(char),[size intValue],tempFile);
		fclose(tempFile);
		[dataOfWizard removeObjectForKey:@"DirectionMap"];
		if([dataOfWizard objectForKey:@"VesselnessMap"])
			[dataOfWizard removeObjectForKey:@"VesselnessMap"];
		if([dataOfWizard objectForKey:@"SeedMap"])
			[dataOfWizard removeObjectForKey:@"SeedMap"];
		[dataOfWizard setObject:file4 forKey:@"DirectionMapPath"];
		err=[dataOfWizard writeToFile:file1 atomically:YES];
	}
	else if([step isEqualToString:@"MaskMap"])
	{
		NSData* tempdata=[dataOfWizard objectForKey:@"MaskMap"];
		NSNumber* size=[dataOfWizard objectForKey:@"MaskMapSize"];
		char* tempbuffer=(char*)[tempdata bytes];
		FILE* tempFile;
		tempFile= fopen([file2 cString],"wb");
		fwrite(tempbuffer,sizeof(char),[size intValue],tempFile);
		fclose(tempFile);
		[dataOfWizard removeObjectForKey:@"MaskMap"];
		[dataOfWizard setObject:file2 forKey:@"MaskMapPath"];
		err=[dataOfWizard writeToFile:file1 atomically:YES];
	}

	

	return err;

}

- (void)saveCurrentStep
{
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	NSString* seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	[self saveIntermediateData:seriesUid];
}
- (int)  saveIntermediateData:(NSString*)seriesUid
{
	int err=0;
	NSString* path=[self osirixDocumentPath];
	path=[path stringByAppendingString:@"/CMIVCTACache"];
	BOOL			isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)
		[[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil];
	NSString* file;
	file= [path stringByAppendingFormat:@"/%@.sav",seriesUid];
	NSMutableDictionary* savedData=[[NSMutableDictionary alloc] initWithContentsOfFile:file];
	if (!savedData) {
		savedData=[[NSMutableDictionary alloc] initWithCapacity: 0];
	}
	//check the validation of each parameter
	
	//heart region
	if([dataOfWizard objectForKey:@"HeartRegionArrays"])
		[savedData setObject:[dataOfWizard objectForKey:@"HeartRegionArrays"] forKey:@"HeartRegionArrays"];
	//Heart volume dimensions
	if([dataOfWizard objectForKey:@"SubvolumesDimension"])
		[savedData setObject:[dataOfWizard objectForKey:@"SubvolumesDimension"] forKey:@"SubvolumesDimension"];
	//vesselness map data
	if([dataOfWizard objectForKey:@"VesselnessMap"])
	{
		[savedData setObject:[dataOfWizard objectForKey:@"VesselnessMap"] forKey:@"VesselnessMap"];
		[savedData setObject:[dataOfWizard objectForKey:@"VesselnessMapTargetSpacing"] forKey:@"VesselnessMapTargetSpacing"];
		[savedData setObject:[dataOfWizard objectForKey:@"VesselnessMapOriginAndDimension"] forKey:@"VesselnessMapOriginAndDimension"];
	}
	//compress seeds data
	NSData* seedsData=[dataOfWizard objectForKey:@"SeedMap"];
	NSArray* contrastlist=[dataOfWizard objectForKey:@"ContrastList"];
	if(seedsData&&contrastlist)
	{
		NSMutableArray* seedsDataCompressedArray=[NSMutableArray arrayWithCapacity:0];
		[self compressSeedsData:seedsData:seedsDataCompressedArray];
		[savedData setObject:[NSNumber numberWithInt:[seedsData length]] forKey:@"SeedsDataSize"];
		[dataOfWizard removeObjectForKey:@"SeedMap"];
		[savedData setObject:seedsDataCompressedArray forKey:@"SeedsDataCompressedArray"];
		

		NSMutableArray* savedcontrastlist=[NSMutableArray arrayWithCapacity:0];
		for(unsigned ii=0;ii<[contrastlist count];ii++)
		{
			NSMutableDictionary* acontrast=[NSMutableDictionary dictionary];
			[acontrast addEntriesFromDictionary:[contrastlist objectAtIndex:ii]];
			NSColor* c=[acontrast objectForKey:@"Color"];
			CGFloat r, g, b;
			
			[c getRed:&r green:&g blue:&b alpha:0L];
			[acontrast setObject:[NSNumber numberWithFloat:(float)r] forKey:@"Red"];
			[acontrast setObject:[NSNumber numberWithFloat:(float)g] forKey:@"Green"];
			[acontrast setObject:[NSNumber numberWithFloat:(float)b] forKey:@"Blue"];
			[acontrast removeObjectForKey:@"Color"];
			[savedcontrastlist addObject:acontrast];
		}
		[savedData setObject:savedcontrastlist forKey:@"ContrastList"];
		[savedData setObject:[dataOfWizard objectForKey:@"SeedNameArray"] forKey:@"SeedNameArray"];
		[savedData setObject:[dataOfWizard objectForKey:@"RootSeedArray"] forKey:@"RootSeedArray"];

	}
	else if (seedsData&&!contrastlist) {
		contrastlist=[savedData objectForKey:@"ContrastList"];
		if(contrastlist)
		{
			NSNumber* seedDateLength = [savedData objectForKey:@"SeedsDataSize"];
			if([seedDateLength unsignedIntValue]==[seedsData length])
			{
				NSMutableArray* seedsDataCompressedArray=[NSMutableArray arrayWithCapacity:0];
				[self compressSeedsData:seedsData:seedsDataCompressedArray];
				[dataOfWizard removeObjectForKey:@"SeedMap"];
				[savedData setObject:seedsDataCompressedArray forKey:@"SeedsDataCompressedArray"];
				[savedData setObject:[dataOfWizard objectForKey:@"SeedNameArray"] forKey:@"SeedNameArray"];
				[savedData setObject:[dataOfWizard objectForKey:@"RootSeedArray"] forKey:@"RootSeedArray"];
			}
		}
		
		
	}

	//save centerline data
	if([dataOfWizard objectForKey:@"CenterlineArrays"])
	{
		[savedData setObject:[dataOfWizard objectForKey:@"CenterlineArrays"] forKey:@"CenterlineArrays"];	
		[savedData setObject:[dataOfWizard objectForKey:@"CenterlinesNames"] forKey:@"CenterlinesNames"];
	}
	[savedData setObject:[NSDate date] forKey:@"LastSavedDate"];
	if([savedData writeToFile:file atomically:YES])
	{
		[savedData release];
		err = 0;
	}
	else{
		[savedData release];
		err = 1;
	}
	return err;
	
	
}
- (int)  checkIntermediatDataForFreeMode:(int)userRespond
{
	int err=0;
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	NSString* seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	NSString* path=[self osirixDocumentPath];
	NSString* file;
	file= [path stringByAppendingFormat:@"/CMIVCTACache/%@.sav",seriesUid];
	NSMutableDictionary* savedData=[[NSMutableDictionary alloc] initWithContentsOfFile:file];

	[self cleanDataOfWizard];
	dataOfWizard=[self dataOfWizard];
	int nrespond;
	
	NSMutableArray		*pixList = [viewerController pixList];
	DCMPix* curPix = [pixList objectAtIndex: 0];
	int imageWidth = [curPix pwidth];
	int imageHeight = [curPix pheight];
	int imageAmount = [pixList count];

	
	if(savedData&&[savedData objectForKey:@"SeedsDataCompressedArray"])
	{	
		int seedsDataSize=[[savedData objectForKey:@"SeedsDataSize"] intValue];
		if(imageWidth*imageHeight*imageAmount*(signed)sizeof(unsigned short)==seedsDataSize)
		{
			if(userRespond==1)
				nrespond=-1;
			else if(userRespond==0)
				nrespond=0;
			else
				nrespond=NSRunAlertPanel(NSLocalizedString  (@"Load Previous Results", nil), NSLocalizedString(@"Found seeds from Previous Processing. Do you want to load them", nil), NSLocalizedString(@"Load", nil), NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Do not load", nil));
			
				
				if(nrespond==1)
				{
			

					err = [self loadIntermediateDataForSeedPlanting:savedData];
		
					
				}
				else if(nrespond==0)
				{
					return 0;
				}
		}
	}
	
	if([savedData objectForKey:@"CenterlineArrays"])
	{
		err = [self loadIntermediateDataForCPRViewing:savedData];
	}
	
	CMIVScissorsController * scissorsController = [[CMIVScissorsController alloc] showScissorsPanel:viewerController:self];
	if(!scissorsController)
		err=1;
	return err;
}
- (int)  checkIntermediatDataForWizardMode:(int)userRespond
{
	
	int err=0;
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	NSString* seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	NSString* path=[self osirixDocumentPath];
	NSString* file;
	file= [path stringByAppendingFormat:@"/CMIVCTACache/%@.sav",seriesUid];
	NSMutableDictionary* savedData=[[NSMutableDictionary alloc] initWithContentsOfFile:file];
	if (!savedData) {
		[self gotoStepNo:1 ];
		return err;
	}
	
	int nrespond;
	
	if([savedData objectForKey:@"SubvolumesDimension"]||[savedData objectForKey:@"SeedsDataCompressedArray"])
	
	{	
		if(userRespond)
			nrespond=userRespond;
		else
			nrespond=NSRunAlertPanel(NSLocalizedString  (@"Load Previous Results", nil), NSLocalizedString(@"Found results from Previous Processing. Do you want to load them", nil), NSLocalizedString(@"Load", nil), NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Discard them and Start Over", nil));
		
		if(nrespond==1)
		{
			[self cleanDataOfWizard];
			dataOfWizard=[self dataOfWizard];
			int step1=0,step2=0;
			err = [self loadIntermediateDataForVolumeCropping:savedData];
			if(!err)
				step1=1;
			err = [self loadIntermediateDataForSeedPlanting:savedData];
			if(!err)
				step2=1;
			if(step2)
			{
				[[CMIVScissorsController alloc]  showPanelAsAutomaticWizard:viewerController:self];
			}
			else if(step1)
				[self gotoStepNo:2];
			else
				[self gotoStepNo:1];
	
			
			
		}
		else if(nrespond==0)
		{
			return 0;
		}
		else
		{
			[[NSFileManager defaultManager] removeFileAtPath:file handler:nil];
			[self gotoStepNo:1 ];
			return 0;
		}
	}
	else
	{
		[self gotoStepNo:1];
	}
	return 0;
}
- (int)  loadIntermediateDataForVolumeCropping:(NSMutableDictionary*)savedData
{
	//if([savedData objectForKey:@"HeartRegionArrays"])
	//	[savedData setObject:[dataOfWizard objectForKey:@"HeartRegionArrays"] forKey:@"HeartRegionArrays"];
	//Heart volume dimensions

	int err=0;
	NSMutableArray		*pixList = [viewerController pixList];
	DCMPix* curPix = [pixList objectAtIndex: 0];
	int imageWidth = [curPix pwidth];
	int imageHeight = [curPix pheight];
	int imageAmount = [pixList count];

	NSArray* dimarray=[savedData objectForKey:@"SubvolumesDimension"];
	if(dimarray&&[dimarray count]==15)
	{
		int olddimension[3];
		int oldorigin[3],neworigin[3];
		
		oldorigin[0]=(int)([[dimarray objectAtIndex:6] floatValue]*100.0);
		oldorigin[1]=(int)([[dimarray objectAtIndex:7] floatValue]*100.0);
		oldorigin[2]=(int)([[dimarray objectAtIndex:8] floatValue]*100.0);
		olddimension[0]=[[dimarray objectAtIndex:9] intValue];
		olddimension[1]=[[dimarray objectAtIndex:10] intValue];
		olddimension[2]=[[dimarray objectAtIndex:11] intValue];
		neworigin[0]=(int)([[dimarray objectAtIndex:12] floatValue]*100.0);
		neworigin[1]=(int)([[dimarray objectAtIndex:13] floatValue]*100.0);
		neworigin[2]=(int)([[dimarray objectAtIndex:14] floatValue]*100.0);
		if(olddimension[0]==imageWidth && olddimension[1]==imageHeight && olddimension[2]==imageAmount && oldorigin[0]==(int)([curPix originX]*100.0) && oldorigin[1]==(int)([curPix originY]*100.0) && oldorigin[2]==(int)([curPix originZ]*100.0))
		{
			CMIVChopperController* chopperController=[[CMIVChopperController alloc] init];
			err=[chopperController reduceTheVolume:dimarray:viewerController];
			[chopperController release];
		}
		else if(neworigin[0]==(int)([curPix originX]*100.0) && neworigin[1]==(int)([curPix originY]*100.0) && neworigin[2]==(int)([curPix originZ]*100.0))
		{
			NSLog(@"volume is already chopped");//do nothing
		}
		else
		{
			NSRunAlertPanel(NSLocalizedString  (@"Loading failed", nil), NSLocalizedString(@"The dimensions of current images do not match with previous results. Please reload the data", nil), NSLocalizedString(@"OK", nil), nil, nil);
			err=1;
		}
	}
	else 
		err=1;

	return err;
	
		
}
- (int)  loadIntermediateDataForSeedPlanting:(NSMutableDictionary*)savedData
{
	int err=0;
	//caclulate the imageSize
	NSMutableArray		*pixList = [viewerController pixList];
	DCMPix* curPix = [pixList objectAtIndex: 0];
	int imageWidth = [curPix pwidth];
	int imageHeight = [curPix pheight];
	int imageAmount = [pixList count];
	if([savedData objectForKey:@"SeedsDataCompressedArray"])
	{
		int seedsDataSize=[[savedData objectForKey:@"SeedsDataSize"] intValue];
		if(imageWidth*imageHeight*imageAmount*(signed)sizeof(unsigned short)==seedsDataSize)
		{
			char* seedsdatabuffer=(char*)malloc(seedsDataSize);
			NSData* seedsData=[NSData dataWithBytesNoCopy:seedsdatabuffer length: seedsDataSize freeWhenDone:NO];
			err=[self uncompressSeedsData:seedsData:[savedData objectForKey:@"SeedsDataCompressedArray"]];
			if(!err)
			{
				[dataOfWizard setObject:seedsData forKey:@"SeedMap"];

				NSMutableArray* contrastlist=[NSMutableArray arrayWithCapacity:0];
				NSMutableArray* savedcontrastlist=[savedData objectForKey:@"ContrastList"];
				for(unsigned ii=0;ii<[savedcontrastlist count];ii++)
				{
					NSMutableDictionary* acontrast=[NSMutableDictionary dictionary];
					[acontrast addEntriesFromDictionary:[savedcontrastlist objectAtIndex:ii]];
					
					CGFloat r, g, b;
					
					
					r=[[acontrast objectForKey:@"Red"] floatValue];
					g=[[acontrast objectForKey:@"Green"] floatValue];
					b=[[acontrast objectForKey:@"Blue"] floatValue];
					[acontrast removeObjectForKey:@"Red"];
					[acontrast removeObjectForKey:@"Green"];
					[acontrast removeObjectForKey:@"Blue"];
					NSColor* c=[NSColor colorWithDeviceRed:r green:g blue:b alpha:1.0];
					[acontrast setObject:c forKey:@"Color"];
					[contrastlist addObject:acontrast];
				}
				[dataOfWizard setObject:contrastlist forKey:@"ContrastList"];
				[dataOfWizard setObject:[savedData objectForKey:@"SeedNameArray"] forKey:@"SeedNameArray"];
				[dataOfWizard setObject:[savedData objectForKey:@"RootSeedArray"] forKey:@"RootSeedArray"];
				
				//[[CMIVScissorsController alloc]  showPanelAsWizard:viewerController:self]; 
				
			}
			else
			{
				
				free(seedsdatabuffer);
			}
			
		}
		else
		{
			NSRunAlertPanel(NSLocalizedString  (@"Loading failed", nil), NSLocalizedString(@"The dimensions of current images do not match with previous results. Please reload the data", nil), NSLocalizedString(@"OK", nil), nil, nil);
			err=1;
		}
	}
	else
		err=1;
	return err;
	
}
- (int)  loadIntermediateDataForCPRViewing:(NSMutableDictionary*)savedData
{
	int err=0;
	if([savedData objectForKey:@"CenterlineArrays"]&&[savedData objectForKey:@"CenterlinesNames"])
	{
		[dataOfWizard setObject:[savedData objectForKey:@"CenterlineArrays"] forKey:@"CenterlineArrays"];	
		[dataOfWizard setObject:[savedData objectForKey:@"CenterlinesNames"] forKey:@"CenterlinesNames"];
	}
	else 
		err=1;
	return err;
}
- (int)  loadAutoSegmentResults:(NSString*)seriesUid
{
	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	NSString* path=[self osirixDocumentPath];
	NSString* file1=[path stringByAppendingFormat:@"/CTACrashChach/%@CMIV.tmp",seriesUid];

	if(dataOfWizard)
		[dataOfWizard release];
	dataOfWizard=[[NSMutableDictionary alloc] initWithContentsOfFile:file1];
	if(dataOfWizard)
	{
		NSString* step=[dataOfWizard objectForKey:@"Step"];
		if([step isEqualToString:@"Step1"])
		{
			
			return 1;
		}
		else if([step isEqualToString:@"Step2"])
			return 2;
		else if([step isEqualToString:@"Step3"])
			return 3;
		else if([step isEqualToString:@"MaskMap"])
			return 101;
		else
			return 0;
	}
	else
	{
		return 0;
	}
}
-(void)cleanUpCachFolder
{
	NSString* path=[self osirixDocumentPath];
	path=[path stringByAppendingString:@"/CMIVCTACache/"];
	NSArray* files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error: nil]; 
	unsigned int i;
	double timeDifferenceThreshold=60*60*24*autoCleanCachDays;
	double howold=0;
	for(i=1;i<[files count];i++)
	{
		NSString* file=[files objectAtIndex:i];
		file=[path stringByAppendingString:file];
		NSDictionary* fileAttri=[[NSFileManager defaultManager] fileAttributesAtPath:file traverseLink:NO];
		NSDate* modifydate=[fileAttri objectForKey:NSFileModificationDate];
		howold=fabs([modifydate timeIntervalSinceNow]);
		if(howold>timeDifferenceThreshold)
		[[NSFileManager defaultManager] removeFileAtPath:file handler:nil];
	}
}
- (BOOL)loadVesselnessMap:(float*)volumeData:(float*)origin:(float*)spacing:(long*)dimension
{
	BOOL resampleresult=YES;

	NSManagedObject	*curImage = [[viewerController fileList] objectAtIndex:0];
	NSString* seriesUid=[curImage valueForKeyPath: @"series.seriesInstanceUID"];
	NSString* path=[self osirixDocumentPath];
	NSString* file;
	file= [path stringByAppendingFormat:@"/CMIVCTACache/%@.sav",seriesUid];
	NSMutableDictionary* savedData=[[NSMutableDictionary alloc] initWithContentsOfFile:file];
	
	
	if(savedData)
	{

		NSData* vesselnessMapData=[savedData objectForKey:@"VesselnessMap"];
		NSNumber* vesselnessMapSpacingNumber=[savedData objectForKey:@"VesselnessMapTargetSpacing"];
		NSMutableArray* VesselnessMapOriginAndDimensionArray=[savedData objectForKey:@"VesselnessMapOriginAndDimension"];
		
		if(vesselnessMapData)
		{
			float* smallvolumedata=(float*)[vesselnessMapData bytes];
			if(smallvolumedata)
			{
				float vesselnessmapspacing=[vesselnessMapSpacingNumber floatValue];
				float vesselnessmaporigin[3];
				long vesselnessmapdimension[3];
				vesselnessmaporigin[0]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:0] floatValue];
				vesselnessmaporigin[1]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:1] floatValue];
				vesselnessmaporigin[2]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:2] floatValue];
				
				vesselnessmapdimension[0]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:3] longValue];
				vesselnessmapdimension[1]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:4] longValue];
				vesselnessmapdimension[2]=[[VesselnessMapOriginAndDimensionArray objectAtIndex:5] longValue];
				
				if(vesselnessmaporigin[0]==origin[0] && vesselnessmaporigin[1]==origin[1] && vesselnessmaporigin[2]==origin[2]&&abs(vesselnessmapdimension[0]*vesselnessmapspacing-dimension[0]*spacing[0])<vesselnessmapspacing&&abs(vesselnessmapdimension[1]*vesselnessmapspacing-dimension[1]*spacing[1])<vesselnessmapspacing&&abs(vesselnessmapdimension[2]*vesselnessmapspacing-dimension[2]*spacing[2])<vesselnessmapspacing)
				{
					CMIV_AutoSeeding* autoSeedingController=[[CMIV_AutoSeeding alloc] init] ;
					if([autoSeedingController resampleImage:smallvolumedata:volumeData:vesselnessmapdimension:dimension])
						resampleresult=NO;
					[autoSeedingController release];

				}
				else
					resampleresult=NO;

			}
			else
				resampleresult=NO;
			
		}
		else
			resampleresult=NO;
		[savedData release];
	}
	else
		resampleresult=NO;
	return resampleresult;
}

-(int)compressSeedsData:(NSData*)seedsData:(NSMutableArray*)compressedArray
{
	unsigned short* seedsbuffer=(unsigned short*)[seedsData bytes];
	int size=[seedsData length]/sizeof(unsigned short);
	int i;
	for(i=0;i<size;i++)
		if(seedsbuffer[i])
		{
			int startindex=i;
			unsigned short color=seedsbuffer[i];
			while(i<size&&seedsbuffer[i]==color)i++;
			[compressedArray addObject:[NSNumber numberWithInt:startindex]];
			[compressedArray addObject:[NSNumber numberWithInt:color]];
			[compressedArray addObject:[NSNumber numberWithInt:i]];
			
			i--;
		}
	return 0;
}
-(int)uncompressSeedsData:(NSData*)seedsData:(NSMutableArray*)compressedArray
{
	unsigned short* seedsbuffer=(unsigned short*)[seedsData bytes];
	memset(seedsbuffer,0x00,[seedsData length]);
	int size=[seedsData length]/sizeof(unsigned short);
	unsigned int i;
	for(i=0;i<[compressedArray count]-2;i++)
	{
		int startindex=[[compressedArray objectAtIndex:i] intValue];
		i++;
		unsigned short color=[[compressedArray objectAtIndex:i] unsignedShortValue];
		i++;
		int endindex=[[compressedArray objectAtIndex:i] intValue];
		int j;
		for(j=startindex;j<endindex&&j<size;j++)
			seedsbuffer[j]=color;
	}
	return 0;
	
}
@end

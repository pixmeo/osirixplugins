//
//  DiscPublishingPreferencesController+RobotOptions.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPreferencesController+RobotOptions.h"
#import "DiscPublishingPreferencesBinViewController.h"
#import "DiscPublishing+Tool.h"
#import <OsiriXAPI/NSXMLNode+N2.h>
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#import <OsiriXAPI/NSView+N2.h>
#import "NSUserDefaultsController+DiscPublishing.h"


@implementation DiscPublishingPreferencesController (RobotOptions)

-(void)robotOptionsInit {
	unavailableRobotOptionsView = [robotOptionsBox contentView];
	robotOptionsBins = [[NSMutableArray alloc] init];
	robotOptionsTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(initRobotGetStatusTimerFireMethod:) userInfo:NULL repeats:YES];
	[robotOptionsTimer fire];
}

-(void)enableDisableMediaTypes {
	NSLog(@"enableDisableMediaTypes with %@ %@", [[[robotOptionsBins objectAtIndex:0] discTypePopup] titleOfSelectedItem], [[[robotOptionsBins objectAtIndex:1] discTypePopup] titleOfSelectedItem]);
	for (DiscPublishingPreferencesBinViewController* bin in robotOptionsBins)
		for (NSMenuItem* mi in [[bin discTypePopup] itemArray])
			[mi setEnabled:YES];
	for (DiscPublishingPreferencesBinViewController* bin1 in robotOptionsBins) {
		NSUInteger bin1MediaType = [[NSUserDefaultsController sharedUserDefaultsController] discPublishingMediaTypeTagForBin:bin1.bin]; // this media type is reserved for this bin1
		for (DiscPublishingPreferencesBinViewController* bin2 in robotOptionsBins) // for all other bins
			if (bin2 != bin1) // so exclude this bin1
				[[[[bin2 discTypePopup] menu] itemWithTag:bin1MediaType] setEnabled:NO];
	}	
}

-(void)robotOptionsInitWithStatusXML:(NSString*)xml {
	NSXMLDocument* doc = [[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:NULL];
	
	NSSize currSize = [[robotOptionsBox contentView] frame].size;
	
	// do we support BR burn?
	BOOL supportBR = NO;
	for (NSXMLNode* drive in [doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/DRIVES/DRIVE" constants:NULL error:NULL])
		if ([[[drive childNamed:@"SUPPORTS_BR"] stringValue] intValue])
			supportBR = YES;
	
	// find out how many bins we have
	NSArray* bins = [doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT/BINS/BIN" constants:NULL error:NULL];
//#warning this MUST be enabled when releasing
	switch (bins.count) {
		case 1: {
			NSView* contentView = [[NSView alloc] initWithSize:NSMakeSize(currSize.width, 41)];
			
			DiscPublishingPreferencesBinViewController* bin = [[DiscPublishingPreferencesBinViewController alloc] initWithName:NSLocalizedString(@"Media type", NULL) bin:0];
			[bin.view setFrame:NSMakeRect(17,11,currSize.width-34,20)];
			[bin setSupportBR:supportBR];
			[contentView addSubview:bin.view];
			[robotOptionsBins addObject:bin];
			
			[robotOptionsBox setContentView:[contentView autorelease]];
		} break;
		case 2: {
			NSView* contentView = [[NSView alloc] initWithSize:NSMakeSize(currSize.width, 63)];
			DiscPublishingPreferencesBinViewController* bin;
			
			bin = [[DiscPublishingPreferencesBinViewController alloc] initWithName:NSLocalizedString(@"Left bin", NULL) bin:1];
			[bin.view setFrame:NSMakeRect(17,33,currSize.width-34,20)];
			[bin setSupportBR:supportBR];
			[contentView addSubview:bin.view];
			[robotOptionsBins addObject:bin];
			
			bin = [[DiscPublishingPreferencesBinViewController alloc] initWithName:NSLocalizedString(@"Right bin", NULL) bin:0];
			[bin.view setFrame:NSMakeRect(17,11,currSize.width-34,20)];
			[bin setSupportBR:supportBR];
			[contentView addSubview:bin.view];
			[robotOptionsBins addObject:bin];
			
			[robotOptionsBox setContentView:[contentView autorelease]];
		} break;
		default:
			[unavailableRobotOptionsTextView setStringValue:[NSString stringWithFormat:NSLocalizedString(@"An unexpected amount of bins was detected (%d).", NULL), bins.count]];
			[robotOptionsBox setContentView:unavailableRobotOptionsView];
			break;
	}
	
	for (DiscPublishingPreferencesBinViewController* bin in robotOptionsBins)
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forValuesKey:[bin mediaTypeTagBindingKey] options:NULL context:NULL];
	
	[self enableDisableMediaTypes];
	
	[doc release];
}

-(void)robotOptionsDealloc {
	[robotOptionsTimer invalidate]; robotOptionsTimer = NULL;
	[robotOptionsBins release]; robotOptionsBins = NULL;
	// bindings observing is cancelled by [self dealloc], that calls this method
}

-(BOOL)robotOptionsObserveValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"prefs+robot observeValueForKeyPath:%@", keyPath);

	if ([keyPath hasSuffix:DiscPublishingMediaTypeTagSuffix]) {
		[self enableDisableMediaTypes];
		return YES;
	}
	
	return NO;
}

-(void)initRobotGetStatusTimerFireMethod:(NSTimer*)timer { // timer is this->robotOptionsTimer
	//[patientModeAuxDirPathControl setEnabled:YES];
	@try {
		NSString* xml = [DiscPublishing GetStatusXML];
		[robotOptionsTimer invalidate]; robotOptionsTimer = NULL;
		[self robotOptionsInitWithStatusXML:xml];
	} @catch (NSException* e) {
	} 
}

@end

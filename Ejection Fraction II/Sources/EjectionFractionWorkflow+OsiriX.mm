//
//  EjectionFractionWorkflow+OsiriX
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 17.11.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionWorkflow+OsiriX.h"
#import "EjectionFractionAlgorithm.h"
#import "EjectionFractionPlugin.h"
#import "EjectionFractionStepsController.h"
#import "EjectionFractionResultsController.h"
#import <OsiriX Headers/Notifications.h>
#import <OsiriX Headers/ViewerController.h>
#import <OsiriX Headers/DCMView.h>
#import <OsiriX Headers/DicomSeries.h>
#import <OsiriX Headers/ROI.h>

NSString* EjectionFractionWorkflowExpectedROIChangedNotification = @"EjectionFractionWorkflowExpectedROIChangedNotification";
NSString* EjectionFractionWorkflowROIAssignedNotification = @"EjectionFractionWorkflowROIAssignedNotification";
NSString* EjectionFractionWorkflowROIIdInfo = @"EjectionFractionWorkflowROIIdInfo";

@interface EjectionFractionWorkflow (OsiriX_Private)

-(void)setRoi:(ROI*)roi forId:(NSString*)roiId;

@end

@implementation EjectionFractionWorkflow (OsiriX)

-(void)loadRoisFromViewer:(ViewerController*)viewer {
	for (ROI* roi in [[viewer imageView] curRoiList])
		if ([_algorithm needsRoiWithId:[roi name] tag:[roi type]])
			[self setRoi:roi forId:[roi name]];	
}

-(void)initOsiriX {
	_rois = [[NSMutableDictionary alloc] initWithCapacity:8];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiAdded:) name:OsirixAddROINotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiChanged:) name:OsirixROIChangeNotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(roiRemoved:) name:OsirixRemoveROINotification object:NULL];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dcmviewUpdateCurrentImage:) name:OsirixDCMUpdateCurrentImageNotification object:NULL];
	
	// by analyzing the currently visible ROIs, guess which algorithm couls be already applied
	NSUInteger algorithmsCount = [[_plugin algorithms] count];
	NSUInteger algorithmsROIsCounts[algorithmsCount];
	for (NSUInteger i = 0; i < algorithmsCount; ++i)
		algorithmsROIsCounts[i] = 0;
	for (ViewerController* viewer in [ViewerController getDisplayed2DViewers])
		for (ROI* roi in [[viewer imageView] curRoiList])
			for (NSUInteger i = 0; i < algorithmsCount; ++i)
				if ([[[_plugin algorithms] objectAtIndex:i] needsRoiWithId:[roi name] tag:[roi type]])
					++algorithmsROIsCounts[i];
	CGFloat algorithmRatios[algorithmsCount];
	for (NSUInteger i = 0; i < algorithmsCount; ++i)
		algorithmRatios[i] = 1.*algorithmsROIsCounts[i]/[[[_plugin algorithms] objectAtIndex:i] countOfNeededRois];
	NSUInteger algorithmIndex = 0;
	for (NSUInteger i = 1; i < algorithmsCount; ++i)
		if (algorithmRatios[i] > algorithmRatios[algorithmIndex])
			algorithmIndex = i;
	
	[_steps setSelectedAlgorithm:[[_plugin algorithms] objectAtIndex:algorithmIndex]];
	
	// use the available ROIs for the algorithm
	for (ViewerController* viewer in [ViewerController getDisplayed2DViewers])
		[self loadRoisFromViewer:viewer];
}

-(void)dcmviewUpdateCurrentImage:(NSNotification*)notification {
	[self loadRoisFromViewer:[[[notification object] window] windowController]];
}

-(void)deallocOsiriX {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixAddROINotification object:NULL];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixROIChangeNotification object:NULL];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixRemoveROINotification object:NULL];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixDCMUpdateCurrentImageNotification object:NULL];
	[_rois release]; _rois = NULL;
}

+(NSArray*)roiTypesForType:(EjectionFractionROIType)roiType {
	switch (roiType) {
		case EjectionFractionROIArea:
			return [NSArray arrayWithObjects: [NSNumber numberWithLong:tCPolygon], [NSNumber numberWithLong:tOPolygon], [NSNumber numberWithLong:tPencil], NULL];
		case EjectionFractionROILength:
			return [NSArray arrayWithObject:[NSNumber numberWithLong:tMesure]];
		default:
			return NULL;
	}
}

-(void)setExpectedRoiId:(NSString*)roiId {
	[_expectedRoiId release];
	_expectedRoiId = [roiId	retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:EjectionFractionWorkflowExpectedROIChangedNotification object:self];
}

-(void)selectOrOpenViewerForRoiWithId:(NSString*)roiId {
	ROI* roi = [self roiForId:roiId];
	
	if (roi) {
		DCMView* view = [roi curView];
		ViewerController* viewer = [[view window] windowController];
		[[view window] makeKeyAndOrderFront:self];
		[viewer selectROI:roi deselectingOther:YES];
	} else {
		ViewerController* viewer = [[NSApp makeWindowsPerform:@selector(frontmostViewerControllerFinder) inOrder:YES] windowController];
		NSArray* roiTypes = [EjectionFractionWorkflow roiTypesForType:[_algorithm typeForRoiId:roiId]];
		[self setExpectedRoiId:roiId];
		[viewer setROIToolTag:[[roiTypes objectAtIndex:0] longValue]];
		[[viewer window] makeKeyAndOrderFront:self];
	}
}

-(ROI*)roiForId:(NSString*)roiId {
	return [_rois objectForKey:roiId];
}

-(NSString*)idForRoi:(ROI*)roi {
	return [_rois keyForObject:roi];
}

-(void)updateResult {
	@try {
		[_steps setResult:[_algorithm compute:_rois]];
	} @catch (NSException* e) {
		[_steps setResult:0];
	}
}

-(void)roiChanged:(NSNotification*)notification {
	ROI* roi = [notification object];
	if ([self idForRoi:roi])
		[self updateResult];
}

-(void)setRoi:(ROI*)roi forId:(NSString*)roiId {
	if (roi == [self roiForId:roiId]) return;
	
	NSLog(@"Setting %@ as %@", [roi name], roiId);
	
	if (roi)
		[_rois setObject:roi forKey:roiId];
	else [_rois removeObjectForKey:roiId];
	
	[roi setName:roiId];
	[self roiChanged:[NSNotification notificationWithName:OsirixROIChangeNotification object:roi]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:EjectionFractionWorkflowROIAssignedNotification object:self userInfo:[NSDictionary dictionaryWithObject:roiId forKey:EjectionFractionWorkflowROIIdInfo]];
}

-(void)roiAdded:(NSNotification*)notification {
	ROI* roi = [[notification userInfo] objectForKey:@"ROI"];
	NSString* roiId = [self expectedRoiId];
	if ([self roiForId:roiId]) roiId = NULL;
	
	/// TODO: if !roiId, we should guess it
	if (!roiId)
		return;
	
	[self setRoi:roi forId:roiId];
}

-(void)roiRemoved:(NSNotification*)notification {
	ROI* roi = [notification object];
	NSString* roiId = [self idForRoi:roi];
	if (roiId) {
		[self setRoi:NULL forId:roiId];
		[self selectOrOpenViewerForRoiWithId:roiId];
		[self updateResult];
	}
}

-(void)showDetails {
	[[EjectionFractionResultsController alloc] initWithWorkflow:self];
}

@end

@implementation NSWindow (EjectionFractionWorkflow_OsiriX)

// used by selectOrOpenViewerForRoiWithId along with [NSApp makeWindowsPerform] to find the frontmost ViewerController
-(id)frontmostViewerControllerFinder {
	return [[self windowController] isKindOfClass:[ViewerController class]] ? self : NULL;
}

@end


//
//  EjectionFraction.mm
//  Ejection Fraction II
//
//  Created by Alessandro Volz on 7/20/09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "EjectionFractionPlugin.h"
#import "EjectionFractionWorkflow.h"
#import "EjectionFractionStepsController.h"
#import <OsiriXAPI/Notifications.h>
#import "MonoPlaneEjectionFractionAlgorithm.h"
#import "BiPlaneEjectionFractionAlgorithm.h"
#import "HemiEllipseEjectionFractionAlgorithm.h"
#import "SimpsonEjectionFractionAlgorithm.h"
#import "TeichholzEjectionFractionAlgorithm.h"
#import <OsiriXAPI/N2Debug.h>

NSString* EjectionFractionAlgorithmAddedNotification = @"EjectionFractionWorkflowAlgorithmAddedNotification";
NSString* EjectionFractionAlgorithmRemovedNotification = @"EjectionFractionWorkflowAlgorithmRemovedNotification";

@implementation EjectionFractionPlugin
@synthesize algorithms = _algorithms;

/*-(void)n2test {
	DLog(@"n2test n2test n2test n2test n2test n2test n2test n2test n2test n2test n2test");
	N2Window* window = [[N2Window alloc] initWithContentRect:NSMakeRect(0, 0, 400, 300) styleMask:NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	N2LayoutManager* layout = [[[N2LayoutManager alloc] initWithControlSize:NSRegularControlSize] autorelease];
//	[layout setForcesSuperviewSize:YES];
//	[layout setStretchesToFill:YES];
//	[layout setOccupiesEntireSuperview:YES];
	[[window contentView] setLayout:layout];
	
	NSTextView* temp;
	temp = [[NSTextView alloc] init];
	[temp setString:@"Random text content."];
	[temp setEditable:NO];
	[[window contentView] addSubview:[temp autorelease]];
	[temp adaptToContent];
	[[window contentView] addDescriptor:[N2LayoutDescriptor createWithAlignment:N2AlignmentRight]];
	temp = [[NSTextView alloc] init];
	[temp setString:@"Random text content."];
	[temp setEditable:NO];
	[[window contentView] addSubview:[temp autorelease]];
	[temp adaptToContent];
 
	
	[layout recalculate:[window contentView]];
	[window makeKeyAndOrderFront:self];
	DLog(@"Ok");
}*/

-(void)addAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	[_algorithms addObject:algorithm];
	[[NSNotificationCenter defaultCenter] postNotificationName:EjectionFractionAlgorithmAddedNotification object:algorithm];
}

-(void)removeAlgorithm:(EjectionFractionAlgorithm*)algorithm {
	[_algorithms removeObject:algorithm];
	[[NSNotificationCenter defaultCenter] postNotificationName:EjectionFractionAlgorithmRemovedNotification object:algorithm];
}

-(void)initPlugin {
	_wfs = [[NSMutableArray alloc] initWithCapacity:1];
	_algorithms = [[NSMutableArray alloc] initWithCapacity:5];
	
	[self addAlgorithm:[[[MonoPlaneEjectionFractionAlgorithm alloc] init] autorelease]];
	[self addAlgorithm:[[[BiPlaneEjectionFractionAlgorithm alloc] init] autorelease]];
	[self addAlgorithm:[[[HemiEllipseEjectionFractionAlgorithm alloc] init] autorelease]];
	[self addAlgorithm:[[[SimpsonEjectionFractionAlgorithm alloc] init] autorelease]];
	[self addAlgorithm:[[[TeichholzEjectionFractionAlgorithm alloc] init] autorelease]];
	
	//[self n2test];
//	EjectionFractionWorkflow* w = [[EjectionFractionWorkflow alloc] initWithPlugin:self viewer:NULL];
//	[[w steps] showWindow:self];
//	[controller showWindow:NULL];
//	DLog(@"controller window [%f, %f, %f, %f]", [[controller window] frame].origin.x, [[controller window] frame].origin.y, [[controller window] frame].size.width, [[controller window] frame].size.height);
}

-(void)dealloc {
	[_algorithms release]; _algorithms = NULL;
	[_wfs release]; _wfs = NULL;
	[super dealloc];
}

-(void)addWorkflow:(EjectionFractionWorkflow*)workflow {
	[_wfs addObject:workflow];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stepsWindowWillClose:) name:NSWindowWillCloseNotification object:[[workflow steps] window]];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewerWillClose:) name:OsirixCloseViewerNotification object:[workflow viewer]];
}

-(void)removeWorkflow:(EjectionFractionWorkflow*)workflow {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[[workflow steps] window]];
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:OsirixCloseViewerNotification object:[workflow viewer]];
	[_wfs removeObject:workflow];
}

-(void)stepsWindowWillClose:(NSNotification*)notification {
	NSWindow* win = [notification object];
	DLog(@"EjectionFractionPlugin notified of Steps window close");
	
	EjectionFractionWorkflow* workflow = NULL;
	for (EjectionFractionWorkflow* wf in _wfs)
		if ([[wf steps] window] == win)
			workflow = wf;
	int rc = [workflow retainCount];
	DLog(@"Workflow is %@, rc = %d", workflow, rc);
	
	[workflow setSteps:NULL];
	[self removeWorkflow:workflow];

	if (rc > 1) DLog(@"Workflow rc = %d", [workflow retainCount]);
}

//-(void)viewerWillClose:(NSNotification*)notification {
//	ViewerController* viewer = [notification object];
//	
//	EjectionFractionWorkflow* workflow = NULL;
//	for (EjectionFractionWorkflow* wf in _wfs)
//		if ([wf viewer] == viewer)
//			workflow = wf;
//	
//	[workflow setViewer:NULL];
//	[self removeWorkflow:workflow];
//}

-(long)filterImage:(NSString*)menuName {
	EjectionFractionWorkflow* workflow = NULL;
	for (EjectionFractionWorkflow* wf in _wfs) {
//		if ([wf viewer] == viewerController)
		workflow = wf;
		break;
	}
	
	if (!workflow) [self addWorkflow: workflow = [[[EjectionFractionWorkflow alloc] initWithPlugin:self viewer:viewerController] autorelease]];
	[[[workflow steps] window] makeKeyAndOrderFront:self];

	return 0;
}

@end

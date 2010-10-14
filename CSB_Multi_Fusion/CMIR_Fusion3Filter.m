//
//  CMIR_Fusion3Filter.m
//  CMIR_Fusion3
//
//  Copyright (c) 2009 CMIR. All rights reserved.
//
#import "CMIR_Fusion3Filter.h"
#import "Controller.h"

@implementation CMIR_Fusion3Filter

//- (CMIR_ViewerController*)   viewerController
- (ViewerController*)   viewerController
{
//	return (CMIR_ViewerController *)viewerController;
	return viewerController;
}


- (long) filterImage:(NSString*) menuName
{

	// Display a nice window to thanks the user for using our powerful filter!
	ControllerCMIRFusion3* coWin = [[ControllerCMIRFusion3 alloc] init:self];
	[coWin showWindow:self];
	
/*
 
	if (new2DViewer == 0L) new2DViewer = [self duplicateCurrent2DViewerWindow];
	if( new2DViewer) return 0; // No Errors
	else return -1;
	
 NSAlert	*myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"New FUSION plugin! new2DViewer=%d   is2D=%d", new2DViewer, [new2DViewer is2DViewer]]
									   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
 [myAlert runModal];
	
	if (new2DViewer == 0L) new2DViewer = [self duplicateCurrent2DViewerWindow];
 
 myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"new2DViewer=%d  blendedWindow=%d", new2DViewer, [[self viewerController] blendedWindow]]
						   defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
 [myAlert runModal];
	
	if( new2DViewer) {
		[[new2DViewer window] setDelegate:self]; // //In order to receive the windowWillClose notification
		
		[self init:[[self viewerController] blendedWindow]];
		return 0; // No Errors
	}	
	else return -1;
*/

	return 0;
}
 
@end

/*
 - (id) init:(ViewerController*) f 
 {
	 //	self = [super initWithWindowNibName:@"Controller"];
	 
	 //	[[self window] setDelegate:self];   //In order to receive the windowWillClose notification!
	 
	 //	filter = f;
	 //	blendedWindow = [[filter viewerController] blendedWindow];
	 
	 
	 NSAlert *myAlert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"blendedWindow=%d  current type=%@", f, [[[f fileList] objectAtIndex:0] valueForKey:@"modality"]]
										defaultButton:@"OK"	 alternateButton:nil	 otherButton:nil   informativeTextWithFormat:@""];
	 [myAlert runModal];
	 
	 return self;
 }
 
 
 - (void) closeViewer :(NSNotification*) note
 {
	 
	 if( [note object] == new2DViewer)
	 {
		 NSLog(@"FUSION3 Window will close with name=%@", [note name]);
		 [new2DViewer release];
		 new2DViewer = 0L;
	 }
 }
 
 
@end
*/


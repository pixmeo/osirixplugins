//
//  Controller.h
//  CMIR_Fusion3
//
//  Created by lfexon on 5/5/09.
//  Copyright 2009 CSB_MGH. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "CSB_Multi_FusionFilter.h"
#import "CMIRViewerController.h"
#import "objc/runtime.h"
#import "WaitRendering.h"
#import "Wait.h"

@interface ControllerCMIRFusion3 : NSWindowController {
	
	CSB_Multi_FusionFilter		*filter;
	NSMutableArray *listOfViewers;
	NSMutableArray *listOfROIs;
	
	IBOutlet NSMatrix *operation;
	IBOutlet NSButton *startButton;
	IBOutlet NSButton *cancelButton;
	
	int COPY_ONLY_TAG;					//100
	int COPY_AND_FUSE_TAG;				//101
}

-(IBAction) compute:(id) sender;
- (id) init:(CSB_Multi_FusionFilter*) f ;
-(void) check_CSB_LUT; 
-(NSMutableArray*) get2DPoints: (NSMutableArray *) roiArray;
-(void) roiRestore:(int)ind fromSet:(int)fixed_i;
@end

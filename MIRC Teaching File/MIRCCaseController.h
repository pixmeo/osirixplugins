//
//  MIRCCaseController.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/8/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class MIRCController;
@class MIRCXMLController;
@interface MIRCCaseController : NSArrayController {
	IBOutlet NSTableView *tableView;
	IBOutlet MIRCController *mircController;
	MIRCXMLController *_mircEditor;
	NSString *_caseName;
	NSMutableData *receivedData;	
	BOOL _animateProgressBar;
	BOOL _hideProgressBar;
}

- (IBAction)controlAction: (id) sender;
- (IBAction)create:(id)sender;
- (void)save;
- (id)teachingFile;
- (IBAction)send: (id)sender;
- (BOOL)sendURL:(NSURL *)url;

- (void)displaySendStatus:(NSString *)status;
- (void)setProgressBarStatus:(BOOL)status;
- (BOOL) animateProgressBar;
- (void) setAnimateProgressBar:(BOOL)animate;
- (BOOL) hideProgressBar;
- (void) setHideProgressBar:(BOOL)hide;
@end

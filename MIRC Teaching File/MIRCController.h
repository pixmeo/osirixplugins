//
//  ThanksControoler.h
//  Invert
//
//  Created by Lance Pysher July 22, 2005
//  Copyright (c) 2005 Macrad, LLC. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <WebKit/WebView.h>


@class MIRCFilter;
@class MIRCXMLController;
@class MIRCWebController;

@interface MIRCController : NSWindowController {

	IBOutlet NSTextField *titleField;
	MIRCFilter *_filter;
	NSString *_caseName;
	NSString *_path;
	NSString *_url;
	NSXMLDocument *_xmlDocument;
	IBOutlet NSTableView *tableView;
	MIRCXMLController *_xmlController;
	MIRCWebController *_webController;
	NSArray *_teachingFiles;
	IBOutlet NSPanel	*_mircSettings;
	IBOutlet NSPanel	*_loginPanel;
	
	//Core Data
	NSManagedObjectModel *_managedObjectModel;
	NSManagedObjectContext *_managedObjectContext;
}

- (id) initWithFilter:(id)filter;

- (IBAction)connectToMIRC:(id)sender;

- (IBAction)createArchive:(id)sender;
- (NSString *)caseName;
- (void) setCaseName: (NSString *)caseName;
- (NSString *)path;
- (NSArray *)directoryContents;
-(void)setDirectoryContents:(id)contents;
- (NSString *)folder;
- (void)addFiles:(NSArray *)files;
- (NSString *)url;
- (void)setUrl:(NSString *)url;
- (IBAction)getInfo:(id)sender;


- (NSArray *)teachingFiles;
- (void)setTeachingFiles:(NSArray *)teachingFiles;
//Core Data
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (void)save;

- (IBAction)openMIRCSettings:(id)sender;
- (IBAction)closeMIRCSettings:(id)sender;
- (IBAction)endLoginPanel:(id)sender;

@end

/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/


#import <Cocoa/Cocoa.h>
/*
#import "DCMView.h"
#import "MyOutlineView.h"
#import "PreviewView.h"
#import "QueryController.h"
#import "AnonymizerWindowController.h"
*/

@class MPR2DController;
@class NSCFDate;
@class BurnerWindowController;
@class ViewerController;
@class BonjourPublisher;
@class BonjourBrowser;
@class AnonymizerWindowController;
@class QueryController;
@class PreviewView;
@class MyOutlineView;
@class DCMView;
@class DCMPix;



enum RootTypes{PatientRootType, StudyRootType, RandomRootType};
enum simpleSearchType {PatientNameSearch, PatientIDSearch};
enum queueStatus{QueueHasData, QueueEmpty};

@interface BrowserController : NSWindowController//NSObject
{
	NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext;
	
	NSString				*currentDatabasePath;
	BOOL					isCurrentDatabaseBonjour;
	NSString				*transferSyntax;
    NSArray                 *dirArray;
    NSToolbar               *toolbar;
	
	NSMutableArray			*files2Send, *sendQueue;
	id						destinationServer;
	
    NSMutableArray          *previewPix;
	
	NSMutableArray			*draggedItems;
		
	NSMutableDictionary		*activeSends;
	NSMutableArray			*sendLog;
	NSMutableDictionary		*activeReceives;
	NSMutableArray			*receiveLog;
	
	QueryController * queryController;
	AnonymizerWindowController *anonymizerController;
	BurnerWindowController *burnerWindowController;
	
    
    DCMPix                  *curPreviewPix;
    
    NSTimer                 *timer, *IncomingTimer, *matrixDisplayIcons, *refreshTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert;
    
	BOOL					setDCMDone;
	
    volatile BOOL           shouldDie, threadRunning, threadWillRunning, bonjourDownloading;
	
	NSArray							*outlineViewArray;
	NSArray							*matrixViewArray;
	NSArray							*allColumns;
	
	IBOutlet NSTextField			*databaseDescription;
	IBOutlet MyOutlineView          *databaseOutline;
	IBOutlet NSMatrix               *oMatrix;
	IBOutlet NSTableView			*albumTable;
	IBOutlet NSSegmentedControl		*segmentedAlbumButton;
	
	IBOutlet NSTextField			*bonjourServiceName;
	IBOutlet NSTableView			*bonjourServicesList;
	IBOutlet NSButton				*bonjourSharingCheck;
	BonjourPublisher				*bonjourPublisher;
	BonjourBrowser					*bonjourBrowser;

    IBOutlet NSProgressIndicator    *working;
	IBOutlet NSSlider				*animationSlider;
	IBOutlet NSButton				*animationCheck;
    
   
    IBOutlet PreviewView			*imageView;
	IBOutlet NSWindow				*serverWindow;
	IBOutlet NSTextField			*noImages;
	IBOutlet NSComboBox				*serverList;
	IBOutlet NSComboBox				*syntaxList;
	IBOutlet NSMatrix				*DICOMSendTool;
	
	
	IBOutlet NSWindow				*newAlbum;
	IBOutlet NSTextField			*newAlbumName;
	
	IBOutlet NSDrawer				*albumDrawer;
	
	IBOutlet NSWindow				*customTimeIntervalWindow;
	IBOutlet NSDatePicker			*customStart, *customEnd, *customStart2, *customEnd2;
	IBOutlet NSView					*timeIntervalView;
	int								timeIntervalType;
	NSDate							*timeIntervalStart, * timeIntervalEnd;
	
	IBOutlet NSView					*searchView;
	IBOutlet NSSearchField			*searchField;
	NSToolbarItem					*toolbarSearchItem;
	int								searchType;
	
	IBOutlet NSTextField			*sendStatusField;
	IBOutlet NSWindow				*searchWindow;
	IBOutlet NSWindow				*smartWindow;
	IBOutlet NSWindow				*mainWindow;
	IBOutlet NSMenu					*imageTileMenu;
	IBOutlet NSWindow				*urlWindow;
	IBOutlet NSTextField			*urlString;
	
	IBOutlet NSTableView			*sendLogTable;
	IBOutlet NSTableView			*receiveLogTable;
	
	IBOutlet NSForm					*rdPatientForm;
	IBOutlet NSForm					*rdPixelForm;
	IBOutlet NSForm					*rdVoxelForm;
	IBOutlet NSForm					*rdOffsetForm;
	IBOutlet NSMatrix				*rdPixelTypeMatrix;
	IBOutlet NSView					*rdAccessory;
    
//    IBOutlet NSTextField            *pNo, *pSize, *pLoc;
//    IBOutlet NSButton               *showAll;
        
//    IBOutlet NSWindow		*window;
    
    BOOL    showAllImages;
	NSConditionLock *queueLock;
}

+ (BrowserController*) currentBrowser;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (void) addURLToDatabaseEnd:(id) sender;
- (void) addURLToDatabase:(id) sender;
- (NSArray*) addURLToDatabaseFiles:(NSArray*) URLs;
- (BOOL) findAndSelectFile:(NSString*) file :(NSManagedObject*) dcmFile :(BOOL) expand;
- (IBAction) sendiDisk:(id) sender;
- (IBAction) sendiPod:(id) sender;
- (void) selectServer: (NSArray*) files;
- (void) loadDICOMFromiPod;
-(void) saveDatabase:(NSString*) path;
- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files;
-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput;
-(void) loadSeries :(NSManagedObject *)curFile :(ViewerController*) viewer :(BOOL) firstViewer;
-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer;
-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer;
- (void) export2PACS:(id) sender;
- (void) queryDICOM:(id) sender;
- (void)sendDICOMFiles:(NSMutableArray *)files;
- (IBAction) endSelectServer:(id) sender;
- (IBAction) delItem:(id) sender;
- (IBAction) selectFilesAndFoldersToAdd:(id) sender;
- (void) showDatabase:(id)sender;
-(IBAction) matrixPressed:(id)sender;
-(void) loadDatabase:(NSString*) path;
- (void) viewerDICOM:(id) sender;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer;
- (void) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer;

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;

-(void) saveSPLIT;
- (void) setupToolbar;

- (IBAction)customize:(id)sender;
- (IBAction)showhide:(id)sender;

- (void) exportDICOMFile:(id) sender;
- (void) viewerDICOM:(id) sender;
- (void) burnDICOM:(id) sender;
- (IBAction) anonymizeDICOM:(id) sender;
- (IBAction)addSmartAlbum: (id)sender;
- (IBAction)search: (id)sender;
- (IBAction)setSearchType: (id)sender;
- (IBAction)setImageTiling: (id)sender;

- (IBAction)setTimeIntervalType: (id)sender;
- (IBAction) endCustomInterval:(id) sender;
- (IBAction) customIntervalNow:(id) sender;

- (IBAction) opendDatabase:(id) sender;
- (IBAction) createDatabase:(id) sender;
- (void) openDatabaseIn:(NSString*) a;

- (void) ReBuildDatabase:(id) sender;
- (long) COLUMN;
- (BOOL) is2DViewer;
- (void) previewSliderAction:(id) sender;
- (void)addHelpMenu;

- (BOOL) isItCD:(NSArray*) pathFilesComponent;
- (void)setSendMessage:(NSNotification *)note;
- (void)receivedImage:(NSNotification *)note;
- (void)storeSCPComplete:(id)sender;
- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingDicomFile;
- (NSMutableArray *)albumForDB:(NSArray *)db forCriteria:(NSArray *)criteria;

- (BOOL) addFilesToDatabase:(NSArray*) newFilesArray;
- (void) addFilesAndFolderToDatabase:(NSArray*) filenames;

//- (short) createAnonymizedFile:(NSString*) srcFile :(NSString*) dstFile;
- (IBAction)setSendTransferSyntax:(id)sender;
- (void)setTransferSyntax:(NSString *)ts;
- (void)runSendQueue:(id)object;
- (void)addToQueue:(NSArray *)array;
- (MyOutlineView*) databaseOutline;

-(void) previewPerformAnimation:(id) sender;
-(void) matrixDisplayIcons:(id) sender;

- (void)reloadReceiveLog:(id)sender;
- (void)reloadSendLog:(id)sender;
- (IBAction)importRawData:(id)sender;
- (void) setBurnerWindowControllerToNIL;

- (void) refreshColumns;
- (void) outlineViewRefresh;
- (void) matrixInit:(long) noOfImages;
- (IBAction) albumButtons: (id)sender;
- (NSArray*) albumArray;
- (NSArray*) childrenArray: (NSManagedObject*) item;

- (NSArray*) imagesPathArray: (NSManagedObject*) item;

//bonjour
- (void)setServiceName:(NSString*) title;
- (IBAction)toggleBonjourSharing:(id) sender;
- (void) bonjourWillPublish;
- (void) bonjourDidStop;
- (IBAction) bonjourServiceClicked:(id)sender;
- (NSString*) currentDatabasePath;
- (void) setBonjourDownloading:(BOOL) v;
- (NSString*) getLocalDCMPath: (NSManagedObject*) obj;

//DB plugins
- (void)executeFilter:(id)sender;

@end

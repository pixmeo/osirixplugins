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
    
    NSTimer                 *timer, *IncomingTimer, *matrixDisplayIcons, *refreshTimer, *databaseCleanerTimer;
	long					loadPreviewIndex, previousNoOfFiles;
	NSManagedObject			*previousItem;
    
    long                    COLUMN;
	IBOutlet NSSplitView	*splitViewHorz, *splitViewVert;
	IBOutlet NSSplitView	*logViewSplit;
    
	BOOL					setDCMDone, mountedVolume;
	
    volatile BOOL           shouldDie, threadRunning, threadWillRunning, bonjourDownloading;
	
	NSArray							*outlineViewArray;
	NSArray							*matrixViewArray;
	NSArray							*allColumns;
	
	IBOutlet NSTextField			*databaseDescription;
	IBOutlet MyOutlineView          *databaseOutline;
	IBOutlet NSMatrix               *oMatrix;
	IBOutlet NSTableView			*albumTable;
	IBOutlet NSSegmentedControl		*segmentedAlbumButton;
	
	IBOutlet NSSplitView			*sourcesSplitView;
	IBOutlet NSBox					*bonjourSourcesBox;
	
	IBOutlet NSTextField			*bonjourServiceName, *bonjourPassword;
	IBOutlet NSTableView			*bonjourServicesList;
	IBOutlet NSButton				*bonjourSharingCheck, *bonjourPasswordCheck;
	BonjourPublisher				*bonjourPublisher;
	BonjourBrowser					*bonjourBrowser;

    IBOutlet NSProgressIndicator    *working;
	IBOutlet NSSlider				*animationSlider;
	IBOutlet NSButton				*animationCheck;
    
   
    IBOutlet PreviewView			*imageView;
	IBOutlet NSWindow				*serverWindow;
	IBOutlet NSTextField			*noImages;
	IBOutlet NSComboBox				*serverList;
	IBOutlet NSPopUpButton			*syntaxListOsiriX, *syntaxListOffis;
	IBOutlet NSMatrix				*DICOMSendTool;
	
	IBOutlet NSWindow				*bonjourPasswordWindow;
	IBOutlet NSTextField			*password;
	
	IBOutlet NSWindow				*newAlbum;
	IBOutlet NSTextField			*newAlbumName;
	
	IBOutlet NSWindow				*editSmartAlbum;
	IBOutlet NSTextField			*editSmartAlbumName, *editSmartAlbumQuery;
	
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
	
	IBOutlet NSWindow				*mainWindow;
	IBOutlet NSMenu					*imageTileMenu;
	IBOutlet NSWindow				*urlWindow;
	IBOutlet NSTextField			*urlString;
	
	IBOutlet NSTableView			*sendLogTable;
//	IBOutlet NSTableView			*receiveLogTable;
	
	IBOutlet NSForm					*rdPatientForm;
	IBOutlet NSForm					*rdPixelForm;
	IBOutlet NSForm					*rdVoxelForm;
	IBOutlet NSForm					*rdOffsetForm;
	IBOutlet NSMatrix				*rdPixelTypeMatrix;
	IBOutlet NSView					*rdAccessory;
	
	IBOutlet NSMatrix				*keyImageMatrix;
    
//    IBOutlet NSTextField            *pNo, *pSize, *pLoc;
//    IBOutlet NSButton               *showAll;
        
//    IBOutlet NSWindow		*window;
    
    BOOL    showAllImages, DatabaseIsEdited;
	NSConditionLock *queueLock;
}

+ (BrowserController*) currentBrowser;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSArray*) childrenArray: (NSManagedObject*) item;
- (NSArray*) childrenArray: (NSManagedObject*) item keyImagesOnly:(BOOL)keyImagesOnly SCOnly:(BOOL) SCOnly;
- (NSArray*) imagesArray: (NSManagedObject*) item;
- (NSArray*) imagesArray: (NSManagedObject*) item  keyImagesOnly:(BOOL)keyImagesOnly SCOnly:(BOOL) SCOnly;


- (void) addURLToDatabaseEnd:(id) sender;
- (void) addURLToDatabase:(id) sender;
- (NSArray*) addURLToDatabaseFiles:(NSArray*) URLs;
-(BOOL) findAndSelectFile: (NSString*) path image: (NSManagedObject*) curImage shouldExpand: (BOOL) expand;
- (IBAction) sendiDisk:(id) sender;
- (IBAction) sendiPod:(id) sender;
- (void) selectServer: (NSArray*) files;
- (void) loadDICOMFromiPod;
-(void) saveDatabase:(NSString*) path;
- (void) addDICOMDIR:(NSString*) dicomdir :(NSMutableArray*) files;
-(NSMutableArray*) copyFilesIntoDatabaseIfNeeded:(NSMutableArray*) filesInput;
-(void) loadSeries :(NSManagedObject *)curFile :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
-(void) loadNextPatient:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
-(void) loadNextSeries:(NSManagedObject *) curImage :(long) direction :(ViewerController*) viewer :(BOOL) firstViewer keyImagesOnly:(BOOL) keyImages;
- (void) openViewerFromImages:(NSArray*) toOpenArray movie:(BOOL) movieViewer viewer:(ViewerController*) viewer keyImagesOnly:(BOOL) keyImages;
- (void) export2PACS:(id) sender;
- (void) queryDICOM:(id) sender;
- (void)sendDICOMFiles:(NSMutableArray *)files;
- (IBAction) endSelectServer:(id) sender;
- (IBAction) delItem:(id) sender;
- (void) delItemMatrix: (NSManagedObject*) obj;
- (IBAction) selectFilesAndFoldersToAdd:(id) sender;
- (void) showDatabase:(id)sender;
-(IBAction) matrixPressed:(id)sender;
-(void) loadDatabase:(NSString*) path;
- (void) viewerDICOM:(id) sender;
- (void) viewerDICOMInt:(BOOL) movieViewer dcmFile:(NSArray *)selectedLines viewer:(ViewerController*) viewer;
- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem;

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
- (void) openDatabaseIn:(NSString*) a Bonjour:(BOOL) isBonjour;

- (void) ReBuildDatabase:(id) sender;
- (long) COLUMN;
- (BOOL) is2DViewer;
- (void) previewSliderAction:(id) sender;
- (void)addHelpMenu;

- (BOOL) isItCD:(NSArray*) pathFilesComponent;
- (void)setSendMessage:(NSNotification *)note;
- (void)receivedImage:(NSNotification *)note;
- (void)storeSCPComplete:(id)sender;
- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingManagedObjects  keyImagesOnly:(BOOL)keyImagesOnly SCOnly:(BOOL) SCOnly;
- (NSMutableArray *)filesForDatabaseOutlineSelection :(NSMutableArray*) correspondingDicomFile;


- (IBAction) smartAlbumHelpButton:(id) sender;

- (NSArray*) addFilesToDatabase:(NSArray*) newFilesArray;
- (void) addFilesAndFolderToDatabase:(NSArray*) filenames;

//- (short) createAnonymizedFile:(NSString*) srcFile :(NSString*) dstFile;

- (void)runSendQueue:(id)object;
- (void)addToQueue:(NSArray *)array;
- (MyOutlineView*) databaseOutline;

-(void) previewPerformAnimation:(id) sender;
-(void) matrixDisplayIcons:(id) sender;

- (void)reloadSendLog:(id)sender;
- (IBAction)importRawData:(id)sender;
- (void) setBurnerWindowControllerToNIL;

- (void) refreshColumns;
- (void) outlineViewRefresh;
- (void) matrixInit:(long) noOfImages;
- (IBAction) albumButtons: (id)sender;
- (NSArray*) albumArray;


- (NSArray*) imagesPathArray: (NSManagedObject*) item;

- (void) autoCleanDatabaseFreeSpace:(id) sender;
- (void) autoCleanDatabaseDate:(id) sender;

-(void) refreshDatabase:(id) sender;

-(void) removeAllMounted;

//bonjour
- (void) setBonjourDatabaseValue:(NSManagedObject*) obj value:(id) value forKey:(NSString*) key;
- (BOOL) isCurrentDatabaseBonjour;
- (void)setServiceName:(NSString*) title;
- (IBAction)toggleBonjourSharing:(id) sender;
- (void) bonjourWillPublish;
- (void) bonjourDidStop;
- (IBAction) bonjourServiceClicked:(id)sender;
- (NSString*) currentDatabasePath;
- (void) setBonjourDownloading:(BOOL) v;
- (NSString*) getLocalDCMPath: (NSManagedObject*) obj :(long) no;
- (void) displayBonjourServices;
- (NSString*) localDatabasePath;
- (NSString*) askPassword;
- (NSString*) bonjourPassword;

//DB plugins
- (void)executeFilterDB:(id)sender;

- (NSString *)documentsDirectory;

@end

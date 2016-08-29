/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/



#import <Cocoa/Cocoa.h>
#import "OSIWindowController.h"
#import "XMLOutlineView.h"

@class ViewerController;
@class DCMObject;
@class DICOMFieldMenu;

/** \brief Window Controller for XML parsing */

@interface XMLController : OSIWindowController <NSToolbarDelegate, NSWindowDelegate>
{
    IBOutlet XMLOutlineView		*table;
	IBOutlet NSScrollView		*tableScrollView;
    IBOutlet NSSearchField		*search;
    IBOutlet NSView				*searchView, *dicomEditingView;
	
    unsigned long               srcFileSize;
	NSStringEncoding            srcFileEncoding;
    NSMutableArray				*xmlDcmData, *tree;
    NSData						*xmlData;    
    NSToolbar					*toolbar;	
	NSString					*srcFile;
	NSXMLDocument				*xmlDocument;
    DCMObject                   *dcmDocument;
	DicomImage                  *imObj;
	NSMutableArray				*dictionaryArray;
	
	ViewerController			*viewer;
	
	BOOL						isDICOM, dontClose;
	BOOL						editingActivated;
	BOOL						allowSelectionChange;
	
	int							editingLevel;
	
	IBOutlet NSWindow			*addWindow;
	IBOutlet NSTextField		*addValue;
	
	IBOutlet NSWindow			*validatorWindow;
	IBOutlet NSTextView			*validatorText;
	
	BOOL						dontListenToIndexChange;
    NSMutableArray              *modificationsToApplyArray, *modifiedFields, *modifiedValues;
    NSMutableDictionary         *cache;
    
    DICOMFieldMenu *DICOMField;
    NSString *addDICOMFieldTextField;
}

@property (retain) NSString *addDICOMFieldTextField;
@property (retain) DICOMFieldMenu *DICOMField;

- (BOOL) modificationsToApply;

+ (XMLController*) windowForViewer: (ViewerController*) v;
+ (NSDictionary *) DICOMDefitionsLinks;

- (void) changeImageObject:(DicomImage*) image;
- (id) initWithImage:(DicomImage*) image windowName:(NSString*) name viewer:(ViewerController*) v;
- (void) setupToolbar;
- (NSMenu*) menuForRow:(int) row;
- (IBAction) addDICOMField:(id) sender;
- (IBAction) executeAdd:(id) sender;
- (IBAction) validatorWebSite:(id) sender;
- (IBAction) verify:(id) sender;
- (void) reload:(id) sender;
- (void) reloadFromDCMDocument;
- (BOOL) item: (id) item containsString: (NSString*) s;
- (void) expandAllItems: (id) sender;
- (void) deepExpandAllItems: (id) sender;
- (void) expandAll: (BOOL) deep;
- (void) collapseAllItems: (id) sender;
- (void) deepCollapseAllItems: (id) sender;
- (void) collapseAll: (BOOL) deep;
- (IBAction) setSearchString:(id) sender;
- (NSString*) srcFile;
- (NSString*) stringsSeparatedForNode:(NSXMLNode*) node;
- (void) traverse: (NSXMLNode*) node string:(NSMutableString*) string;
- (void) clickInDefinitionCell: (NSCell*) cell event: (NSEvent*) event;

@property(readonly) NSManagedObject *imObj;
@property(readonly) ViewerController *viewer;
@property(nonatomic) BOOL editingActivated;
@end

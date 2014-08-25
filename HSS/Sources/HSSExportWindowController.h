//
//  HSSExportWindowController.h
//  HSS
//
//  Created by Alessandro Volz on 21.12.11.
//  Copyright (c) 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HSSAPISession;
@class HSSFolder;
@class DicomImage;
@class HSSMedcaseCreation;

@interface HSSExportWindowController : NSWindowController<NSWindowDelegate,NSOutlineViewDelegate,NSMenuDelegate> {
    BOOL _alreadyDidBecomeSheet;
    BOOL _doneFetchingCases;
    NSArray* _images;
    NSArray* _series;
    NSArray* _keyImages;
    HSSAPISession* _session;
    HSSMedcaseCreation* _medcase;
    NSAnimation* _animation;
    // outlets
    HSSFolder* _folder;
    NSOutlineView* _foldersOutline;
    NSTreeController* _treeController;
    NSTextField* _usernameField;
    NSTextField* _nameField;
    NSMatrix* _imagesMatrix;
    NSTextField* _diagnosisField;
    NSTextField* _historyField;
    NSButton* _openCheckbox;
    NSProgressIndicator* _progressIndicator;
    NSScrollView* _foldersOutlineScroll;
    NSButton* _sendButton;
}

@property(retain,readonly) NSArray* images;
@property(retain,readonly) NSArray* keyImages;
@property(retain,readonly) NSArray* series;
@property(retain,readonly) HSSAPISession* session;
@property(retain,readonly) HSSMedcaseCreation* medcase;
@property(retain,readonly) NSAnimation* animation;

@property(assign) IBOutlet HSSFolder* folder;
@property(assign) IBOutlet NSOutlineView* foldersOutline;
@property(assign) IBOutlet NSTreeController* treeController;
@property(assign) IBOutlet NSTextField* usernameField;
@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet NSMatrix* imagesMatrix;
@property(assign) IBOutlet NSTextField* diagnosisField;
@property(assign) IBOutlet NSTextField* historyField;
@property(assign) IBOutlet NSButton* openCheckbox;
@property(assign) IBOutlet NSProgressIndicator* progressIndicator;
@property(assign) IBOutlet NSScrollView* foldersOutlineScroll;
@property(assign) IBOutlet NSButton* sendButton;

- (id)initWithSeries:(NSArray*)series images:(NSArray*)images;
//- (id)initWithPatientKeyImages:(NSArray*)keyImages series:(NSArray*)series images:(NSArray*)images;
- (void)beginSheetOnWindow:(NSWindow*)parentWindow;

- (IBAction)sendAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end

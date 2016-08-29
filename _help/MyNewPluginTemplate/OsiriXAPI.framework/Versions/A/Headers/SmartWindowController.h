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


/** \brief Window Controller for creating smart albums
*
* Window Controller for creating Smart albums
*/

#import <AppKit/AppKit.h>

@class O2DicomPredicateEditor;
@class DicomDatabase;
@class DicomAlbum;

@interface SmartWindowController : NSWindowController {
    DicomDatabase* _database;
    NSString* _name;
    DicomAlbum* _album;
    NSString* _predicateFormat;
    NSTextField* _nameField;
    O2DicomPredicateEditor* _editor;
    NSInteger _mode;
    NSString *_PODActiveString;
}

@property(retain) DicomDatabase* database;
@property(retain, nonatomic) DicomAlbum* album;

@property(retain) NSString* name;
@property(retain) NSString* PODActiveString;
@property(assign) NSPredicate* predicate;
@property(retain,nonatomic) NSString* predicateFormat;

@property NSInteger mode;

@property(readonly) BOOL nameIsValid;
@property(readonly) BOOL predicateFormatIsValid;

@property(readonly) BOOL modeIsPredicate;
@property(readonly) BOOL modeIsSQL;

@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet O2DicomPredicateEditor* editor;

- (id)initWithDatabase:(DicomDatabase*)db;

- (IBAction)cancelAction:(id)sender;
- (IBAction)okAction:(id)sender;
- (IBAction)helpAction:(id)sender;
- (IBAction)testAction:(id)sender;

@end

//
//  HSSCreateSubfolderWindowController.h
//  HSS
//
//  Created by Alessandro Volz on 10.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class HSSFolder;

@interface HSSCreateSubfolderWindowController : NSWindowController {
    HSSFolder* _folder;
    // outlets
    NSTextField* _messageField;
    NSTextField* _nameField;
    NSTextField* _descriptionField;
}

@property(assign) IBOutlet NSTextField* messageField;
@property(assign) IBOutlet NSTextField* nameField;
@property(assign) IBOutlet NSTextField* descriptionField;

-(IBAction)createAction:(id)sender;
-(IBAction)cancelAction:(id)sender;

@end

//
//  HSSCreateSubfolderWindowController.m
//  HSS
//
//  Created by Alessandro Volz on 10.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSCreateSubfolderWindowController.h"
#import "HSSFolder.h"

@interface HSSCreateSubfolderWindowController ()

@property(retain) HSSFolder* folder;

@end

@implementation HSSCreateSubfolderWindowController

@synthesize folder = _folder;
@synthesize messageField = _messageField;
@synthesize nameField = _nameField;
@synthesize descriptionField = _descriptionField;

-(id)initWithFolder:(HSSFolder*)folder {
    if ((self = [super initWithWindowNibName:@"HSSCreateSubfolderWindow"])) {
        self.folder = folder;
    }
    
    return self;
}

-(void)dealloc {
    self.folder = nil;
    [super dealloc];
}

-(void)windowDidLoad {
    [super windowDidLoad];
    [self.messageField setStringValue:[NSString stringWithFormat:self.messageField.stringValue, self.folder.name]];
}

-(IBAction)createAction:(id)sender {
    [NSApp endSheet:self.window];
}

-(IBAction)cancelAction:(id)sender {
    [NSApp endSheet:self.window returnCode:NSRunAbortedResponse];
}


@end

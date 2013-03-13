//
//  DicomUnEnhancerNIfTIAccessoryViewController.h
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 17.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DicomUnEnhancerNIfTIAccessoryViewController : NSViewController {
    NSButton* _outputNamingDateCheckbox;
    NSButton* _outputNamingEventsCheckbox;
    NSButton* _outputNamingIDCheckbox;
    NSButton* _outputNamingProtocolCheckbox;
}

@property(readonly) IBOutlet NSButton* outputNamingDateCheckbox;
@property(readonly) IBOutlet NSButton* outputNamingEventsCheckbox;
@property(readonly) IBOutlet NSButton* outputNamingIDCheckbox;
@property(readonly) IBOutlet NSButton* outputNamingProtocolCheckbox;

-(IBAction)outputNamingChanged:(id)sender;

@end

//
//  DiscPublishingPreferencesBinViewController.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscPublishingPreferencesBinViewController : NSViewController {
	IBOutlet NSTextField* label;
	IBOutlet NSPopUpButton* discTypePopup;
	IBOutlet NSTextField* amountTextField;
	IBOutlet NSPopUpButton* measurePopup;
	NSUInteger bin;
}

@property(readonly) NSPopUpButton* discTypePopup;

@property(readonly) NSUInteger bin;
-(NSString*)mediaTypeTagBindingKey;
-(NSString*)mediaCapacityBindingKey;
-(NSString*)mediaCapacityMeasureTagBindingKey;

-(id)initWithName:(NSString*)name bin:(NSUInteger)bin;

-(void)setSupportBR:(BOOL)flag;

@end

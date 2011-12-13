//
//  DiscPublishingPreferencesBinViewController.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPreferencesBinViewController.h"
#import <OsiriXAPI/NSUserDefaultsController+N2.h>
#import "NSUserDefaultsController+DiscPublishing.h"
#import <JobManager/PTJobManager.h>
#import "DiscPublishingUtils.h"


@interface DiscPublishingPreferencesBinViewController ()

@property(readwrite) NSUInteger bin;

@end


@implementation DiscPublishingPreferencesBinViewController

@synthesize bin, discTypePopup;

-(NSString*)mediaTypeTagBindingKey {
	return [NSUserDefaultsController discPublishingMediaTypeTagBindingKeyForBin:self.bin];
}

-(NSString*)mediaCapacityBindingKey {
	return [NSUserDefaultsController discPublishingMediaCapacityBindingKeyForBin:self.bin];
}

-(NSString*)mediaCapacityMeasureTagBindingKey {
	return [NSUserDefaultsController discPublishingMediaCapacityMeasureTagBindingKeyForBin:self.bin];
}

-(id)initWithName:(NSString*)name bin:(NSUInteger)bind {
	self = [self initWithNibName:@"DiscPublishingPreferencesBinView" bundle:[NSBundle bundleForClass:[self class]]];
	self.bin = bind;
	NSView* view = self.view; // load
	
	[label setStringValue:[NSString stringWithFormat:@"%@:", name]];
	[discTypePopup setAutoenablesItems:NO];
	
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	
	NSDictionary* optionsRaise = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:TRUE], NSRaisesForNotApplicableKeysBindingOption, NULL];
	
	[discTypePopup bind:@"selectedTag" toObject:defaultsController withValuesKey:[self mediaTypeTagBindingKey] options:optionsRaise];
	[amountTextField bind:@"value" toObject:defaultsController withValuesKey:[self mediaCapacityBindingKey] options:optionsRaise];
	[measurePopup bind:@"selectedTag" toObject:defaultsController withValuesKey:[self mediaCapacityMeasureTagBindingKey] options:optionsRaise];
	
	[defaultsController addObserver:self forValuesKey:[self mediaTypeTagBindingKey] options:NULL context:NULL];
	
	return self;
}

-(void)dealloc {
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forValuesKey:[self mediaTypeTagBindingKey]];
	[super dealloc];
}
																						
-(NSUInteger)mediaCapacityBytes {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	return [[defaultsController valueForValuesKey:[self mediaCapacityBindingKey]] floatValue] * [[defaultsController valueForValuesKey:[self mediaCapacityMeasureTagBindingKey]] unsignedIntValue];
}

+(CGFloat)mediaCapacityBytesForMediaType:(UInt32)mediaType {
	switch (mediaType) {
		case DISCTYPE_CD: return 700*1000000; // 700 MB
		case DISCTYPE_DVD: return 4.7*1000000000; // 4.7 GB
		case DISCTYPE_DVDDL: return 8.5*1000000000; // 8.5 GB
		case DISCTYPE_BR: return 25*1000000000; // 25 GB
		case DISCTYPE_BR_DL: return 50*1000000000; // 50 GB
		default: return 0;
	}
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
//	NSLog(@"binView observeValueForKeyPath:%@", keyPath);
	
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

	if ([keyPath hasSuffix:[self mediaTypeTagBindingKey]]) {
		CGFloat bytes = [DiscPublishingPreferencesBinViewController mediaCapacityBytesForMediaType:[[defaultsController valueForValuesKey:[self mediaTypeTagBindingKey]] unsignedIntValue]];
		NSUInteger measure = bytes<1000000000? 1000000 : 1000000000;
		[defaultsController setValue:[NSNumber numberWithFloat:bytes/measure] forKeyPath:DP_valuesKeyPath([self mediaCapacityBindingKey])];
		[defaultsController setValue:[NSNumber numberWithUnsignedInt:measure] forKeyPath:DP_valuesKeyPath([self mediaCapacityMeasureTagBindingKey])];
	}
}

-(void)setSupportBR:(BOOL)flag {
	[[[discTypePopup menu] itemWithTag:DISCTYPE_BR] setHidden:!flag];
	[[[discTypePopup menu] itemWithTag:DISCTYPE_BR_DL] setHidden:!flag];
}

@end

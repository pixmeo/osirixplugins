//
//  DiscPublishingPrefsViewController.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPrefsViewController.h"
#import "DiscPublishingUserDefaultsController.h"
#import "DiscPublishingUserDefaultsController.h"
#import "DiscBurningOptions.h"


@implementation DiscPublishingPrefsViewController

@synthesize burnModeMatrix;
@synthesize selectedModeOptionsBox;
@synthesize patientModeOptions;
@synthesize archivingModeOptions;

-(id)init {
	return [super initWithNibName:@"DiscPublishingPrefsView" bundle:[NSBundle bundleForClass:[self class]]];
}

-(void)awakeFromNib {
	[super awakeFromNib];
	
	[[DiscPublishingUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"mode" options:NSKeyValueObservingOptionInitial context:NULL];
	
	NSImage* warningImage = [[[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"Warning" ofType:@"png"]] autorelease];
	[patientModeZipPasswordWarningView setImage:warningImage];
	[patientModeAuxiliaryDirWarningView setImage:warningImage];
	[archivingModeZipPasswordWarningView setImage:warningImage];
	[archivingModeAuxiliaryDirWarningView setImage:warningImage];
	NSString* zipPasswordToolTip = NSLocalizedString(@"The password must be at least 8 characters long. If this condition is not met then the files will not be zipped.", @"Disc publishing zip password warning");
	[patientModeZipPasswordWarningView setToolTip:zipPasswordToolTip];
	[archivingModeZipPasswordWarningView setToolTip:zipPasswordToolTip];
	NSString* auxDirToolTip = NSLocalizedString(@"The auxiliary directory must point to an existing directory. If the selected directory does not exist then no files are copied.", @"Disc publishing auxiliary directory warning");
	[patientModeAuxiliaryDirWarningView setToolTip:auxDirToolTip];
	[archivingModeAuxiliaryDirWarningView setToolTip:auxDirToolTip];
}

-(void)dealloc {
	[[DiscPublishingUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"mode"];
	[super dealloc];
}

-(DiscPublishingUserDefaultsController*)defaultsController {
	return [DiscPublishingUserDefaultsController sharedUserDefaultsController];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	if (obj == [DiscPublishingUserDefaultsController sharedUserDefaultsController]) {
		if ([keyPath isEqual:@"mode"]) {
			NSView* selectedModeView = NULL;
			switch ([DiscPublishingUserDefaultsController sharedUserDefaultsController].mode) {
				case BurnModeArchiving: selectedModeView = self.archivingModeOptions; break;
				case BurnModePatient: selectedModeView = self.patientModeOptions; break;
			} [self.selectedModeOptionsBox setContentView:selectedModeView];
		}
	}
}

-(IBAction)showPatientModeAnonymizationOptionsSheet:(id)sender {
	//AnonymizationOptionsPanelController* aopc = [[AnonymizationOptionsPanelController alloc] initWithAnonymizationOptions:self.anonymizationOptions];
	//[aopc beginSheetForWindow:self.window];
}

-(void)showDirSelectionSheetForKey:(NSString*)key {
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel beginSheetForDirectory:[self.defaultsController.defaults stringForKey:key] file:NULL types:NULL modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(dirSelectionSheetDidEnd:returnCode:contextInfo:) contextInfo:key];	
}

-(void)dirSelectionSheetDidEnd:(NSOpenPanel*)openPanel returnCode:(int)returnCode contextInfo:(void*)context {
	NSString* key = (id)context;
	if (returnCode == NSOKButton)
		[self.defaultsController.values setValue:openPanel.URL.path forKey:key];
}

-(IBAction)showPatientModeAuxiliaryDirSelectionSheet:(id)sender {
	[self showDirSelectionSheetForKey:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey];
}

-(IBAction)showArchivingModeAuxiliaryDirSelectionSheet:(id)sender {
	[self showDirSelectionSheetForKey:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey];
}

@end


@interface CompressionIsCompress: NSValueTransformer
@end
@implementation CompressionIsCompress

+(Class)transformedValueClass {
	return [NSNumber class];
}

+(BOOL)allowsReverseTransformation {
	return NO;
}

-(id)transformedValue:(id)value {
    return [NSNumber numberWithBool: [value intValue] == CompressionCompress];
}

@end


@interface DiscPublishingIsValidPassword: NSValueTransformer
@end
@implementation DiscPublishingIsValidPassword

+(Class)transformedValueClass {
	return [NSNumber class];
}

+(BOOL)allowsReverseTransformation {
	return NO;
}

-(id)transformedValue:(NSString*)value {
    return [NSNumber numberWithBool: value.length >= 8];
}

@end


@interface DiscPublishingIsValidDirPath: NSValueTransformer
@end
@implementation DiscPublishingIsValidDirPath

+(Class)transformedValueClass {
	return [NSNumber class];
}

+(BOOL)allowsReverseTransformation {
	return NO;
}

-(id)transformedValue:(NSString*)value {
	BOOL isDir, exists = [[NSFileManager defaultManager] fileExistsAtPath:value isDirectory:&isDir];
    return [NSNumber numberWithBool: exists&&isDir];
}

@end














































//
//  DiscPublishingPrefsViewController.mm
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPrefsViewController.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "NSUserDefaultsController+DiscPublishing.h"
#import "DiscBurningOptions.h"
#import "DiscPublishing.h"
#import <OsiriX Headers/N2Operators.h>


@interface NSPathControl (DiscPublishing)
-(NSRect)usedFrame;
@end @implementation NSPathControl (DiscPublishing)

-(NSRect)usedFrame {
	return [self.cell rectOfPathComponentCell:[[self.cell pathComponentCells] lastObject] withFrame:self.frame inView:self];
}

@end


@implementation DiscPublishingPrefsViewController

-(id)init {
	self = [super initWithNibName:@"DiscPublishingPrefsView" bundle:[NSBundle bundleForClass:[self class]]];
	return self;
}

-(void)awakeFromNib {
	[super awakeFromNib];
	
	deltaFromPathControlBRToButtonTL = NSZeroSize+patientModeLabelTemplateEditButton.frame.origin - (patientModeLabelTemplatePathControl.frame.origin+patientModeLabelTemplatePathControl.frame.size);
	
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	[defaultsController addObserver:self forKeyPath:valuesKeyPath(DiscPublishingBurnModeDefaultsKey) options:NSKeyValueObservingOptionInitial context:NULL];
	[defaultsController addObserver:self forKeyPath:valuesKeyPath(DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey) options:NSKeyValueObservingOptionInitial context:NULL];
	[defaultsController addObserver:self forKeyPath:valuesKeyPath(DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey) options:NSKeyValueObservingOptionInitial context:NULL];
	
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
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self];
	[super dealloc];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context {
	NSUserDefaultsController* defaultsController = [NSUserDefaultsController sharedUserDefaultsController];
	if (obj == defaultsController) {
		if ([keyPath isEqual:valuesKeyPath(DiscPublishingBurnModeDefaultsKey)])
			switch ([[defaultsController valueForKeyPath:keyPath] intValue]) {
				case BurnModeArchiving: [burnModeOptionsBox setContentView:archivingModeOptionsView]; break;
				case BurnModePatient: [burnModeOptionsBox setContentView:patientModeOptionsView]; break;
			}
		else if ([keyPath isEqual:valuesKeyPath(DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey)])
			[patientModeLabelTemplateEditButton setFrameOrigin:RectBR([patientModeLabelTemplatePathControl usedFrame])+deltaFromPathControlBRToButtonTL];
		else if ([keyPath isEqual:valuesKeyPath(DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey)])
			[archivingModeLabelTemplateEditButton setFrameOrigin:RectBR([archivingModeLabelTemplatePathControl usedFrame])+deltaFromPathControlBRToButtonTL];
	}
}

-(IBAction)showPatientModeAnonymizationOptionsSheet:(id)sender {
	//AnonymizationOptionsPanelController* aopc = [[AnonymizationOptionsPanelController alloc] initWithAnonymizationOptions:self.anonymizationOptions];
	//[aopc beginSheetForWindow:self.window];
}

-(void)fileSelectionSheetDidEnd:(NSOpenPanel*)openPanel returnCode:(int)returnCode contextInfo:(void*)context {
	NSString* key = (id)context;
	if (returnCode == NSOKButton) {
		[[NSUserDefaultsController sharedUserDefaultsController] setValue:openPanel.URL.path forValuesKey:key];
	}
}

-(void)showDirSelectionSheetForKey:(NSString*)key {
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	NSString* location = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	
	[openPanel beginSheetForDirectory:[location stringByDeletingLastPathComponent] file:[location lastPathComponent] types:NULL modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(fileSelectionSheetDidEnd:returnCode:contextInfo:) contextInfo:key];	
}

-(IBAction)showPatientModeAuxiliaryDirSelectionSheet:(id)sender {
	[self showDirSelectionSheetForKey:DiscPublishingPatientModeAuxiliaryDirectoryPathDefaultsKey];
}

-(IBAction)showArchivingModeAuxiliaryDirSelectionSheet:(id)sender {
	[self showDirSelectionSheetForKey:DiscPublishingArchivingModeAuxiliaryDirectoryPathDefaultsKey];
}

-(void)showFileSelectionSheetForKey:(NSString*)key fileTypes:(NSArray*)types defaultLocation:(NSString*)defaultLocation {
	NSOpenPanel* openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setTreatsFilePackagesAsDirectories:NO];
	
	NSString* location = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	if (!location) location = defaultLocation;
	
	[openPanel beginSheetForDirectory:[location stringByDeletingLastPathComponent] file:[location lastPathComponent] types:types modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(fileSelectionSheetDidEnd:returnCode:contextInfo:) contextInfo:key];	
}

-(void)showDiscCoverFileSelectionSheetForKey:(NSString*)key {
	[self showFileSelectionSheetForKey:key fileTypes:[NSArray arrayWithObject:@"dcover"] defaultLocation:[DiscPublishing discCoverTemplatesDirPath]];
}

-(IBAction)showPatientModeDiscCoverFileSelectionSheet:(id)sender {
	[self showDiscCoverFileSelectionSheetForKey:DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey];
}

-(IBAction)showArchivingModeDiscCoverFileSelectionSheet:(id)sender {
	[self showDiscCoverFileSelectionSheetForKey:DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey];
}

-(void)editDiscCoverFileWithKey:(NSString*)key {
	NSString* location = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	
	if (!location || ![[NSFileManager defaultManager] fileExistsAtPath:location]) {
		location = [[DiscPublishing discCoverTemplatesDirPath] stringByAppendingPathComponent:@"Template.dcover"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:location])
			[[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"Standard.dcover"] toPath:location error:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] setValue:location forValuesKey:key];
	}
	
	[[NSWorkspace sharedWorkspace] openFile:location];
}

-(IBAction)editPatientModeDiscCoverFile:(id)sender {
	[self editDiscCoverFileWithKey:DiscPublishingPatientModeDiscCoverTemplatePathDefaultsKey];
}

-(IBAction)editArchivingModeDiscCoverFile:(id)sender {
	[self editDiscCoverFileWithKey:DiscPublishingArchivingModeDiscCoverTemplatePathDefaultsKey];
}

-(IBAction)mediaCapacityValueChanged:(id)sender {
	// do nothing
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


@implementation DiscPublishingIsValidPassword

+(Class)transformedValueClass {
	return [NSNumber class];
}

+(BOOL)allowsReverseTransformation {
	return NO;
}

+(BOOL)isValidPassword:(NSString*)value {
	return value.length >= 8;	
}

-(id)transformedValue:(NSString*)value {
    return [NSNumber numberWithBool:[DiscPublishingIsValidPassword isValidPassword:value]];
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


@interface DiscCoverTemplatePathTransformer: NSValueTransformer
@end
@implementation DiscCoverTemplatePathTransformer

+(Class)transformedValueClass {
	return [NSString class];
}

+(BOOL)allowsReverseTransformation {
	return NO;
}

-(id)transformedValue:(NSString*)value {
	if (!value | ![[NSFileManager defaultManager] fileExistsAtPath:value])
		return @"/Standard Disc Cover Template";
	return value;
}

@end












































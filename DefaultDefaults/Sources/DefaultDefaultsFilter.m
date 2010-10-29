#import "DefaultDefaultsFilter.h"
#import <OsiriX Headers/DicomImage.h>
#import <OsiriX Headers/DicomAlbum.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX Headers/DicomSeries.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/DicomSeries.h>

@implementation DefaultDefaultsFilter

-(void)initPlugin {
	NSDictionary* defaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"defaults" ofType:@"plist"]];
	
	NSLog(@"Setting defaults:");
	for (NSString* key in defaults) {
		NSLog(@"- %@ is %@", key, [[defaults objectForKey:key] description]);
		[[NSUserDefaults standardUserDefaults] setObject:[defaults objectForKey:key] forKey:key];
	}
}

-(long)filterImage:(NSString*)menuTitle {
	return 0;
}

@end

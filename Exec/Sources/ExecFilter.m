#import "ExecFilter.h"
#import <OsiriX Headers/DicomImage.h>
#import <OsiriX Headers/DicomAlbum.h>
#import <OsiriX Headers/DicomStudy.h>
#import <OsiriX Headers/DicomSeries.h>
#import <OsiriX/DCMAttributeTag.h>
#import <OsiriX/DCMAttribute.h>
#import <OsiriX/DCMObject.h>
#import <OsiriX Headers/BrowserController.h>
#import <OsiriX Headers/DicomSeries.h>

@implementation ExecFilter

-(void)initPlugin {
}

-(void)filesIn:(id)obj into:(NSMutableArray*)files {
	if ([obj isKindOfClass:[NSArray class]])
		for (id sobj in obj)
			[self filesIn:sobj into:files];
	else
		if ([obj isKindOfClass:[DicomAlbum class]])
			for (id study in ((DicomAlbum*)obj).studies)
				[self filesIn:study into:files];
		else
			if ([obj isKindOfClass:[DicomStudy class]])
				for (id series in ((DicomStudy*)obj).series)
					[self filesIn:series into:files];
			else
				if ([obj isKindOfClass:[DicomSeries class]])
					[files addObjectsFromArray:[((DicomSeries*)obj).images allObjects]];
}

-(NSArray*)filesIn:(NSArray*)arr {
	NSMutableArray* files = [NSMutableArray array];
	[self filesIn:arr into:files];
	return files;
}

-(NSString*)replacementForKey:(NSString*)str forImage:(DicomImage*)dicomImage asDcmObj:(DCMObject*)dcmObj menuTitle:(NSString*)menuTitle {
	if ([str isEqual:@"BundleResourcesPath"])
		return [[NSBundle bundleForClass:[self class]] resourcePath];
	
	if ([str isEqual:@"DicomFilePath"])
		return dicomImage.completePathResolved;
	
	if ([str isEqual:@"MenuTitle"])
		return menuTitle;
	
	DCMAttributeTag* tag = [DCMAttributeTag tagWithName:str];
	if (!tag) tag = [DCMAttributeTag tagWithTagString:str];
	if (tag && tag.group && tag.element) {
		DCMAttribute* attr = [dcmObj attributeForTag:tag];
		NSString* val = [[attr value] description];
		if (val) return val;
	}
	
	NSLog(@"Warning: key %@ unrecognized", str);
	return [NSString stringWithFormat:@"%%%@%%", str];
}

-(long)filterImage:(NSString*)menuTitle {
	NSDictionary* info = [[NSBundle bundleForClass:[self class]] infoDictionary];
	
	NSArray* dicomImages = [self filesIn:[[BrowserController currentBrowser] databaseSelection]];
	NSArray* execParamsTemplate = [info objectForKey:@"Command"];
	
	for (DicomImage* dicomImage in dicomImages) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

		DCMObject* dcmObj = [DCMObject objectWithContentsOfFile:dicomImage.completePathResolved decodingPixelData:NO];
		
		NSMutableArray* params = [[execParamsTemplate mutableCopy] autorelease];
		for (int i = 0; i < params.count; ++i) {
			NSMutableString* str = [[[params objectAtIndex:i] mutableCopy] autorelease];
			
			NSUInteger from = 0;
			NSRange r1;
			while (from < str.length && (r1 = [str rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(from, str.length-from)]).length) {
				NSRange r2 = [str rangeOfString:@"%" options:NSLiteralSearch range:NSMakeRange(r1.location+r1.length, str.length-(r1.location+r1.length))];
				if (!r2.length) break;
				r1.length = r2.location+r2.length-r1.location;
				NSString* replaceFrom = [str substringWithRange:NSMakeRange(r1.location+1, r1.length-2)];
				NSString* replaceTo = [self replacementForKey:replaceFrom forImage:dicomImage asDcmObj:dcmObj menuTitle:menuTitle];
				[str replaceCharactersInRange:r1 withString:replaceTo];
				from = r1.location+replaceTo.length;
			}
			
			[params replaceObjectAtIndex:i withObject:str];
		}
		
		NSString* path = [[[params objectAtIndex:0] retain] autorelease];
		[params removeObjectAtIndex:0];
		
		NSLog(@"Executing %@ with params [%@]", path, [params componentsJoinedByString:@", "]);
		[NSTask launchedTaskWithLaunchPath:path arguments:params];

		[pool release];
	}
	
	return 0;
}

@end

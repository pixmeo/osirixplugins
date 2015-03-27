//
//  ArthroplastyTemplatingWindowController+List.mm
//  Arthroplasty Templating II
//
//  Created by Alessandro Volz on 08.09.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import "ArthroplastyTemplatingWindowController+Templates.h"
#import "ArthroplastyTemplateFamily.h"
#import "InfoTxtTemplate.h"
#import <OsiriXAPI/NSFileManager+N2.h>

@implementation ArthroplastyTemplatingWindowController (Templates)

+(NSArray*)templatesAtPath:(NSString*)dirpath {
	NSMutableArray* templates = [NSMutableArray array];
	
    NSDictionary* classes = [NSDictionary dictionaryWithObjectsAndKeys:
                             [InfoTxtTemplate class], @"txt",
                             nil];
    
	BOOL isDirectory, exists = [[NSFileManager defaultManager] fileExistsAtPath:dirpath isDirectory:&isDirectory];
	if (exists && isDirectory) {
		NSDirectoryEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:dirpath];
		NSString* sub; while (sub = [e nextObject]) {
			NSString* subpath = [dirpath stringByAppendingPathComponent:sub];
			[[NSFileManager defaultManager] fileExistsAtPath:subpath isDirectory:&isDirectory];
			if (!isDirectory && [subpath rangeOfString:@".disabled/"].location == NSNotFound) {
                for (NSString* ext in classes)
                    if ([[subpath pathExtension] isEqualToString:ext])
                        [templates addObjectsFromArray:[[classes objectForKey:ext] templatesFromFileAtPath:subpath]];
            }
		}
	}
	
	return templates;
}

-(void)awakeTemplates {
	[_templates removeAllObjects];
    
    NSArray* paths = [NSArray arrayWithObjects:
                      [[NSBundle bundleForClass:[self class]] resourcePath],
                      [[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kUserDomain] stringByAppendingPathComponent:@"OsiriX/HipArthroplastyTemplating"],
                      [[[NSFileManager defaultManager] findSystemFolderOfType:kApplicationSupportFolderType forDomain:kLocalDomain] stringByAppendingPathComponent:@"OsiriX/HipArthroplastyTemplating"],
                      nil];
	for (NSString* path in paths) {
        for (NSString* sub in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL])
            if ([sub hasSuffix:@"Templates"]) {
                NSString* tdpath = [NSFileManager.defaultManager destinationOfAliasOrSymlinkAtPath:[path stringByAppendingPathComponent:sub]];
                [_templates addObjectsFromArray:[[self class] templatesAtPath:tdpath]];
                NSString* plistpath = [tdpath stringByAppendingPathComponent:@"_Bounds.plist"];
                if ([NSFileManager.defaultManager fileExistsAtPath:plistpath])
                    [_presets addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:plistpath]];
            }
    }
	
	// fill _families from _templates
	for (unsigned i = 0; i < [_templates count]; ++i) {
		ArthroplastyTemplate* templat = [_templates objectAtIndex:i];
		BOOL included = NO;
		
		for (unsigned i = 0; i < [[_familiesArrayController content] count]; ++i) {
			ArthroplastyTemplateFamily* family = [[_familiesArrayController content] objectAtIndex:i];
			if ([family matches:templat]) {
				[family add:templat];
				included = YES;
				break;
			}
		}
		
		if (included)
			continue;
		
		[_familiesArrayController addObject:[[[ArthroplastyTemplateFamily alloc] initWithTemplate:templat] autorelease]];
	}
	
	//	[_familiesArrayController rearrangeObjects];
	[_familiesTableView reloadData];
}

-(ArthroplastyTemplate*)templateAtPath:(NSString*)path {
	for (unsigned i = 0; i < [_templates count]; ++i)
		if ([[[_templates objectAtIndex:i] path] isEqualToString:path])
			return [_templates objectAtIndex:i];
	return NULL;
}

//-(ArthroplastyTemplate*)templateAtIndex:(int)index {
//	return [[_templatesArrayController arrangedObjects] objectAtIndex:index];	
//}

-(ArthroplastyTemplateFamily*)familyAtIndex:(int)index {
	return (index >= 0 && index < (int)[[_familiesArrayController content] count])? [[_familiesArrayController arrangedObjects] objectAtIndex:index] : NULL;	
}

//-(ArthroplastyTemplate*)selectedTemplate {
//	return [self templateAtIndex:[_templatesTableView selectedRow]];
//}

-(ArthroplastyTemplateFamily*)selectedFamily {
	return [self familyAtIndex:[_familiesTableView selectedRow]];
}

-(ArthroplastyTemplate*)currentTemplate {
	return [[self selectedFamily] templateMatchingSize:[_sizes titleOfSelectedItem] side:self.side];
}

-(void)filterTemplates {
    NSMutableArray* subpredicates = [NSMutableArray arrayWithObject:[NSPredicate predicateWithValue:YES]];
    
    for (NSString* str in [[_searchField stringValue] componentsSeparatedByString:@" "]) {
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (str.length) {
            BOOL no = NO;
            if ([str characterAtIndex:0] == '!') {
                no = YES;
                str = [str substringFromIndex:1];
            }

            NSPredicate* subpredicate = [NSPredicate predicateWithFormat:@"((fixation contains[c] %@) OR (group contains[c] %@) OR (manufacturer contains[c] %@) OR (modularity contains[c] %@) OR (name contains[c] %@) OR (patientSide contains[c] %@) OR (surgery contains[c] %@) OR (type contains[c] %@))", str, str, str, str, str, str, str, str];
            if (no)
                subpredicate = [NSCompoundPredicate notPredicateWithSubpredicate:subpredicate];
            
            [subpredicates addObject:subpredicate];
        }
    }
    
    [_familiesArrayController setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:subpredicates]];

	//	[_familiesArrayController rearrangeObjects];
	[_familiesTableView noteNumberOfRowsChanged];
	//	[_familiesTableView reloadData];

    [self.window orderFront:self];
    [self setFamily:_familiesTableView];
}

-(BOOL)setFilter:(NSString*)string {
	[_searchField setStringValue:string];
	[self searchFilterChanged:self];
	return [[_familiesArrayController arrangedObjects] count] > 0;
}

-(IBAction)searchFilterChanged:(id)sender {
	[self filterTemplates];
}

@end

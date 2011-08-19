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

@implementation ArthroplastyTemplatingWindowController (Templates)

-(void)awakeTemplates {
	[_templates removeAllObjects];
	// [_templates addObjectsFromArray:[ZimmerTemplate bundledTemplates]];
	// [_templates addObjectsFromArray:[MEDACTATemplate bundledTemplates]];
	NSString* path = [[NSBundle bundleForClass:[self class]] resourcePath];
	NSDirectoryEnumerator* e = [[NSFileManager defaultManager] enumeratorAtPath:path];
	while (NSString* sub = [e nextObject])
		if ([sub hasSuffix:@"Templates"])
			if ([sub rangeOfString:@"Zimmer"].location != NSNotFound)
				[_templates addObjectsFromArray:[InfoTxtTemplate templatesAtPath:[path stringByAppendingPathComponent:sub]]];
			else [_templates addObjectsFromArray:[InfoTxtTemplate templatesAtPath:[path stringByAppendingPathComponent:sub]]];
	
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
	return [[self selectedFamily] template:[_sizes indexOfSelectedItem]];
}

-(void)filterTemplates {
	NSString* filter = [_searchField stringValue];
	
	if ([filter length] == 0) {
		[_familiesArrayController setFilterPredicate:[NSPredicate predicateWithValue:YES]];
	} else {
		NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fixation contains[c] %@) OR (group contains[c] %@) OR (manufacturer contains[c] %@) OR (modularity contains[c] %@) OR (name contains[c] %@) OR (placement contains[c] %@) OR (surgery contains[c] %@) OR (type contains[c] %@)", filter, filter, filter, filter, filter, filter, filter, filter];
		[_familiesArrayController setFilterPredicate:predicate];
	}
	
	//	[_familiesArrayController rearrangeObjects];
	[_familiesTableView noteNumberOfRowsChanged];
	//	[_familiesTableView reloadData];
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

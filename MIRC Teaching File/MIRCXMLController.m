//
//  MIRCXMLController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/10/05.
//  Copyright 2005 Macrad,LLC. All rights reserved.
//

#import "MIRCXMLController.h"
#import "MIRCAuthor.h"
#import "MIRCQuiz.h"
#import "MIRCQuestion.h"
#import "MIRCImage.h"
#import "MIRCPatient.h"
#import "MIRCAuthor.h"
#import "MIRCAuthorController.h"
#import "MIRCQuestionWindowController.h"
#import "MIRCImageWindowController.h"
#import "WhackedTVController.h"
#import "MIRCThumbnail.h"
#import <QTKit/QTKit.h>
#import "AddressBook/AddressBook.h"
#import "WindowLayoutManager.h"

@implementation MIRCXMLController

- (id)initWithTeachingFile:(id)teachingFile  managedObjectContext:(NSManagedObjectContext *)context;{
	if (self = [super initWithWindowNibName:@"MIRCXMLEditor"]) {
		_teachingFile = teachingFile;
		_managedObjectContext = context;
		// set up default values for TF, if this is our first time through
		NSString *name = [_teachingFile valueForKey:@"name"];
		if (![_teachingFile valueForKey:@"display"])
			[_teachingFile setValue:@"mstf" forKey:@"display"];
		if (![_teachingFile valueForKey:@"title"])
			[_teachingFile setValue:name forKey:@"title"];
		if (![_teachingFile valueForKey:@"altTitle"])
			[_teachingFile setValue:name forKey:@"altTitle"];
		if ([[_teachingFile valueForKey:@"authors"] count] <  1){
			[self createAuthor];
		}	
		id currentStudy = [[WindowLayoutManager sharedWindowLayoutManager] currentStudy];
		if (![_teachingFile valueForKey:@"age"])
			[_teachingFile setValue:[currentStudy yearOldAcquisition] forKey:@"age"];
		if (![_teachingFile valueForKey:@"sex"])
			[_teachingFile setValue:[currentStudy valueForKey:@"patientSex"] forKey:@"sex"];
		
		if ([_teachingFile valueForKey:@"discussionMovie"]) {
			NSError *error;
			_discussionMovie = [[QTMovie movieWithData:[_teachingFile valueForKey:@"discussionMovie"] error:&error] retain];
			[discussionMovieView setMovie:_discussionMovie];
		}
		if ([_teachingFile valueForKey:@"historyMovie"]) {
			NSError *error;
			_historyMovie = [[QTMovie movieWithData:[_teachingFile valueForKey:@"historyMovie"] error:&error] retain];
			[historyMovieView setMovie:_historyMovie];
		}
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMovie:) name:@"MIRCNewMovie" object:nil];
	}
	return self;
}


#pragma mark Teaching File
- (id)teachingFile{
	return _teachingFile;
}

- (void)setTeachingFile:(id)teachingFile{
	_teachingFile = teachingFile;
}

- (id)authors{
	return [_teachingFile valueForKey:@"authors"];
}

#pragma mark Author
- (id)createAuthor{
	ABPerson *me = [[ABAddressBook sharedAddressBook] me];
	id  author =  [NSEntityDescription insertNewObjectForEntityForName:@"author"  inManagedObjectContext:_managedObjectContext];
	[author setValue:_teachingFile forKey:@"teachingFile"];
	[author setValue:[NSString stringWithFormat: @"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty]] forKey:@"name"];
	ABMultiValue *phones = [me valueForProperty:kABPhoneProperty]; 
	id value = [phones valueAtIndex:[phones indexForIdentifier: [phones primaryIdentifier]]];
	[author setValue:value forKey:@"phone"];
	ABMultiValue *emails = [me valueForProperty:kABEmailProperty]; 
	value = [emails valueAtIndex:[emails indexForIdentifier: [emails primaryIdentifier]]];
	[author setValue:value forKey:@"email"];
	[author setValue:[me valueForProperty:kABOrganizationProperty] forKey:@"affilitation"];
	return author;
}

- (void)windowDidLoad{

}

- (NSManagedObjectContext *)managedObjectContext{
	return _managedObjectContext;
}


#pragma mark Movies
- (QTMovie *)historyMovie{
	return _historyMovie;
}

- (void)setHistoryMovie:(QTMovie *)movie{
	[_historyMovie release];
	_historyMovie = [movie retain];
	//[_teachingFile setValue:[_historyMovie movieFormatRepresentation] forKey:@"historyMovie"];
	[historyMovieView setMovie:_historyMovie];
}

- (QTMovie *)discussionMovie{
	return _discussionMovie;
}

- (void)setDiscussionMovie:(QTMovie *)movie{
	[_discussionMovie release];
	_discussionMovie = [movie retain];
	//[_teachingFile setValue:[_discussionMovie movieFormatRepresentation] forKey:@"discussionMovie"];
	[discussionMovieView setMovie:_discussionMovie];
}

 - (void)newMovie:(NSNotification *)note{
	NSString *path = [[note userInfo] objectForKey:@"moviePath"];
	QTMovie *movie = nil;
	if ([QTMovie canInitWithFile:path])
		movie = [QTMovie movieWithFile:path error:nil];
	if ([[path lastPathComponent] isEqualToString:@"history.mov"]) {
		[self setHistoryMovie:movie];
		[_teachingFile setValue:[NSData dataWithContentsOfFile:path] forKey:@"historyMovie"];
	}
	else if ([[path lastPathComponent] isEqualToString:@"discussion.mov"]) {
		[self setDiscussionMovie:movie];
		[_teachingFile setValue:[NSData dataWithContentsOfFile:path] forKey:@"discussionMovie"];
	}
	[[NSFileManager defaultManager] removeFileAtPath:(NSString *)path handler:nil];
 }
 
 - (IBAction)captureHistory:(id)sender{
	NSString *moviePath = [@"/tmp" stringByAppendingPathComponent:@"history.mov"];
	if (whackedController)
		[whackedController setPath:moviePath];
	else
		whackedController = [[WhackedTVController alloc] initWithPath:moviePath];
	//[NSApp beginSheet:[whackedController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:@selector(sheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
	[whackedController showWindow:self];
}

- (IBAction)captureDiscussion:(id)sender{
	NSString *moviePath = [@"/tmp"  stringByAppendingPathComponent:@"discussion.mov"];
	if (whackedController)
		[whackedController setPath:moviePath];
	else
		whackedController = [[WhackedTVController alloc] initWithPath:moviePath];
	//[NSApp beginSheet:[whackedController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:@selector(sheetDidEnd: returnCode: contextInfo:) contextInfo:nil];
	[whackedController showWindow:self];
}





- (void)dealloc {
	[_historyMovie release];
	[_discussionMovie release];
	[super dealloc];
}




/*
- (id) initWithPath: (NSString *)folder{
	if (self = [super initWithWindowNibName:@"MIRCXMLEditor"]) {
		NSError *error;
		_path = [folder retain];
		_xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[folder stringByAppendingPathComponent:@"teachingFile.xml"]] options:NSXMLDocumentTidyXML error:&error];
		if (!_xmlDocument){
			NSLog(@"new XMLDocument");
			NSXMLElement *root = [[[NSXMLElement alloc] initWithName:@"MIRCdocument"] autorelease];
			_xmlDocument = [[NSXMLDocument alloc] initWithRootElement:root];
			[root addAttribute:[NSXMLNode attributeWithName:@"display" stringValue:@"mstf"]];
			[root addChild:[NSXMLNode elementWithName:@"title" stringValue:[folder lastPathComponent]]];
			[root addChild:[NSXMLNode elementWithName:@"alternative-title" stringValue:[folder lastPathComponent]]];
			[root addChild:[self createAuthor]];
			[root addChild:[NSXMLNode elementWithName:@"abstract"]];
			[root addChild:[NSXMLNode elementWithName:@"alternative-abstract"]];
			[root addChild:[NSXMLNode elementWithName:@"keywords"]];
			//sections
			//History
			NSXMLElement *section = [NSXMLNode elementWithName:@"section"];
			[section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"History"]];
			[root addChild:section];
			//Images
			section = [NSXMLNode elementWithName:@"image-section"];
			[section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"Images"]];
			[root addChild:section];
			//Discussion
			section = [NSXMLNode elementWithName:@"section"];
			[section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"Discussion"]];
			[root addChild:section];
			//Quiz
			section = [NSXMLNode elementWithName:@"section"];
			[section addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"Quiz"]];
			[root addChild:section];

			[self saveWithAlert:NO];
			
		}
		NSMutableArray *images = [NSMutableArray array];
		NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:_path];
		NSString *file;
		NSLog(@"path: %@", _path);
		while (file = [dirEnum nextObject]) {
			NSLog(@"file: %@", file);
			NSLog(@"adding images");
			if (!([file hasPrefix:@"."] || [file hasSuffix:@"xml"]))
				[images addObject:[MIRCThumbnail imageWithPath:[_path stringByAppendingPathComponent:file]]];
		}
		_images = [images retain];
		NSLog(@"look for movies");
		_historyMovie = nil;
		if ([QTMovie canInitWithFile:[_path stringByAppendingPathComponent:@"history.mov"]])
			[self setHistoryMovie:[QTMovie movieWithFile:[_path stringByAppendingPathComponent:@"history.mov"] error:nil]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMovie:) name:@"MIRCNewMovie" object:nil];
	}
	NSLog(@"Init XML Controller");
	return self;
}

- (MIRCAuthor *)createAuthor{
		ABPerson *me = [[ABAddressBook sharedAddressBook] me];
		MIRCAuthor *author = [MIRCAuthor author];
		[author setAuthorName:[NSString stringWithFormat: @"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty]]];
		ABMultiValue *phones = [me valueForProperty:kABPhoneProperty]; 
		id value = [phones valueAtIndex:[phones indexForIdentifier: [phones primaryIdentifier]]];
		[author setPhone:value];
		ABMultiValue *emails = [me valueForProperty:kABEmailProperty]; 
		value = [emails valueAtIndex:[emails indexForIdentifier: [emails primaryIdentifier]]];
		[author setEmail:value];
		[author setAffiliation:[me valueForProperty:kABOrganizationProperty]];
		return author;
}




- (NSXMLDocument *)xmlDocument{
	return _xmlDocument;
}

- (NSXMLElement *)rootElement{
	return [_xmlDocument rootElement];
}
- (NSArray *)sections{
	return [[self rootElement] elementsForName:@"section"];
}

- (NSXMLElement *)sectionWithHeading:(NSString *)heading{
	NSArray *array = [self sections];
	NSEnumerator *enumerator = [array objectEnumerator];
	NSXMLElement *node;
	while (node = [enumerator nextObject]){
		NSXMLNode *attr = [node attributeForName:@"heading"];
		if ([[attr stringValue] isEqual:heading])
			return node;
	}
	node = [NSXMLNode elementWithName:@"section"];
	[node addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:heading]];
	[[self rootElement] addChild:node];
	return node;
}

- (NSXMLElement *)historySection{
	return [self sectionWithHeading:@"History"];
}
- (NSXMLElement *)imageSection{
	NSArray *array = [[self rootElement] elementsForName:@"image-section"];
	if ([array count] > 0)
		return [array objectAtIndex:0];
	NSXMLElement *	node = [NSXMLNode elementWithName:@"image-section"];
	[node addAttribute:[NSXMLNode attributeWithName:@"heading" stringValue:@"Images"]];
	[[self rootElement] addChild:node];
	
	return nil;
}
- (NSXMLElement *)discussionSection{
	return [self sectionWithHeading:@"Discussion"];
}

- (NSXMLElement *)quizSection{
	return [self sectionWithHeading:@"Quiz"];
}

-(NSXMLNode *)nodeFromXML:(NSString *)xml withName:(NSString *)name{
	NSError *error;
	NSString *xmlString = [NSString stringWithFormat:@"<%@>%@</%@>",name, xml, name];
	NSXMLElement *node = [[[NSXMLElement alloc] initWithXMLString:xmlString error:&error] autorelease];
	if (!error)
		return node;
	NSLog(@"Error reading XML: %@", [error description]);
	return nil;
}

- (void)insertNode:(NSXMLElement *)node  intoNode:(NSXMLElement *)destination atIndex:(int)index{
	int childCount = [destination childCount];
	if (childCount > index)
		[destination insertChild:node atIndex:index]; 
	else {
		//NSLog(@"add Node: %@", [node description]);
		[destination addChild:node];
	}
}

- (NSString *)stringValueForNodeNamed:(NSString *)name  parentNode:(NSXMLElement *)parent{
	NSString *string =  nil;
	NS_DURING
	NSArray *array = [parent elementsForName:name];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		string =  [node stringValue];
	}
	NS_HANDLER
		string = nil;
	NS_ENDHANDLER
	return string;
}

- (IBAction)chooseRefDoc:(id)sender{

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel beginSheetForDirectory:[self folder] 
		file:lastPathComponent 
		modalForWindow:[self window]
		modalDelegate:self 
		didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
		contextInfo:nil];

}


- (NSString *)refDoc{
	NSXMLNode *attr = [[self rootElement] attributeForName:@"docref"];
	//NSLog(@"refDoc:%@", [attr stringValue]);
	return [attr stringValue];
}

- (void)setRefDoc:(NSString *)refDoc{
	if (refDoc && ![refDoc isEqualToString:@""]) {
		NSLog(@"setRefDoc: %@", refDoc);
		NSXMLNode *attr = [[self rootElement] attributeForName:@"docref"];
		if (attr) {
			[attr setStringValue:refDoc];
			//[[self rootElement] addAttribute:attr];
		}
		else {
			attr = [NSXMLNode attributeWithName:@"docref" stringValue:refDoc];
			[[self rootElement] addAttribute:attr];
		}
		//remove display attribute
		attr = [[self rootElement] attributeForName:@"display"];
		[attr detach];
	}
	else {
		NSXMLNode *attr = [[self rootElement] attributeForName:@"docref"];
		[attr detach];
		[[self rootElement]  addAttribute:[NSXMLNode attributeWithName:@"display" stringValue:@"mstf"]];
	}
}

-(void)setAuthors:(NSArray *)authors{
	NS_DURING
	NSArray *array = [[self rootElement] elementsForName:@"author"];
	NSXMLNode *node = nil;
	int index= 0;
	if ([array count] > 0){
		int i;
		node = [array objectAtIndex:0];
		NSArray *children = [[self rootElement]  children];
		i = [children indexOfObject:node];
		NSEnumerator *enumerator = [array objectEnumerator];
		while (node = [enumerator nextObject]) {
			index = [children indexOfObject:node];
			[[self rootElement] removeChildAtIndex:index];
		}
		[[self rootElement] insertChildren:authors atIndex:i];

	}
	else {
		//no authors found;
		//NSLog(@"Adding new Authors");
		if ([[self rootElement] childCount] > 2)
			[[self rootElement] insertChildren:authors atIndex:2]; 
		 else if ([[self rootElement] childCount] > 0)
			[[self rootElement] insertChildren:authors atIndex:[[self rootElement] childCount] - 1]; 
		else
			[[self rootElement] insertChildren:authors atIndex:0];
	}
		
	NS_HANDLER
			NSLog(@"Exception: %@", [localException name]);
	NS_ENDHANDLER

	
	
}
	
-(NSArray *)authors{
	return [[self rootElement] elementsForName:@"author"];
}



- (NSString *)title{
	return [self stringValueForNodeNamed:@"title"  parentNode:[self rootElement]];
}

- (void)setTitle:(NSString *)title{
	NSXMLNode *node = nil;
	NSArray *array = [[self rootElement] elementsForName:@"title"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLNode elementWithName:@"title" stringValue:title];
		[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:0];
	}
	else
		[node setStringValue:title];
}

- (NSString *)altTitle{
	return [self stringValueForNodeNamed:@"alternative-title"  parentNode:[self rootElement]];
}

- (void)setAltTitle:(NSString *)title{
	NSXMLNode *node = nil;
	NSArray *array = [[self rootElement] elementsForName:@"alternative-title"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLNode elementWithName:@"alternative-title" stringValue:title];
		[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:1];
	}
	else
		[node setStringValue:title];
}

- (NSString *)keywords{
	return [self stringValueForNodeNamed:@"keywords"  parentNode:[self rootElement]];
}

- (void)setKeywords:(NSString *)keywords{
	NS_DURING
	NSLog(@"set Keywords: %@", keywords);
	NSXMLNode *node = nil;
	NSArray *array = [[self rootElement] elementsForName:@"keywords"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLNode elementWithName:@"keywords" stringValue:keywords];
		[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:6];	
	}
	else
		[node setStringValue:keywords];
	NS_HANDLER
	NS_ENDHANDLER
}

- (NSAttributedString *)abstractText{
	
	//this is a little more complex because we need to parse the html elements inside.
	NSArray *array = [[self rootElement] elementsForName:@"abstract"];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		NSLog(@"abstract: %@", [node stringValue]);
		NSArray *children = [node children];
		if ([children count] > 0) {
			NSEnumerator *enumerator = [children objectEnumerator];
			NSXMLNode *child;
			NSMutableString *string = [NSMutableString string];
			while (child = [enumerator nextObject]){
				[string appendString:[child XMLString]];
			}
			return [[[NSAttributedString alloc] initWithString:string] autorelease];
		}
		else{
			
			return [[[NSAttributedString alloc] initWithString:[node stringValue]] autorelease];
		}
	}
	return nil;
}



- (void)setAbstractText:(NSAttributedString *)abstractText{
	NS_DURING
	NSString *string = [abstractText string];
	if ([string hasPrefix:@"<"]) {
		//should be xml or html"
		NSLog(@"set Abstract as html: %@", [abstractText string]);
		NSError *error;
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[abstractText string] withName:@"abstract"];
		if (!error) {
			NSArray *array = [[self rootElement] elementsForName:@"abstract"];
			if ([array count] > 0) {
				int index = [[[self rootElement] children] indexOfObject:[array objectAtIndex:0]];
				[[self rootElement] replaceChildAtIndex:(unsigned int)index withNode:(NSXMLNode *)node];
			}
			else
				[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:4];

		}
		
	}
	// probably no HTML. treat it as plain text.
	else {
		NSLog(@"set abstract: %@", [abstractText string]);
		NSXMLElement *node;
		NSXMLNode *textNode = [NSXMLNode textWithStringValue:[abstractText string]];
		NSArray *array = [[self rootElement] elementsForName:@"abstract"];
		if ([array count] > 0) 
			node = [array objectAtIndex:0];
		if (!node) {
			node = [NSXMLNode elementWithName:@"abstract"];
			[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:4];
		}

		[node setChildren:[NSArray arrayWithObject:textNode]];
	}
	NS_HANDLER
		NSLog (@"error saving abstract: %@", [localException name]);
	NS_ENDHANDLER
}

- (NSAttributedString *)altAbstractText{
	NSLog (@"alternative-abstract");
	//this is a little more complex because we need to parse the html elements inside.
	NSArray *array = [[self rootElement] elementsForName:@"alternative-abstract"];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		NSLog(@"alternative-abstract: %@", [node stringValue]);
		NSArray *children = [node children];
		if ([children count] > 0) {
			NSEnumerator *enumerator = [children objectEnumerator];
			NSXMLNode *child;
			NSMutableString *string = [NSMutableString string];
			while (child = [enumerator nextObject]){
				[string appendString:[child XMLString]];
			}
			return [[[NSAttributedString alloc] initWithString:string] autorelease];
		}
		else{
			
			return [[[NSAttributedString alloc] initWithString:[node stringValue]] autorelease];
		}
	}
	return nil;
}


- (void)setAltAbstractText:(NSAttributedString *)abstractText{
	NS_DURING
	NSString *string = [abstractText string];
	if ([string hasPrefix:@"<"]) {
		//should be xml or html"
		NSLog(@"set alternative_abstract as html: %@", [abstractText string]);
		NSError *error;
		//NSString *xml = [NSString stringWithFormat:@"<alternative-abstract>%@</alternative-abstract>", string];
		//NSXMLElement *node = [[[NSXMLElement alloc] initWithXMLString:xml error:&error] autorelease];
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[abstractText string] withName:@"alternative-abstract"];
		if (!error) {
			NSArray *array = [[self rootElement] elementsForName:@"alternative-abstract"];
			if ([array count] > 0) {
				int index = [[[self rootElement] children] indexOfObject:[array objectAtIndex:0]];
				[[self rootElement] replaceChildAtIndex:(unsigned int)index withNode:(NSXMLNode *)node];
			}
			else 
				[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:5];
		}
		
	}
	// probably no HTML. treat it as plain text.
	else {
		NSLog(@"set alternative-abstract: %@", [abstractText string]);
		NSXMLElement *node;
		NSXMLNode *textNode = [NSXMLNode textWithStringValue:[abstractText string]];
		NSArray *array = [[self rootElement] elementsForName:@"alternative-abstract"];
		if ([array count] > 0) 
			node = [array objectAtIndex:0];
		if (!node) {
			node = [NSXMLNode elementWithName:@"alternative-abstract"];
			[self insertNode:(NSXMLElement *)node  intoNode:[self rootElement] atIndex:5];
		}

		[node setChildren:[NSArray arrayWithObject:textNode]];
	}
	NS_HANDLER
		NSLog (@"error saving alternative-abstract: %@", [localException name]);
	NS_ENDHANDLER
}

- (NSAttributedString *)history{
	NSLog (@"history");
	//this is a little more complex because we need to parse the html elements inside.
	NSArray *array = [[self historySection] elementsForName:@"history"];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		NSLog(@"history: %@", [node stringValue]);
		NSArray *children = [node children];
		if ([children count] > 0) {
			NSEnumerator *enumerator = [children objectEnumerator];
			NSXMLNode *child;
			NSMutableString *string = [NSMutableString string];
			while (child = [enumerator nextObject]){
				[string appendString:[child XMLString]];
			}
			return [[[NSAttributedString alloc] initWithString:string] autorelease];
		}
		else{
			
			return [[[NSAttributedString alloc] initWithString:[node stringValue]] autorelease];
		}
	}
	return nil;
}

- (void)setHistory:(NSAttributedString *)history{
	NS_DURING
	NSString *string = [history string];
	if ([string hasPrefix:@"<"]) {
		//should be xml or html"
		NSLog(@"set history as html: %@", [history string]);
		NSError *error;
		NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[history string] withName:@"history"];
		if (!error) {
			NSArray *array = [[self historySection] elementsForName:@"history"];
			if ([array count] > 0) {
				int index = [[[self historySection] children] indexOfObject:[array objectAtIndex:0]];
				[[self historySection] replaceChildAtIndex:(unsigned int)index withNode:(NSXMLNode *)node];
			}
			else 
				[self insertNode:(NSXMLElement *)node  intoNode:[self historySection] atIndex:0];
		}
		
	}
	// probably no HTML. treat it as plain text.
	else {
		NSLog(@"set history: %@", [history string]);
		NSXMLElement *node = nil;
		NSXMLNode *textNode = [NSXMLNode textWithStringValue:[history string]];
		NSArray *array = [[self historySection] elementsForName:@"history"];
		//NSLog(@"node count: %d", [array count]);
		if ([array count] > 0) {
			node = [array objectAtIndex:0];
			//NSLog(@"History Node: %@", [node description]);
		}
		if (!node) {
			node = [NSXMLNode elementWithName:@"history"];
			[self insertNode:(NSXMLElement *)node  intoNode:[self historySection] atIndex:0];
		}
		[node setChildren:[NSArray arrayWithObject:textNode]];
		
	}
	NS_HANDLER
		NSLog (@"error saving history: %@", [localException name]);
	NS_ENDHANDLER
}

- (NSXMLElement *)patient{
	NSArray *array = [[self historySection] elementsForName:@"patient"];
	if ([array count] > 0)
		return [array objectAtIndex:0];
	else {
		NSXMLElement *patient = [NSXMLElement patient];
		[[self historySection] addChild:patient];
		return patient;
	}
}
	


//Discussion
- (NSAttributedString *)discussion{
	NSLog (@"Discussion");
	//this is a little more complex because we need to parse the html elements inside.
	NSArray *array = [[self discussionSection] elementsForName:@"discussion"];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		NSLog(@"discussion: %@", [node stringValue]);
		NSArray *children = [node children];
		if ([children count] > 0) {
			NSEnumerator *enumerator = [children objectEnumerator];
			NSXMLNode *child;
			NSMutableString *string = [NSMutableString string];
			while (child = [enumerator nextObject]){
				[string appendString:[child XMLString]];
			}
			return [[[NSAttributedString alloc] initWithString:string] autorelease];
		}
		else{
			
			return [[[NSAttributedString alloc] initWithString:[node stringValue]] autorelease];
		}
	}
	return nil;
}

- (void)setDiscussion:(NSAttributedString *)discussion{
	NS_DURING
		NSString *string = [discussion string];
		if ([string hasPrefix:@"<"]) {
			//should be xml or html"
			NSLog(@"set discussion as html: %@", [discussion string]);
			NSError *error;
			NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[discussion string] withName:@"discussion"];
			if (!error) {
				NSArray *array = [[self discussionSection] elementsForName:@"discussion"];
				if ([array count] > 0) {
					int index = [[[self discussionSection] children] indexOfObject:[array objectAtIndex:0]];
					[[self discussionSection] replaceChildAtIndex:(unsigned int)index withNode:(NSXMLNode *)node];
				}
				else 
					[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:3];
			}
			
		}
		// probably no HTML. treat it as plain text.
		else {
			NSLog(@"set discussion: %@", [discussion string]);
			NSXMLElement *node = nil;
			NSXMLNode *textNode = [NSXMLNode textWithStringValue:[discussion string]];
			NSArray *array = [[self discussionSection] elementsForName:@"discussion"];
			//NSLog(@"node count: %d", [array count]);
			if ([array count] > 0) {
				node = [array objectAtIndex:0];
				//NSLog(@"History Node: %@", [node description]);
			}
			if (!node) {
				node = [NSXMLNode elementWithName:@"discussion"];
				[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:3];
			}
			[node setChildren:[NSArray arrayWithObject:textNode]];
			
		}
		NS_HANDLER
			NSLog (@"error saving history: %@", [localException name]);
		NS_ENDHANDLER
}


- (NSString *)diagnosis{
	NSLog(@"DIAGNOSIS");
	return [self stringValueForNodeNamed:@"diagnosis"  parentNode:[self discussionSection]];
}

- (void)setDiagnosis:(NSString *)diagnosis{
	NS_DURING
	NSLog(@"set diagnosis: %@", diagnosis);
	NSXMLNode *node = nil;
	NSArray *array = [[self discussionSection] elementsForName:@"diagnosis"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLNode elementWithName:@"diagnosis" stringValue:diagnosis];
		[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:0];	
	}
	else
		[node setStringValue:diagnosis];
	NS_HANDLER
	NS_ENDHANDLER
}


- (NSAttributedString *)findings{
	NSLog (@"findings");
	//this is a little more complex because we need to parse the html elements inside.
	NSArray *array = [[self discussionSection] elementsForName:@"findings"];
	if ([array count] > 0) {
		NSXMLNode *node = [array objectAtIndex:0];
		NSLog(@"findings: %@", [node stringValue]);
		NSArray *children = [node children];
		if ([children count] > 0) {
			NSEnumerator *enumerator = [children objectEnumerator];
			NSXMLNode *child;
			NSMutableString *string = [NSMutableString string];
			while (child = [enumerator nextObject]){
				[string appendString:[child XMLString]];
			}
			return [[[NSAttributedString alloc] initWithString:string] autorelease];
		}
		else{
			
			return [[[NSAttributedString alloc] initWithString:[node stringValue]] autorelease];
		}
	}
	return nil;
}

- (void)setFindings:(NSAttributedString *)findings{
	NS_DURING
		NSString *string = [findings string];
		if ([string hasPrefix:@"<"]) {
			//should be xml or html"
			NSLog(@"set findings as html: %@", [findings string]);
			NSError *error;
			NSXMLElement *node = (NSXMLElement *)[self nodeFromXML:[findings string] withName:@"findings"];
			if (!error) {
				NSArray *array = [[self discussionSection] elementsForName:@"findings"];
				if ([array count] > 0) {
					int index = [[[self discussionSection] children] indexOfObject:[array objectAtIndex:0]];
					[[self discussionSection] replaceChildAtIndex:(unsigned int)index withNode:(NSXMLNode *)node];
				}
				else 
					[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:1];
			}
			
		}
		// probably no HTML. treat it as plain text.
		else {
			NSLog(@"set findings: %@", [findings string]);
			NSXMLElement *node = nil;
			NSXMLNode *textNode = [NSXMLNode textWithStringValue:[findings string]];
			NSArray *array = [[self discussionSection] elementsForName:@"findings"];
			//NSLog(@"node count: %d", [array count]);
			if ([array count] > 0) {
				node = [array objectAtIndex:0];
				//NSLog(@"History Node: %@", [node description]);
			}
			if (!node) {
				node = [NSXMLNode elementWithName:@"findings"];
				[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:1];
			}
			[node setChildren:[NSArray arrayWithObject:textNode]];
			
		}
		NS_HANDLER
			NSLog (@"error saving history: %@", [localException name]);
		NS_ENDHANDLER
}


- (NSString *)ddx{
	NSLog(@"ddx");
	return [self stringValueForNodeNamed:@"differential-diagnosis"  parentNode:[self discussionSection]];
}

- (void)setDdx:(NSString *)ddx{
	NS_DURING
	NSLog(@"set differential-diagnosis: %@", ddx);
	NSXMLNode *node = nil;
	NSArray *array = [[self discussionSection] elementsForName:@"differential-diagnosis"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLNode elementWithName:@"differential-diagnosis" stringValue:ddx];
		[self insertNode:(NSXMLElement *)node  intoNode:[self discussionSection] atIndex:2];	
	}
	else
		[node setStringValue:ddx];
	NS_HANDLER
	NS_ENDHANDLER
}

- (NSXMLElement *)quiz{
	NSXMLElement *node = nil;
	NSArray *array = [[self quizSection] elementsForName:@"quiz"];
	if ([array count] > 0) 
		node = [array objectAtIndex:0];
	if (!node) {
		node = [NSXMLElement quiz];
		[[self quizSection] addChild:node];
	}
	return node;
}

- (NSArray *)questions {
	return [[self quiz] questions];
}

- (void)setQuestions:(NSArray *)questions {
	[[self quiz] setQuestions:questions];
}


- (void)save:(id)sender{
	//if ([authorController arrangedObjects])
	//	[self setAuthors:[authorController arrangedObjects]];
	[self saveWithAlert:YES];

}

-  (void)saveWithAlert:(BOOL)useAlert{
	NSAlert *alert;
	NSData *data = [_xmlDocument XMLData];
	
	if ([data writeToFile:[_path stringByAppendingPathComponent:@"teachingFile.xml"] atomically:YES] && useAlert) 
		alert = [NSAlert alertWithMessageText:@"OsiriX MIRC plugin" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"XML saved"];
	else if (useAlert)
		alert = [NSAlert alertWithMessageText:@"OsiriX MIRC plugin" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Save failed"];
	[alert runModal];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
              ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"arrangedObjects"] && [object isEqual:authorController]) {
		[self setAuthors:[change objectForKey:NSKeyValueChangeNewKey]];
    }
    // the same change
    [super observeValueForKeyPath:keyPath
                ofObject:object 
                 change:change 
                 context:context];
				 

}



- (IBAction)quizAction:(id)sender{
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		switch ([sender selectedSegment]) {
			case 0: [self addQuestion:sender];
					break;
			case 1: [self modifyQuestion:sender];
					break;
			case 2: [self deleteQuestion:sender];
					break;
		}
	}
}

- (IBAction)addQuestion:(id)sender{
	NSXMLElement *question = [NSXMLElement questionWithString:@"What is the question?"];
	//[[self quiz] addQuestion:question];
	NSMutableArray *questions = [NSMutableArray arrayWithArray:[self questions]];
	[questions makeObjectsPerformSelector:@selector(detach)];
	[questions addObject:question];
	[self setQuestions:questions];
	if (questionController)
		[questionController release];
	questionController = [[MIRCQuestionWindowController alloc] initWithQuestion:question];
	[NSApp beginSheet:[questionController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:nil contextInfo:nil];
	
}

- (IBAction)modifyQuestion:(id)sender{	
	NSArray *selectedObjects = [questionArrayController selectedObjects];
	//NSLog(@"modify Question: %d", [selectedObjects count]);
	if ([selectedObjects count]) {
		NSXMLElement *question = [selectedObjects objectAtIndex:0];
		if (questionController)
			[questionController release];
		questionController = [[MIRCQuestionWindowController alloc] initWithQuestion:question];
		[NSApp beginSheet:[questionController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:nil contextInfo:nil];
		
	}
}
- (IBAction)deleteQuestion:(id)sender{

	NSArray *selectedObjects = [questionArrayController selectedObjects];
	//NSLog(@"delete Question: %d", [selectedObjects count]);
	if ([selectedObjects count]) {
		NSXMLElement *question = [selectedObjects objectAtIndex:0];
		[question detach];
	 }
	[self setQuestions:[self questions]];
	
}

- (NSArray *)thumbnails{
	return _images;
}

- (NSArray *)images{
	NSLog(@"images");
	return [[self imageSection] elementsForName:@"image"];
}

- (void)setImages:(NSArray *)images{
	NSLog(@"setImages: %@", [images description]);
	[[self images] makeObjectsPerformSelector:@selector(detach)];
	NSEnumerator *enumerator = [images objectEnumerator];
	NSXMLElement *node;
	while (node = [enumerator nextObject])
		[[self imageSection] addChild:node];

}



- (IBAction)imageAction:(id)sender{
	if ([sender isKindOfClass:[NSSegmentedControl class]]) {
		switch ([sender selectedSegment]) {
			case 0: [self addImage:sender];
					break;
			case 1: [self modifyImage:sender];
					break;
			case 2: [self deleteImage:sender];
					break;
		}
	}

}
- (IBAction)addImage:(id)sender{
	NSXMLElement *image = [NSXMLElement image];
	NSMutableArray *images = [NSMutableArray arrayWithArray:[self images]];
	[images makeObjectsPerformSelector:@selector(detach)];
	[images addObject:image];
	[self setImages:images];
	if (imageController)
		[imageController release];
	imageController = [[MIRCImageWindowController alloc] initWithImage:(NSXMLElement *)image imageArray:[self thumbnails]];
	[NSApp beginSheet:[imageController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:nil contextInfo:nil];
}

- (IBAction)modifyImage:(id)sender{
	NSArray *selectedObjects = [imageArrayController selectedObjects];
	//NSLog(@"modify Question: %d", [selectedObjects count]);
	if ([selectedObjects count]) {
		NSXMLElement *image = [selectedObjects objectAtIndex:0];
		if (imageController)
			[imageController release];
		imageController = [[MIRCImageWindowController alloc] initWithImage:(NSXMLElement *)image imageArray:[self thumbnails]];
		[NSApp beginSheet:[imageController window] modalForWindow:[self window] modalDelegate:self  didEndSelector:nil contextInfo:nil];
		
	}
}
- (IBAction)deleteImage:(id)sender{
		NSArray *selectedObjects = [imageArrayController selectedObjects];
	//NSLog(@"delete Question: %d", [selectedObjects count]);
	if ([selectedObjects count]) {
		NSXMLElement *image = [selectedObjects objectAtIndex:0];
		[image detach];
	 }
	//[self setQuestions:[self questions]];
}



- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	[whackedController release];
	whackedController = nil;
}

 - (QTMovie *)historyMovie{
	return _historyMovie;
 }
 
 - (void)setHistoryMovie:(QTMovie *)movie{
	[self setMovie:(QTMovie *)movie withName:@"history"];
		
		
	
 }
 
  - (QTMovie *)discussionMovie{
	return _discussionMovie;
 }
 
 - (void)setDiscussionMovie:(QTMovie *)movie{
	[self setMovie:(QTMovie *)movie withName:@"discussion"];
	
 }
 
- (void)setMovie:(QTMovie *)movie withName:(NSString *)name{
	NSXMLElement *node = nil;
	NSArray *array;
	if ([name isEqualToString:@"discussion"]) {
		[_discussionMovie release];
		_discussionMovie = [movie retain];
		[discussionMovieView setMovie:_discussionMovie];
		array = [[self discussionSection] elementsForName:@"a"];
	}
	else if ([name isEqualToString:@"history"]) {	
		[_historyMovie release];
		_historyMovie = [movie retain];
		[historyMovieView setMovie:_historyMovie];
		array = [[self historySection] elementsForName:@"a"];
	}
	NSEnumerator *enumerator = [array objectEnumerator];
	while (node = [enumerator nextObject]) {
		NSXMLNode *attr = nil;
		attr = [node attributeForName:@"href"];
		if ([[attr stringValue] isEqualToString:[name stringByAppendingPathExtension:@"mov"]]) //already have link
			return;
	}
	node = [NSXMLNode elementWithName:@"a" stringValue:@"watch video"];
	[node addAttribute:[NSXMLNode attributeWithName:@"href" stringValue:[name stringByAppendingPathExtension:@"mov"]]];
	if ([name isEqualToString:@"discussion"])
		[[self discussionSection] addChild:node];
	else if ([name isEqualToString:@"history"])
		[[self historySection] addChild:node];
		
  }
 
 - (void)newMovie:(NSNotification *)note{
	NSString *path = [[note userInfo] objectForKey:@"moviePath"];
	QTMovie *movie = nil;
	if ([QTMovie canInitWithFile:path])
		movie = [QTMovie movieWithFile:path error:nil];
	if ([[path lastPathComponent] isEqualToString:@"history.mov"]) {
		[self setHistoryMovie:movie];
	}
	else if ([[path lastPathComponent] isEqualToString:@"discussion.mov"]) 
		[self setDiscussionMovie:movie];
 }
*/





@end

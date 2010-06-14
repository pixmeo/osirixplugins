//
//  DiscPublisherStatus.mm
//  Primiera
//
//  Created by Alessandro Volz on 2/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublisherStatus.h"
#import "DiscPublisher+Constants.h"
#import <OsiriX Headers/NSXMLNode+N2.h>
#import <JobManager/PTJobManager.h>


@implementation DiscPublisherStatus

@synthesize path = _path;
@synthesize doc = _doc;

-(id)initWithFileAtPath:(NSString *)path {
	self = [super init];
	
	_path = [path retain];
	@try {
		[self refresh];
	} @catch (NSException* e) {
		NSLog(@"Initial status invalid: %@", e);
	}
	
	return self;
}

-(void)dealloc {
	self.doc = NULL;
	[_path release];
	[super dealloc];
}

-(void)refresh {
	NSString* xml = [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:NULL];
	
//	NSLog(@"Status XML:\n\n%@\n\n", xml);
	
	NSError* error = NULL;
	NSXMLDocument* doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA error:&error] autorelease];
	
	if (error) [NSException raise:DiscPublisherException format:@"%@", [error localizedDescription]];
	
	if (doc) self.doc = doc;
}

-(NSArray*)robotIds {
	NSMutableArray* robotIds = [NSMutableArray arrayWithCapacity:4];
	for (NSXMLNode* robot in [self.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT" constants:NULL error:NULL])
		[robotIds addObject:[NSNumber numberWithFloat:[[[robot childNamed:@"ROBOT_ID"] stringValue] floatValue]]];
	return robotIds;
}

-(BOOL)allRobotsAreIdle {
	[self refresh];
	for (NSXMLNode* robot in [self.doc objectsForXQuery:@"/PTRECORD_STATUS/ROBOTS/ROBOT" constants:NULL error:NULL])
		if ([[[robot childNamed:@"SYSTEM_STATE"] stringValue] floatValue] != SYSSTATE_IDLE)
			return NO;
	return YES;
}



@end

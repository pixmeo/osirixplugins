//
//  xmlrpcFilter.m
//  xmlrpc
//
//  XML-RPC Generator for MacOS: http://www.ditchnet.org/xmlrpc/
//
//  About XML-RPC: http://www.xmlrpc.com/
//
//  This plugin supports 2 methods for xml-rpc messages
//
//  exportSelectedToPath - {path:"/Users/antoinerosset/Desktop/"}
//
//  openSelectedWithTiling - {rowsTiling:2, columnsTiling:2}
//

#import "xmlrpcFilter.h"
#import "DCMPix.h"
#import "ViewerController.h"
#import "DicomFile.h"
#import "BrowserController.h"

@implementation xmlrpcFilter

- (void) initPlugin
{
	NSLog( @"************* xml-rpc plugin init :-)");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OsiriXXMLRPCMessage:) name:@"OsiriXXMLRPCMessage" object:nil];
}

- (void) OsiriXXMLRPCMessage: (NSNotification*) note
{
	@try
	{
		NSMutableDictionary	*httpServerMessage = [note object];
		NSXMLDocument *doc = [httpServerMessage valueForKey:@"NSXMLDocument"];
		NSString *encoding = [doc characterEncoding];
		
		// ****************************************************************************************
		
		if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"updateDICOMNode"])	//AETitle, Port, TransferSyntax
		{
			NSError	*error = 0L;
			NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
			NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
			if (3 == [keys count] || 3 == [values count])
			{
				int i;
				NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
				for( i = 0; i < [keys count]; i++)
				{
					id value;
					
					if( [encoding isEqualToString:@"UTF-8"] == NO &&  [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
						value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
					else
						value = [[values objectAtIndex: i] objectValue];
					
					[paramDict setValue: value  forKey: [[keys objectAtIndex: i] objectValue]];
				}
				
				NSMutableArray *serversArray = [NSMutableArray arrayWithArray: [[NSUserDefaults standardUserDefaults] arrayForKey: @"SERVERS"]];
				
				BOOL found = NO;
				
				for( NSDictionary *d in serversArray)
				{
					if( [[d valueForKey:@"AETitle"] isEqualToString: [paramDict valueForKey:@"AETitle"]])
					{
						NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary: d];
						
						[m setObject: [httpServerMessage valueForKey: @"peerAddress"] forKey:@"Address"];
						[m setObject: [paramDict valueForKey:@"Port"] forKey:@"Port"];
						[m setObject: [NSNumber numberWithInt: [[paramDict valueForKey:@"TransferSyntax"] intValue]] forKey:@"Transfer Syntax"];
						
						[serversArray removeObject: d];
						[serversArray addObject: m];
						
						found = YES;
						
						break;
					}
				}
				
				if( found == NO)
				{
					[serversArray addObject: [NSDictionary dictionaryWithObjectsAndKeys:	[httpServerMessage valueForKey: @"peerAddress"], @"Address",
																							[paramDict valueForKey:@"AETitle"], @"AETitle",
																							[paramDict valueForKey:@"Port"], @"Port",
																							[NSNumber numberWithBool:YES] , @"QR",
																							[NSNumber numberWithBool:YES] , @"Send",
																							[paramDict valueForKey:@"AETitle"], @"Description",
																							[NSNumber numberWithInt: [[paramDict valueForKey:@"TransferSyntax"] intValue]], @"Transfer Syntax",
																							nil]];
				}
				
				NSLog( @"%@", serversArray);
				
				[[NSUserDefaults standardUserDefaults] setObject: serversArray forKey:@"SERVERS"];
				
				// Done, we can send the response to the sender
				
				NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
				NSError *error = nil;
				NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
				[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
				[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
			}
		}

		// ****************************************************************************************
		
		if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"importFromURL"])
		{
			NSError	*error = 0L;
			NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
			NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
			if (1 == [keys count] || 1 == [values count])
			{
				int i;
				NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
				
				for( i = 0; i < [keys count]; i++)
				{
					id value;
					
					NSLog( [[values objectAtIndex: i] objectValue]);
					
					if( [encoding isEqualToString:@"UTF-8"] == NO &&  [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
						value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
					else
						value = [[values objectAtIndex: i] objectValue];
					
					[paramDict setValue: value  forKey: [[keys objectAtIndex: i] objectValue]];
				}
				
				// Ok, now, we have the parameters -> execute it !
				
	//			NSArray *result = [[BrowserController currentBrowser] addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString: @"http://www.osirix-viewer.com/internet.dcm"]]];
				
				NSString *url = [paramDict valueForKey:@"url"];
				if( url == 0L) url = [paramDict valueForKey:@"url "];
				if( url == 0L) url = [paramDict valueForKey:@"URL"];
				
				if( url)
				{
					NSArray *result = [[BrowserController currentBrowser] addURLToDatabaseFiles: [NSArray arrayWithObject: [NSURL URLWithString: url]]];
					if( [result count] == 0) NSLog(@"error.... addURLToDatabaseFiles failed");
				}
				else NSLog( @"no URL ! for importFromURL");
				
				// Done, we can send the response to the sender
				
				NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
				NSError *error = nil;
				NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
				[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
				[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
			}
		}
		
		// ****************************************************************************************
		
		if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"exportSelectedToPath"])
		{
			NSError	*error = 0L;
			NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
			NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
			if (1 == [keys count] || 1 == [values count])
			{
				int i;
				NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
				for( i = 0; i < [keys count]; i++)
				{
					id value;
					
					if( [encoding isEqualToString:@"UTF-8"] == NO &&  [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
						value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
					else
						value = [[values objectAtIndex: i] objectValue];
					
					[paramDict setValue: value  forKey: [[keys objectAtIndex: i] objectValue]];
				}
				
				// Ok, now, we have the parameters -> execute it !
				
				NSMutableArray *dicomFiles2Export = [NSMutableArray array];
				NSMutableArray *filesToExport;
				
				filesToExport = [[BrowserController currentBrowser] filesForDatabaseOutlineSelection: dicomFiles2Export onlyImages:YES];
				[[BrowserController currentBrowser] exportDICOMFileInt: [paramDict valueForKey:@"path"] files: filesToExport objects: dicomFiles2Export];
				
				// Done, we can send the response to the sender
				
				NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
				NSError *error = nil;
				NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
				[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
				[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
			}
		}

		
		// ****************************************************************************************
		
		if( [[httpServerMessage valueForKey: @"MethodName"] isEqualToString: @"openSelectedWithTiling"])
		{
			NSError	*error = 0L;
			NSArray *keys = [doc nodesForXPath:@"methodCall/params//member/name" error:&error];
			NSArray *values = [doc nodesForXPath:@"methodCall/params//member/value" error:&error];
			if (2 == [keys count] || 2 == [values count])
			{
				int i;
				NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
				for( i = 0; i < [keys count]; i++)
				{
					id value;
					
					if( [encoding isEqualToString:@"UTF-8"] == NO &&  [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
						value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
					else
						value = [[values objectAtIndex: i] objectValue];
					
					[paramDict setValue: value  forKey: [[keys objectAtIndex: i] objectValue]];
				}
				
				// Ok, now, we have the parameters -> execute it !
				
				[[BrowserController currentBrowser] viewerDICOM: self];
				
				// And change the tiling, of the frontmost viewer
				
				NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
				
				for( i = 0; i < [viewersList count] ; i++)
				{
					{
						[[viewersList objectAtIndex: i] checkEverythingLoaded];
						[[viewersList objectAtIndex: i] setImageRows: [[paramDict valueForKey: @"rowsTiling"] intValue] columns: [[paramDict valueForKey: @"rowsTiling"] intValue]];
					}
				}
				
				// Done, we can send the response to the sender
				
				NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
				NSError *error = nil;
				NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
				[httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
				[httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
			}
		}
		
		// ****************************************************************************************

		NSLog( [httpServerMessage description]);
	}
	
	@catch (NSException *e)
	{
		NSLog( @"**** EXCEPTION IN XML-RPC PROCESSING: %@", e);
	}
}

- (long) filterImage : (NSString*) menuName
{

	NSRunInformationalAlertPanel( @"XML-RPC Plugin", @"This plugin is a XML-RPC message listener.", @"OK", 0L, 0L);
	
	return 0;
}

@end
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
#import "OsiriXAPI/PluginFilter.h"
#import "OsiriXAPI/DCMPix.h"
#import "OsiriXAPI/ViewerController.h"
#import "OsiriXAPI/DicomFile.h"
#import "OsiriXAPI/BrowserController.h"

@implementation xmlrpcFilter

- (void) initPlugin
{
	NSLog( @"************* xml-rpc plugin init :-)");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(OsiriXXMLRPCMessage:) name:@"OsiriXXMLRPCMessage" object:nil];
}

- (void) OsiriXXMLRPCMessage: (NSNotification*) note
{
    if( [NSThread isMainThread] == NO)
    {
        [self performSelectorOnMainThread:@selector(OsiriXXMLRPCMessage:) withObject: note waitUntilDone: YES];
        return;
    }
    
	@try
	{
		NSMutableDictionary	*httpServerMessage = [note object];
		
        NSLog( @"%@", httpServerMessage);
        
        // You will also receive this notification when XMLRPC methods are called through an osirix:// URL
        // In this case, the notification dictionary won't contain an NSXMLDocument and request parameters will be available directly in the dictionary.
        // The following code shows you how to obtain the parameters, no matter if XMLRPC or osirix://
        
        // first, obtain the called method name. its key is "MethodName" from XMLRPC, "methodName" from osirix://
        NSString* methodName = [httpServerMessage objectForKey:@"MethodName"];
        if (!methodName) methodName = [httpServerMessage objectForKey:@"methodName"];
        
        // now that we have the method name, do we want to handle this notification? This plugin provides implementations for 4 methods:
        // updateDICOMNode, importFromURL, exportSelectedToPath and openSelectedWithTiling
        if (![methodName isEqualToString: @"updateDICOMNode"] &&
            ![methodName isEqualToString: @"importFromURL"] &&
            ![methodName isEqualToString: @"exportSelectedToPath"] &&
            ![methodName isEqualToString: @"openSelectedWithTiling"])
            return; // the called method is not one of our 4 methods, so just stop handling this notification
        
        // since now we're sure we are going to handle this XMLRPC/osirix:// method call, let's build a dictionary with all parameters
        
        // osirix:// calls just put all parameters in the httpServerMessage dictonary, so we first copy it
        NSMutableDictionary* paramDict = [[httpServerMessage mutableCopy] autorelease];
        // XMLRPC calls provide us with a "NSXMLDocument" key containing an NSXMLDocument object
        NSXMLDocument* doc = [httpServerMessage valueForKey:@"NSXMLDocument"];
        if (doc) { // if we have such object, we must extract the parameters from it
            NSString* encoding = [doc characterEncoding];
			NSArray* keys = [doc nodesForXPath:@"methodCall/params//member/name" error:NULL];
			NSArray* values = [doc nodesForXPath:@"methodCall/params//member/value" error:NULL];
            for (int i = 0; i < [keys count]; i++) {
                id value;
                if ([encoding isEqualToString:@"UTF-8"] == NO &&  [[[values objectAtIndex: i] objectValue] isKindOfClass:[NSString class]])
                    value = [(NSString*)CFXMLCreateStringByUnescapingEntities(NULL, (CFStringRef)[[values objectAtIndex: i] objectValue], NULL) autorelease];
                else value = [[values objectAtIndex:i] objectValue];
                [paramDict setValue:value forKey:[[keys objectAtIndex:i] objectValue]];
            }
        }
        
        // now we can use methodName and paramDict
        
		// ****************************************************************************************
		
		if ([methodName isEqualToString: @"updateDICOMNode"])	//AETitle, Port, TransferSyntax
		{				
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

		// ****************************************************************************************
		
		if ([methodName isEqualToString: @"importFromURL"])
		{
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
            
            NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value><string>0</string></value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
            NSError *error = nil;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
            [httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
            [httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
		
		// ****************************************************************************************
		
		if ([methodName isEqualToString: @"exportSelectedToPath"])
		{
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

		
		// ****************************************************************************************
		
		if ([methodName isEqualToString: @"openSelectedWithTiling"])
		{
            [[BrowserController currentBrowser] viewerDICOM: self];
            
            // And change the tiling, of the frontmost viewer
            
            NSMutableArray *viewersList = [ViewerController getDisplayed2DViewers];
            
            for (int i = 0; i < [viewersList count] ; i++)
            {
                {
                    [[viewersList objectAtIndex: i] checkEverythingLoaded];
                    [[viewersList objectAtIndex: i] setImageRows: [[paramDict valueForKey: @"rowsTiling"] intValue] columns: [[paramDict valueForKey: @"columnsTiling"] intValue]];
                }
            }
            
            // Done, we can send the response to the sender
            
            NSString *xml = @"<?xml version=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";		// Simple answer, no errors
            NSError *error = nil;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease];
            [httpServerMessage setValue: doc forKey: @"NSXMLDocumentResponse"];
            [httpServerMessage setValue: [NSNumber numberWithBool: YES] forKey: @"Processed"];		// To tell to other XML-RPC that we processed this order
		}
		
		// ****************************************************************************************

		NSLog(@"%@", [httpServerMessage description]);
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

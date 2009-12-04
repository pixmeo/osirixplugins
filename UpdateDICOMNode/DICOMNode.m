//
//  DICOMNodeUpdate.m
//  DICOMNodeUpdate

#import "DICOMNode.h"

@implementation DICOMNodeUpdate

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	done = YES;
}

- (long) filterImage:(NSString*) menuName
{
	// Send an XML-RPC message to uin-mc04.hcuge.ch
	
	NSString *aet = [[NSUserDefaults standardUserDefaults] stringForKey: @"AETITLE"];
	NSString *port = [[NSUserDefaults standardUserDefaults] stringForKey: @"AEPORT"];
	NSString *ts = @"0";
	
	NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><methodCall><methodName>updateDICOMNode</methodName><params><param><value><struct><member><name>AETitle</name><value><string>%@</string></value></member><member><name>Port</name><value><string>%@</string></value></member><member><name>TransferSyntax</name><value><string>%@</string></value></member></struct></value></param></params></methodCall>", aet, port, ts, 0L];
	
	NSError *error = nil; 
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithXMLString:xml options:NSXMLNodeOptionsNone error:&error] autorelease]; 
	NSData *data = [doc XMLData]; 
	
	NSURL *url  = [NSURL URLWithString:@"http://uin-mc04.hcuge.ch:8080"];
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0] autorelease]; 
	[request setHTTPMethod:@"POST"]; 
	[request setHTTPBody:data]; 
	[request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"]; 
	
	done = NO;
	
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: YES];
	
	while ( done == NO) 
	{ 
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]; 
	}
	
	[conn release];
	
	return 0;
}

- (void) initPlugin{
}

@end

//
//  MIRCCaseController.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/8/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCCaseController.h"
#import "MIRCController.h"
#import "MIRCXMLController.h"
#import "CoreDataToMIRCXMLConverter.h"

@implementation MIRCCaseController

- (void)dealloc{
	[self save];
	[_caseName release];
	[_mircEditor release];
	[receivedData release];
	[super dealloc];
}



- (IBAction)controlAction: (id) sender{	
	if ([sender selectedSegment] == 0) {
		[self add:self];
	}
	else if ([sender selectedSegment] == 1) {
			[self remove:self];
	}
}


- (void)awakeFromNib{
	[super awakeFromNib];
	[self setProgressBarStatus:NO];
}


- (void)save{
	NSLog(@"save Case");
	[mircController save];
}

- (IBAction)create:(id)sender{
	if (_mircEditor) 
		[_mircEditor release];
	_mircEditor = [[MIRCXMLController alloc] initWithTeachingFile:[self teachingFile] managedObjectContext:[self managedObjectContext]];
	[_mircEditor showWindow:self];
}

- (IBAction)send: (id)sender{
	
	id teachingFile = [self teachingFile];
	NSLog(@"Send %@", teachingFile);
	// Create Temp Folder
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *tempPath= @"/tmp/TeachingFile";
	if ([manager fileExistsAtPath:tempPath])
		[manager removeFileAtPath:tempPath handler:nil];
	NSLog(@"create temp Folder: %@", tempPath);
	[manager createDirectoryAtPath:tempPath attributes:nil];
	//Create XML
	CoreDataToMIRCXMLConverter *converter = [[CoreDataToMIRCXMLConverter alloc] initWithTeachingFile:teachingFile];
	NSXMLDocument  *xmlDocument = [converter xmlDocument];
	NSLog(@"get xml\n %@", xmlDocument);
	[[xmlDocument XMLData] writeToFile:[tempPath stringByAppendingPathComponent:@"teachingFile.xml"] atomically:YES];
	[converter release];
	//Add movies
	NSLog(@"copy Movies");
	if ([teachingFile valueForKey:@"historyMovie"])
		[[teachingFile valueForKey:@"historyMovie"] writeToFile:[tempPath stringByAppendingPathComponent:@"history.mov"] atomically:YES];
	if ([teachingFile valueForKey:@"historyMovie"])
		[[teachingFile valueForKey:@"discussionMovie"] writeToFile:[tempPath stringByAppendingPathComponent:@"discussion.mov"] atomically:YES];
		
	// Add Images;
	NSEnumerator *enumerator = [[teachingFile valueForKey:@"images"] objectEnumerator];
	id image;
	NSLog(@"copy images");
	while (image = [enumerator nextObject]) {
		NSString *index = [[image valueForKey:@"index"] stringValue];
		[[image valueForKey:@"primary"] writeToFile:
			[tempPath stringByAppendingPathComponent:[index stringByAppendingPathExtension:@"jpg"]] atomically:YES];
			
		[[image valueForKey:@"originalDimension"] writeToFile:
			[tempPath stringByAppendingPathComponent:[[index stringByAppendingString:@"-OD"] 
			stringByAppendingPathExtension:[image valueForKey:@"originalDimensionExtension"]]] atomically:YES];
			
		[[image valueForKey:@"annotation"] writeToFile:
			[tempPath stringByAppendingPathComponent:[[index stringByAppendingString:@"-ANN"]
			stringByAppendingPathExtension:@"jpg"]] atomically:YES];
			
		[[image valueForKey:@"originalFormat"] writeToFile:
			[tempPath stringByAppendingPathComponent:[[index stringByAppendingString:@"-OF"]
			stringByAppendingPathExtension:[image valueForKey:@"originalFormatExtension"]]] atomically:YES];
	}
	
	//Create Archive
	manager = [NSFileManager defaultManager];
	NSString *path = @"/tmp/archive.zip";
	if ([manager fileExistsAtPath:path])
			[manager removeFileAtPath:path handler:nil];
		//create Zip with NSTask
	NSTask *task = [[NSTask alloc] init];
	[task setCurrentDirectoryPath:tempPath];
	[task setLaunchPath:@"/usr/bin/zip/"];
	NSMutableArray*args = [NSMutableArray arrayWithObject:path];
	[args addObjectsFromArray:[[NSFileManager defaultManager] directoryContentsAtPath:tempPath]];
	[task setArguments:args];
	NSLog(@"Create archive args: %@ path: %@", args, path);
	[task  launch];
	[task waitUntilExit];
	[task release];
	
	// send
	NSString *destinationIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_IPAddress"];
	if (!destinationIP) 
		destinationIP = @"localhost";
	NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_Port"];
	if (!port) 
		port = @"8080";
		
	NSString *storageService = [[NSUserDefaults standardUserDefaults] objectForKey:@"MIRC_StorageService"];
	if (!storageService)
		storageService = @"storageService";
	NSString *destination = [NSString stringWithFormat:@"http://%@:%@/%@/submit/doc", destinationIP , port, storageService];
	NSURL *url = [NSURL URLWithString:destination];
	[self sendURL:url];
	[manager removeFileAtPath:path handler:nil];
	[manager removeFileAtPath:tempPath handler:nil];
	
	
}

- (BOOL)sendURL:(NSURL *)url{
	// create the request
	//url = [NSURL URLWithString:@"http://10.125.6.182:8080/mdmhmirc/submit/doc"];
	NSLog(@"send URL: %@", url);
	 NSMutableURLRequest *theRequest=[ NSMutableURLRequest requestWithURL:url
							cachePolicy:NSURLRequestUseProtocolCachePolicy
						timeoutInterval:60.0];
	// create the connection with the request
	// and start loading the data
	
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setValue:@" application/x-zip-compressed" forHTTPHeaderField:@"Content-type"];
	[theRequest setHTTPBody:[NSData dataWithContentsOfFile:@"/tmp/archive.zip"]];
	
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (theConnection) {
		// Create the NSMutableData that will hold
		// the received data
		receivedData = [[NSMutableData data] retain];
		[self setProgressBarStatus:YES];
		return YES;
	} else {
		// inform the user that the download could not be made
		NSLog(@"connection failed");
		[self setProgressBarStatus:NO];
		return NO;
	} 
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
 
    // it can be called multiple times, for example in the case of a 
    // redirect, so each time we reset the data.
    [receivedData setLength:0];
	[self setProgressBarStatus:NO];
	NSLog(@"url response: %@", response);
	NSLog(@"url: %@", [response URL]);
	NSLog(@"mime: %@", [response MIMEType]);
	NSLog(@"header: %@", [response allHeaderFields]);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    [receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    [receivedData release];
	receivedData = nil;
 
    // inform the user
	[self setProgressBarStatus:NO];
	[self displaySendStatus:NSLocalizedString(@"Connection failed", nil)];
    NSLog(@"Connection failed! Error - %@ %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey], error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // do something with the data
	NSString *response = [NSString stringWithUTF8String:[receivedData bytes]];
	if ([response rangeOfString: @"The zip file was received and unpacked successfully"].location == NSNotFound)
		[self displaySendStatus:NSLocalizedString(@"Connection failed", nil)];
	else
		[self displaySendStatus:NSLocalizedString(@"Connection Succeeded", nil)];
	NSLog(@"response:\n%@", response);
    // release the connection, and the data object
    [connection release];
    [receivedData release];
	receivedData = nil;
}

-(void)connection:(NSURLConnection *)connection
        didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:@"lpysher"
                                                 password:@"password"
                                              persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        // inform the user that the user name and password
        // in the preferences are incorrect
        //[self showPreferencesCredentialsAreIncorrectPanel:self];
    }
}

- (void)setProgressBarStatus:(BOOL)status{
	[self setAnimateProgressBar:status];
	[self setHideProgressBar:!status];
}

- (void)displaySendStatus:(NSString *)status{
	NSAlert *alert = [NSAlert alertWithError:nil];
	[alert setInformativeText:status];
	[alert setMessageText:NSLocalizedString(@"MIRC", nil)];
	[alert beginSheetModalForWindow:[mircController window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (BOOL) animateProgressBar{
	return _animateProgressBar;
}
- (void) setAnimateProgressBar:(BOOL)animate{
	_animateProgressBar = animate;
}
- (BOOL) hideProgressBar{
	return _hideProgressBar;
}
- (void) setHideProgressBar:(BOOL)hide{
	_hideProgressBar = hide;
}

- (id)teachingFile {
	return [[self selectedObjects] objectAtIndex:0];
}








@end

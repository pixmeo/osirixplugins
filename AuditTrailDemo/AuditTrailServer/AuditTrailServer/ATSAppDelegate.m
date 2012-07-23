//
//  ATSAppDelegate.m
//  AuditTrailServer
//
//  Created by Joël Spaltenstein on 7/8/12.
//  Copyright (c) 2012 Spaltenstein Natural Image. All rights reserved.
//

#import "ATSAppDelegate.h"
#import "HTTPServer.h"
#import "AuditTrailRecord.h"

#include <arpa/inet.h>

@interface HTTPConnection (ATSExtensions)

- (NSString *)IPAddressString;

@end

@implementation HTTPConnection (ATSExtensions)

- (NSString *)IPAddressString
{
    const struct sockaddr *sa = [[self peerAddress] bytes];
    
    switch(sa->sa_family) {
        case AF_INET:
        {
            char addr_string[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &(((struct sockaddr_in *)sa)->sin_addr), addr_string, INET_ADDRSTRLEN);
            return [NSString stringWithCString:addr_string encoding:NSASCIIStringEncoding];
        }
        case AF_INET6:
        {
            char addr_string6[INET6_ADDRSTRLEN];
            inet_ntop(AF_INET6, &(((struct sockaddr_in6 *)sa)->sin6_addr), addr_string6, INET6_ADDRSTRLEN);
            return [NSString stringWithCString:addr_string6 encoding:NSASCIIStringEncoding];
        }
    }
    
    return nil;
}

@end

@interface ATSAppDelegate ()

- (NSURL *)databaseDirectoryURL;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;

@end

@implementation ATSAppDelegate

@synthesize window = _window;
@synthesize arrayController = _arrayController;
@synthesize managedObjectContext;

- (void)dealloc
{
    [super dealloc];
}

- (NSManagedObjectContext *)managedObjectContext
{	
    if (managedObjectContext == nil) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{	
    if (persistentStoreCoordinator == nil) {
        NSURL *storeURL = [NSURL URLWithString:@"database.sqlite" relativeToURL:[self databaseDirectoryURL]];
        NSError *error = nil;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"could not open the persistent store because; %@", error);
        }    
	}
    
    return persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{	
    if (managedObjectModel == nil) {
        managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    }
    
    return managedObjectModel;
}


- (NSURL *)databaseDirectoryURL
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSURL *databaseDirectoryURL = [NSURL fileURLWithPath: [basePath stringByAppendingPathComponent: @"AuditTrail"]];
    [[NSFileManager defaultManager] createDirectoryAtURL:databaseDirectoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
    return databaseDirectoryURL;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    HTTPServer *server = [[HTTPServer alloc] init];
    [server setType:@"_http._tcp."];
    [server setName:@"OsiriX Audit Trail Server"];
    [server setDocumentRoot:[NSURL fileURLWithPath:@"/"]];
    [server setDelegate:self];
    
    NSError *startError = nil;
    if (![server start:&startError] ) {
        NSLog(@"Error starting server: %@", startError);
    } else {
        NSLog(@"Starting server on port %d", [server port]);
    }
        
    [[self managedObjectContext] save:NULL];
}

- (void)HTTPConnection:(HTTPConnection *)conn didReceiveRequest:(HTTPServerRequest *)mess
{
    CFHTTPMessageRef request = [mess request];
    
    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, (CFStringRef)vers); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
    
    NSString *method = [(id)CFHTTPMessageCopyRequestMethod(request) autorelease];
    if (!method) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
    
    if ([method isEqual:@"POST"]) {
        NSData* data = [(NSData*)CFHTTPMessageCopyBody(request) autorelease];
        
        if (!data) {
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
        
        @try {
            NSError *error;
            NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData:data options:NSXMLNodeOptionsNone error:&error] autorelease];
            if (doc == nil) {
                NSLog(@"Could not parse the XML: %@", error);
                CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
                [mess setResponse:response];
                CFRelease(response);
                return;
            }
            
            NSArray* methodCalls = [doc nodesForXPath:@"methodCall" error:NULL];
            if ([methodCalls count] != 1) {
                [NSException raise:NSGenericException format:@"request contains %d method calls", [methodCalls count]];
            }
            
            NSXMLElement *methodCall = [methodCalls objectAtIndex:0];
            
            NSArray *methodNames = [methodCall nodesForXPath:@"methodName" error:NULL];
            if ([methodNames count] != 1) {
                [NSException raise:NSGenericException format:@"method call contains %d method names", [methodNames count]];
            }
            
            NSString *methodName = [[methodNames objectAtIndex:0] stringValue];
            NSString *patientName = nil;
            NSString *userName = nil;
            NSString *note = nil;
            
            NSArray *keys = [methodCall nodesForXPath:@"params//member/name" error:&error];
            NSArray *values = [methodCall nodesForXPath:@"params//member/value" error:&error];
            NSMutableDictionary *parametersDict = [NSMutableDictionary dictionary];
            if ([keys count] == [values count])
            {
                NSInteger i;
                for (i = 0; i < [keys count]; i++) {
                    [parametersDict setObject:[[values objectAtIndex:i] stringValue] forKey:[[keys objectAtIndex:i] stringValue]];
                }
            }
            
            patientName = [parametersDict objectForKey:@"patientName"];
            userName = [parametersDict objectForKey:@"userName"];
            note = [parametersDict objectForKey:@"note"];
            
            if (userName) {
                AuditTrailRecord *newRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AuditTrailRecord"
                                                                            inManagedObjectContext:[self managedObjectContext]];
                newRecord.reportDate = [NSDate date];
                newRecord.clientIP = [conn IPAddressString];
                newRecord.action = methodName;
                newRecord.userName = userName;
                newRecord.patientName = patientName;
                newRecord.note = note;
                [[self managedObjectContext] save:NULL];
            } else {
                [NSException raise:NSGenericException format:@"request contains no userName"];
            }
        
            NSString *okResponse = @"<?xmlversion=\"1.0\"?><methodResponse><params><param><value><struct><member><name>error</name><value>0</value></member></struct></value></param></params></methodResponse>";            
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, (CFStringRef)okResponse, kCFHTTPVersion1_1);
            [mess setResponse:response];
            CFRelease(response);
            return;
        } @catch (NSException* e) {
            NSLog(@"Warning: [N2XMLRPCConnection handleRequest:] %@", [e reason]);
            CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 500, (CFStringRef)[e reason], kCFHTTPVersion1_1);
            [mess setResponse:response];
            CFRelease(response);
            return;
        }
    }
    
    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 405, NULL, kCFHTTPVersion1_1); // Method Not Allowed
    [mess setResponse:response];
    CFRelease(response);
}


@end

//
//  HSSAPI.m
//  HSS
//
//  Created by Alessandro Volz on 04.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSAPI.h"
#import "HSS.h"
#import "HSSAPISession.h"
#import <OsiriXAPI/NSData+N2.h>
#import <OsiriXAPI/NSString+N2.h>
#import <OsiriXAPI/JSON.h>
#import <objc/runtime.h>

@interface NSURLRequest ()

+ (void)setAllowsAnyHTTPSCertificate:(BOOL)flag forHost:(NSString*)host;
    
@end

/*@interface _HSSConnector : NSObject {
    NSConditionLock* _lock;
    HSSAPI* _api;
    NSMutableData* _data;
    NSError* _err;
}

+ (NSData*)dataWithAPI:(HSSAPI*)api request:(NSURLRequest*)request;

@end*/

@interface HSSAPIURLConnectionDelegate : NSObject {
    id _delegate;
    NSMutableData* _data;
    NSHTTPURLResponse* _response;
    BOOL _done;
    NSError* _error;
}

@property(readonly) NSData* data;
@property(readonly) NSHTTPURLResponse* response;
@property(readonly) BOOL done;
@property(readonly) NSError* error;

- (id)initWithProgressDelegate:(id)delegate;

@end

@implementation HSSAPI

@synthesize timeoutInterval = _timeoutInterval;
@synthesize acceptAllCertificates = _acceptAllCertificates;

+ (void)load {
    Method originalMethod = class_getClassMethod([NSURLRequest class], @selector(allowsAnyHTTPSCertificateForHost:));
	Method hssapiMethod = class_getClassMethod([self class], @selector(allowsAnyHTTPSCertificateForHost:));		
	method_exchangeImplementations(originalMethod, hssapiMethod);
}

static NSMutableArray* HostsAllowedAnyHTTPSCertificate = [[NSMutableArray alloc] init];

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host {
    @synchronized (HostsAllowedAnyHTTPSCertificate) {
        if ([HostsAllowedAnyHTTPSCertificate containsObject:host])
            return YES;
    }
    
    return [HSSAPI allowsAnyHTTPSCertificateForHost:host]; // this actually calls [NSURLRequest allowsAnyHTTPSCertificateForHost:]
}

+ (HSSAPI*)defaultAPI {
    static HSSAPI* api = [[HSSAPI alloc] initWithBaseURL:HSS.baseURL];
    return api;
}

- (id)initWithBaseURL:(NSURL*)url {
    if ((self = [super init])) {
        _url = [[url URLByAppendingPathComponent:@"hss/api"] retain];
        _timeoutInterval = 60;
        _acceptAllCertificates = [[[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"Accept all HTTPS certificates"] boolValue];
    }
    
    return self;
}

- (void)dealloc {
    [_url release];
    [super dealloc];
}

//NSString* const HSSAPIPOSTFilePathKey = @"HSSAPIPOSTFilePath";

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint parameters:(NSDictionary*)params error:(NSError**)error {
    return [self requestWithMethod:method endpoint:endpoint cookies:nil parameters:params timeout:_timeoutInterval progressDelegate:nil error:error];
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params error:(NSError**)error {
    return [self requestWithMethod:method endpoint:endpoint cookies:cookies parameters:params timeout:_timeoutInterval progressDelegate:nil error:error];
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params progressDelegate:(id)delegate error:(NSError**)error {
    return [self requestWithMethod:method endpoint:endpoint cookies:cookies parameters:params timeout:_timeoutInterval progressDelegate:delegate error:error];
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params timeout:(NSTimeInterval)timeout error:(NSError**)error {
    return [self requestWithMethod:method endpoint:endpoint cookies:cookies parameters:params timeout:timeout progressDelegate:nil error:error];
}

+ (NSString*)boundaryForParts:(NSArray*)parts {
    NSString* boundary = @"Boundary";
    
    while (true) {
        BOOL boundaryOk = YES;
        NSString* bb = [NSString stringWithFormat:@"--%@", boundary];
        NSData* bbd = [bb dataUsingEncoding:NSUTF8StringEncoding];
        for (NSData* part in parts)
            if ([part rangeOfData:bbd options:0 range:NSMakeRange(0, part.length)].location != NSNotFound) {
                boundaryOk = NO;
                break;
            }
        
        if (boundaryOk)
            break;
        
        NSData* randomData = [[NSString stringWithFormat:@"%ld", random()] dataUsingEncoding:NSUTF8StringEncoding];
        boundary = [[randomData md5] hex];
    }
    
    return boundary;
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params timeout:(NSTimeInterval)timeout progressDelegate:(id)delegate error:(NSError**)error {
    if (error) *error = nil;
    
    if ([NSThread isMainThread] && delegate) {
        NSLog(@"Warning: HSSAPI progress delegate is only supported in background threads, ignored.");
        delegate = nil;
    }
    
    NSURL* url = [_url URLByAppendingPathComponent:endpoint];
    
    NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:timeout] autorelease];
    request.HTTPMethod = method;
    
    if (cookies.count) {
        NSMutableArray* cookiesArray = [NSMutableArray array];
        for (NSString* key in cookies)
            [cookiesArray addObject:[NSHTTPCookie cookieWithProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                        url.host, NSHTTPCookieDomain,
                                                                        @"/", NSHTTPCookiePath,
                                                                        key, NSHTTPCookieName,
                                                                        [cookies objectForKey:key], NSHTTPCookieValue, nil]]];
        [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookiesArray]];
    }
    
    if (params.count) {
        BOOL multipartFormData = NO;
        for (NSString* key in params)
            if ([[params objectForKey:key] isKindOfClass:[NSArray class]])
                multipartFormData = YES;
        
        if (!multipartFormData) {
            NSMutableArray* paramsArray = [NSMutableArray array];
            for (NSString* key in params)
                [paramsArray addObject:[NSString stringWithFormat:@"%@=%@", key, [[params objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            request.HTTPBody = [[paramsArray componentsJoinedByString:@";"] dataUsingEncoding:NSUTF8StringEncoding];
        } else {
            NSMutableArray* parts = [NSMutableArray array];
            for (NSString* key in params) {
                id value = [params objectForKey:key];
                NSMutableString* part = [NSMutableString string];
                if ([value isKindOfClass:[NSArray class]]) {
                    NSString* filename = [value objectAtIndex:0];
                    NSData* data = [value objectAtIndex:1];
                    [part appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename];
                    [part appendFormat:@"Content-Type: application/octet-stream\r\n\r\n"];
                 //   [part appendString:@"Content-Transfer-Encoding: base64\r\n\r\n"];
                    NSMutableData* dpart = [NSMutableData dataWithData:[part dataUsingEncoding:NSUTF8StringEncoding]];
                    [dpart appendData:data];
                    [parts addObject:dpart];
                } else {
                    [part appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
                    [part appendString:value];
                    [parts addObject:[part dataUsingEncoding:NSUTF8StringEncoding]];
                }
            }
            
            NSString* boundary = [[self class] boundaryForParts:parts];
            
            NSMutableData* body = [NSMutableData data];
            for (NSData* part in parts) {
                [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:part];
            }
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            
            request.HTTPBody = body;
            [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
        }
    }
    
    if (_acceptAllCertificates)
        @synchronized (HostsAllowedAnyHTTPSCertificate) {
            [HostsAllowedAnyHTTPSCertificate addObject:url.host];
        }
    NSData* data = nil;
    NSHTTPURLResponse* response;
    @try {
        if (delegate) {
            HSSAPIURLConnectionDelegate* ucd = [[[HSSAPIURLConnectionDelegate alloc] initWithProgressDelegate:delegate] autorelease];
            [NSURLConnection connectionWithRequest:request delegate:ucd];
            while (!ucd.done)
                [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
            response = ucd.response;
            data = ucd.data;
        } else {
            data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
        }
    } @catch (NSException* e) {
        if (error) *error = [NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:e.reason forKey:NSLocalizedDescriptionKey]];
    } @finally {
        if (_acceptAllCertificates)
            @synchronized (HostsAllowedAnyHTTPSCertificate) {
                [HostsAllowedAnyHTTPSCertificate removeObjectAtIndex:[HostsAllowedAnyHTTPSCertificate indexOfObject:url.host]]; // don't use removeObject: because that method removes ALL occurrences of the object
            }
    }
    
    id r = nil;
    
    if (data.length) {
        NSString* s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
//        NSLog(@"response: %@", string);
        r = [s JSONValue];
//        NSLog(@"HSS API Response for %@ is %@", endpoint, response);
    }
    
    if (response.statusCode < 200 || response.statusCode >= 300) {
        if (error && [r isKindOfClass:[NSDictionary class]] && [[r objectForKey:@"error"] isKindOfClass:[NSString class]])
            *error = [NSError errorWithDomain:HSSErrorDomain code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:[r objectForKey:@"error"] forKey:NSLocalizedDescriptionKey]];
        if (error && !*error)
            *error = [NSError errorWithDomain:HSSErrorDomain code:response.statusCode userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat: r? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : NSLocalizedString(@"HTTP error: %@", nil), [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]] forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    return r;
}

- (HSSAPISession*)newSessionWithLogin:(NSString*)login password:(NSString*)password timeout:(NSTimeInterval)timeout error:(NSError**)error {
    HSSAPISession* session = [[[HSSAPISession alloc] initWithAPI:self login:login password:password] autorelease];
    BOOL ok = [session openWithTimeout:timeout error:error];
    return ok? session : nil;
}

@end

@implementation HSSAPIURLConnectionDelegate

@synthesize data = _data;
@synthesize response = _response;
@synthesize done = _done;
@synthesize error = _error;

- (id)initWithProgressDelegate:(id)delegate {
    if ((self = [super init])) {
        _delegate = [delegate retain];
        _data = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [_error release];
    [_data release];
    [_response release];
    [_delegate release];
    [super dealloc];
}

- (void)connection:(NSURLConnection*)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (_delegate)
        [_delegate performSelector:@selector(HSSAPIProgress:) withObject:[NSNumber numberWithFloat:float(totalBytesWritten)/totalBytesExpectedToWrite]];
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSHTTPURLResponse*)response {
    _response = [response retain];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [_data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    _done = YES;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    _error = [error retain];
    _done = YES;
}

@end

@implementation NSObject (HSS)

- (id)valueForKeyPath:(NSString*)keyPath ofClass:(Class)c {
    id value = [self valueForKeyPath:keyPath];
    if ([value isKindOfClass:c])
        return value;
    return nil;
}

- (NSString*)stringForKeyPath:(NSString*)keyPath {
    return [self valueForKeyPath:keyPath ofClass:[NSString class]];
}

@end


//
//  HSSAPI.h
//  HSS
//
//  Created by Alessandro Volz on 04.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSSAPISession;

@interface HSSAPI : NSObject {
    NSURL* _url;
    NSTimeInterval _timeoutInterval;
    BOOL _acceptAllCertificates;
}

@property NSTimeInterval timeoutInterval;
@property BOOL acceptAllCertificates;

+ (HSSAPI*)defaultAPI;

- (id)initWithBaseURL:(NSURL*)url;

//extern NSString* const HSSAPIPOSTFilePathKey;

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint parameters:(NSDictionary*)params error:(NSError**)error;
- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params error:(NSError**)error;
- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params progressDelegate:(id)delegate error:(NSError**)error;
- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params timeout:(NSTimeInterval)timeout error:(NSError**)error;
- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint cookies:(NSDictionary*)cookies parameters:(NSDictionary*)params timeout:(NSTimeInterval)timeout progressDelegate:(id)progressDelegate error:(NSError**)error;

- (HSSAPISession*)newSessionWithLogin:(NSString*)login password:(NSString*)password timeout:(NSTimeInterval)timeout error:(NSError**)error;

@end

@interface NSObject (HSS)

- (id)valueForKeyPath:(NSString*)keyPath ofClass:(Class)c;
- (NSString*)stringForKeyPath:(NSString*)keyPath;

@end
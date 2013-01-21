//
//  HSSAPISession.m
//  HSS
//
//  Created by Alessandro Volz on 05.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSS.h"
#import "HSSAPISession.h"
#import "HSSAPI.h"
#import <OsiriXAPI/NSDictionary+N2.h>

@interface HSSAPISession ()

@property(readwrite,retain) HSSAPI* api;
@property(readwrite,retain) NSString* apiSessionId;

@property(readwrite,retain) NSString* userLogin;
@property(readwrite,retain) NSString* userPassword;
@property(readwrite,retain) NSString* userHomeFolderOid;
@property(readwrite,retain) NSString* userOid;
@property(readwrite,retain) NSString* userName;

@end

@implementation HSSAPISession

@synthesize api = _api;
@synthesize apiSessionId = _apiSessionId;
@synthesize userLogin = _userLogin;
@synthesize userPassword = _userPassword;
@synthesize userHomeFolderOid = _userHomeFolderOid;
@synthesize userOid = _userOid;
@synthesize userName = _userName;

- (id)initWithAPI:(HSSAPI*)api login:(NSString*)login password:(NSString*)password {
    if ((self = [super init])) {
        self.api = api;
        self.userLogin = login;
        self.userPassword = password;
    }
    
    return self;
}

- (void)dealloc {
    self.api = nil;
    
    self.apiSessionId = nil;
    self.userHomeFolderOid = nil;
    self.userOid = nil;
    
    self.userLogin = nil;
    self.userPassword = nil;
    [super dealloc];
}

- (BOOL)openWithTimeout:(NSTimeInterval)timeout error:(NSError**)error {
    NSError* localError;
    if  (!error) error = &localError;
    
    NSDictionary* response = [self.api requestWithMethod:@"POST"
                                                endpoint:@"session"
                                                 cookies:nil
                                              parameters:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          self.userLogin, @"login",
                                                          self.userPassword, @"password",
                                                          @"1", @"fixed", nil]
                                                 timeout:timeout
                                                   error:error];
    
    if (*error || !response)
        return NO;
    
    self.userHomeFolderOid = [response stringForKeyPath:@"user.home_folder.oid"];
    self.userOid = [response stringForKeyPath:@"user.oid"];
    self.userName = [NSString stringWithFormat:@"%@ %@", [response stringForKeyPath:@"user.first_name"], [response stringForKeyPath:@"user.last_name"]];
    NSString* userLogin = [response stringForKeyPath:@"user.login"];
    if (userLogin) self.userLogin = userLogin;
    
    self.apiSessionId = [response stringForKeyPath:@"api_session.id"];
    if (self.apiSessionId)
        return YES;
    
    NSString* message = [response stringForKeyPath:@"message"];
    if (message)
        *error = [NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey]];
    else *error = [NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Unexpected HSS API response", nil) forKey:NSLocalizedDescriptionKey]];

    return NO;
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint parameters:(NSDictionary*)params error:(NSError**)error {
    return [self.api requestWithMethod:method
                              endpoint:endpoint
                               cookies:[NSDictionary dictionaryWithObject:self.apiSessionId forKey:@"studyshare_session"]
                            parameters:params
                                 error:error];
}

- (id)requestWithMethod:(NSString*)method endpoint:(NSString*)endpoint parameters:(NSDictionary*)params timeout:(NSTimeInterval)timeout progressDelegate:(id)delegate error:(NSError**)error {
    return [self.api requestWithMethod:method
                              endpoint:endpoint
                               cookies:[NSDictionary dictionaryWithObject:self.apiSessionId forKey:@"studyshare_session"]
                            parameters:params
                               timeout:timeout
                      progressDelegate:delegate
                                 error:error];
}

/*- (NSArray*)medcasesWithError:(NSError**)error {
    
    NSDictionary* response = [self requestWithMethod:@""
                                            endpoint:@"medcase"
                                          parameters:nil
                                               error:error];
    
    
    NSLog(@"Medcases: %@", response);
    
    return nil;
}*/

- (id)_treatResponseErrors:(id)response error:(NSError**)error {
    if (![response isKindOfClass:[NSDictionary class]])
        return response;
    
    NSString* errorString = [response stringForKeyPath:@"error"];
    if (errorString) {
        if (error)
            *error = [NSError errorWithDomain:HSSErrorDomain code:-1 userInfo:[NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey]];
        return nil;
    }
    
    return response;
}

- (NSArray*)getHomeFolderTreeWithError:(NSError**)error {
    //return [self getFolderTreeWithOid:_userHomeFolderOid error:error]; // a dictionary
    NSDictionary* response = [self requestWithMethod:@"GET"
                                            endpoint:[NSString stringWithFormat:@"user/%@/folder/tree", _userOid]
                                          parameters:nil
                                               error:error];
    response = [self _treatResponseErrors:response error:error];
    return response? [response objectForKey:@"folders"] : nil;
}

- (NSDictionary*)getFolderWithOid:(NSString*)oid error:(NSError**)error {
    NSDictionary* response = [self requestWithMethod:@"GET"
                                            endpoint:[NSString stringWithFormat:@"folder/%@", oid]
                                          parameters:nil
                                               error:error];
    return [self _treatResponseErrors:response error:error];
}

- (NSDictionary*)getFolderTreeWithOid:(NSString*)oid error:(NSError**)error {
    NSArray* response = [self requestWithMethod:@"GET"
                                       endpoint:[NSString stringWithFormat:@"folder/%@/tree", oid]
                                     parameters:nil
                                          error:error];
    response = [self _treatResponseErrors:response error:error];
    return response? [response objectAtIndex:0] : nil;
}

- (NSDictionary*)getMedcaseWithOid:(NSString*)oid error:(NSError**)error {
    NSDictionary* response = [self requestWithMethod:@"GET"
                                            endpoint:[NSString stringWithFormat:@"medcase/%@", oid]
                                          parameters:nil
                                               error:error];
    return [self _treatResponseErrors:response error:error];
}

- (NSArray*)getMedcasesRelatedToPatientId:(NSString*)patientId error:(NSError**)error {
    NSArray* response = [self requestWithMethod:@"POST"
                                       endpoint:@"medcase/related"
                                     parameters:[NSDictionary dictionaryWithObject:patientId forKey:@"patient_id"]
                                        timeout:(self.api.timeoutInterval > 400 ? self.api.timeoutInterval : 400) // we're doing this because HSS is currently extremely slow at returning this information, depending on the patient
                               progressDelegate:nil
                                          error:error];
    return [self _treatResponseErrors:response error:error];
}

- (NSDictionary*)postMedcaseWithZipFileAtPath:(NSString*)zipFilePath folderOid:(NSString*)folderOid progressDelegate:(id)delegate error:(NSError**)error {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionaryWithObject:[NSArray arrayWithObjects: @"mirc.zip", [NSData dataWithContentsOfFile:zipFilePath options:NSDataReadingUncached error:error], nil] forKey:@"mirc"];
    if (folderOid.length)
        [parameters setObject:folderOid forKey:@"folder"];
    
    NSDictionary* response = [self requestWithMethod:@"POST"
                                            endpoint:@"medcase"
                                          parameters:parameters
                                             timeout:MAXFLOAT
                                    progressDelegate:delegate
                                               error:error];
    return [self _treatResponseErrors:response error:error];
}

- (NSDictionary*)putFileAtPath:(NSString*)filePath intoMedcaseWithOid:(NSString*)oid error:(NSError**)error {
    NSDictionary* response = [self requestWithMethod:@"PUT"
                                            endpoint:[NSString stringWithFormat:@"medcase/%@", oid]
                                          parameters:[NSMutableDictionary dictionaryWithObject:[NSArray arrayWithObjects: @"image", [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:error], nil] forKey:@"image"]
                                             timeout:MAXFLOAT
                                    progressDelegate:nil
                                               error:error];
    return [self _treatResponseErrors:response error:error];
}

@end

//
//  HSSAPISession.h
//  HSS
//
//  Created by Alessandro Volz on 05.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSSAPI;

@interface HSSAPISession : NSObject {
    HSSAPI* _api;
    NSString* _apiSessionId;
    
    NSString* _userLogin;
    NSString* _userPassword;
    NSString* _userHomeFolderOid;
    NSString* _userOid;
    NSString* _userName;
}

@property(readonly,retain) HSSAPI* api;
@property(readonly,retain) NSString* apiSessionId;

@property(readonly,retain) NSString* userLogin;
@property(readonly,retain) NSString* userPassword;
@property(readonly,retain) NSString* userHomeFolderOid;
@property(readonly,retain) NSString* userOid;
@property(readonly,retain) NSString* userName;

- (id)initWithAPI:(HSSAPI*)api login:(NSString*)login password:(NSString*)password;

- (BOOL)openWithTimeout:(NSTimeInterval)timeout error:(NSError**)error;

- (NSArray*)getHomeFolderTreeWithError:(NSError**)error;
- (NSDictionary*)getFolderWithOid:(NSString*)folderOid error:(NSError**)error;
- (NSDictionary*)getFolderTreeWithOid:(NSString*)folderOid error:(NSError**)error;

- (NSDictionary*)getMedcaseWithOid:(NSString*)oid error:(NSError**)error;

- (NSArray*)getMedcasesRelatedToPatientId:(NSString*)patientId error:(NSError**)error;

- (NSDictionary*)postMedcaseWithZipFileAtPath:(NSString*)zipFilePath folderOid:(NSString*)folderOid progressDelegate:(id)delegate error:(NSError**)error;
- (NSDictionary*)putFileAtPath:(NSString*)filePath intoMedcaseWithOid:(NSString*)medcaseOid error:(NSError**)error;

@end

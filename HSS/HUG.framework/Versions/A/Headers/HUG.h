//
//  HUG.h
//  HUG Framework
//
//  Created by Alessandro Volz on 10.12.09.
//  Copyright 2009 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define HUGDevelopmentMode @"DEVE"
#define HUGTestMode @"TEST"
#define HUGFormationMode @"FORM"
#define HUGProductionMode @"PROD"


@interface HUG : NSObject {
}

+(NSString*)master;
+(NSString*)recommendedUsername __deprecated; // le concept "utilisateur recommandé" est éliminé

+(NSArray*)modes;
+(NSString*)mode;
+(void)setMode:(NSString*)mode;

+(NSString*)hostname;
+(NSString*)hostname:(NSArray**)rAddresses;
+(NSString*)blockForHostname:(NSArray**)rAddresses forTimeInterval:(NSTimeInterval)seconds;

+(NSString*)username;
+(NSString*)modalUsername;
+(NSString*)modalUsernameOnWindow:(NSWindow*)window;

+(NSString*)passwordForUser:(NSString*)user; // les mdp peuvent être stockés sur le disque dur pour faciliter la vie du programmeur

+(NSString*)certificate;
+(NSString*)modalCertificate __deprecated;
+(NSString*)modalCertificateOnWindow:(NSWindow*)window __deprecated;
+(void)startConditionalCertificateSheetOnWindow:(NSWindow*)window callbackTarget:(id)target selector:(SEL)sel context:(void*)context;

+(void)setCertificate:(NSString*)certificate __deprecated;
+(void)setCertificate:(NSString*)certificate password:(NSString*)password forUser:(NSString*)username;
//+(void)invalidateCertificate;

+(void)checkMasterUserAgain;

@end

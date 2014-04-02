//
//  Enterprise.h
//  HUG Framework
//
//  Created by Alessandro Volz on 21.12.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Enterprise : NSObject

+(NSString*)Name; // the enterprise's name, @"Apple"
+(NSString*)Username; // the current user's username (could be the OSX session username if LDAP is used, or extracted from some smartcard, or anything)
+(NSString*)StoredPasswordForUsername:(NSString*)username; // the passed username's password, if it was recently entered
+(void)StorePassword:(NSString*)password forUsername:(NSString*)username;

@end

//
//  LogEntry.h
//  Logger
//
//  Created by Arnaud Garcia on 27.09.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
// ==>voir doc dans LoggerHug.h

#import <Cocoa/Cocoa.h>


@interface LogEntry : NSObject {
	NSString* _app; // application
	NSString* _use; // usage DEV,PROD
	NSString* _dom; // domaine
	NSString* _hosts; // hostname du serveur
	NSString* _hostc; // hostname du client
	NSString* _ipc; // ip du client
	
	NSString* _pat; // code patient
	NSString* _urs; // intiale de l'utilisateur
	NSString* _role; // role du patient
	NSString* _dta; // champ libre
}

@property(retain) NSString* app;
@property(retain) NSString* use;
@property(retain) NSString* dom;
@property(retain) NSString* hosts;
@property(retain) NSString* hostc;
@property(retain) NSString* ipc;
@property(retain) NSString* pat;
@property(retain) NSString* urs;
@property(retain) NSString* role;
@property(retain) NSString* dta;

+(LogEntry*)sharedInstance DEPRECATED_ATTRIBUTE;
-(NSString*)encodeToXML;

@end

//
//  ServiceXML.h
//
//  Created by Arnaud
//
// ==> voir doc dans LoggerHug.h
#import <Cocoa/Cocoa.h>


@interface XMLServices : NSObject {
	NSXMLDocument* _xml;
	NSString* _url;
}

@property(readonly) NSXMLDocument* xml;
@property(retain,nonatomic) NSString* url;

+(NSString*&)URL;
+(void)setURL:(NSString*)url;
+(XMLServices*)sharedInstance;

-(void)reloadServiceListing;

#define XMLServicesUrlEntry @"URL"
#define XMLServicesWebUrlEntry @"WEBURL"
#define XMLServicesSoapUrlEntry @"SOAPURL"

-(NSArray*)extractServiceURLs:(NSString*)ID;
-(NSArray*)extractServiceURLs:(NSString*)ID mode:(NSString*)MODE;
-(NSArray*)extractServiceURLs:(NSString*)ID mode:(NSString*)MODE entry:(NSString*)entry;

extern NSString* const Logsrv2005Service;
extern NSString* const OsirixAuthenticationService;

-(NSArray*)logProdURLs DEPRECATED_ATTRIBUTE;
-(NSArray*)osirixAuthServerProdURLs DEPRECATED_ATTRIBUTE;

// ID=COMPACS, N=(A|B), mode=PROD/DEVE/TEST/FORM
-(NSURL*)logProdAURL DEPRECATED_ATTRIBUTE;
-(NSURL*)logProdBURL DEPRECATED_ATTRIBUTE;
-(NSURL*)osirixAuthentificationServerAURL DEPRECATED_ATTRIBUTE;
-(NSURL*)osirixAuthentificationServerBURL DEPRECATED_ATTRIBUTE;

@end

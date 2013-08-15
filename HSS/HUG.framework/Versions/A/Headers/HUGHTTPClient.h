//
//  HTTPClient.h
//  HUG Framework
//
//  Created by Alessandro Volz on 20.10.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "XMLServicesWebServiceClient.h"

//extern NSString* ReplaceDomain;


@interface HUGHTTPClient : XMLServicesWebServiceClient {
}

+(HUGHTTPClient*)sharedInstanceForIdentifier:(NSString*)identifier mode:(NSString*)mode;
-(NSData*)get:(id)path;

@end

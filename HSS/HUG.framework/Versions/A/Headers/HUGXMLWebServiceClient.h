//
//  HUGXMLWebServiceClient.h
//  HUG Framework
//
//  Created by Alessandro Volz on 15.10.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "XMLServicesWebServiceClient.h"


@interface HUGXMLWebServiceClient : XMLServicesWebServiceClient {
}

-(NSXMLNode*)execute:(NSString*)serviceId withBody:(id)body;
-(NSXMLNode*)execute:(NSString*)serviceId subservice:(NSString*)subserviceId withBody:(id)body;
-(NSXMLNode*)execute:(NSString*)serviceId subservice:(NSString*)subserviceId session:(NSString*)sessionId withBody:(id)body;

@end

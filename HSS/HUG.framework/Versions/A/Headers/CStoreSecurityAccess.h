//
//  CStoreSecurityAccess.h
//  Logger
//
//  Created by Arnaud Garcia on 28.09.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "XMLServicesWebServiceClient.h"


@interface CStoreSecurityAccess : XMLServicesWebServiceClient {
}

+(BOOL)isStoreAuthorizedForHost:(NSString*)host;

@end

//
//  HUGSOAPWebServiceClient.h
//  HUG Framework
//
//  Created by Alessandro Volz on 19.03.2011.
//  Copyright 2011 HUG. All rights reserved.
//

#import "XMLServicesWebServiceClient.h"


@interface HUGSOAPWebServiceClient : XMLServicesWebServiceClient {
}

-(id)execute:(NSString*)methodName withParameterNamesAndValues: firstName, ...;

@end

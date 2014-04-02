//
//  Logger.h
//  Logger
//
//  Created by Arnaud Garcia on 26.09.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "HUGXMLWebServiceClient.h"
@class LogEntry;


@interface Logger : HUGXMLWebServiceClient {
}

+(void)send:(id)entry;
-(BOOL)sendFullMessage:(NSString*)message DEPRECATED_ATTRIBUTE;
-(BOOL)sendAutoCompleteMessage:(NSString*)message DEPRECATED_ATTRIBUTE;

@end

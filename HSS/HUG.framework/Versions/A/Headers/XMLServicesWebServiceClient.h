//
//  XMLServicesWebServiceClient.h
//  HUG Framework
//
//  Created by Alessandro Volz on 15.10.09.
//  Copyright 2009 HUG. All rights reserved.
//

#import "N2RedundantWebServiceClient.h"


@interface XMLServicesWebServiceClient : N2RedundantWebServiceClient {
	NSString* _identifier;
	NSString* _mode;
}

@property(retain) NSString* identifier;
@property(retain) NSString* mode;

-(id)initWithIdentifier:(NSString*)identifier;
-(id)initWithIdentifier:(NSString*)identifier mode:(NSString*)mode;
-(NSArray*)extractServiceURLs;

@end

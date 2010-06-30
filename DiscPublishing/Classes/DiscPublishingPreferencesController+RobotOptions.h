//
//  DiscPublishingPreferencesController+RobotOptions.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 6/24/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import "DiscPublishingPreferencesController.h"


@interface DiscPublishingPreferencesController (RobotOptions)

-(void)robotOptionsInit;
-(void)robotOptionsDealloc;
-(BOOL)robotOptionsObserveValueForKeyPath:(NSString*)keyPath ofObject:(id)obj change:(NSDictionary*)change context:(void*)context;

@end

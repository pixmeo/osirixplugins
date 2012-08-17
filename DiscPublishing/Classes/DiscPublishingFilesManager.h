//
//  DiscPublishingFilesManager.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscPublishingFilesManager : NSObject {
	@private
	NSMutableDictionary* _serviceStacks;
    NSTimer* _publishTimer;
}

-(id)invalidate;

@end

//
//  DiscPublishingFilesManager.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 2/26/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DiscPublishingFilesManager : NSThread {
	@private
	NSMutableArray* _files;
	NSLock* _filesLock;
	NSDate* _lastReceiveTime;
	NSMutableDictionary* _patientsLastReceiveTimes;
}

@property(retain) NSDate* lastReceiveTime;
@property(readonly) NSMutableDictionary* patientsLastReceiveTimes;

-(id)invalidate;

@end

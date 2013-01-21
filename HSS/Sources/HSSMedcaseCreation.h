//
//  HSSMedcaseCreation.h
//  HSS
//
//  Created by Alessandro Volz on 09.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HSSAPISession;
@class HSSItem;

@interface HSSMedcaseCreation : NSThread {
    HSSAPISession* _session;
    NSString* _caseName;
    NSArray* _images;
    HSSItem* _destination;
    NSString* _diagnosis;
    NSString* _history;
    BOOL _openFlag;
@private
    BOOL _connectionDone;
    NSMutableData* _connectionData;
    NSWindow* _docWindow;
}

@property(retain) HSSAPISession* session;
@property(retain) NSString* caseName;
@property(retain) NSArray* images;
@property(retain) HSSItem* destination;
@property(retain) NSString* diagnosis;
@property(retain) NSString* history;
@property BOOL openFlag;
@property(retain) NSWindow* docWindow;

- (id)initWithSession:(HSSAPISession*)session;

@end

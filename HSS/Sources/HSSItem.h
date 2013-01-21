//
//  HSSItem.h
//  HSS
//
//  Created by Alessandro Volz on 11.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HSSItem : NSArrayController {
    NSString* _oid;
    NSString* _name;
    BOOL _assignable;
}

@property(retain) NSString* oid;
@property(retain) NSString* name;
@property BOOL assignable;

extern NSString* const HSSTab;

- (NSMutableString*)descriptionWithTab:(NSInteger)t;

@end

//
//  HSSFolder.h
//  HSS
//
//  Created by Alessandro Volz on 06.01.12.
//  Copyright (c) 2012 OsiriX Team. All rights reserved.
//

#import "HSSItem.h"

@interface HSSFolder : HSSItem {
    NSAttributedString* _desc;
    NSInteger _numCases;
}

@property(retain) NSAttributedString* desc;
@property NSInteger numCases;

- (void)syncWithAPIFolders:(NSArray*)items;
- (void)syncWithAPIMedcases:(NSArray*)items;

@end

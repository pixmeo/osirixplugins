//
//  Worklist+POD.h
//  Worklists
//
//  Created by Alessandro Volz on 19.09.12.
//
//

#import "Worklist.h"


@class DicomDatabase;


@interface Worklist (POD)

- (void)autoretrieveWithDatabase:(DicomDatabase*)db;
- (void)autoretrieve;

@end

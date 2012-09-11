//
//  WorklistsPreferencesController.m
//  Worklists
//
//  Created by Alessandro Volz on 09/11/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "WorklistsPreferencesController.h"
#import "WorklistsPlugin.h"


@implementation WorklistsPreferencesController

@synthesize worklistsTable = _worklistsTable;

- (NSArrayController*)worklists {
    return [[WorklistsPlugin instance] worklists]; // NSClassFromString(@"WorklistsPlugin")
}

+ (NSString*)stringWithUUID {
    CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
    //get the string representation of the UUID
    NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return [uuidString autorelease];
}

- (IBAction)add:(id)caller {
    NSString* uid = [[self class] stringWithUUID];
    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithObjectsAndKeys: uid, @"id", nil];
    
    [self.worklists addObject:dic];
    
    [self.worklists setSelectedObjects:[NSArray arrayWithObject:dic]];
    [self.worklistsTable editColumn:0 row:[self.worklists.arrangedObjects indexOfObject:dic] withEvent:nil select:YES];

}

- (void)tableViewTextDidEndEditing:(NSNotification*)n {
    [self.worklists rearrangeObjects];
}

@end

@interface WorklistsTableView : NSTableView

@end

@implementation WorklistsTableView

- (void)textDidEndEditing:(NSNotification*)n {
    [super textDidEndEditing:n];
    if ([self.delegate respondsToSelector:@selector(tableViewTextDidEndEditing:)])
        [self.delegate performSelector:@selector(tableViewTextDidEndEditing:) withObject:n];
}

@end

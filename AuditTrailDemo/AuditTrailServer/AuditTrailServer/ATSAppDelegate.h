//
//  ATSAppDelegate.h
//  AuditTrailServer
//
//  Created by Joël Spaltenstein on 7/8/12.
//  Copyright (c) 2012 Spaltenstein Natural Image. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ATSAppDelegate : NSObject <NSApplicationDelegate>
{
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
}

@property (retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSArrayController *arrayController;

@end

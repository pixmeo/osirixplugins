/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - LGPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

#import <Cocoa/Cocoa.h>


@interface N2ManagedDatabase : NSObject {
	@protected
    NSString *_sqlFilePath;
	@private
	NSManagedObjectContext *_managedObjectContext;
    NSPersistentStore *mainStore;
    id _mainDatabase;
    volatile BOOL _isDeallocating;
    
    NSTimeInterval timeOfLastModification;
    NSThread *associatedThread;
}

@property(readonly) NSThread* associatedThread;
@property(readonly) NSPersistentStore *mainStore;
@property(readonly,retain) NSString* sqlFilePath;
@property(readonly) NSManagedObjectModel* managedObjectModel;
@property(readwrite,retain) NSManagedObjectContext* managedObjectContext; // only change this value if you know what you're doing
@property NSTimeInterval timeOfLastModification;
@property(readonly,retain) id mainDatabase; // for independentDatabases
-(BOOL)isMainDatabase;

// locking actually locks the context
-(void)lock;
-(BOOL)lockBeforeDate:(NSDate*) date;
-(BOOL)tryLock;
-(void)unlock;
#ifndef NDEBUG
-(void) checkForCorrectContextThread;
-(void) checkForCorrectContextThread: (NSManagedObjectContext*) c;
#endif
// write locking uses writeLock member
//-(void)writeLock;
//-(BOOL)tryWriteLock;
//-(void)writeUnlock;

+(NSString*) modelName;
-(BOOL) deleteSQLFileIfOpeningFailed;
-(BOOL) dumpSqlFile;
-(NSManagedObjectModel*)managedObjectModel;
//-(NSMutableDictionary*)persistentStoreCoordinatorsDictionary;
-(BOOL)migratePersistentStoresAutomatically; // default implementation returns YES
-(NSPersistentStore*) addPersistentStoreWithPath: (NSString*) sqlFilePath;
-(void) removeAllSecondaryStores;

-(id)initWithPath:(NSString*)sqlFilePath;
-(id)initWithPath:(NSString*)sqlFilePath context:(NSManagedObjectContext*)context;
-(id)initWithPath:(NSString*)sqlFilePath context:(NSManagedObjectContext*)context mainDatabase:(N2ManagedDatabase*)mainDbReference;

- (void) renewManagedObjectContext;
-(NSManagedObjectContext*)independentContext:(BOOL)independent;
-(NSManagedObjectContext*)independentContext;
-(id)independentDatabase;
-(id)independentDatabaseIfNotMainThread;
-(BOOL) managedObjectContextExist;
-(NSEntityDescription*)entityForName:(NSString*)name;

-(id)objectWithID:(id)oid;
-(NSArray*)objectsWithIDs:(NSArray*)objectIDs;

// in these methods, e can be an NSEntityDescription* or an NSString*
-(NSArray*)objectsForEntity:(id)e;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err;
-(NSArray*)objectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)error fetchLimit:(NSUInteger)fetchLimit sortDescriptors:(NSArray*)sortDescriptors;
-(NSUInteger)countObjectsForEntity:(id)e;
-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p;
-(NSUInteger)countObjectsForEntity:(id)e predicate:(NSPredicate*)p error:(NSError**)err;
-(id)newObjectForEntity:(id)e;

-(BOOL)save;
-(BOOL)save:(NSError**)err;

-(void)deleteSqlFiles;
+(void)deleteSqlFiles: (NSString*) sqlIndex;
@end

@interface N2ManagedDatabase (Protected)

-(NSManagedObjectContext*)contextAtPath:(NSString*)sqlFilePath;

@end

@interface N2ManagedObjectContext : NSManagedObjectContext {
    
	N2ManagedDatabase* _database;
}

@property(readonly) N2ManagedDatabase* database;
@end

//
//  ZombiesFilter.m
//  Zombies
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "ZombiesFilter.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/NSThread+N2.h>
#import <OsiriXAPI/ThreadsManager.h>
#import <OsiriXAPI/NSFileManager+N2.h>
#import <OsiriXAPI/N2Stuff.h>
#import <objc/runtime.h>

@implementation ZombiesFilter

- (void) initPlugin
{
    Class dd = NSClassFromString(@"DicomDatabase");
    if (!dd || !class_getClassMethod(dd, @selector(activeLocalDatabase)))
        [NSException raise:NSGenericException format:@"This plugin is only compatible with more recent versions of OsiriX"];
}

- (long) filterImage:(NSString*) menuName
{
    [NSThread performBlockInBackground:^{
        NSThread* thread = [NSThread currentThread];
        thread.name = NSLocalizedString(@"Scanning for zombies...", nil);
        thread.status = NSLocalizedString(@"Preparing...", nil);
        thread.supportsCancel = YES;
        [ThreadsManager.defaultManager addThreadAndStart:thread];
        
        thread.threadPriority = 0.0;
        
        DicomDatabase* xdatabase = [DicomDatabase activeLocalDatabase];
        DicomDatabase* idatabase = [xdatabase independentDatabase];
        
        NSArray* iimages = [idatabase objectsForEntity:idatabase.imageEntity];
        NSMutableArray* ipaths = [NSMutableArray array];
        for (NSInteger i = 0; i < iimages.count; ++i) {
            thread.progress = 1.0*i/iimages.count;
            DicomImage* iimage = [iimages objectAtIndex:i];
            NSString* path = iimage.completePath;
            if (![ipaths containsObject:path])
                [ipaths addObject:path];
        }
        
        NSString* base = [idatabase dataDirPath];
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDirectoryEnumerator* de = [fm enumeratorAtPath:base filesOnly:YES recursive:YES];
        NSUInteger filesCount = 0, zombiesCount = 0;
        NSString* sub;
        while ((sub = [de nextObject]) && !thread.isCancelled) {
            [NSThread sleepForTimeInterval:0.001];
            
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            thread.status = [NSString stringWithFormat:NSLocalizedString(@"Zombies found: %d of %@", nil), zombiesCount, N2LocalizedSingularPluralCount(filesCount, @"file", @"files")];
            @try {
                NSString* path = [base stringByAppendingPathComponent:sub]; 
                BOOL isDir;
                if ([fm fileExistsAtPath:path isDirectory:&isDir] && !isDir) {
                    NSString* name = [[path lastPathComponent] stringByDeletingPathExtension];
                    NSInteger num = [name integerValue];
                    if (num > 0) {
                        ++filesCount;

                        if ([ipaths containsObject:path])
                            continue;
                        
                        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"pathNumber = %@", [NSNumber numberWithInteger:num]];
                        
                        // look for a database image object that points to this image path number
//                        NSArray* iarray = [iimages filteredArrayUsingPredicate:predicate]; // this is actually slower than querying CoreData
                        NSArray* iarray = [idatabase objectsForEntity:idatabase.imageEntity predicate:predicate];
                        if (iarray.count > 0)
                            continue; // there is an NSImage pointing to that file in our independent database
                        // the independent database isn't synced to the main database, so make sure that such object doesn't exist in the main db
                        NSArray* xarray = [xdatabase objectsForEntity:xdatabase.imageEntity predicate:predicate];
                        if (xarray.count > 0)
                            continue; // there is an NSImage pointing to that file in the main database
                        
                        // if we're here, it means the current iteration is a zombie, zap it
                        //[fm removeItemAtPath:path error:NULL];
                        
                        NSLog(@"I should kill this, but shall I? %@", path);
                        
                        ++zombiesCount;
                    }
                }
            } @catch (...) {
                // do nothing
            } @finally {
                [pool release];
            }
        }
        
        thread.status = NSLocalizedString(@"Cleaning up...", nil);
    }];
    
    return 0;
}

@end

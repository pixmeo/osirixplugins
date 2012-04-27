//
//  ZombiesFilter.m
//  Zombies
//
//  Copyright (c) 2012 OsiriX. All rights reserved.
//

#import "ZombiesFilter.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/N2Debug.h>
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
        @try {
            thread.name = NSLocalizedString(@"Scanning for zombies...", nil);
            thread.status = NSLocalizedString(@"Preparing...", nil);
            thread.supportsCancel = YES;
            [ThreadsManager.defaultManager addThreadAndStart:thread];
            
            thread.threadPriority = 0.0;
            
            DicomDatabase* xdatabase = [DicomDatabase activeLocalDatabase];
            DicomDatabase* idatabase = [xdatabase independentDatabase];
            
            thread.status = NSLocalizedString(@"Listing images...", nil);
            NSArray* iimages = [idatabase objectsForEntity:idatabase.imageEntity];
            if (thread.isCancelled) return;

            NSMutableArray* ipaths = [NSMutableArray array];
            thread.status = NSLocalizedString(@"Finding image file paths...", nil);
            __block NSInteger c = 0;
            dispatch_apply(iimages.count, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
                if (thread.isCancelled) return;
                @synchronized (iimages) {
                    ++c;
                }
                thread.progress = 1.0*c/iimages.count;
                DicomImage* iimage = [iimages objectAtIndex:i];
                NSString* path = iimage.completePath;
                @synchronized (ipaths) {
                    [ipaths addObject:path];
                }
            });
            if (thread.isCancelled) return;
            
            thread.progress = -1;
            thread.status = NSLocalizedString(@"Sorting files list...", nil);
            [ipaths sortUsingSelector:@selector(compare:)];
            thread.status = NSLocalizedString(@"Optimizing files list...", nil);
            for (int i = 0; i < ipaths.count-1; ++i) {
                if (thread.isCancelled) return;
                thread.progress = 1.0*i/ipaths.count;
                NSString* io = [ipaths objectAtIndex:i];
                while (i < ipaths.count-1 && [[ipaths objectAtIndex:i+1] isEqualToString:io])
                    [ipaths removeObjectAtIndex:i+1];
            }
            
            thread.progress = -1;
            
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

                            // if this file is in the ipaths array, it means there's a DicomImage explicitly pointing to it
                            if ([ipaths containsObject:path])
                                continue;
                            
                            // otherwise, look for a DicomImage with that path's number
                            
                            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"pathNumber = %@", [NSNumber numberWithInteger:num]];
                            
                            // look for a database image object that points to this image path number
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
        } @catch (NSException* e) {
            N2LogExceptionWithStackTrace(e);
        } @finally {
            thread.status = NSLocalizedString(@"Cleaning up...", nil);
        }
    }];
    
    return 0;
}

@end

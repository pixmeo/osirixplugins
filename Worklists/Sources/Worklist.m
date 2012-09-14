//
//  Worklist.m
//  Worklists
//
//  Created by Alessandro Volz on 09/14/2012.
//  Copyright 2012 OsiriX Team. All rights reserved.
//

#import "Worklist.h"
#import "WorklistsPlugin.h"
#import <OsiriXAPI/DicomDatabase.h>
#import <OsiriXAPI/DicomAlbum.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/Notifications.h>


NSString* const WorklistIDKey = @"id";
NSString* const WorklistAlbumIDKey = @"album_id";
NSString* const WorklistNameKey = @"name";
NSString* const WorklistHostKey = @"host";
NSString* const WorklistPortKey = @"port";
NSString* const WorklistAETKey = @"aet";
NSString* const WorklistRefreshSecondsKey = @"refreshSeconds";
NSString* const WorklistAutoRetrieveKey = @"autoRetrieve";


@interface Worklist ()

@property(retain,readwrite) NSDate* lastRefreshDate;

//+ (void)worklistWithID:(NSString*)wid setAlbumID:(NSString*)aid;

@end


@implementation Worklist

@synthesize lastRefreshDate = _lastRefreshDate;
@synthesize properties = _properties;

+ (id)worklistWithProperties:(NSMutableDictionary*)properties {
    return [[[[self class] alloc] initWithProperties:properties] autorelease];
}

-(id)initWithProperties:(NSMutableDictionary*)properties {
    if ((self = [super init])) {
        self.properties = properties;
    }
    
    return self;
}

- (void)dealloc {
    self.lastRefreshDate = nil;
    self.properties = nil;
    [super dealloc];
}

+ (void)invaludateAlbumsCacheForDatabase:(DicomDatabase*)db {
    [NSNotificationCenter.defaultCenter postNotificationName:O2DatabaseInvalidateAlbumsCacheNotification object:db];
}

- (void)setProperties:(NSMutableDictionary*)properties {
    if (properties != _properties) {
        [_properties release];
        _properties = [properties retain];
    }
    
    if (!properties)
        return;
    
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    NSString* name = [_properties objectForKey:WorklistNameKey];
    if (!name.length)
        name = NSLocalizedString(@"Worklist", nil);
    
    // make sure it has an album
    NSString* albumId = [_properties objectForKey:WorklistAlbumIDKey];
    DicomAlbum* album = nil;
    if (albumId) // make sure the album exists
        if ((album = [db objectWithID:albumId]) == nil) // it doesn't
            albumId = nil;
        else {
            // make sure the album name matches the name property
            album.name = name;
        }
    if (!albumId) { // create the album
        album = [db newObjectForEntity:[db albumEntity]];
        album.name = name;
        [album.managedObjectContext save:NULL]; // we want a persistent NSManagedObject ID, that is only given on save
        albumId = [[album.objectID URIRepresentation] absoluteString];
        [_properties setObject:albumId forKey:WorklistAlbumIDKey];
    }
    
    [[self class] invaludateAlbumsCacheForDatabase:db];
    [BrowserController.currentBrowser refreshAlbums];

}

- (void)delete {
    DicomDatabase* db = [DicomDatabase defaultDatabase];
    
    // TODO: if album is selected, select database
    
    // delete the album
    NSString* albumId = [_properties objectForKey:WorklistAlbumIDKey];
    DicomAlbum* album = [db objectWithID:albumId];
    [db.managedObjectContext deleteObject:album];

    [[self class] invaludateAlbumsCacheForDatabase:db];
    [BrowserController.currentBrowser refreshAlbums];
}

/*+ (void)worklistWithID:(NSString*)wid setAlbumID:(NSString*)aid {
    NSArrayController* worklists = [[WorklistsPlugin instance] worklists];
    
    NSInteger i = [[worklists.content valueForKey:WorklistIDKey] indexOfObject:wid];
    if (i == NSNotFound)
        return NSLog(@"Warning: couldn't set the album ID of an unidentified worklist with ID %@", wid);
    
    NSMutableDictionary* wp = [worklists.content objectAtIndex:i];
    
    [wp setObject:aid forKey:WorklistAlbumIDKey];
}
*/






























@end

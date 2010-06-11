//
//  DiscPublishingPatientDisc.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions, DiscBurningOptions;//, DicomSeries;

@interface DiscPublishingPatientDisc : NSThread {
	@private
	NSMutableArray* _files;
	DiscPublishingOptions* _options;
	NSString* _tmpPath;
}

-(id)initWithFiles:(NSArray*)files options:(DiscPublishingOptions*)options;

+(NSArray*)prepareSeriesDataForImages:(NSArray*)images inDirectory:(NSString*)dirPath options:(DiscBurningOptions*)options context:(NSManagedObjectContext*)managedObjectContext seriesPaths:(NSMutableDictionary*)seriesPaths;

@end

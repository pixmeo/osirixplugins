//
//  DiscPublishingPatientDisc.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/2/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DiscPublishingOptions, DiscBurningOptions;//, DicomSeries;
@class DicomDatabase;


@interface DiscPublishingPatientDisc : NSThread {
	@private
	NSMutableArray* _images;
    NSManagedObjectContext* _icontext;
	DiscPublishingOptions* _options;
	NSString* _tmpPath;
    NSWindow* _window;
}

@property(retain) NSWindow* window;

-(id)initWithImages:(NSArray*)images options:(DiscPublishingOptions*)options;

+(NSArray*)prepareSeriesDataForImages:(NSArray*)imagesIn inDirectory:(NSString*)basePath options:(DiscBurningOptions*)options database:(DicomDatabase*)db seriesPaths:(NSMutableDictionary*)seriesPaths;

@end

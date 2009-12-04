//
//  MIRCThumbnail.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MIRCThumbnail : NSObject {
	NSString *_path;
	NSImage *_image;
	

}

+ (id)imageWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;
- (NSString *)path;
- (NSString *)title;
- (NSImage *)image;


@end

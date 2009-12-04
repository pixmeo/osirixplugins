//
//  MIRCThumbnail.m
//  TeachingFile
//
//  Created by Lance Pysher on 8/13/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import "MIRCThumbnail.h"
#import "DCMPix.h"
#import <QuartzCore/QuartzCore.h>


@implementation MIRCThumbnail

- (id)copyWithZone:(NSZone *)zone{
	return [[MIRCThumbnail alloc] initWithPath:_path];
}

+ (id)imageWithPath:(NSString *)path{
	return [[[MIRCThumbnail alloc] initWithPath:path] autorelease];
}

- (id)initWithPath:(NSString *)path{
	if (self = [super init]){
		_path = [path retain];
		
		float			*fVolumePtr = 0L;
		DCMPix *pix = [[DCMPix alloc] myinit:_path :0 :1 :fVolumePtr :0 :0];
		NSData *tiff = [[pix generateThumbnailImageWithWW: 0 WL: 0] TIFFRepresentation];
		_image = [[NSImage alloc] initWithData:tiff];
		[pix release];		
	}
	return self;
}

- (void)dealloc{
	[_image release];
	[_path release];
	[super dealloc];
}
	
- (NSString *)path{
	return _path;
}
- (NSString *)title{
	return [_path lastPathComponent];
}
- (NSImage *)image{
	return _image;
}



@end

//
//  DicomCompressor.h
//  DiscPublishing
//
//  Created by Alessandro Volz on 3/4/10.
//  Copyright 2010 OsiriX Team. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum Compression {
	CompressionDont = 0,
	CompressionCompress = 1,
	CompressionDecompress = 2
};

@interface DicomCompressor : NSObject

+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath;
+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptions:(NSDictionary*)options;
+(void)decompressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptionsPath:(NSString*)optionsPlistPath;

+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath;
+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptions:(NSDictionary*)options;
+(void)compressFiles:(NSArray*)filePaths toDirectory:(NSString*)dirPath withOptionsPath:(NSString*)optionsPlistPath;

@end

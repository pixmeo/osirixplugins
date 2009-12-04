//
//  MIRCImage.h
//  TeachingFile
//
//  Created by Lance Pysher on 8/24/05.
//  Copyright 2005 Macrad, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSXMLElement  (MIRCImage) 

+ (id)image;
+ (id)altImage;

- (NSString *)path;
- (void)setPath:(NSString *)path;

- (NSArray *)alternativeImages;
- (NSXMLElement *)alternativeImageWithRole:(NSString *)role;
- (NSXMLElement *)newAltImageWithRole:(NSString *)role  src:(NSString *)src;

- (void)setOriginalFormatImage:(NSXMLElement *)altImage;
- (void)setOriginalDimensionImage:(NSXMLElement *)altImage;
- (void)setAnnotationImage:(NSXMLElement *)altImage;
- (void)setOriginalFormatImagePath:(NSString *)path;
- (void)setOriginalDimensionImagePath:(NSString *)path;
- (void)setAnnotationImagePath:(NSString *)path;

- (NSXMLElement *)originalFormatImage;
- (NSXMLElement *)originalDimensionImage;
- (NSXMLElement *)annotationImage;
- (NSString *)originalFormatImagePath;
- (NSString *)originalDimensionImagePath;
- (NSString *)annotationImagePath;







@end

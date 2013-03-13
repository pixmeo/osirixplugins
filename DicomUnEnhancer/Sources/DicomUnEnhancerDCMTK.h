//
//  DicomUnEnhancerDCMTK.h
//  DicomUnEnhancer
//
//  Created by Alessandro Volz on 11.10.11.
//  Copyright 2011 OsiriX Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DicomUnEnhancerDCMTK : NSObject

+(NSString*)processFileAtPath:(NSString*)path intoDirInPath:(NSString*)destDirPath;

@end
